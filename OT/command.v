SSH: 
ee30.si2.iee.nycu.edu.tw
ee29.si2.iee.nycu.edu.tw

tar -xvf ~iclabTA01/OT.tar
tar -xvf ~iclabTA01/2025_F_OT.tar

cd 2025_F_OT

password: eason1024

如果要換channel:
chto ee28
chto ee27

開nWave:
nWave &

一定要記得去除中文註解!!

一定會用到的指令:

cd 01_RTL
./01_run_vcs_rtl
.rc不能刪除!!!

cd 02_SYN
./01_run_dc_shell


cd 03_GATE
./01_run_vcs_gate
pkill verdi
pkill simv
pkill dve
pkill vcs
make clean


cd 09_SUBMIT
./00_tar 5.6
./01_submit 3rd_demo
./02_check 3rd_demo


my path: 
/RAID2/COURSE/2025_Fall/iclab/iclab095/Lab05_2025F/Exercise/Memory/ftclib_200901.2.1