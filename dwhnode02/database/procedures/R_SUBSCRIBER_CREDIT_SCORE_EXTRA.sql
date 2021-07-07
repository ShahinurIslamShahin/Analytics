--
-- R_SUBSCRIBER_CREDIT_SCORE_EXTRA  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.R_SUBSCRIBER_CREDIT_SCORE_EXTRA IS
    VDATE_KEY       NUMBER;
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE,'RRRRMMDD');
   
--DELETE SUBSCRIBER_CREDIT_SCORE WHERE MONTH_KEY=(SELECT  MONTH_KEY-1 FROM DATE_DIM P WHERE  DATE_VALUE= TRUNC(TO_DATE(SYSDATE,'DD/MM/RRRR')));
--COMMIT;
    
INSERT INTO SUBSCRIBER_CREDIT_SCORE


SELECT/*+PARALLEL(P,15)*/ MONTH_KEY,MSISDN,nvl(ROUND(SUM(RECHARGE_COUNT),2),0)MONTHLY_RECHARGE_COUNT,nvl(ROUND(SUM(RECHARGE_AMOUNT),2),0)TOTAL_RECHARGE_AMOUNT,
       nvl(ROUND(SUM(VOICE_PPU_REVENUE),2),0) TOTAL_USAGE ,nvl(ROUND((SUM(VOICE_PPU_REVENUE)/SUM(RECHARGE_AMOUNT)),2),0) CREDIT_SCORE,VDATE_KEY
FROM 
(
(
SELECT /*+PARALLEL(P,15)*/ MONTH_KEY ,RE6_PRI_IDENTITY MSISDN,COUNT(*)RECHARGE_COUNT,SUM(RE3_RECHARGE_AMT) RECHARGE_AMOUNT,CAST(NULL AS NUMBER(20,5)) VOICE_PPU_REVENUE 
FROM L3_RECHARGE P,DATE_DIM Q
WHERE (RE30_ENTRY_DATE_KEY BETWEEN (SELECT DATE_KEY
                                                               FROM DATE_DIM
                                                              WHERE DATE_VALUE =
                                                                       TRUNC (
                                                                          TO_DATE (
                                                                             '01/02/2021',
                                                                             'DD/MM/RRRR')))
                                                        AND (SELECT DATE_KEY
                                                               FROM DATE_DIM
                                                              WHERE DATE_VALUE =
                                                                       TRUNC (
                                                                          TO_DATE (
                                                                            '31/03/2021',
                                                                             'DD/MM/RRRR'))))
    AND RE30_ENTRY_DATE_KEY=DATE_KEY                      
GROUP BY MONTH_KEY ,RE6_PRI_IDENTITY
)
UNION ALL
(SELECT /*+PARALLEL(P,15)*/ MONTH_KEY,V372_CALLINGPARTYNUMBER,CAST(NULL AS NUMBER(20))RECHARGE_COUNT,CAST(NULL AS NUMBER(20,5))RECHARGE_AMOUNT,SUM (V41_DEBIT_AMOUNT) VOICE_PPU_REVENUE  
FROM L3_VOICE P,DATE_DIM Q
WHERE (V387_CHARGINGTIME_KEY BETWEEN (SELECT DATE_KEY
                                                               FROM DATE_DIM
                                                              WHERE DATE_VALUE =
                                                                       TRUNC (
                                                                          TO_DATE (
                                                                             '01/02/2021',
                                                                             'DD/MM/RRRR')))
                                                        AND (SELECT DATE_KEY
                                                               FROM DATE_DIM
                                                              WHERE DATE_VALUE =
                                                                       TRUNC (
                                                                          TO_DATE (
                                                                            '31/03/2021',
                                                                             'DD/MM/RRRR'))))
    AND V387_CHARGINGTIME_KEY=DATE_KEY 
GROUP BY MONTH_KEY,V372_CALLINGPARTYNUMBER
)
UNION ALL
(SELECT /*+PARALLEL(P,15)*/ MONTH_KEY,G372_CALLINGPARTYNUMBER,CAST(NULL AS NUMBER(20))RECHARGE_COUNT,CAST(NULL AS NUMBER(20,5))RECHARGE_AMOUNT,SUM (G41_DEBIT_AMOUNT) DATA_PPU_REVENUE 
FROM L3_DATA P,DATE_DIM Q
WHERE (G383_CHARGINGTIME_KEY BETWEEN (SELECT DATE_KEY
                                                               FROM DATE_DIM
                                                              WHERE DATE_VALUE =
                                                                       TRUNC (
                                                                          TO_DATE (
                                                                             '01/02/2021',
                                                                             'DD/MM/RRRR')))
                                                        AND (SELECT DATE_KEY
                                                               FROM DATE_DIM
                                                              WHERE DATE_VALUE =
                                                                       TRUNC (
                                                                          TO_DATE (
                                                                            '31/03/2021',
                                                                             'DD/MM/RRRR'))))
    AND G383_CHARGINGTIME_KEY=DATE_KEY 
GROUP BY MONTH_KEY,G372_CALLINGPARTYNUMBER
)

UNION ALL
(SELECT /*+PARALLEL(P,15)*/ MONTH_KEY,S22_PRI_IDENTITY,CAST(NULL AS NUMBER(20))RECHARGE_COUNT,CAST(NULL AS NUMBER(20,5))RECHARGE_AMOUNT,SUM (S41_DEBIT_AMOUNT) SMS_PPU_REVENUE 
FROM L3_SMS P,DATE_DIM Q
WHERE (S387_CHARGINGTIME_KEY BETWEEN (SELECT DATE_KEY
                                                               FROM DATE_DIM
                                                              WHERE DATE_VALUE =
                                                                       TRUNC (
                                                                          TO_DATE (
                                                                             '01/02/2021',
                                                                             'DD/MM/RRRR')))
                                                        AND (SELECT DATE_KEY
                                                               FROM DATE_DIM
                                                              WHERE DATE_VALUE =
                                                                       TRUNC (
                                                                          TO_DATE (
                                                                            '31/03/2021',
                                                                             'DD/MM/RRRR'))))
    AND S387_CHARGINGTIME_KEY=DATE_KEY 
GROUP BY MONTH_KEY,S22_PRI_IDENTITY
)
UNION ALL
(SELECT /*+PARALLEL(P,15)*/ MONTH_KEY,R375_CHARGINGPARTYNUMBER,CAST(NULL AS NUMBER(20))RECHARGE_COUNT,CAST(NULL AS NUMBER(20,5))RECHARGE_AMOUNT,SUM (R41_DEBIT_AMOUNT) RECURRING_REVENUE 
FROM L3_RECURRING P,DATE_DIM Q
WHERE (R377_CYCLEBEGINTIME_KEY BETWEEN (SELECT DATE_KEY
                                                               FROM DATE_DIM
                                                              WHERE DATE_VALUE =
                                                                       TRUNC (
                                                                          TO_DATE (
                                                                             '01/02/2021',
                                                                             'DD/MM/RRRR')))
                                                        AND (SELECT DATE_KEY
                                                               FROM DATE_DIM
                                                              WHERE DATE_VALUE =
                                                                       TRUNC (
                                                                          TO_DATE (
                                                                           '31/03/2021',
                                                                             'DD/MM/RRRR'))))
    AND R377_CYCLEBEGINTIME_KEY=DATE_KEY 
GROUP BY MONTH_KEY,R375_CHARGINGPARTYNUMBER
)
)Q

GROUP BY MONTH_KEY,MSISDN
having SUM(RECHARGE_AMOUNT)>0
;
             
             
             
      COMMIT;
END;
/

