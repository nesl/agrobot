filename = 'dset0_Log1, 100.mat';
load(filename);
omegas = struct([]);
for i = 1:size(accel,1)
    omegas(i).gyro = gyro(i,:)';
    omegas(i).acc = accel(i,:)';
end
t = linspace(0,size(accel,1)/imuFs,size(accel,1))';
ys = truePos + normrnd(0,1.5,[size(truePos,1),3]);
ys = ys';
one_hot_ys = zeros(size(accel,1),1);
gps_idx_count = 1;
for i = 1:size(accel,1)
    if((i==1 || mod(i,imuFs+1)==0) && gps_idx_count < size(lla,1))
        one_hot_ys(i) = 1;
    end
end
save(strcat(filename(1:end-4),'_ukfm.mat'),'one_hot_ys','ys','omegas','t');