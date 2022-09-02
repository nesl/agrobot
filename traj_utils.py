from math import atan2, pi, sqrt, atan2, sin, cos, radians, ceil
import math
import numpy as np
from scipy import interpolate


'''
generate ATE and RTE values

inputs:
Gvx, Gvy: Ground truth velocity (in m/s)
Pvx, Pvy: neural network predicted velocity (in m/s)
sampling_rate: data sampling rate
window_size and stride: input window size and stride for training set
length: how many samples?

outputs:
ate,rte: ATE and RTE (in m)
at_all, rt_all: Trajectory lengths (full, and 60 seconds) (in m)

'''
def Cal_TE(Gvx, Gvy, Pvx, Pvy, sampling_rate=100,window_size=200,stride=10,length=None):
    
    if length==None:
        length = len(Gvx)
        
    distance = []
    
    for i in range(length):
        d = ((Gvx[i]-Pvx[i])*(Gvx[i]-Pvx[i])) + ((Gvy[i]-Pvy[i])*(Gvy[i]-Pvy[i]))
        d = math.sqrt(d)
        distance.append(d)
    
    mean_distance = sum(distance)/len(distance)
    ate = mean_distance
    at_all = distance
    
    n_windows_one_min= int(((sampling_rate*60)-window_size)/stride)
    distance = []
    if(n_windows_one_min < length):
        for i in range(n_windows_one_min):
            d = ((Gvx[i]-Pvx[i])*(Gvx[i]-Pvx[i])) + ((Gvy[i]-Pvy[i])*(Gvy[i]-Pvy[i]))
            d = math.sqrt(d)
            distance.append(d)
        rte = sum(distance)/len(distance)
    else:
        rte=ate*(n_windows_one_min/length)
    
    rt_all = distance
    return ate, rte, at_all, rt_all


'''Calculate Trajectory Length

inputs:
Gvx, Gvy: Velocity
length: how many samples?

outputs:
sum_distance: trajectory length in meters

'''
def Cal_len_meters(Gvx, Gvy, length=None):
    if length==None:
        length = len(Gvx)
        
    distance = []
    
    for i in range(1, length):
        d = ((Gvx[i]-Gvx[i-1])*(Gvx[i]-Gvx[i-1])) + ((Gvy[i]-Gvy[i-1])*(Gvy[i]-Gvy[i-1]))
        d = math.sqrt(d)
        distance.append(d)
    
    sum_distance = sum(distance)
    
    return sum_distance  


'''
generate trajectory from ground truth velocity for specific file

inputs:
GT_vel_x, GT_vel_y: Ground truth velocity (in m/s)
size_of_each: index of new trajectory in windowed files 
x0_list, y0_list: initial coordinates for each trajectory 
window_size and stride: input window size and stride for training set
file_idx: index of the file to be considered

outputs:
Gvx, Gvy: x and y position (in m)

'''
def GT_pos_generator(GT_vel_x, GT_vel_y, size_of_each, 
                   x0_list, y0_list, window_size, stride,file_idx):  
    if (file_idx == 0):
        x_vel_test_sel = GT_vel_x[0:size_of_each[0]]
        y_vel_test_sel = GT_vel_y[0:size_of_each[0]]
    elif (file_idx == 1):
        x_vel_test_sel = GT_vel_x[np.sum(size_of_each[0]):np.sum(size_of_each[0:file_idx+1])]
        y_vel_test_sel = GT_vel_y[np.sum(size_of_each[0]):np.sum(size_of_each[0:file_idx+1])]

    else:
        x_vel_test_sel = GT_vel_x[np.sum(size_of_each[0:file_idx]):np.sum(size_of_each[0:file_idx+1])]
        y_vel_test_sel = GT_vel_y[np.sum(size_of_each[0:file_idx]):np.sum(size_of_each[0:file_idx+1])]

    pointx = []
    pointy = []
    Lx =  x0_list[file_idx]
    Ly = y0_list[file_idx]
    for j in range(len(x_vel_test_sel)):
        Lx = Lx + (x_vel_test_sel[j]/(((window_size-stride)/stride)))
        Ly = Ly + (y_vel_test_sel[j]/(((window_size-stride)/stride)))    
        pointx.append(Lx)
        pointy.append(Ly)   
    Gvx = pointx
    Gvy = pointy
    
    return Gvx, Gvy


