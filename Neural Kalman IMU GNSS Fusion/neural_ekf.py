from math import atan2, pi, sqrt, atan2, sin, cos, radians, ceil
import math
import numpy as np
from scipy import interpolate
from traj_utils import *
from tqdm import tqdm
import tensorflow as tf


ACCELEROMETER_NOISE_VARIANCE = 0.00615490459 # 0.00615490459 #(m/s^2)^2, 0.0011858
GYROSCOPE_NOISE_VARIANCE = 0.0000030462#0.0000030462 #(rad/s)^2 0.0000030462
MAGNETOMETER_NOISE_VARIANCE = 0.36 #0.36 #ut^2 0.09 
GYROSCOPE_ARW = [3.09, 2.7, 5.4] #[3.09, 2.7, 5.4] #deg/sqrt(hr) [11.28, 12.85,13.45]
GYROSCOPE_BI = [88.91,78.07,211.4] #[88.91,78.07,211.4] #deg/hr [45.9, 54.68, 52.38]

GPS_VELOCITY_NOISE_VARIANCE = 0.0025
GPS_POSITION_NOISE_VARIANCE = 1.5**2

def kalman_predict(X, P, Q, A, B, G,T):
    X = A@X + B@T
    P = A@P@np.transpose(A) + G@Q@np.transpose(G)
    return X,P

def kalman_update(X,P,z,R,H):
    K = (P@np.transpose(H))@np.linalg.inv(H@P@np.transpose(H) + R)
    X = X + K@(z-H@X)
    P = P-K@H@P
    return X, P

'''
inputs:
net_inp_mat: Windowed training data for imu, equals a q X window_size X n_channels matrix (q is 10 when acc,gyr,mag and physics used)
GT_vel_x, GT_vel_y: ground truth velocities (to generate synthetic GPS)
size_of_each: index of new trajectory in windowed files 
x0_list, y0_list: initial coordinates for each trajectory 
window_size and stride: input window size and stride for training set
file_idx: index of the trajectory to be considered
decimation factor: by what factor to downsample GPS compared to  IMU stride? (e.g. if stride is 20 for 100 Hz sampling rate and window size of 100, the network runs at 4 Hz. A decimation factor of 4 would equate to 1s GPS interval
my_model: the neural network in keras, loaded using model.load(MODEL_NAME.h5)

outputs:
fused_pos_x, fused_pos_y: GPS+IMU position
GPS_x, GPS_y: GPS position (for debugging)

'''

