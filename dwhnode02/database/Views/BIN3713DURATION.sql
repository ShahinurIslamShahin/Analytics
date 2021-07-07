--
-- BIN3713DURATION  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.BIN3713DURATION
(Y, X, DURATION)
BEQUEATH DEFINER
AS 
SELECT Y,
          X,
          COALESCE (MO_DURATION, 0) + COALESCE (MT_DURATION, 0) DURATION
     FROM (  SELECT V381_CALLINGCELLID Y, SUM (V35_RATE_USAGE) MO_DURATION
               FROM L3_VOICE B
              WHERE     V403_ROAMSTATE != 3
                    AND V378_SERVICEFLOW = 1
                    AND V387_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY V381_CALLINGCELLID)
          FULL JOIN
          (  SELECT V383_CALLEDCELLID X, SUM (V35_RATE_USAGE) MT_DURATION
               FROM L3_VOICE B
              WHERE     V403_ROAMSTATE != 3
                    AND V378_SERVICEFLOW = 2
                    AND V387_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY V383_CALLEDCELLID)
             ON Y = X;


