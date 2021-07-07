--
-- R_REPEAT_ONLY_SMS_USE_SUBSCRIBERS  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.R_REPEAT_ONLY_SMS_USE_SUBSCRIBERS IS
    VDATE_KEY       NUMBER;
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE,'RRRRMMDD');

    
INSERT INTO REPEAT_ONLY_SMS_USE_SUBSCRIBERS

SELECT /*+parallel(P,16)*/MSISDN,VDATE_KEY FROM
(SELECT /*+parallel(P,16)*/S372_CALLINGPARTYNUMBER MSISDN,TOTAL,DISTINCT_CALLEDPARTY FROM (
SELECT /*+parallel(P,16)*/ DISTINCT S372_CALLINGPARTYNUMBER, COUNT(S373_CALLEDPARTYNUMBER) AS TOTAL, COUNT(DISTINCT S373_CALLEDPARTYNUMBER) AS DISTINCT_CALLEDPARTY 
FROM L3_SMS P
WHERE (S387_CHARGINGTIME_KEY BETWEEN (SELECT DATE_KEY FROM DATE_DIM WHERE DATE_VALUE=TO_DATE(SYSDATE-30,'dd/mm/rrrr'))
                             AND  (SELECT DATE_KEY FROM DATE_DIM WHERE DATE_VALUE=TO_DATE(SYSDATE-1,'dd/mm/rrrr')))
AND S378_SERVICEFLOW=1
GROUP BY S372_CALLINGPARTYNUMBER)P
WHERE (TOTAL/DISTINCT_CALLEDPARTY)>1
)P

;
    COMMIT;
END;
/

