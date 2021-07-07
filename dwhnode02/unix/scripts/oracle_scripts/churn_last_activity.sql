
set colsep ,
set headsep off
set pagesize 0
set trimspool on
set linesize 200	


alter session set current_schema = dwh_user;
spool Daily_churn.csv

 SELECT ac.MSISDIN_NO,
          PD.PAY_TYPE_NAME,
          dd1.date_value,
          dd2.date_value,
          dd3.date_value AS Revenue_last_activity_date,
          dd4.date_value AS Data_last_activity_date,
          dd5.date_value AS VAS_last_activity_date,
          dd6.date_value AS Voice_last_activity_date
     FROM  PAYTYPE_DIM PD,date_dim dd1,date_dim dd2,date_dim dd3,date_dim dd4,date_dim dd5,date_dim dd6,ACTIVEBASE ac
          LEFT OUTER JOIN L3_VOICE v
             ON  ac.MSISDIN_NO = v.V372_CALLINGPARTYNUMBER
          LEFT OUTER JOIN AGEONNETWROK ag
             ON ac.MSISDIN_NO = ag.MSISDIN_NO 
          LEFT OUTER JOIN activebaserecharge rv
             ON ac.MSISDIN_NO = RV.MSISDIN_NO 
          LEFT OUTER JOIN activebasedata la
             ON ac.MSISDIN_NO = LA.MSISDIN_NO 
          LEFT OUTER JOIN activebaserecurring lv
             ON ac.MSISDIN_NO = lv.MSISDIN_NO 
          LEFT OUTER JOIN activebasevoice lb
             ON AC.MSISDIN_NO = LB.MSISDIN_NO 
      where  
     dd1.date_key= ag.FIRST_ACTIVE_DATE
    and  dd2.date_key= ac.LAST_ACTIVITY_DATE_KEY      
    and  dd3.date_key= rv.LAST_ACTIVITY_DATE_KEY 
    and  dd4.date_key= la.LAST_ACTIVITY_DATE_KEY 
    and  dd5.date_key= lv.LAST_ACTIVITY_DATE_KEY 
    and  dd6.date_key= lb.LAST_ACTIVITY_DATE_KEY 
    and  PD.PAY_TYPE_ID= V.V400_PAYTYPE;

spool off

