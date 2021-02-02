#!/bin/bash
printf "\033c"
echo -e "run_simu_tim781.bash: starting TiM871 emulation\n"
pushd ../../../..
source /opt/ros/melodic/setup.bash
source ./install/setup.bash

# Start roscore if not yet running
roscore_running=`(ps -elf | grep roscore | grep -v grep | wc -l)`
if [ $roscore_running -lt 1 ] ; then 
  roscore &
  sleep 3
fi

for emulator_launch_cfg in emulator_01_default.launch emulator_03_2nd_fieldset.launch emulator_02_toggle_fieldsets.launch ; do # emulator_04_fieldset_test.launch
  echo -e "Starting TiM871 emulation $emulator_launch_cfg, shutdown ros nodes\n"
  
  # Start sick_scan emulator
  roslaunch sick_scan $emulator_launch_cfg &
  sleep 1
  
  # Start rviz
  # Note: Due to a bug in opengl 3 in combination with rviz and VMware, opengl 2 should be used by rviz option --opengl 210
  # See https://github.com/ros-visualization/rviz/issues/1444 and https://github.com/ros-visualization/rviz/issues/1508 for further details
  rosrun rviz rviz -d ./src/sick_scan/test/emulator/config/rviz_emulator_cfg.rviz --opengl 210 &
  sleep 1
  
  # Start sick_scan driver for TiM871S
  roslaunch sick_scan sick_tim_7xxS.launch hostname:=127.0.0.1 &
  sleep 1
  
  # rosservice call /sick_tim_7xx/ColaMsg "{request: 'sEN LIDoutputstate 1'}"
  # rosservice call /sick_tim_7xx/ColaMsg "{request: 'sRN LIDoutputstate'}"
  # rosservice call /sick_tim_7xx/ColaMsg "{request: 'sEN LFErec 1'}"
  # rosservice call /sick_tim_7xx/ColaMsg "{request: 'sRN LFErec'}"
  # rosservice call /sick_tim_7xx/ColaMsg "{request: 'sEN field000 1'}"
  # rosservice call /sick_tim_7xx/ColaMsg "{request: 'sRN field000'}"
  # rosservice call /sick_tim_7xx/ColaMsg "{request: 'sEN LIDinputstate 1'}"
  # rosservice call /sick_tim_7xx/ColaMsg "{request: 'sRN LIDinputstate'}" # response: "sRA LIDinputstate \\x00\\x00\\x00\\x00\\x00\\x00\\x01\\x00\\x00\\x00\\x00\\x00"
  # rostopic echo "/sick_tim_7xxS/lferec" &
  # rostopic echo "/sick_tim_7xxS/lidoutputstate" &
  
  # Wait for 'q' or 'Q' to exit or until rviz is closed
  while true ; do  
    echo -e "TiM871 emulation running. Close rviz or press 'q' to exit..." ; read -t 1.0 -n1 -s key
    if [[ $key = "q" ]] || [[ $key = "Q" ]]; then break ; fi
    rviz_running=`(ps -elf | grep rviz | grep -v grep | wc -l)`
    if [ $rviz_running -lt 1 ] ; then break ; fi
  done
  
  # Shutdown
  echo -e "Finishing TiM871 emulation $emulator_launch_cfg, shutdown ros nodes\n"
  rosnode kill -a ; sleep 1
  killall sick_generic_caller ; sleep 1
  killall sick_scan_emulator ; sleep 1

done
killall rosmaster ; sleep 1
echo -e "run_simu_tim781.bash: TiM871 emulation finished.\n\n"

popd

