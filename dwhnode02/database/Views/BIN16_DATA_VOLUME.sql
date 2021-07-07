--
-- BIN16_DATA_VOLUME  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.BIN16_DATA_VOLUME
(X, VOLUME3G, Y, VOLUME2G, Z, 
 VOLUME4G)
BEQUEATH DEFINER
AS 
SELECT "X",
          "VOLUME3G",
          "Y",
          "VOLUME2G",
          "Z",
          "VOLUME4G"
     FROM (  SELECT G401_MAINOFFERINGID X, SUM (G384_TOTALFLUX) VOLUME3G
               FROM L3_DATA
              WHERE     G429_RATTYPE = 1
                    AND G383_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           --AND G401_MAINOFFERINGID IS NOT NULL
           GROUP BY G401_MAINOFFERINGID)
          FULL JOIN
          (  SELECT G401_MAINOFFERINGID Y, SUM (G384_TOTALFLUX) VOLUME2G
               FROM L3_DATA
              WHERE     G429_RATTYPE = 2
                    AND G383_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           --AND G401_MAINOFFERINGID IS NOT NULL
           GROUP BY G401_MAINOFFERINGID)
             ON (Y = X)
          FULL JOIN
          (  SELECT G401_MAINOFFERINGID Z, SUM (G384_TOTALFLUX) VOLUME4G
               FROM L3_DATA
              WHERE     G429_RATTYPE = 6
                    AND G383_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           --AND G401_MAINOFFERINGID IS NOT NULL
           GROUP BY G401_MAINOFFERINGID)
             ON (Z = X OR Z = Y);


