PATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib;TH=$PATH:$HOME/.local/bin:$HOME/bin

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


partition=`sqlplus  -s <<EOF
dwh_user/dwh_user_123
SET echo off
SET head off
SET feedback off
REM "WHENEVER SQLERROR EXIT SQL.SQLCODE"
select 'date_key'||'_'||date_key from date_dim where trunc(date_value)=trunc(sysdate+1);
EXIT
EOF`



REPEAT_TOTAL_ACTIVE_SUBSCRIBERS()
{
sqlplus  -s <<EOF
dwh_user/dwh_user_123
SET echo off
SET head off
SET feedback off
REM "WHENEVER SQLERROR EXIT SQL.SQLCODE"
alter table REPEAT_TOTAL_ACTIVE_SUBSCRIBERS truncate partition $1;
EXECUTE R_REPEAT_TOTAL_ACTIVE_SUBSCRIBERS;
EXIT
EOF
}
REPEAT_TOTAL_ACTIVE_SUBSCRIBERS $partition
echo "$1"



