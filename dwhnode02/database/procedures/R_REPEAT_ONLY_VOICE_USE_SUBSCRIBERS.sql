--
-- R_REPEAT_ONLY_VOICE_USE_SUBSCRIBERS  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.R_REPEAT_ONLY_VOICE_USE_SUBSCRIBERS IS
    VDATE_KEY       NUMBER;
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE,'RRRRMMDD');

    
INSERT INTO REPEAT_ONLY_VOICE_USE_SUBSCRIBERS


SELECT /*+parallel(P,16)*/MSISDN,VDATE_KEY  FROM
(SELECT/*+parallel(P,16)*/ V372_CALLINGPARTYNUMBER MSISDN,TOTAL,DISTINCT_CALLEDPARTY FROM (
SELECT /*+parallel(P,16)*/ DISTINCT V372_CALLINGPARTYNUMBER, COUNT(V373_CALLEDPARTYNUMBER) AS TOTAL, COUNT(DISTINCT V373_CALLEDPARTYNUMBER) AS DISTINCT_CALLEDPARTY 
FROM L3_VOICE P
WHERE (V387_CHARGINGTIME_KEY BETWEEN (SELECT DATE_KEY FROM DATE_DIM WHERE DATE_VALUE=TO_DATE(SYSDATE-30,'dd/mm/rrrr'))
                             AND  (SELECT DATE_KEY FROM DATE_DIM WHERE DATE_VALUE=TO_DATE(SYSDATE-1,'dd/mm/rrrr')))
AND V378_SERVICEFLOW=1
GROUP BY V372_CALLINGPARTYNUMBER)P
WHERE (TOTAL/DISTINCT_CALLEDPARTY)>1
)P

;
    COMMIT;
END;
/

