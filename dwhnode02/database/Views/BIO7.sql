--
-- BIO7  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.BIO7
(SALE_REGION, PACKAGEALL, CALLTYPE, MO_REVENUE, MT_REVENUE, 
 VOLUME)
BEQUEATH DEFINER
AS 
SELECT sale_region,
          packageall,
          calltype,
          MO_REVENUE,
          MT_REVENUE,
          VOLUME
     FROM (SELECT V381_CALLINGCELLID sale_region,
                  V397_MAINOFFERINGID packageall,
                  V400_PAYTYPE calltype
             FROM L3_VOICE
            WHERE    V402_CALLTYPE !=3 and 
            
              V387_CHARGINGTIME_KEY IN (SELECT A.DATE_KEY
                                                  FROM DATE_DIM A
                                                 WHERE A.DATE_VALUE >
                                                          TO_DATE (
                                                             SYSDATE - 30,
                                                             'DD/MM/RRRR'))
                  AND V381_CALLINGCELLID IS NOT NULL
           UNION
           SELECT V383_CALLEDCELLID Y,
                  V397_MAINOFFERINGID VOICE_PACKAGE2,
                  V400_PAYTYPE TYPE2
             FROM L3_VOICE
            WHERE   V402_CALLTYPE !=3 and  V387_CHARGINGTIME_KEY IN (SELECT A.DATE_KEY
                                                  FROM DATE_DIM A
                                                 WHERE A.DATE_VALUE >
                                                          TO_DATE (
                                                             SYSDATE - 30,
                                                             'DD/MM/RRRR'))
                  AND V383_CALLEDCELLID IS NOT NULL
           UNION
           SELECT G379_CALLINGCELLID Z,
                  G401_MAINOFFERINGID GPRS_PACKAGE,
                  G403_PAYTYPE TYPE3
             FROM L3_DATA
            WHERE G383_CHARGINGTIME_KEY IN (SELECT A.DATE_KEY
                                              FROM DATE_DIM A
                                             WHERE A.DATE_VALUE >
                                                      TO_DATE (SYSDATE - 30,
                                                               'DD/MM/RRRR')))
          P
          LEFT OUTER JOIN
          (  SELECT V381_CALLINGCELLID X,
                    V397_MAINOFFERINGID VOICE_PACKAGE1,
                    V400_PAYTYPE TYPE1,
                    SUM (V41_DEBIT_AMOUNT) MO_REVENUE
               FROM L3_VOICE A
              WHERE     V378_SERVICEFLOW = 1
                    AND V402_CALLTYPE != 3
                    AND V387_CHARGINGTIME_KEY IN (SELECT A.DATE_KEY
                                                    FROM DATE_DIM A
                                                   WHERE A.DATE_VALUE >
                                                            TO_DATE (
                                                               SYSDATE - 30,
                                                               'DD/MM/RRRR'))
           GROUP BY V381_CALLINGCELLID, V397_MAINOFFERINGID, V400_PAYTYPE) Q
             ON     P.sale_region = Q.X
                AND P.packageall = Q.VOICE_PACKAGE1
                AND P.calltype = Q.TYPE1
          LEFT OUTER JOIN
          (  SELECT V383_CALLEDCELLID Y,
                    V397_MAINOFFERINGID VOICE_PACKAGE2,
                    V400_PAYTYPE TYPE2,
                    SUM (V41_DEBIT_AMOUNT) MT_REVENUE
               FROM L3_VOICE A
              WHERE     V378_SERVICEFLOW = 2
                    AND V402_CALLTYPE != 3
                    AND V387_CHARGINGTIME_KEY IN (SELECT A.DATE_KEY
                                                    FROM DATE_DIM A
                                                   WHERE A.DATE_VALUE >
                                                            TO_DATE (
                                                               SYSDATE - 30,
                                                               'DD/MM/RRRR'))
           GROUP BY V383_CALLEDCELLID, V397_MAINOFFERINGID, V400_PAYTYPE) R
             ON     P.sale_region = R.Y
                AND P.packageall = R.VOICE_PACKAGE2
                AND P.calltype = R.TYPE2
          LEFT OUTER JOIN
          (  SELECT G379_CALLINGCELLID Z,
                    G401_MAINOFFERINGID GPRS_PACKAGE,
                    G403_PAYTYPE TYPE3,
                    SUM (G384_TOTALFLUX) VOLUME
               FROM L3_DATA C
              WHERE G383_CHARGINGTIME_KEY IN (SELECT A.DATE_KEY
                                                FROM DATE_DIM A
                                               WHERE A.DATE_VALUE >
                                                        TO_DATE (SYSDATE - 30,
                                                                 'DD/MM/RRRR'))
           GROUP BY G379_CALLINGCELLID, G401_MAINOFFERINGID, G403_PAYTYPE) S
             ON     P.sale_region = S.Z
                AND P.packageall = S.GPRS_PACKAGE
                AND P.calltype = S.TYPE3;