'''
generate synthetic GPS values for specific file from ground truth velocities

inputs:
GT_vel_x, GT_vel_y: Ground truth velocity (in m/s)
size_of_each: index of new trajectory in windowed files 
x0_list, y0_list: initial coordinates for each trajectory 
window_size and stride: input window size and stride for training set
file_idx: index of the file to be considered
decimation factor: by what factor to downsample GPS compared to  IMU stride? (e.g. if stride is 20 for 100 Hz sampling rate and window size of 100, the network runs at 4 Hz. A decimation factor of 4 would equate to 1s GPS interval
pos_noise_var, velocity_noise_var: GPS position and velocity noise variance, in m^2 and (m/s)^2

outputs:
Gvx, Gvy: x and y position (in m)
GPS_vel_x, GPS_vel_y: x and y velocities from GPS position (in m/s)

'''

def gen_GPS_values(GT_vel_x, GT_vel_y, size_of_each, 
                   x0_list, y0_list, window_size, stride,  file_idx,
                  decimation_factor, pos_noise_var, velocity_noise_var):

    if (file_idx == 0):
        x_vel_test_sel = GT_vel_x[0:size_of_each[0]]
        y_vel_test_sel = GT_vel_y[0:size_of_each[0]]
    elif (file_idx == 1):
        x_vel_test_sel = GT_vel_x[np.sum(size_of_each[0]):np.sum(size_of_each[0:file_idx+1])]
        y_vel_test_sel = GT_vel_y[np.sum(size_of_each[0]):np.sum(size_of_each[0:file_idx+1])]

    else:
        x_vel_test_sel = GT_vel_x[np.sum(size_of_each[0:file_idx]):np.sum(size_of_each[0:file_idx+1])]
        y_vel_test_sel = GT_vel_y[np.sum(size_of_each[0:file_idx]):np.sum(size_of_each[0:file_idx+1])]

    pointx = []
    pointy = []
    Lx =  x0_list[file_idx]
    Ly = y0_list[file_idx]
    for j in range(len(x_vel_test_sel)):
        Lx = Lx + (x_vel_test_sel[j]/(((window_size-stride)/stride)))
        Ly = Ly + (y_vel_test_sel[j]/(((window_size-stride)/stride)))    
        pointx.append(Lx)
        pointy.append(Ly)   
    Gvx = pointx
    Gvy = pointy
    GPS_vel_x = np.insert(np.ediff1d(Gvx),0,0.0)
    GPS_vel_y = np.insert(np.ediff1d(Gvy),0,0.0)
    if(decimation_factor!=0):
        Gvx = Gvx[0::decimation_factor]
        Gvy = Gvy[0::decimation_factor]
        GPS_vel_x = GPS_vel_x[0::decimation_factor]
        GPS_vel_y = GPS_vel_y[0::decimation_factor]        
    if(pos_noise_var != 0 and velocity_noise_var!=0):
        Gvx = Gvx + np.random.normal(0,sqrt(pos_noise_var),len(Gvx))
        Gvy = Gvy + np.random.normal(0,sqrt(pos_noise_var),len(Gvy))
        GPS_vel_x = GPS_vel_x + np.random.normal(0,sqrt(velocity_noise_var),len(GPS_vel_x))
        GPS_vel_y = GPS_vel_y + np.random.normal(0,sqrt(velocity_noise_var),len(GPS_vel_y))    
    
    return Gvx, Gvy, GPS_vel_x, GPS_vel_y


