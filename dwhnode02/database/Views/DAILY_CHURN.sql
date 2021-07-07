--
-- DAILY_CHURN  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.DAILY_CHURN
(MSISDIN_NO, PAY_TYPE_NAME, FIRST_ACTIVE_DATE, LAST_ACTIVITY_DATE, REVENUE_LAST_ACTIVITY_DATE, 
 DATA_LAST_ACTIVITY_DATE, VAS_LAST_ACTIVITY_DATE, VOICE_LAST_ACTIVITY_DATE)
BEQUEATH DEFINER
AS 
SELECT ac.MSISDIN_NO,
          v.PAY_TYPE_NAME,
          ag.DATE_VALUE as FIRST_ACTIVE_DATE,
          ac.DATE_VALUE as LAST_ACTIVITY_DATE,
          rv.DATE_VALUE AS Revenue_last_activity_date,
          la.DATE_VALUE AS Data_last_activity_date,
          lv.DATE_VALUE AS VAS_last_activity_date,
          lb.DATE_VALUE AS Voice_last_activity_date
     FROM (select MSISDIN_NO,DATE_VALUE from 
        date_dim,
        (
        SELECT MSISDIN_NO, LAST_ACTIVITY_DATE_KEY as LAST_ACTIVITY_DATE
        FROM ACTIVEBASE Inner join date_dim on DATE_KEY = LAST_ACTIVITY_DATE_KEY
        where  date_value  BETWEEN TO_DATE ('2020/01/13', 'yyyy/mm/dd')
        AND TO_DATE ('2020/02/01', 'yyyy/mm/dd')
        GROUP BY MSISDIN_NO, LAST_ACTIVITY_DATE_KEY)
        where DATE_KEY=LAST_ACTIVITY_DATE) ac
        
          LEFT OUTER JOIN ( select V372_CALLINGPARTYNUMBER,PAY_TYPE_NAME from 
                PAYTYPE_DIM,
                    (
                     select V372_CALLINGPARTYNUMBER, V400_PAYTYPE
                      from L3_VOICE Inner join date_dim on DATE_KEY = V387_CHARGINGTIME_KEY
                      where  date_value  BETWEEN TO_DATE ('2020/01/13', 'yyyy/mm/dd')
                      AND TO_DATE ('2020/02/01', 'yyyy/mm/dd')
                      GROUP BY V372_CALLINGPARTYNUMBER,V400_PAYTYPE)
                      where PAY_TYPE_ID=V400_PAYTYPE
                     ) v
             ON  ac.MSISDIN_NO = v.V372_CALLINGPARTYNUMBER
          LEFT OUTER JOIN (select MSISDIN_NO,DATE_VALUE 
                from 
                date_dim,
                    (
                    SELECT MSISDIN_NO, FIRST_ACTIVE_DATE
                    FROM AGEONNETWROK Inner join date_dim on DATE_KEY = FIRST_ACTIVE_DATE
                    where  date_value  BETWEEN TO_DATE ('2020/01/13', 'yyyy/mm/dd')
                    AND TO_DATE ('2020/02/01', 'yyyy/mm/dd')
                    GROUP BY MSISDIN_NO, FIRST_ACTIVE_DATE)
                    where DATE_KEY=FIRST_ACTIVE_DATE
                    ) ag
             ON ac.MSISDIN_NO = ag.MSISDIN_NO 
             
          LEFT OUTER JOIN (select MSISDIN_NO,DATE_VALUE from 
        date_dim,
            (    
              SELECT MSISDIN_NO, LAST_ACTIVITY_DATE_KEY AS Revenue_last_activity_date
              FROM ACTIVEBASERECHARGE Inner join date_dim on DATE_KEY = LAST_ACTIVITY_DATE_KEY
              where  date_value  BETWEEN TO_DATE ('2020/01/13', 'yyyy/mm/dd')
              AND TO_DATE ('2020/02/01', 'yyyy/mm/dd')
              GROUP BY MSISDIN_NO, LAST_ACTIVITY_DATE_KEY)
              where DATE_KEY=Revenue_last_activity_date
             ) rv
             ON ac.MSISDIN_NO = RV.MSISDIN_NO 
           LEFT OUTER JOIN ( select MSISDIN_NO,DATE_VALUE from 
           date_dim,
            (SELECT MSISDIN_NO, LAST_ACTIVITY_DATE_KEY AS Data_last_activity_date
            FROM ACTIVEBASEDATA Inner join date_dim on DATE_KEY = LAST_ACTIVITY_DATE_KEY
            where  date_value  BETWEEN TO_DATE ('2020/01/13', 'yyyy/mm/dd')
            AND TO_DATE ('2020/02/01', 'yyyy/mm/dd')
            GROUP BY MSISDIN_NO, LAST_ACTIVITY_DATE_KEY)
            where DATE_KEY=Data_last_activity_date) 
            la
             ON ac.MSISDIN_NO = LA.MSISDIN_NO 
             
          LEFT OUTER JOIN (select MSISDIN_NO,DATE_VALUE from 
          date_dim,
         (SELECT MSISDIN_NO, LAST_ACTIVITY_DATE_KEY AS VAS_last_activity_date
         FROM ACTIVEBASERECURRING inner join date_dim on DATE_KEY = LAST_ACTIVITY_DATE_KEY
         where  date_value  BETWEEN TO_DATE ('2020/01/13', 'yyyy/mm/dd')
         AND TO_DATE ('2020/02/01', 'yyyy/mm/dd')
         GROUP BY MSISDIN_NO, LAST_ACTIVITY_DATE_KEY)
         where DATE_KEY=VAS_last_activity_date)
         lv
             ON ac.MSISDIN_NO = lv.MSISDIN_NO 
             
          LEFT OUTER JOIN (select MSISDIN_NO,DATE_VALUE from 
          date_dim,
             (
          SELECT MSISDIN_NO, LAST_ACTIVITY_DATE_KEY AS Voice_last_activity_date
          FROM ACTIVEBASEVOICE Inner join date_dim on DATE_KEY = LAST_ACTIVITY_DATE_KEY
          where  date_value  BETWEEN TO_DATE ('2020/01/13', 'yyyy/mm/dd')
          AND TO_DATE ('2020/02/01', 'yyyy/mm/dd')
          GROUP BY MSISDIN_NO, LAST_ACTIVITY_DATE_KEY)
          where DATE_KEY=Voice_last_activity_date) lb
             ON AC.MSISDIN_NO = LB.MSISDIN_NO;


