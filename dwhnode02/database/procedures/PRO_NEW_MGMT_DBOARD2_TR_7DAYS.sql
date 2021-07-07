--
-- PRO_NEW_MGMT_DBOARD2_TR_7DAYS  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.PRO_NEW_MGMT_DBOARD2_TR_7DAYS IS
    VDATE_KEY       NUMBER;
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD');

    
DELETE NEW_MGMT_DBOARD2_TR_7DAYS WHERE PDR_DATE_KEY=VDATE_KEY;
COMMIT;
    
INSERT INTO NEW_MGMT_DBOARD2_TR_7DAYS


SELECT DATE_VALUE,TOTAL_REVENUE,VDATE_KEY
       FROM DATE_DIM,
(SELECT A.DATE_KEY DATE1,
                  (  COALESCE (DATA_REVENUE, 0)
                  + COALESCE (VOICE_REVENUE, 0)
                  + COALESCE (VAS_REVENUE, 0)
                  + COALESCE (SMS_REVENUE, 0)
                  + COALESCE (CONTENT_REVENUE, 0)
                  + COALESCE (ADJUSTMENT_REVENUE, 0)
                  )/10000000
                    TOTAL_REVENUE
     FROM (SELECT /*+PARALLEL(P,8)*/ DATE_KEY
                        FROM DATE_DIM P
                       WHERE DATE_VALUE >=
                                TO_DATE (SYSDATE - 7, 'DD/MM/RRRR')
                                AND
                                DATE_VALUE <
                                TO_DATE (SYSDATE , 'DD/MM/RRRR')
          ) A
          LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(Q,8)*/ G383_CHARGINGTIME_KEY,
                    SUM (G41_DEBIT_AMOUNT) DATA_REVENUE,SUM(G384_TOTALFLUX)/1099511627776 DATA_TB
               FROM L3_DATA Q
              WHERE G383_CHARGINGTIME_KEY IN
                       (SELECT DATE_KEY
                          FROM DATE_DIM 
                         WHERE DATE_VALUE >=
                                  TO_DATE (SYSDATE - 7, 'DD/MM/RRRR'))
           GROUP BY G383_CHARGINGTIME_KEY) B
             ON A.DATE_KEY = B.G383_CHARGINGTIME_KEY
          LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(R,8)*/ V387_CHARGINGTIME_KEY,
                    SUM (V41_DEBIT_AMOUNT) VOICE_REVENUE
               FROM L3_VOICE R
              WHERE  V387_CHARGINGTIME_KEY IN
                       (SELECT DATE_KEY
                          FROM DATE_DIM 
                         WHERE DATE_VALUE >=
                                  TO_DATE (SYSDATE - 7, 'DD/MM/RRRR'))
           GROUP BY V387_CHARGINGTIME_KEY) C
             ON A.DATE_KEY = C.V387_CHARGINGTIME_KEY
          LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(S,8)*/ R377_CYCLEBEGINTIME_KEY,
                    SUM (R41_DEBIT_AMOUNT) VAS_REVENUE
               FROM L3_RECURRING S
              WHERE R377_CYCLEBEGINTIME_KEY IN
                       (SELECT DATE_KEY
                          FROM DATE_DIM 
                         WHERE DATE_VALUE >=
                                  TO_DATE (SYSDATE - 7, 'DD/MM/RRRR'))
           GROUP BY R377_CYCLEBEGINTIME_KEY) D
             ON A.DATE_KEY = D.R377_CYCLEBEGINTIME_KEY
          LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(T,8)*/ S387_CHARGINGTIME_KEY, SUM (S41_DEBIT_AMOUNT) SMS_REVENUE
               FROM L3_SMS T
              WHERE  S387_CHARGINGTIME_KEY IN
                       (SELECT DATE_KEY
                          FROM DATE_DIM 
                         WHERE DATE_VALUE >=
                                  TO_DATE (SYSDATE - 7, 'DD/MM/RRRR'))
           GROUP BY S387_CHARGINGTIME_KEY) E
             ON A.DATE_KEY = E.S387_CHARGINGTIME_KEY
             
             
             LEFT OUTER JOIN
          ( SELECT /*+PARALLEL(U,8)*/ CO402_STARTTIMEOFBILLCYL_KEY,SUM(CO41_DEBIT_AMOUNT) CONTENT_REVENUE
             FROM L3_CONTENT U
            WHERE CO402_STARTTIMEOFBILLCYL_KEY IN
                     (SELECT DATE_KEY
                        FROM DATE_DIM 
                       WHERE DATE_VALUE >=
                                TO_DATE (SYSDATE - 7, 'DD/MM/RRRR'))
                                
                                                
           GROUP BY CO402_STARTTIMEOFBILLCYL_KEY) F
             ON A.DATE_KEY = F.CO402_STARTTIMEOFBILLCYL_KEY
                   
                LEFT OUTER JOIN
          ( SELECT /*+PARALLEL(V,8)*/ A22_ENTRY_DATE_KEY,SUM(A30_DEBIT_AMOUNT) ADJUSTMENT_REVENUE
             FROM L3_ADJUSTMENT V
            WHERE A22_ENTRY_DATE_KEY IN
                     (SELECT DATE_KEY
                        FROM DATE_DIM 
                       WHERE DATE_VALUE >=
                                TO_DATE (SYSDATE - 7, 'DD/MM/RRRR'))
                                
                                                
           GROUP BY A22_ENTRY_DATE_KEY) G
             ON A.DATE_KEY = G.A22_ENTRY_DATE_KEY
             
) WHERE DATE1=DATE_KEY
ORDER BY DATE_VALUE ASC;

    COMMIT;
END;
/

