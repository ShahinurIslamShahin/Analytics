--
-- BIN12JOINDATAVOLUME2G3G  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.BIN12JOINDATAVOLUME2G3G
(X, VOLUME3G, Y, VOLUME2G)
BEQUEATH DEFINER
AS 
SELECT X,
          VOLUME3G,
          Y,
          VOLUME2G
     FROM (  SELECT G379_CALLINGCELLID X, SUM (G384_TOTALFLUX) VOLUME3G
               FROM L3_DATA
              WHERE     G429_RATTYPE = 1
                    AND G383_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           --AND G401_MAINOFFERINGID IS NOT NULL
           GROUP BY G379_CALLINGCELLID)
          FULL JOIN
          (  SELECT G379_CALLINGCELLID Y, SUM (G384_TOTALFLUX) VOLUME2G
               FROM L3_DATA
              WHERE     G429_RATTYPE = 2
                    AND G383_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           --AND G401_MAINOFFERINGID IS NOT NULL
           GROUP BY G379_CALLINGCELLID)
             ON (Y = X);