'''
generate  synthetic GPS values for  all files

inputs:
GT_vel_x, GT_vel_y: Ground truth velocity (in m/s)
size_of_each: index of new trajectory in windowed files 
x0_list, y0_list: initial coordinates for each trajectory 
window_size and stride: input window size and stride for training set
decimation factor: by what factor to downsample GPS compared to  IMU stride? (e.g. if stride is 20 for 100 Hz sampling rate and window size of 100, the network runs at 4 Hz. A decimation factor of 4 would equate to 1s GPS interval
pos_noise_var, velocity_noise_var: GPS position and velocity noise variance, in m^2 and (m/s)^2

outputs:
Gvx_list, Gvy_list: x and y position (in m)
Gvx_vel_list, Gvy_vel_list: x and y velocities from GPS position (in m/s)
size_of_each_GPS_list: index of new trajectory in the output velocities and positions

'''
def gen_GPS_values_all_traj(GT_vel_x, GT_vel_y, size_of_each, 
                   x0_list, y0_list, window_size, stride,
                  decimation_factor, pos_noise_var,velocity_noise_var):
    Gvx_list = []
    Gvy_list = []
    Gvx_vel_list = []
    Gvy_vel_list = []
    size_of_each_GPS_list = []
    
    for i in range(len(size_of_each)):
        Gvx, Gvy, GPS_vel_x, GPS_vel_y = gen_GPS_values(GT_vel_x,GT_vel_y,
                          size_of_each,x0_list,y0_list,window_size,stride,i,decimation_factor,pos_noise_var,velocity_noise_var)
        
        Gvx_list.append(Gvx)
        Gvy_list.append(Gvy)
        Gvx_vel_list.append(GPS_vel_x)
        Gvy_vel_list.append(GPS_vel_y)
        size_of_each_GPS_list.append(len(Gvx))
    return Gvx_list, Gvy_list,Gvx_vel_list, Gvy_vel_list, size_of_each_GPS_list


'''
generate trajectory from neural network predicted velocity for specific file


inputs:
net_inp_mat: The processed and windowed NN input (e.g. the test set matrix)
size_of_each: index of new trajectory in windowed files 
x0_list, y0_list: initial coordinates for each trajectory 
window_size and stride: input window size and stride for training set
file_idx: index of the file to be considered
my_model: the neural network in keras, loaded using model.load(MODEL_NAME.h5)

outputs:
Pvx, Pvy: predicted x and y position (in m)

'''

def model_pos_generator(net_inp_mat, size_of_each, 
                   x0_list, y0_list, window_size, stride,file_idx,my_model):
    
    if (file_idx == 0):
        cur_inp = net_inp_mat[0:size_of_each[0],:,:]
    elif (file_idx == 1):
        cur_inp = net_inp_mat[np.sum(size_of_each[0]):np.sum(size_of_each[0:file_idx+1]),:,:]

    else:
        cur_inp = net_inp_mat[np.sum(size_of_each[0:file_idx]):np.sum(size_of_each[0:file_idx+1]),:,:]    
    
    y_pred = my_model.predict(cur_inp)
    
    pointx = []
    pointy = []
    Lx =  x0_list[file_idx]
    Ly = y0_list[file_idx]
    for j in range(len(cur_inp)):
        Lx = Lx + (y_pred[0][j][0]/(((window_size-stride)/stride)))
        Ly = Ly + (y_pred[1][j][0]/(((window_size-stride)/stride)))
        pointx.append(Lx)
        pointy.append(Ly)
    Pvx = pointx
    Pvy = pointy   
    
    return Pvx, Pvy


'''
resample gps to match ground truth sampling rate, but with nearest interpolation

inputs:
x_gps, y_gps: GPs position (x,y) or GPS velocity(x,y)
gt_x: either x or y ground truth velocities

outputs:
gps_x_res, gps_y_res: resampled GPS position or velocity

'''
def resample_GPS(x_gps,y_gps,gt_x):
    my_x = np.linspace(0,len(gt_x),len(x_gps))
    f1 = interpolate.interp1d(my_x, x_gps,kind='nearest')
    f2 = interpolate.interp1d(my_x, y_gps,kind='nearest')

    gps_x_res = f1(np.linspace(0,len(gt_x),len(gt_x))) 
    gps_y_res = f2(np.linspace(0,len(gt_x),len(gt_x)))  
    
    return gps_x_res,gps_y_res