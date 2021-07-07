#Auther: Tareq
## date :29-Jan-2020
## purpose : to run the jobs for Life Cycle FCT

#dt=`date '+%Y%m%d'`
#dt=$1
dt=`date -d yesterday '+%Y%m%d'`

cd /data02/scripts/process/bin/

#./sp_active_base_segment.sh $dt
#./sp_active_base.sh $dt
#./sp_lifecycle_active_base.sh $dt
./sp_lifecycle_data.sh $dt
./sp_lifecycle_evcrec.sh $dt
./sp_lifecycle_evctra.sh $dt
./sp_lifecycle_recharge.sh $dt
./sp_lifecycle_recurring.sh $dt
./sp_lifecycle_revenue.sh $dt
./sp_lifecycle_sms.sh $dt
./sp_lifecycle_voice.sh $dt
./sp_lifecycle_active_base.sh $dt
