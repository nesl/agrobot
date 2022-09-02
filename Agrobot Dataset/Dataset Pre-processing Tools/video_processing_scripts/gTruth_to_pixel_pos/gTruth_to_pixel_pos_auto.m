%% import list of gTruth files
file_header = 'DJI_0013';
file_list = dir(strcat(file_header,'*.mat')); %file formats where gTruth is stored: DJI_0013_1.mat, DJI_0013_2.mat...
str = natsortfiles({file_list.name});
for i=1:length(str)
   file_list(i).name = str{i};
end

%% find the start and end points of data to consider for each file automatically
% might fail when idx_mat_min/max[j] becomes less than idx_mat_min/max[j+1]
idx_mat_max = zeros(length(file_list),1);
idx_mat_min = zeros(length(file_list),1);

for j=1:length(file_list)
    disp(j);
    cur_file = load(file_list(j).name);
    empty_or_not = zeros(length(cur_file.gTruth.LabelData.landmark),1);
    for i=1:length(cur_file.gTruth.LabelData.robot)
        if(isempty(cur_file.gTruth.LabelData.robot{i}))
            empty_or_not(i) = 1;
        else
            empty_or_not(i) = 0;
        end
    end
    idx_mat_max(j) = find(empty_or_not==0, 1, 'last' );
    if(j>1)
        idx_mat_min(j) = idx_mat_max(j-1) + find(empty_or_not(idx_mat_max(j-1)+1:end)==0, 1, 'first' );
    else
        idx_mat_min(j) = 1;
    end
end

%% extract position from all files in one array
cur_file = load(file_list(1).name);
rob_x = NaN(length(cur_file.gTruth.LabelData.Robot),1);
rob_y = NaN(length(cur_file.gTruth.LabelData.Robot),1);
lm_x = NaN(length(cur_file.gTruth.LabelData.Landmark),1);
lm_y = NaN(length(cur_file.gTruth.LabelData.Landmark),1);

for j=1:length(file_list)
    disp(j);
    cur_file = load(file_list(j).name);
    for k = idx_mat_min(j):idx_mat_max(j)
            rob_x(k) = cur_file.gTruth.LabelData.Robot{k}(1)+(cur_file.gTruth.LabelData.Robot{k}(3)/2);
            rob_y(k) = cur_file.gTruth.LabelData.Robot{k}(2)-(cur_file.gTruth.LabelData.Robot{k}(4)/2);
            if(isempty(cur_file.gTruth.LabelData.Landmark{k}))
                lm_x(k) = lm_x(k-1);
                lm_y(k) = lm_y(k-1);
            else
                lm_x(k) =  cur_file.gTruth.LabelData.Landmark{k}(1)+(cur_file.gTruth.LabelData.Landmark{k}(3)/2);
                lm_y(k) =  cur_file.gTruth.LabelData.Landmark{k}(2)-(cur_file.gTruth.LabelData.Landmark{k}(4)/2);
            end
            rob_x(k) = rob_x(k) - (lm_x(k)-lm_x(idx_mat_min(1)));
            rob_y(k) = rob_y(k) - (lm_y(k)-lm_y(idx_mat_min(1)));
    end
end

%% plot and inspect
figure;
plot(rob_x);
figure;
plot(rob_y);
figure
plot(lm_x);
figure
plot(lm_y);

%% clean up problematic sections plus interpolate missing values elsewhere

rob_x(1436:1447) = NaN;
rob_y(1436:1447) = NaN;
lm_x(1436:1447) = NaN;
lm_y(1436:1447) = NaN;

rob_x(6621:6624) = NaN;
rob_y(6621:6624) = NaN;
lm_x(6621:6624) = NaN;
lm_y(6621:6624) = NaN;

rob_x(7359:7362) = NaN;
rob_y(7359:7362) = NaN;
lm_x(7359:7362) = NaN;
lm_y(7359:7362) = NaN;

rob_x(7511:7610) = NaN;
rob_y(7511:7610) = NaN;
lm_x(7511:7610) = NaN;
lm_y(7511:7610) = NaN;

rob_x(8089:8101) = NaN;
rob_y(8089:8101) = NaN;
lm_x(8089:8101) = NaN;
lm_y(8089:8101) = NaN;

t = 1:length(rob_x);
rob_x = interp1(t(~isnan(rob_x)),rob_x(~isnan(rob_x)),t);
rob_y = interp1(t(~isnan(rob_y)),rob_y(~isnan(rob_y)),t);
lm_x = interp1(t(~isnan(lm_x)),lm_x(~isnan(lm_x)),t);
lm_y = interp1(t(~isnan(lm_y)),lm_y(~isnan(lm_y)),t);

%% smoothing

rob_x = medfilt1(rob_x,600);
rob_y = medfilt1(rob_y,600);
lm_x = medfilt1(lm_x,600);
lm_y = medfilt1(lm_y,600);

%% scale factor extraction
cur_file = load(file_list(1).name);
xscale = cur_file.gTruth.LabelData.landmark{idx_mat_min(1)}(3);
yscale = cur_file.gTruth.LabelData.landmark{idx_mat_min(1)}(4);

%% save variables
clearvars -except rob_x rob_y lm_x lm_y xscale yscale file_header
save(strcat(file_header,'all.mat'),'rob_x', 'rob_y', 'lm_x', 'lm_y', 'xscale', 'yscale');
