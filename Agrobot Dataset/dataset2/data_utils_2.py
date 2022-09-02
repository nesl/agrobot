import pandas as pd
import numpy as np
from gtda.time_series import SlidingWindow
import matplotlib.pyplot as plt
from math import atan2, pi, sqrt, atan2, sin, cos, radians, ceil
from scipy.fft import fft
from tqdm import tqdm
import math
from pyproj import Transformer
from scipy.io import savemat

'''
Input: 
dataset_folder: where the dataset is located at.
type_flag: import training or test set. 1 is train, anything else is test.
window_size, stride: window size and stride.


Output:
X: Windowed 9DoF IMU readings 
Y_Pos: Windowed ground truth positions
Physics_vec: Windowed physics metadata channel
x_vel, y_vel: windowed x and y velocities (output of NN)
x0_list, y0_list: initial coordinates for each trajectory (useful for plotting)
size_of_each: index of new trajectory in windowed files (useful for plotting)
'''

def import_agrobot_dataset_p3(dataset_folder = './dataset/AgroBot Dataset/dataset2', type_flag = 1, window_size = 50, stride = 5):
    
    x0_list = []
    y0_list = []
    size_of_each = []
    X = np.empty([0, window_size, 9])
    Y_pos = np.empty([0,window_size, 2])
    x_vel = np.empty([0])
    y_vel = np.empty([0])
    Physics_Vec = np.empty([0])
    
    if(type_flag==1):
        type_file = 'train.txt'
    else:
        type_file = 'test.txt'
    with open(dataset_folder+type_file, 'r') as f:
        list_of_files = [line.strip() for line in f]
    with open(dataset_folder+'groundTruthScaleFactors.txt', 'r') as f:
        sf = [line.strip() for line in f]
    print('List of log files being imported: ',list_of_files)
    for line in tqdm(list_of_files):
        #Import IMU and Ground Truth
        cur_file = pd.read_csv(dataset_folder+line)
        #unit of ground truth: meters
        cur_GT = cur_file[['X','Y']].to_numpy()
        scale_factor = [int(s) for s in sf[[idx for idx, s in enumerate(sf) if line in s][0]].split() if s.isdigit()][0]
        cur_GT = cur_GT*(1.0/scale_factor)
        #Take care of missing data
        for i in range(cur_GT.shape[1]):
            mask = np.isnan(cur_GT[:,i])
            cur_GT[mask,i] = np.interp(np.flatnonzero(mask), np.flatnonzero(~mask), cur_GT[~mask,i])
        # acc: m/s^2, gyro: rad/s, mag: uT
        cur_train = cur_file[['field_linear_acceleration_x_RAW','field_linear_acceleration_y_RAW',
                              'field_linear_acceleration_z_RAW',
                              'field_angular_velocity_x','field_angular_velocity_y',
                              'field_angular_velocity_z',
                              'field_magnetic_field_x','field_magnetic_field_y',
                              'field_magnetic_field_z']].to_numpy()
        cur_train[:,0:3] = cur_train[:,0:3]*(1/9.80665) #m/s^2 to g
        #take care of missing data
        ind = np.where(~np.isnan(cur_train))[0]
        first, last = ind[0], ind[-1]
        cur_train[:first] = cur_train[first]
        cur_train[last + 1:] = cur_train[last]

        windows = SlidingWindow(size=window_size, stride=stride)
        #Window IMU Readings
        cur_train_3D = windows.fit_transform(cur_train[:,0])
        for i in range(1,cur_train.shape[1]):
            X_windows = windows.fit_transform(cur_train[:,i])
            cur_train_3D = np.dstack((cur_train_3D,X_windows))
        #Window Ground Truth
        cur_GT_3D = windows.fit_transform(cur_GT[:,0])
        for i in range(1,cur_GT.shape[1]):
            X_windows = windows.fit_transform(cur_GT[:,i])
            cur_GT_3D = np.dstack((cur_GT_3D,X_windows))
                      
        #Extract Physics Channel
        loc_mat = np.empty((cur_train_3D.shape[0]))
        for i in range(cur_train_3D.shape[0]):
            acc_x =  cur_train_3D[i,:,0]
            acc_y =  cur_train_3D[i,:,1]
            acc_z =  cur_train_3D[i,:,2]
            VecSum = np.sqrt(acc_x**2 + acc_y**2 + acc_z**2)
            VecSum = VecSum - np.mean(VecSum)
            FFT_VS = fft(VecSum)
            P2 = np.abs(FFT_VS/acc_x.shape[0])
            P1 = P2[0:math.ceil(acc_x.shape[0]/2)]
            P1[1:-1-2] = 2*P1[1:-1-2]
            loc_mat[i] = np.mean(P1)  
        #Extract Ground Truth Velocity
        vx = np.zeros((cur_GT_3D.shape[0]))
        vy = np.zeros((cur_GT_3D.shape[0]))
        for i in range(cur_GT_3D.shape[0]): 
            Xdisp = (cur_GT_3D[i,-1,0]-cur_GT_3D[i,0,0])
            vx[i] = Xdisp
            Ydisp = (cur_GT_3D[i,-1,1]-cur_GT_3D[i,0,1])
            vy[i] = Ydisp
        #Stack readings
        X = np.vstack((X, cur_train_3D))
        Physics_Vec = np.concatenate((Physics_Vec,loc_mat))
        Y_pos = np.vstack((Y_pos, cur_GT_3D))
        x0_list.append(cur_GT[0,0])
        y0_list.append(cur_GT[0,1])
        size_of_each.append(cur_GT_3D.shape[0])
        x_vel = np.concatenate((x_vel, vx))
        y_vel = np.concatenate((y_vel, vy))
        
    return X,Y_pos, Physics_Vec, x_vel, y_vel, x0_list, y0_list, size_of_each


