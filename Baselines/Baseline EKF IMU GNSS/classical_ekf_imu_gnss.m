load('dset0_Log1, 100.mat');

f = insfilterMARG;
f.IMUSampleRate = imuFs;
f.ReferenceLocation = refloc;
f.AccelerometerBiasNoise = 2e-4; %default
GYROSCOPE_ARW = [3.09, 2.7, 5.4]; %deg/sqrt(hr) [11.28, 12.85,13.45]
GYROSCOPE_BI = [88.91,78.07,211.4]; %deg/hr [45.9, 54.68, 52.38]
f.AccelerometerNoise = 0.00615490459; %0.0011858 (m/s^2)^2
f.GyroscopeBiasNoise = [((deg2rad(GYROSCOPE_ARW(1))/60.0)*sqrt(1/imuFs))^2+(deg2rad(GYROSCOPE_BI(1))/3600.0)^2, ...
    ((deg2rad(GYROSCOPE_ARW(2))/60.0)*sqrt(1/imuFs))^2+(deg2rad(GYROSCOPE_BI(2))/3600.0)^2, ...
    ((deg2rad(GYROSCOPE_ARW(3))/60.0)*sqrt(1/imuFs))^2+(deg2rad(GYROSCOPE_BI(3))/3600.0)^2];
f.GyroscopeNoise = 0.0000030462; %0.0000030462
f.MagnetometerBiasNoise = 0.36; %0.09
f.GeomagneticVectorNoise = 0.36; 
f.StateCovariance = 1e-9*ones(22);

gpsidx = 1;
N = size(accel,1);
p = zeros(N,3);

for ii = 1:size(accel,1)  
   f.predict(accel(ii,:), gyro(ii,:));
   f.fusemag(mag(ii,:),Rmag);
   if (~mod(ii,imuFs) && gpsidx < size(gpsvel,1))                   % Fuse GPS once per second
       f.fusegps(lla(gpsidx,:),Rpos,gpsvel(gpsidx,:),Rvel);
       gpsidx = gpsidx + 1;
   end
   
   [p(ii,:),~] = pose(f);
end
    