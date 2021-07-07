--
-- SHAHIN  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.SHAHIN
(X, Z, MO_REVENUE, MO_DURATION, VOLUME)
BEQUEATH DEFINER
AS 
SELECT X,
          Z,
          MO_REVENUE,
          MO_DURATION,
          VOLUME
     FROM (  SELECT V381_CALLINGCELLID X,
                    SUM (V41_DEBIT_AMOUNT) MO_REVENUE,
                    SUM (V35_RATE_USAGE) MO_DURATION
               FROM L3_VOICE A
              WHERE     V403_ROAMSTATE != 3
                    AND V378_SERVICEFLOW = 1
                    AND ETL_DATE_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                    AND V381_CALLINGCELLID IS NOT NULL
           GROUP BY V381_CALLINGCELLID)
          FULL JOIN
          (  SELECT G379_CALLINGCELLID Z, SUM (G384_TOTALFLUX) VOLUME
               FROM L3_DATA C
              WHERE     ETL_DATE_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                    AND G379_CALLINGCELLID IS NOT NULL
           GROUP BY G379_CALLINGCELLID)
             ON X = Z;


