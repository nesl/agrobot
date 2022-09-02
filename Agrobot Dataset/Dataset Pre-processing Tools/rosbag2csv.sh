#!/bin/bash
# Arthur Lovekin May 2022
# Instructions:
# When first using, enable execute permissions with `chmod +x rosbag2csv.sh`
# Replace the names in the for loop with bagfile names (name.bag --> name)
# run `./rosbag2csv.sh`
cd /home/jetbot/ydu/catkin_ws/src/bagfiles/

for NAME in \
'imu_gps_2022-05-04-01-13-06' \
'imu_gps_2022-05-04-01-13-14' \
'imu_gps_2022-05-04-01-13-57' \
'imu_gps_2022-05-04-01-14-20' \
'imu_gps_2022-05-04-01-15-42' \
'imu_gps_2022-05-04-01-17-03' \
'imu_gps_2022-05-04-01-46-38'
do
rostopic echo -b ${NAME}.bag -p /data > data_${NAME}.csv
rostopic echo -b ${NAME}.bag -p /raw > raw_${NAME}.csv
rostopic echo -b ${NAME}.bag -p /fix > fix_${NAME}.csv
rostopic echo -b ${NAME}.bag -p /mag > mag_${NAME}.csv
done
