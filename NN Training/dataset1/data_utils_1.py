import pandas as pd
import numpy as np
from gtda.time_series import SlidingWindow
import matplotlib.pyplot as plt
from math import atan2, pi, sqrt, atan2, sin, cos, radians, ceil
from scipy.fft import fft
from tqdm import tqdm
import math
from geographiclib.geodesic import Geodesic

'''
Input: 
dataset_folder: where the dataset is located at.
type_flag: import training or test set. 1 is train, anything else is test.
window_size, stride: window size and stride.


Output:
X: Windowed 9DoF IMU readings 
Y_Pos: Windowed ground truth positions
GPS: windowed longitude, lattitude
GPS_xy: windowed cartesian position from GPS
Physics_vec: Windowed physics metadata channel
x_vel, y_vel: windowed x and y velocities (output of NN)
x0_list, y0_list: initial coordinates for each trajectory (useful for plotting)
size_of_each: index of new trajectory in windowed files (useful for plotting)
'''

def import_agrobot_dataset_p2(dataset_folder = './dataset/AgroBot Dataset/dataset1', type_flag = 1, window_size = 50, stride = 5):
    
    x0_list = []
    y0_list = []
    size_of_each = []
    X = np.empty([0, window_size, 9])
    GPS = np.empty([0, window_size, 2])
    GPS_xy = np.empty([0, window_size, 2])
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
    print('List of log files being imported: ',list_of_files)
    for line in tqdm(list_of_files):
        #Import IMU and Ground Truth
        cur_file = pd.read_csv(dataset_folder+line)
        #unit of ground truth: meters
        cur_GT = cur_file[['OptiTrackX','OptiTrackZ']].to_numpy()
        #Take care of missing data
        for i in range(cur_GT.shape[1]):
            mask = np.isnan(cur_GT[:,i])
            cur_GT[mask,i] = np.interp(np.flatnonzero(mask), np.flatnonzero(~mask), cur_GT[~mask,i])
        # acc: m/s^2, gyro: rad/s, mag: uT
        cur_train = cur_file[['field.linear_acceleration.x_RAW','field.linear_acceleration.y_RAW',
                              'field.linear_acceleration.z_RAW',
                              'field.angular_velocity.x','field.angular_velocity.y',
                              'field.angular_velocity.z',
                              'field.magnetic_field.x','field.magnetic_field.y',
                              'field.magnetic_field.z']].to_numpy()
        cur_train[:,0:3] = cur_train[:,0:3]*(1/9.80665) #m/s^2 to g
        #take care of missing data
        ind = np.where(~np.isnan(cur_train))[0]
        first, last = ind[0], ind[-1]
        cur_train[:first] = cur_train[first]
        cur_train[last + 1:] = cur_train[last]
        
        cur_GPS = cur_file[['field.longitude_GPS','field.latitude_GPS']].to_numpy()
        #take care of missing data
        for i in range(cur_GPS.shape[1]):
            mask = np.isnan(cur_GPS[:,i])
            cur_GPS[mask,i] = np.interp(np.flatnonzero(mask), np.flatnonzero(~mask), cur_GPS[~mask,i])
        
        cur_GPS_len = long_lat_to_x_y(cur_GPS) #long, lat data to x,y data
        
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
            
        cur_GPS_3D = windows.fit_transform(cur_GPS[:,0])
        for i in range(1,cur_GPS.shape[1]):
            X_windows = windows.fit_transform(cur_GPS[:,i])
            cur_GPS_3D = np.dstack((cur_GPS_3D,X_windows)) 
            
        cur_GPS_len_3D = windows.fit_transform(cur_GPS_len[:,0])
        for i in range(1,cur_GPS_len.shape[1]):
            X_windows = windows.fit_transform(cur_GPS_len[:,i])
            cur_GPS_len_3D = np.dstack((cur_GPS_len_3D,X_windows))         
        
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
        GPS = np.vstack((GPS, cur_GPS_3D))
        GPS_xy = np.vstack((GPS_xy, cur_GPS_len_3D))
        x0_list.append(cur_GT[0,0])
        y0_list.append(cur_GT[0,1])
        size_of_each.append(cur_GT_3D.shape[0])
        x_vel = np.concatenate((x_vel, vx))
        y_vel = np.concatenate((y_vel, vy))
        
    return X,Y_pos, GPS, GPS_xy, Physics_Vec, x_vel, y_vel, x0_list, y0_list, size_of_each
      
def long_lat_to_x_y(long_lat_mat):
    x_y_z_mat = np.zeros((long_lat_mat.shape[0],3))
    geod = Geodesic.WGS84
    lat_init = long_lat_mat[0,1]
    long_init = long_lat_mat[0,0]
    for i in range(1,long_lat_mat.shape[0]):
        g = geod.Inverse(lat_init,long_init,long_lat_mat[i,1],long_lat_mat[i,0])
        x_y_z_mat[i,0] = g['s12']*np.cos(np.abs(radians(g['azi1'])))
        x_y_z_mat[i,1] = g['s12']*np.sin(np.abs(radians(g['azi1'])))
    return x_y_z_mat[:,0:2]
