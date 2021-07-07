--
-- R_BIN6  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.R_BIN6 IS
    VDATE_KEY       NUMBER;
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD');



    --EXECUTE IMMEDIATE  'TRUNCATE TABLE PKPI DROP STORAGE';
    --EXECUTE IMMEDIATE 'ALTER TABLE PKPI TRUNCATE PARTITION PKPI_||VDATE_KEY DROP STORAGE';
    
DELETE BIN6 WHERE DATE_KEY=VDATE_KEY;
COMMIT;
    
INSERT INTO BIN6

select MSISDN,PRODUCT_NAME,TOTAL_REVENUE ,VDATE_KEY
from Product_dim,
(SELECT A.V372_CALLINGPARTYNUMBER MSISDN,A.V397_MAINOFFERINGID Package1,
          COALESCE (Data_Revenue, 0)
                  + COALESCE (Voice_Revenue1, 0)
                  + COALESCE (Voice_Revenue2, 0)
                  + COALESCE (Vas_Revenue, 0)
                  + COALESCE (SMS_Revenue, 0)
                     TOTAL_REVENUE
     FROM (             SELECT V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID
             FROM L3_voice
            WHERE V387_CHARGINGTIME_KEY =
                     (SELECT A.DATE_KEY
                        FROM DATE_DIM A
                       WHERE A.DATE_VALUE =
                                TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                  and V402_CALLTYPE!=3
                  and V378_SERVICEFLOW=1
           UNION
           SELECT V373_CALLEDPARTYNUMBER,V397_MAINOFFERINGID
             FROM L3_voice
            WHERE V387_CHARGINGTIME_KEY =
                     (SELECT A.DATE_KEY
                        FROM DATE_DIM A
                       WHERE A.DATE_VALUE =
                                TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                  and V402_CALLTYPE!=3
                  and V378_SERVICEFLOW=2
           UNION
           SELECT G372_CALLINGPARTYNUMBER, G401_MAINOFFERINGID
             FROM L3_Data
            WHERE G383_CHARGINGTIME_KEY =
                     (SELECT A.DATE_KEY
                        FROM DATE_DIM A
                       WHERE A.DATE_VALUE =
                                TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           UNION
           SELECT S22_PRI_IDENTITY, S395_MAINOFFERINGID
             FROM L3_sms
            WHERE S387_CHARGINGTIME_KEY =
                     (SELECT A.DATE_KEY
                        FROM DATE_DIM A
                       WHERE A.DATE_VALUE =
                                TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                                
                   and S400_SMSTYPE !=3
           UNION
           SELECT R375_CHARGINGPARTYNUMBER,R373_MAINOFFERINGID
             FROM L3_recurring
            WHERE R377_CYCLEBEGINTIME_KEY =
                     (SELECT A.DATE_KEY
                        FROM DATE_DIM A
                       WHERE A.DATE_VALUE =
                                TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))) A
          LEFT OUTER JOIN
          (  SELECT G372_CALLINGPARTYNUMBER, G401_MAINOFFERINGID,
                    SUM (G448_PAY_DEBIT_AMOUNT) Data_Revenue
               FROM L3_DATA
              WHERE G383_CHARGINGTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY G372_CALLINGPARTYNUMBER, G401_MAINOFFERINGID) B
             ON A.V372_CALLINGPARTYNUMBER=B.G372_CALLINGPARTYNUMBER
             and A.V397_MAINOFFERINGID = B.G401_MAINOFFERINGID
          LEFT OUTER JOIN
          (  SELECT V372_CALLINGPARTYNUMBER, V397_MAINOFFERINGID,
                    SUM (V41_DEBIT_AMOUNT) Voice_Revenue1
               FROM L3_VOICE
              WHERE V387_CHARGINGTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                                  
                                  and V402_CALLTYPE!=3
                                   and V378_SERVICEFLOW=1
                                  
           GROUP BY V372_CALLINGPARTYNUMBER, V397_MAINOFFERINGID) C
             ON A.V372_CALLINGPARTYNUMBER=C.V372_CALLINGPARTYNUMBER
             and A.V397_MAINOFFERINGID = C.V397_MAINOFFERINGID
             
             LEFT OUTER JOIN
          (  SELECT V373_CALLEDPARTYNUMBER, V397_MAINOFFERINGID,
                    SUM (V41_DEBIT_AMOUNT) Voice_Revenue2
               FROM L3_VOICE
              WHERE V387_CHARGINGTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                                  
                                  and V402_CALLTYPE!=3
                                  and V378_SERVICEFLOW=2
                                  
           GROUP BY V373_CALLEDPARTYNUMBER, V397_MAINOFFERINGID) F
             ON A.V372_CALLINGPARTYNUMBER=F.V373_CALLEDPARTYNUMBER
             and A.V397_MAINOFFERINGID = F.V397_MAINOFFERINGID 
             
          LEFT OUTER JOIN
          
          
          (  SELECT R375_CHARGINGPARTYNUMBER, R373_MAINOFFERINGID,
                    SUM (R41_DEBIT_AMOUNT) Vas_Revenue
               FROM L3_RECURRING
              WHERE R377_CYCLEBEGINTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY R375_CHARGINGPARTYNUMBER, R373_MAINOFFERINGID) D
             ON A.V372_CALLINGPARTYNUMBER=D.R375_CHARGINGPARTYNUMBER
             and A.V397_MAINOFFERINGID = D.R373_MAINOFFERINGID
          LEFT OUTER JOIN
          (  SELECT S22_PRI_IDENTITY, S395_MAINOFFERINGID, SUM (S41_DEBIT_AMOUNT) SMS_Revenue
               FROM L3_sms
              WHERE S387_CHARGINGTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                     and S400_SMSTYPE !=3

           GROUP BY S22_PRI_IDENTITY,  S395_MAINOFFERINGID) E
           
           
             ON A.V372_CALLINGPARTYNUMBER=E.S22_PRI_IDENTITY
             and A.V397_MAINOFFERINGID = E.S395_MAINOFFERINGID
             
             
  )
  where Package1=PRODUCT_ID and rownum<5000;
      COMMIT;
END;
/