'''
Input: 
dataset_folder: where the dataset is located at.
type_flag: import training or test set. 1 is train, anything else is test.
decimation_factor: GPS decimation factor (e.g., if IMU is sampled at 100 Hz, a decimation factor of 100 would yield 1 Hz GPS
sampling_rate_imu: sampling rate of imu
pos_noise_var, velocity_noise_var:  GPS position and velocity noise variance, in m^2 and (m/s)^2
magnetometer_noise_var: noise variance of magnetometer, in (uT)^2


Output:
MATLAB file containing IMU data, ground truth position, GPS data (lat, lon, alt), measurement errors, etc. for use
with MATLAB's EKF IMU-GPS demo
'''

def export_agrobot_dataset_p3_to_matlab(dataset_folder = './dataset/AgroBot Dataset/dataset2/', 
                                        type_flag = 1, decimation_factor = 100, sampling_rate_imu=100.0, 
                                        pos_noise_var = 1.5**2,
                                       velocity_noise_var = 0.0025,
                                       magnetometer_noise_var = 0.09):
    if(type_flag==1):
        type_file = 'train.txt'
    else:
        type_file = 'test.txt'
    with open(dataset_folder+type_file, 'r') as f:
        list_of_files = [line.strip() for line in f]
    with open(dataset_folder+'groundTruthScaleFactors.txt', 'r') as f:
        sf = [line.strip() for line in f]
    print('List of log files being imported: ',list_of_files)
    for line in tqdm(list_of_files):
        #Import IMU and Ground Truth
        cur_file = pd.read_csv(dataset_folder+line)
        #unit of ground truth: meters
        cur_GT = cur_file[['X','Y']].to_numpy()
        scale_factor = [int(s) for s in sf[[idx for idx, s in enumerate(sf) if line in s][0]].split() if s.isdigit()][0]
        cur_GT = cur_GT*(1.0/scale_factor)
        #Take care of missing data
        for i in range(cur_GT.shape[1]):
            mask = np.isnan(cur_GT[:,i])
            cur_GT[mask,i] = np.interp(np.flatnonzero(mask), np.flatnonzero(~mask), cur_GT[~mask,i])
        # acc: m/s^2, gyro: rad/s, mag: uT
        cur_train = cur_file[['field_linear_acceleration_x_RAW','field_linear_acceleration_y_RAW',
                              'field_linear_acceleration_z_RAW',
                              'field_angular_velocity_x','field_angular_velocity_y',
                              'field_angular_velocity_z',
                              'field_magnetic_field_x','field_magnetic_field_y',
                              'field_magnetic_field_z']].to_numpy()
        cur_train[:,0:3] = cur_train[:,0:3]*(1/9.80665) #m/s^2 to g
        #take care of missing data
        ind = np.where(~np.isnan(cur_train))[0]
        first, last = ind[0], ind[-1]
        cur_train[:first] = cur_train[first]
        cur_train[last + 1:] = cur_train[last]
        
        gt_pos_x = cur_GT[:,0]
        gt_pos_y = cur_GT[:,1]
        gt_pos_z = np.hstack(np.zeros((cur_GT.shape[0],1)))
        
        
        #generate synthetic GPS
        x_pos = cur_GT[:,0]
        y_pos = cur_GT[:,1]
        z_pos = np.hstack(np.zeros((len(x_pos),1)))
        vel_x = np.insert(np.ediff1d(x_pos),0,0.0)
        vel_y = np.insert(np.ediff1d(y_pos),0,0.0)
        vel_z = np.insert(np.ediff1d(z_pos),0,0.0)
        if(decimation_factor!=0):
            x_pos = x_pos[0::decimation_factor]
            y_pos = y_pos[0::decimation_factor]
            z_pos = z_pos[0::decimation_factor]
            vel_x = vel_x[0::decimation_factor]
            vel_y = vel_y[0::decimation_factor] 
            vel_z = vel_z[0::decimation_factor]
        if(pos_noise_var != 0 and velocity_noise_var!=0):
            x_pos = x_pos + np.random.normal(0,sqrt(pos_noise_var),len(x_pos))
            y_pos = y_pos + np.random.normal(0,sqrt(pos_noise_var),len(y_pos))
            z_pos = z_pos + np.random.normal(0,sqrt(pos_noise_var),len(z_pos))
            vel_x = vel_x + np.random.normal(0,sqrt(velocity_noise_var),len(vel_x))
            vel_y = vel_y + np.random.normal(0,sqrt(velocity_noise_var),len(vel_y))
            vel_z = vel_z + np.random.normal(0,sqrt(velocity_noise_var),len(vel_z))
        accel = cur_train[:,0:3]*9.80665
        gyro = cur_train[:,3:6]
        mag = cur_train[:,3:6]
        truePos = np.concatenate((gt_pos_x.reshape(gt_pos_x.shape[0],1),
                                  gt_pos_y.reshape(gt_pos_y.shape[0],1),
                                  gt_pos_z.reshape(gt_pos_z.shape[0],1)),axis=1)
        gpsvel = np.concatenate((vel_x.reshape(vel_x.shape[0],1),
                                  vel_y.reshape(vel_y.shape[0],1),
                                  vel_z.reshape(vel_z.shape[0],1)),axis=1)
                
        lon_mat=[]
        lat_mat = []
        transformer = Transformer.from_crs("epsg:3857","epsg:4326")
        for j in range(len(x_pos)):
            lon,lat = transformer.transform(x_pos[j],y_pos[j])
            lon_mat.append(lon)
            lat_mat.append(lat)
        lon_mat = np.array(lon_mat)
        lat_mat = np.array(lat_mat)
        refloc = [lat_mat[0],lon_mat[0],0] #pseudo-location
        lla = np.concatenate((lat_mat.reshape(lat_mat.shape[0],1),
                                  lon_mat.reshape(lon_mat.shape[0],1),
                                  z_pos.reshape(z_pos.shape[0],1)),axis=1)
        
        Rpos = pos_noise_var
        Rvel = velocity_noise_var
        Rmag = magnetometer_noise_var
        gpsFs = sampling_rate_imu/decimation_factor
        imuFs = sampling_rate_imu
        
        mdic = {"accel": accel, "gyro": gyro, "mag": mag, "lla": lla, 
                "gpsvel": gpsvel, "truePos": truePos, "imuFs": imuFs, "gpsFs": gpsFs, 
               "Rpos": Rpos, "Rvel": Rvel, "Rmag": Rmag, "refloc": refloc}
        savemat(dataset_folder+"dset2_"+line[0:-4]+".mat", mdic)
