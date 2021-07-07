--
-- R_BIP7  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.R_BIP7 IS
    VDATE_KEY       NUMBER;
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD');
   
DELETE BIP7 WHERE PDR_DATE_KEY=VDATE_KEY;
COMMIT;
    
INSERT INTO BIP7

SELECT DISTRICT,  SUM(TOTAL_REVENUE) DATA_VOICE_REVENUE,VDATE_KEY
FROM
(SELECT INITCAP(DISTRICT) DISTRICT,TOTAL_REVENUE FROM ZONE_DIM,
(SELECT V381_CALLINGCELLID,
COALESCE (MO_VOICE_REVENUE, 0)+COALESCE (DATA_REVENUE, 0) + COALESCE (MT_VOICE_REVENUE, 0) TOTAL_REVENUE
FROM 
(

SELECT A.V381_CALLINGCELLID,
          B.MO_VOICE_REVENUE,
          C.DATA_REVENUE,
          D.MT_VOICE_REVENUE
     FROM (  SELECT V381_CALLINGCELLID
               FROM L3_VOICE
              WHERE V387_CHARGINGTIME_KEY =
                           (SELECT DATE_KEY
                              FROM DATE_DIM
                             WHERE DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY V381_CALLINGCELLID
           UNION
             SELECT V383_CALLEDCELLID
               FROM L3_VOICE
              WHERE  V387_CHARGINGTIME_KEY =
                           (SELECT DATE_KEY
                              FROM DATE_DIM
                             WHERE DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY V383_CALLEDCELLID
           UNION
             SELECT G379_CALLINGCELLID
               FROM L3_DATA
              WHERE G383_CHARGINGTIME_KEY =
                       (SELECT DATE_KEY
                          FROM DATE_DIM
                         WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY G379_CALLINGCELLID
           ) A
          LEFT OUTER JOIN
          (  SELECT V381_CALLINGCELLID, SUM (V41_DEBIT_AMOUNT) MO_VOICE_REVENUE
               FROM L3_VOICE
              WHERE  V387_CHARGINGTIME_KEY =
                           (SELECT DATE_KEY
                              FROM DATE_DIM
                             WHERE DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                    
           GROUP BY V381_CALLINGCELLID) B
             ON A.V381_CALLINGCELLID = B.V381_CALLINGCELLID
          LEFT OUTER JOIN
          (  SELECT G379_CALLINGCELLID, SUM (G41_DEBIT_AMOUNT) DATA_REVENUE
               FROM L3_DATA
              WHERE G383_CHARGINGTIME_KEY =
                       (SELECT DATE_KEY
                          FROM DATE_DIM
                         WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY G379_CALLINGCELLID) C
             ON A.V381_CALLINGCELLID = C.G379_CALLINGCELLID
        
          LEFT OUTER JOIN
          (  SELECT V383_CALLEDCELLID, SUM (V41_DEBIT_AMOUNT) MT_VOICE_REVENUE
               FROM L3_VOICE
              WHERE   V387_CHARGINGTIME_KEY =
                           (SELECT DATE_KEY
                              FROM DATE_DIM
                             WHERE DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                  
           GROUP BY V383_CALLEDCELLID) D
             ON A.V381_CALLINGCELLID = D.V383_CALLEDCELLID




)


)
WHERE CGI=V381_CALLINGCELLID
)
GROUP BY DISTRICT;
COMMIT;
END;
/

