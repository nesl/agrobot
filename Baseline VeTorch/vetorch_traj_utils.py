from math import atan2, pi, sqrt, atan2, sin, cos, radians, ceil
import math
import numpy as np




def abs_heading(cur_x, cur_y, prev_x, prev_y):
        dely = (cur_y - prev_y)
        delx = (cur_x - prev_x)
        delh= atan2(delx,dely)*57.2958
        return delh
   
'''
generate trajectory from neural network predicted heading and displacement for specific file


inputs:
net_inp_mat1: The processed and windowed NN input for displacement model (e.g. the test set matrix)
net_inp_mat2: The processed and windowed NN input for heading model (e.g. the test set matrix)
size_of_each: index of new trajectory in windowed files 
x0_list, y0_list: initial coordinates for each trajectory 
window_size and stride: input window size and stride for training set
file_idx: index of the file to be considered
my_model1: the displacement neural network in keras, loaded using model.load(MODEL_NAME.h5)
my_model2: the heading neural network in keras, loaded using model.load(MODEL_NAME.h5)

outputs:
Pvx, Pvy: predicted x and y position (in m)

'''
    
def vetorch_pos_generator(net_inp_mat1, net_inp_mat_2, size_of_each, 
                   x0_list, y0_list, window_size, stride,file_idx,my_model1, my_model2):
    
    if (file_idx == 0):
        cur_inp1 = net_inp_mat1[0:size_of_each[0],:,:]
        cur_inp2 = net_inp_mat2[0:size_of_each[0],:,:]
    elif (file_idx == 1):
        cur_inp1 = net_inp_mat1[np.sum(size_of_each[0]):np.sum(size_of_each[0:file_idx+1]),:,:]
        cur_inp2 = net_inp_mat2[np.sum(size_of_each[0]):np.sum(size_of_each[0:file_idx+1]),:,:]

    else:
        cur_inp1 = net_inp_mat1[np.sum(size_of_each[0:file_idx]):np.sum(size_of_each[0:file_idx+1]),:,:]    
        cur_inp2 = net_inp_mat2[np.sum(size_of_each[0:file_idx]):np.sum(size_of_each[0:file_idx+1]),:,:]  
    
    y_pred1 = my_model1.predict(cur_inp1)
    y_pred2 = my_model2.predict(cur_inp2)
    
    pointx = []
    pointy = []
    Lx =  x0_list[file_idx]
    Ly = y0_list[file_idx]
    for j in range(len(cur_inp)):
        Lx = Lx + (y_pred1[0][i]/(((window_size-stride)/stride)))*cos(y_pred2[0][i])
        Ly = Ly + (y_pred1[0][i]/(((window_size-stride)/stride)))*sin(y_pred2[0][i])
        pointx.append(Lx)
        pointy.append(Ly)
    Pvx = pointx
    Pvy = pointy   
    
    return Pvx, Pvy


'''
generate trajectory from ground truth displacement and heading for specific file

inputs:
disp, head: displacement and heading (in m and rad)
size_of_each: index of new trajectory in windowed files 
x0_list, y0_list: initial coordinates for each trajectory 
window_size and stride: input window size and stride for training set
file_idx: index of the file to be considered

outputs:
Gvx, Gvy: x and y position (in m)

'''

def vetorch_GT_pos_generator(disp, head, size_of_each, 
                   x0_list, y0_list, window_size, stride,file_idx):  
    if (file_idx == 0):
        disp_sel = disp[0:size_of_each[0]]
        head_sel = head[0:size_of_each[0]]
    elif (file_idx == 1):
        disp_sel = disp[np.sum(size_of_each[0]):np.sum(size_of_each[0:file_idx+1])]
        head_sel = head[np.sum(size_of_each[0]):np.sum(size_of_each[0:file_idx+1])]

    else:
        disp_sel = disp[np.sum(size_of_each[0:file_idx]):np.sum(size_of_each[0:file_idx+1])]
        head_sel = head[np.sum(size_of_each[0:file_idx]):np.sum(size_of_each[0:file_idx+1])]

    head_sel = head_sel*0.0174533
    pointx = []
    pointy = []
    Lx =  x0_list[file_idx]
    Ly = y0_list[file_idx]
    for j in range(len(x_vel_test_sel)):
        Lx = Lx + (disp_sel[i]/(((window_size-stride)/stride)))*cos(head_sel[i])
        Ly = Ly + (disp_sel[i]/(((window_size-stride)/stride)))*sin(head_sel[i])  
        pointx.append(Lx)
        pointy.append(Ly)   
    Gvx = pointx
    Gvy = pointy
    
    return Gvx, Gvy



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
