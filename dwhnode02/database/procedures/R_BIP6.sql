--
-- R_BIP6  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.R_BIP6 IS
    VDATE_KEY       NUMBER;
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD');
   
DELETE BIP6 WHERE PDR_DATE_KEY=VDATE_KEY;
COMMIT;
    
INSERT INTO BIP6


SELECT PRODUCT_NAME,TOTAL_REVENUE,VDATE_KEY FROM PRODUCT_DIM,
(SELECT A.V397_MAINOFFERINGID MSISDN,
          COALESCE (DATA_REVENUE, 0)
                  + COALESCE (VOICE_REVENUE, 0)
                  + COALESCE (VAS_REVENUE, 0)
                  + COALESCE (SMS_REVENUE, 0)
                  + COALESCE (CONTENT_REVENUE, 0)
                
                  
                     TOTAL_REVENUE
     FROM (SELECT V397_MAINOFFERINGID
             FROM L3_VOICE
            WHERE  V387_CHARGINGTIME_KEY =
                     (SELECT DATE_KEY
                        FROM DATE_DIM 
                       WHERE DATE_VALUE =
                                TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           UNION
           SELECT G401_MAINOFFERINGID
             FROM L3_DATA
            WHERE G383_CHARGINGTIME_KEY =
                     (SELECT DATE_KEY
                        FROM DATE_DIM 
                       WHERE DATE_VALUE =
                                TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           UNION
           SELECT S395_MAINOFFERINGID
             FROM L3_SMS
            WHERE  S387_CHARGINGTIME_KEY =
                     (SELECT DATE_KEY
                        FROM DATE_DIM 
                       WHERE DATE_VALUE =
                                TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           UNION
           SELECT R373_MAINOFFERINGID
             FROM L3_RECURRING
            WHERE R377_CYCLEBEGINTIME_KEY =
                     (SELECT DATE_KEY
                        FROM DATE_DIM 
                       WHERE DATE_VALUE =
                                TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                                
                                
           UNION
           SELECT CO396_MAINOFFERINGID
             FROM L3_CONTENT
            WHERE CO402_STARTTIMEOFBILLCYL_KEY =
                     (SELECT DATE_KEY
                        FROM DATE_DIM 
                       WHERE DATE_VALUE =
                                TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                                
                                                     
                                
                                
                                
                                
                                ) A
          LEFT OUTER JOIN
          (  SELECT G401_MAINOFFERINGID,
                    SUM (G448_PAY_DEBIT_AMOUNT) DATA_REVENUE
               FROM L3_DATA
              WHERE G383_CHARGINGTIME_KEY =
                       (SELECT DATE_KEY
                          FROM DATE_DIM 
                         WHERE DATE_VALUE =
                                  TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY G401_MAINOFFERINGID) B
             ON A.V397_MAINOFFERINGID = B.G401_MAINOFFERINGID
          LEFT OUTER JOIN
          (  SELECT V397_MAINOFFERINGID,
                    SUM (V41_DEBIT_AMOUNT) VOICE_REVENUE
               FROM L3_VOICE
              WHERE  V387_CHARGINGTIME_KEY =
                       (SELECT DATE_KEY
                          FROM DATE_DIM 
                         WHERE DATE_VALUE =
                                  TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY V397_MAINOFFERINGID) C
             ON A.V397_MAINOFFERINGID = C.V397_MAINOFFERINGID
          LEFT OUTER JOIN
          (  SELECT R373_MAINOFFERINGID,
                    SUM (R41_DEBIT_AMOUNT) VAS_REVENUE
               FROM L3_RECURRING
              WHERE R377_CYCLEBEGINTIME_KEY =
                       (SELECT DATE_KEY
                          FROM DATE_DIM 
                         WHERE DATE_VALUE =
                                  TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY R373_MAINOFFERINGID) D
             ON A.V397_MAINOFFERINGID = D.R373_MAINOFFERINGID
          LEFT OUTER JOIN
          (  SELECT S395_MAINOFFERINGID, SUM (S41_DEBIT_AMOUNT) SMS_REVENUE
               FROM L3_SMS
              WHERE  S387_CHARGINGTIME_KEY =
                       (SELECT DATE_KEY
                          FROM DATE_DIM 
                         WHERE DATE_VALUE =
                                  TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY S395_MAINOFFERINGID) E
             ON A.V397_MAINOFFERINGID = E.S395_MAINOFFERINGID
             
             
             LEFT OUTER JOIN
          ( SELECT CO396_MAINOFFERINGID,SUM(CO41_DEBIT_AMOUNT) CONTENT_REVENUE
             FROM L3_CONTENT
            WHERE CO402_STARTTIMEOFBILLCYL_KEY =
                     (SELECT DATE_KEY
                        FROM DATE_DIM 
                       WHERE DATE_VALUE =
                                TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                                
                                                
           GROUP BY CO396_MAINOFFERINGID) F
             ON A.V397_MAINOFFERINGID = F.CO396_MAINOFFERINGID
              
             
             
             
             ) WHERE MSISDN=PRODUCT_ID;
             
             
             
      COMMIT;
END;
/

