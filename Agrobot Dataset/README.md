## Dataset architecture

- ```imu_noise.xlsx``` has Allan Variance parameters of the IMU used in the paper.
- ```Dataset Pre-processing Tools``` has the video-processing scripts introduced in the paper to get position data from quadrotor video feeds of the robot.
- ```datasetX``` has ground truth position, GPS and IMU (9DoF) data in csv files. These folders also have scripts to import the data in Python (```data_utils_x.py```), export the data to MATLAB, and training/test splits.
- Link to ground truth mocap/videos and unlabelled data:  https://ucla.box.com/s/ytnhq18rhdca773q3otjkysddmi1w2al