def neural_ekf_gnss_imu(net_inp_mat, GT_vel_x,GT_vel_y, size_of_each,
                x0_list, y0_list,file_idx,window_size,stride,
                gps_decimation_factor,
                my_model):
    
    fused_pos_x = []
    fused_pos_y = []
    
    dt = stride/(window_size-stride)
    ########################################
    #using emulated GPS here, you can input original GPS data if available
    Gvx_gps, Gvy_gps, Gvx_vel, Gvy_vel, _ = gen_GPS_values_all_traj(GT_vel_x,GT_vel_y,
                          size_of_each,x0_list,y0_list,window_size,stride,gps_decimation_factor,
                          GPS_POSITION_NOISE_VARIANCE, GPS_VELOCITY_NOISE_VARIANCE)
    
    GPS_x = Gvx_gps[file_idx]
    GPS_y = Gvy_gps[file_idx]
    GPS_vel_x = Gvx_vel[file_idx]
    GPS_vel_y = Gvy_vel[file_idx]
    ########################################
    if (file_idx == 0):
        cur_inp = net_inp_mat[0:size_of_each[0],:,:]
    elif (file_idx == 1):
        cur_inp = net_inp_mat[np.sum(size_of_each[0]):np.sum(size_of_each[0:file_idx+1]),:,:]

    else:
        cur_inp = net_inp_mat[np.sum(size_of_each[0:file_idx]):np.sum(size_of_each[0:file_idx+1]),:,:]
        
    X = np.array([x0_list[file_idx],y0_list[file_idx],0.0,0.0]).reshape(4,1)
    A = np.array(((1.0,0.0,0.0,0.0),(0.0,1.0,0.0,0.0),(0.0,0.0,0.0,0.0),(0.0,0.0,0.0,0.0)))
    H = np.identity(4)
    B = np.array(((dt, 0.0),(0.0,dt),(1.0,0),(0.0,1.0)))
    R = np.identity(4) 
    R[0,0] = GPS_POSITION_NOISE_VARIANCE
    R[1,1] = GPS_POSITION_NOISE_VARIANCE
    R[2,2] = GPS_VELOCITY_NOISE_VARIANCE
    R[3,3] = GPS_VELOCITY_NOISE_VARIANCE
    
    P = 1e-5*np.zeros((4,4))
    gps_counter = 1
    for i in tqdm(range(cur_inp.shape[0])):
        image = tf.cast(cur_inp[i,:,:].reshape(1,cur_inp.shape[1],cur_inp.shape[2]), tf.float32)
        with tf.GradientTape(persistent=True) as t:
            t.watch(image)
            vx_jacob = my_model(image)[0][0]
            vy_jacob = my_model(image)[1][0]
            pred = my_model(image)
            
        my_grad1 = np.array(t.gradient(vx_jacob, image)).reshape(cur_inp.shape[1],cur_inp.shape[2])
        my_grad2 = np.array(t.gradient(vy_jacob, image)).reshape(cur_inp.shape[1],cur_inp.shape[2])
            
                    
        T = np.array(pred).flatten().reshape(2,1)
        
        G = np.zeros((4,10))
        for j in range(10):
            G[0,j] = dt*np.sum(np.abs(my_grad1[:,j]))/np.sum(np.abs(my_grad1))
            G[1,j] = dt*np.sum(np.abs(my_grad2[:,j]))/np.sum(np.abs(my_grad2))
            G[2,j] = np.sum(np.abs(my_grad1[:,j]))/np.sum(np.abs(my_grad1))
            G[3,j] = np.sum(np.abs(my_grad2[:,j]))/np.sum(np.abs(my_grad2)) 
     
        
        Q = np.diag((ACCELEROMETER_NOISE_VARIANCE,
                     ACCELEROMETER_NOISE_VARIANCE,
                     ACCELEROMETER_NOISE_VARIANCE,
                     ((np.deg2rad(GYROSCOPE_ARW[0])/60.0)*sqrt(dt))**2+(np.deg2rad(GYROSCOPE_BI[0])/3600.0)**2+GYROSCOPE_NOISE_VARIANCE,     
                     ((np.deg2rad(GYROSCOPE_ARW[1])/60.0)*sqrt(dt))**2+(np.deg2rad(GYROSCOPE_BI[1])/3600.0)**2+GYROSCOPE_NOISE_VARIANCE,                      
                     ((np.deg2rad(GYROSCOPE_ARW[2])/60.0)*sqrt(dt))**2+(np.deg2rad(GYROSCOPE_BI[2])/3600.0)**2+GYROSCOPE_NOISE_VARIANCE,                      
             MAGNETOMETER_NOISE_VARIANCE,
             MAGNETOMETER_NOISE_VARIANCE,
             MAGNETOMETER_NOISE_VARIANCE,
             3*ACCELEROMETER_NOISE_VARIANCE               
            ))

        X, P = kalman_predict(X, P, Q, A, B, G,T)
        
        if(i%gps_decimation_factor == 0 and gps_counter < len(GPS_x)):
            z = np.array((GPS_x[gps_counter],GPS_y[gps_counter],GPS_vel_x[gps_counter],GPS_vel_y[gps_counter])).reshape(4,1)
            X, P = kalman_update(X,P,z,R,H) 
            gps_counter+=1
        
        fused_pos_x.append(X[0,0])
        fused_pos_y.append(X[1,0])
    
    return fused_pos_x, fused_pos_y, GPS_x, GPS_y