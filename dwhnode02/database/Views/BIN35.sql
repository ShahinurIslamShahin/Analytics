--
-- BIN35  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.BIN35
(X, Y, DURATION, REVENUE)
BEQUEATH DEFINER
AS 
SELECT X,
          Y,
          COALESCE (MO_DURATION, 0) + COALESCE (MT_DURATION, 0) DURATION,
          COALESCE (MO_REVENUE, 0) + COALESCE (MT_REVENUE, 0) REVENUE
     FROM (  SELECT V381_CALLINGCELLID X,
                    SUM (V41_DEBIT_AMOUNT) MO_REVENUE,
                    SUM (V35_RATE_USAGE) MO_DURATION
               FROM L3_VOICE A
              WHERE     V403_ROAMSTATE != 3
                    AND V378_SERVICEFLOW = 1
                    AND V387_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY V381_CALLINGCELLID)
          FULL JOIN
          (  SELECT V383_CALLEDCELLID Y,
                    SUM (V41_DEBIT_AMOUNT) MT_REVENUE,
                    SUM (V35_RATE_USAGE) MT_DURATION
               FROM L3_VOICE A
              WHERE     V403_ROAMSTATE != 3
                    AND V378_SERVICEFLOW = 2
                    AND V387_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY V383_CALLEDCELLID)
             ON X = Y;


