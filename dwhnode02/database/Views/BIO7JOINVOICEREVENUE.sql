--
-- BIO7JOINVOICEREVENUE  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.BIO7JOINVOICEREVENUE
(VOICE_PACKAGE1, VOICE_PACKAGE2, TYPE1, TYPE2, X, 
 Y, VOICE_REVENUE)
BEQUEATH DEFINER
AS 
SELECT VOICE_PACKAGE1,
          VOICE_PACKAGE2,
          TYPE1,
          TYPE2,
          X,
          Y,
          COALESCE (MO_REVENUE, 0) + COALESCE (MT_REVENUE, 0) VOICE_REVENUE
     FROM (  SELECT V397_MAINOFFERINGID VOICE_PACKAGE1,
                    V24_SERVICE_CATEGORY TYPE1,
                    V381_CALLINGCELLID X,
                    SUM (V41_DEBIT_AMOUNT) MO_REVENUE
               FROM L3_VOICE A
              WHERE     V378_SERVICEFLOW = 1
                    AND V403_ROAMSTATE != 3
                    AND V387_CHARGINGTIME_KEY IN
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE >
                                      TO_DATE (SYSDATE - 30, 'DD/MM/RRRR'))
           GROUP BY V381_CALLINGCELLID,
                    V397_MAINOFFERINGID,
                    V24_SERVICE_CATEGORY)
          FULL JOIN
          (  SELECT V397_MAINOFFERINGID VOICE_PACKAGE2,
                    V24_SERVICE_CATEGORY TYPE2,
                    V383_CALLEDCELLID Y,
                    SUM (V41_DEBIT_AMOUNT) MT_REVENUE
               FROM L3_VOICE A
              WHERE     V378_SERVICEFLOW = 2
                    AND V403_ROAMSTATE != 3
                    AND V387_CHARGINGTIME_KEY IN
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE >
                                      TO_DATE (SYSDATE - 30, 'DD/MM/RRRR'))
           GROUP BY V383_CALLEDCELLID,
                    V397_MAINOFFERINGID,
                    V24_SERVICE_CATEGORY)
             ON VOICE_PACKAGE1 = VOICE_PACKAGE2 AND TYPE1 = TYPE2 AND X = Y;


