--
-- UPDATED_BIN12  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.UPDATED_BIN12
(X, VOICE_REVENUE, VOICE_DURATION, DATAPAYG_REVENUE, VOLUME3G, 
 VOLUME2G, VOLUME4G)
BEQUEATH DEFINER
AS 
SELECT A.V381_CALLINGCELLID X,
          COALESCE (MO_REVENUE, 0) + COALESCE (MT_REVENUE, 0) VOICE_REVENUE,
          COALESCE (MO_DURATION, 0) + COALESCE (MT_DURATION, 0)
             VOICE_DURATION,
          DATAPAYG_REVENUE,
          VOLUME3G,
          VOLUME2G,
          VOLUME4G
     FROM (SELECT /*+PARALLEL(P,8)*/  V381_CALLINGCELLID
             FROM L3_Voice P
            WHERE     V387_CHARGINGTIME_KEY =
                         (SELECT A.DATE_KEY
                            FROM DATE_DIM A
                           WHERE A.DATE_VALUE =
                                    TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                  AND V402_CALLTYPE != 3
           UNION
           SELECT /*+PARALLEL(Q,8)*/ V383_CALLEDCELLID
             FROM L3_Voice Q
            WHERE     V387_CHARGINGTIME_KEY =
                         (SELECT A.DATE_KEY
                            FROM DATE_DIM A
                           WHERE A.DATE_VALUE =
                                    TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                  AND V402_CALLTYPE != 3
           UNION
           SELECT /*+PARALLEL(R,8)*/ G379_CALLINGCELLID
             FROM L3_data R
            WHERE G383_CHARGINGTIME_KEY =
                     (SELECT A.DATE_KEY
                        FROM DATE_DIM A
                       WHERE A.DATE_VALUE =
                                TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))) A
          LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(S,8)*/ V381_CALLINGCELLID,
                    SUM (V41_DEBIT_AMOUNT) MO_REVENUE,
                    SUM (V35_RATE_USAGE) MO_DURATION
               FROM L3_VOICE S
              WHERE     V378_SERVICEFLOW = 1
                    AND V402_CALLTYPE != 3
                    AND V387_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY V381_CALLINGCELLID) B
             ON A.V381_CALLINGCELLID = B.V381_CALLINGCELLID
          LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(T,8)*/ V383_CALLEDCELLID,
                    SUM (V41_DEBIT_AMOUNT) MT_REVENUE,
                    SUM (V35_RATE_USAGE) MT_DURATION
               FROM L3_VOICE T
              WHERE     V378_SERVICEFLOW = 2
                    AND V402_CALLTYPE != 3
                    AND V387_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY V383_CALLEDCELLID) C
             ON A.V381_CALLINGCELLID = C.V383_CALLEDCELLID
          LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(U,8)*/ G379_CALLINGCELLID, SUM (G384_TOTALFLUX) VOLUME3G
               FROM L3_DATA U
              WHERE     G429_RATTYPE = 1
                    AND G383_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY G379_CALLINGCELLID) D
             ON A.V381_CALLINGCELLID = D.G379_CALLINGCELLID
          LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(V,8)*/ G379_CALLINGCELLID, SUM (G384_TOTALFLUX) VOLUME2G
               FROM L3_DATA V
              WHERE     G429_RATTYPE = 2
                    AND G383_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY G379_CALLINGCELLID) E
             ON A.V381_CALLINGCELLID = E.G379_CALLINGCELLID
          LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(W,8)*/ G379_CALLINGCELLID, SUM (G384_TOTALFLUX) VOLUME4G
               FROM L3_DATA W
              WHERE     G429_RATTYPE = 6
                    AND G383_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY G379_CALLINGCELLID) F
             ON A.V381_CALLINGCELLID = F.G379_CALLINGCELLID
          LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(X,8)*/ G379_CALLINGCELLID, SUM (G41_DEBIT_AMOUNT) DATAPAYG_REVENUE
               FROM L3_DATA X
              WHERE G383_CHARGINGTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY G379_CALLINGCELLID) G
             ON A.V381_CALLINGCELLID = G.G379_CALLINGCELLID;


