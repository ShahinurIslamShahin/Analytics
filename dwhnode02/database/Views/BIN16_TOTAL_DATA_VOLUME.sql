--
-- BIN16_TOTAL_DATA_VOLUME  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.BIN16_TOTAL_DATA_VOLUME
(X, VOLUME3G, VOLUME2G, VOLUME4G)
BEQUEATH DEFINER
AS 
SELECT "X",
          "VOLUME3G",
          "VOLUME2G",
          "VOLUME4G"
     FROM (SELECT X,
                  VOLUME3G,
                  VOLUME2G,
                  VOLUME4G
             FROM BIN16_DATA_VOLUME
           UNION
           SELECT Y,
                  VOLUME3G,
                  VOLUME2G,
                  VOLUME4G
             FROM BIN16_DATA_VOLUME
           UNION
           SELECT Z,
                  VOLUME3G,
                  VOLUME2G,
                  VOLUME4G
             FROM BIN16_DATA_VOLUME)
    WHERE X IS NOT NULL;


