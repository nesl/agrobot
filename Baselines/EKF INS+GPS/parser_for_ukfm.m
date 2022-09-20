aa = 0;
for q = 1:9
    filename = strcat('dset0_Log',num2str(q),', 100.mat');
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
        if((i==1 || mod(i,imuFs*aa+1)==0) && gps_idx_count < size(lla,1)/aa)
            one_hot_ys(i) = 1;
        end
    end
    save(strcat(filename(1:end-4),'_',num2str(aa),'_ukfm.mat'),'one_hot_ys','ys','omegas','t','truePos');
end