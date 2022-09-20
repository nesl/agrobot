% IMU-GNSS Sensor-Fusion on the KITTI Dataset
% 
% Goals of this script:
% 
% * apply the UKF for estimating the 3D pose, velocity and sensor biases of a
%   vehicle on real data.
% * efficiently propagate the filter when one part of the Jacobian is already
%   known.
% * efficiently update the system for GNSS position.
% 
% _We assume the reader is already familiar with the approach described in the
% tutorial and in the 2D SLAM example._
% 
% This script proposes an UKF to estimate the 3D attitude, the velocity, and the
% position of a rigid body in space from inertial sensors and position
% measurement.
% 
% We use the KITTI data that can be found in the <`iSAM repo
% https://github.com/borglab/gtsam/blob/develop/matlab/gtsam_examples/IMUKittiExampleGNSS.m>
% (examples folder).

% Initialization
% Start by cleaning the workspace.

clear all;
close all;

% Model and Data

% observation frequency (Hz)
gps_freq = 1;
imuFs = 100;
% load data
GYROSCOPE_ARW = [3.09, 2.7, 5.4]; %[3.09, 2.7, 5.4]; %deg/sqrt(hr) [11.28, 12.85,13.45]
GYROSCOPE_BI = [88.91,78.07,211.4]; %[88.91,78.07,211.4]; %deg/hr [45.9, 54.68, 52.38]
GYROSCOPE_BIAS_NOISE = [((deg2rad(GYROSCOPE_ARW(1))/60.0)*sqrt(1/imuFs))^2+(deg2rad(GYROSCOPE_BI(1))/3600.0)^2, ...
    ((deg2rad(GYROSCOPE_ARW(2))/60.0)*sqrt(1/imuFs))^2+(deg2rad(GYROSCOPE_BI(2))/3600.0)^2, ...
    ((deg2rad(GYROSCOPE_ARW(3))/60.0)*sqrt(1/imuFs))^2+(deg2rad(GYROSCOPE_BI(3))/3600.0)^2];


ate_mas = [];
rte_mas = [];
for q = 1:9
    disp(q);
    load(strcat('dset0_Log',num2str(q),', 100_600_ukfm.mat'));

% IMU noise standard deviation (noise is isotropic)
imu_noise_std = [sqrt(0.0000030462);    % gyro (rad/s)
                sqrt(0.0011858);     % accelerometer (m/s^2) %0.0011858
                sqrt(mean(GYROSCOPE_BIAS_NOISE)); % gyro bias
                sqrt(2e-4)];  % accelerometer bias
% gps noise standard deviation (m)
gps_noise_std = 0.0005;

% total number of timestamps
N = length(one_hot_ys);

%
% The state and the input contain the following variables:
%
%   states(n).Rot     % 3d orientation (matrix)
%   states(n).v       % 3d velocity
%   states(n).p       % 3d position
%   states(n).b_gyro  % gyro bias
%   states(n).b_acc   % accelerometer bias
%   omega(n).gyro     % vehicle angular velocities 
%   omega(n).acc      % vehicle specific forces
%
% A measurement ys(:, k) contains GNSS (position) measurement

% Filter Design and Initialization
% We now design the UKF on parallelizable manifolds. This script embeds the
% state in $SO(3) \times R^{12}$, such that:
%
% * the retraction $\varphi(.,.)$ is the $SO(3)$ exponential for orientation, 
%   and the vector addition for the remaining part of the state.
% * the inverse retraction $\varphi^{-1}_.(.)$ is the $SO(3)$ logarithm for
%   orientation and the vector subtraction for the remaining part of the state.
%
% Remaining parameter setting is standard.

% propagation noise covariance matrix
ukf_Q = blkdiag(imu_noise_std(1)^2*eye(3), imu_noise_std(2)^2*eye(3), ...
    imu_noise_std(3)^2*eye(3), imu_noise_std(4)^2*eye(3));
% measurement noise covariance matrix
R = gps_noise_std.^2 * eye(3);
% initial uncertainty matrix
ukf_P0 = blkdiag(0.01*eye(3), eye(3), eye(3), 0.001*eye(3), 0.001*eye(3));
% sigma point parameters
ukf_alpha = [1e-2, 1e-2, 1e-2];

% We use the UKF that is able to infer Jacobian to speed up the update step, see
% the 2D SLAM example.

% define UKF functions
f = @imu_gnss_kitti_f;
h = @imu_gnss_kitti_h;
% retraction used during update
up_phi = @imu_gnss_kitti_up_phi;
phi = @imu_gnss_kitti_phi;
phi_inv = @imu_gnss_kitti_phi_inv;
% reduced weights during propagation
red_weights = ukf_set_weight(15, 3, ukf_alpha);
red_idxs = 1:9; % indices corresponding to the robot state in P
% weights during update
weights = ukf_set_weight(3, 3, ukf_alpha);
cholQ = chol(ukf_Q);
up_idxs = 7:9;

ukf_state.Rot = eye(3);
ukf_state.v = zeros(3, 1);
ukf_state.p = ys(:, 2); % first GPS measurement
ukf_state.b_gyro = zeros(3, 1);
ukf_state.b_acc = zeros(3, 1);
ukf_P = ukf_P0;

ukf_states = ukf_state;
ukf_Ps = zeros(N, 15, 15);
ukf_Ps(1, :, :) = ukf_P;

k = 2;
n0 = 100;
for n = n0:N
    % propagation
    dt = t(n) - t(n-1);
    [ukf_state, ukf_P] = ukf_propagation(ukf_state, ukf_P, omegas(n-1), ...
        f, dt, phi, phi_inv, cholQ(1:6, 1:6), red_weights);
    % add bias covariance
    ukf_P(10:15, 10:15) = ukf_P(10:15, 10:15) + ukf_Q(7:12, 7:12)*dt^2;
    % update only if a measurement is received
    if one_hot_ys(n) == 1
       [H, res] = ukf_jacobian_update(ukf_state, ukf_P, ys(:, k), h, ...
             up_phi, weights, up_idxs);
        % update state and covariance with Kalman update
        [ukf_state, ukf_P] = kf_update(ukf_state, ukf_P, H, res,  R, phi);
        k = k + 1;
    end
    % save estimates
    ukf_states(n) = ukf_state;
    ukf_Ps(n, :, :) = ukf_P;
end
[~, ~, ukf_ps, ~, ~] = imu_gnss_kitti_get_states(ukf_states);


    truePos = truePos(1:size(ukf_ps,1),:);
    ate = sum(sqrt((ukf_ps(:,1)-truePos(:,1)).^2 + (ukf_ps(:,2)-truePos(:,2)).^2))/size(truePos,1);
    rte = [];
    for j = 1:6000:size(ukf_ps,1)-mod(size(ukf_ps,1),6000)
        rte = [rte,(sum(sqrt((ukf_ps(j:j+6000,1)-truePos(j:j+6000,1)).^2 + (ukf_ps(j:j+6000,2)-truePos(j:j+6000,2)).^2))/size(truePos,1))];
    end
    rte = sum(rte)/length(rte);
    disp([ate,rte]);
    ate_mas = [ate_mas,ate];
    rte_mas = [rte_mas,rte];
end
disp([mean(ate_mas),mean(rte_mas)]);
disp([std(ate_mas),std(rte_mas)]);
%imu_gnss_kitti_results_plot(ukf_states, ys);

