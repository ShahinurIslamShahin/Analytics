--
-- BIN16_VOICE_DURATION  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.BIN16_VOICE_DURATION
(P, MO_DURATION, Q, MT_DURATION)
BEQUEATH DEFINER
AS 
SELECT "P",
          "MO_DURATION",
          "Q",
          "MT_DURATION"
     FROM (  SELECT V397_MAINOFFERINGID P, SUM (V35_RATE_USAGE) MO_Duration
               FROM L3_VOICE
              WHERE     V378_SERVICEFLOW = 1
                    AND V387_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           --AND V397_MAINOFFERINGID IS NOT NULL
           GROUP BY V397_MAINOFFERINGID)
          FULL JOIN
          (  SELECT V397_MAINOFFERINGID Q, SUM (V35_RATE_USAGE) MT_Duration
               FROM L3_VOICE
              WHERE     V378_SERVICEFLOW = 2
                    AND V387_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           --AND V397_MAINOFFERINGID IS NOT NULL
           GROUP BY V397_MAINOFFERINGID)
             ON P = Q;


