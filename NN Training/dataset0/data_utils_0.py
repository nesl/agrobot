import pandas as pd
import numpy as np
from gtda.time_series import SlidingWindow
import matplotlib.pyplot as plt
from math import atan2, pi, sqrt, atan2, sin, cos, radians, ceil
from scipy.fft import fft
from tqdm import tqdm
import math



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

def import_agrobot_dataset_p1(dataset_folder = './dataset/AgroBot Dataset/dataset0', type_flag = 1, window_size = 50, stride = 5):
    
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
    print('List of log files being imported: ',list_of_files)
    for line in tqdm(list_of_files):
        #Import IMU and Ground Truth
        cur_file = pd.read_csv(dataset_folder+line)
        #unit of ground truth: meters
        cur_GT = cur_file[['X','Z']].to_numpy()
        #Take care of missing data
        for i in range(cur_GT.shape[1]):
            mask = np.isnan(cur_GT[:,i])
            cur_GT[mask,i] = np.interp(np.flatnonzero(mask), np.flatnonzero(~mask), cur_GT[~mask,i])
        #unit of IMU and compass data: acc: g, gyro: dps mag: uT
        cur_train = cur_file[['Ax','Ay','Az','Gx','Gy','Gz','Mx','My','Mz']].to_numpy()
        cur_train[:,3:6] = cur_train[:,3:6]*0.0174533 #dps to rad/s
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
    
    

