--
-- PRO_NEW_MGMT_DBOARD7_USAGE  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.PRO_NEW_MGMT_DBOARD7_USAGE IS
    VDATE_KEY       NUMBER;
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD');

    
DELETE NEW_MGMT_DBOARD7_USAGE WHERE PDR_DATE_KEY=VDATE_KEY;
COMMIT;
    
INSERT INTO NEW_MGMT_DBOARD7_USAGE


SELECT  DATE_VALUE ,DATA_GB ,MO_VOICE_DURATION_HR ,MT_VOICE_DURATION_HR,SMS_COUNT,VDATE_KEY FROM DATE_DIM,
(SELECT A.DATE_KEY DATE1,DATA_GB,MO_VOICE_DURATION_HR,MT_VOICE_DURATION_HR,SMS_COUNT FROM  

       (SELECT /*+PARALLEL(P,8)*/ DATE_KEY
                        FROM DATE_DIM  P
                       WHERE DATE_VALUE >=
                                TO_DATE (SYSDATE - 3, 'DD/MM/RRRR')
                                AND
                                DATE_VALUE <
                                TO_DATE (SYSDATE , 'DD/MM/RRRR')
          ) A
          
          
      LEFT OUTER JOIN
          (  SELECT  /*+PARALLEL(Q,8)*/ G383_CHARGINGTIME_KEY,
                   SUM(G384_TOTALFLUX)/1099511627776  DATA_GB
               FROM L3_DATA Q
              WHERE G383_CHARGINGTIME_KEY IN
                       (SELECT DATE_KEY
                          FROM DATE_DIM 
                         WHERE DATE_VALUE >=
                                  TO_DATE (SYSDATE - 3, 'DD/MM/RRRR'))
           GROUP BY G383_CHARGINGTIME_KEY) B
             ON A.DATE_KEY = B.G383_CHARGINGTIME_KEY
             
             
        LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(R,8)*/ V387_CHARGINGTIME_KEY,
                   SUM(V35_RATE_USAGE)/(3600*1000)  MO_VOICE_DURATION_HR
               FROM L3_VOICE R
              WHERE  V378_SERVICEFLOW =1 and V387_CHARGINGTIME_KEY IN
                       (SELECT DATE_KEY
                          FROM DATE_DIM 
                         WHERE DATE_VALUE >=
                                  TO_DATE (SYSDATE - 3, 'DD/MM/RRRR'))
           GROUP BY V387_CHARGINGTIME_KEY) C
             ON A.DATE_KEY = C.V387_CHARGINGTIME_KEY
             
             
            LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(S,8)*/ S387_CHARGINGTIME_KEY,
               COUNT(S22_PRI_IDENTITY)/1000 SMS_COUNT
               FROM L3_SMS S
              WHERE  S387_CHARGINGTIME_KEY IN
                       (SELECT DATE_KEY
                          FROM DATE_DIM 
                         WHERE DATE_VALUE >=
                                  TO_DATE (SYSDATE - 3, 'DD/MM/RRRR'))
           GROUP BY S387_CHARGINGTIME_KEY) D
             ON A.DATE_KEY = D.S387_CHARGINGTIME_KEY 
             
                          
        LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(T,8)*/ V387_CHARGINGTIME_KEY,
                   SUM(V35_RATE_USAGE)/(3600*1000)  MT_VOICE_DURATION_HR
               FROM L3_VOICE T
              WHERE  V378_SERVICEFLOW =2 and V387_CHARGINGTIME_KEY IN
                       (SELECT DATE_KEY
                          FROM DATE_DIM 
                         WHERE DATE_VALUE >=
                                  TO_DATE (SYSDATE - 3, 'DD/MM/RRRR'))
           GROUP BY V387_CHARGINGTIME_KEY) E
             ON A.DATE_KEY = E.V387_CHARGINGTIME_KEY
             
 )
 WHERE DATE1=DATE_KEY;

    COMMIT;
END;
/

