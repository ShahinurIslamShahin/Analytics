--
-- UPDATED_BIN16  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.UPDATED_BIN16
(X, MO_DURATION, MT_DURATION, VOLUME3G, VOLUME2G, 
 VOLUME4G, SMS_COUNT)
BEQUEATH DEFINER
AS 
SELECT A.V397_MAINOFFERINGID X,
          MO_Duration,
          MT_Duration,
          VOLUME3G,
          VOLUME2G,
          VOLUME4G,
          SMS_Count
     FROM (SELECT /*+PARALLEL(P,8)*/ V397_MAINOFFERINGID
             FROM L3_Voice P
            WHERE     V387_CHARGINGTIME_KEY =
                         (SELECT A.DATE_KEY
                            FROM DATE_DIM A
                           WHERE A.DATE_VALUE =
                                    TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                  AND V402_CALLTYPE != 3
           UNION
           SELECT /*+PARALLEL(Q,8)*/ S395_MAINOFFERINGID
             FROM L3_SMS Q
            WHERE     S387_CHARGINGTIME_KEY =
                         (SELECT A.DATE_KEY
                            FROM DATE_DIM A
                           WHERE A.DATE_VALUE =
                                    TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                  AND S400_SMSTYPE != 3
           UNION
           SELECT /*+PARALLEL(R,8)*/ G401_MAINOFFERINGID
             FROM L3_data R
            WHERE G383_CHARGINGTIME_KEY =
                     (SELECT A.DATE_KEY
                        FROM DATE_DIM A
                       WHERE A.DATE_VALUE =
                                TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))) A
          LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(S,8)*/ V397_MAINOFFERINGID, SUM (V35_RATE_USAGE) MO_Duration
               FROM L3_VOICE S
              WHERE     V378_SERVICEFLOW = 1
                    AND V402_CALLTYPE != 3
                    AND V387_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           --AND V397_MAINOFFERINGID IS NOT NULL
           GROUP BY V397_MAINOFFERINGID) B
             ON A.V397_MAINOFFERINGID = B.V397_MAINOFFERINGID
          LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(T,8)*/ V397_MAINOFFERINGID, SUM (V35_RATE_USAGE) MT_Duration
               FROM L3_VOICE T
              WHERE     V378_SERVICEFLOW = 2
                    AND V402_CALLTYPE != 3
                    AND V387_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           --AND V397_MAINOFFERINGID IS NOT NULL
           GROUP BY V397_MAINOFFERINGID) C
             ON A.V397_MAINOFFERINGID = C.V397_MAINOFFERINGID
          LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(U,8)*/ G401_MAINOFFERINGID, SUM (G384_TOTALFLUX) VOLUME3G
               FROM L3_DATA U
              WHERE     G429_RATTYPE = 1
                    AND G383_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY G401_MAINOFFERINGID) D
             ON A.V397_MAINOFFERINGID = D.G401_MAINOFFERINGID
          LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(V,8)*/ G401_MAINOFFERINGID, SUM (G384_TOTALFLUX) VOLUME2G
               FROM L3_DATA V
              WHERE     G429_RATTYPE = 2
                    AND G383_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY G401_MAINOFFERINGID) E
             ON A.V397_MAINOFFERINGID = E.G401_MAINOFFERINGID
          LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(W,8)*/ G401_MAINOFFERINGID, SUM (G384_TOTALFLUX) VOLUME4G
               FROM L3_DATA W
              WHERE     G429_RATTYPE = 6
                    AND G383_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY G401_MAINOFFERINGID) F
             ON A.V397_MAINOFFERINGID = F.G401_MAINOFFERINGID
          LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(X,8)*/ S395_MAINOFFERINGID, COUNT (S22_PRI_IDENTITY) SMS_Count
               FROM L3_SMS X
              WHERE     S387_CHARGINGTIME_KEY =
                           (SELECT DATE_KEY
                              FROM DATE_DIM
                             WHERE DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                    AND S400_SMSTYPE != 3
           GROUP BY S395_MAINOFFERINGID) G
             ON A.V397_MAINOFFERINGID = G.S395_MAINOFFERINGID;


