PATH=$PATH:$HOME/.local/bin:$HOME/bin

export PATH

export TMP=/tmp
export TMPDIR=$TMP

export ORACLE_HOSTNAME=dwhnode02
export ORACLE_UNQNAME=dwhdb02
export ORACLE_BASE=/data01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.0.0/dbhome_1
export ORA_INVENTORY=/data01/app/oraInventory
export ORACLE_SID=dwhdb02
export DATA_DIR=/data01/oradata

export PATH=/usr/sbin:/usr/local/bin:$PATH
export PATH=$ORACLE_HOME/bin:$PATH

export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib


select_upazila_code()
{
sqlplus  -s <<EOF
dwh_user/dwh_user_123
SET echo on
SET head off
SET feedback off
WHENEVER SQLERROR EXIT SQL.SQLCODE
select upazila_code2 
from zone_dim_with_code
--where rownum < 3
group by upazila_code2
order by 1
/
EXIT
EOF
}


insert_script()
{
sqlplus  -s <<EOF
dwh_user/dwh_user_123
SET echo on
SET head off
SET feedback off
WHENEVER SQLERROR EXIT SQL.SQLCODE
INSERT INTO MSISDN_COMPARE_FINAL
SELECT DATE_KEY,UPAZILA_CODE1,UPAZILA_CODE2, COUNT(*) COUNTS
FROM MSISDN_COMPARE
WHERE DATE_KEY = (SELECT A.DATE_KEY FROM DATE_DIM A WHERE A.DATE_VALUE = TO_DATE (SYSDATE-1,'dd/mm/rrrr'))
AND UPAZILA_CODE1='$1'
AND UPAZILA_CODE2 IS NOT NULL
GROUP BY  DATE_KEY,UPAZILA_CODE1,UPAZILA_CODE2
/
COMMIT
/
EXIT
EOF
}


lock=/data02/scripts/dwh/lock/msisdn_upazila_wise  export lock

if [ -f $lock ] ; then
exit 2

else
touch $lock

upazila_code=`select_upazila_code`

for fil in $upazila_code
do

v1=`echo ${fil}|sed s/,/\ /g|awk '{print $1}'`   ### file name
echo $v1
insert_script $v1

done

rm -f $lock

fi

