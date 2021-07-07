--
-- MSISDN_USSD_BI_NEW  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.MSISDN_USSD_BI_NEW
(MSISDN, TIMESTAMP, LATITUDE, LONGITUDE, UPAZILA, 
 DISTRICT)
BEQUEATH DEFINER
AS 
SELECT AA.MSISDN,
          AA.TIMESTAMP,
          AA.LATITUDE,
          AA.LONGITUDE,
          AA.UPAZILA,
          AA.DISTRICT
     FROM (SELECT XX.MSISDN,
                  XX.TIMESTAMP,
                  XX.LATITUDE,
                  XX.LONGITUDE,
                  XX.UPAZILA,
                  XX.DISTRICT,
                  RANK ()
                     OVER (PARTITION BY XX.MSISDN ORDER BY XX.TIMESTAMP DESC)
                     AS LAST_KEY
             FROM (SELECT Z.V372_CALLINGPARTYNUMBER AS MSISDN,
                          TO_CHAR (
                             TO_DATE (Z.CALL_DATE, 'YYYY-MM-DD HH24:MI:SS'),
                             'YYYY-MM-DD HH24:MI:SS')
                             AS TIMESTAMP,
                          Z.LATITUDE,
                          Z.LONGITUDE,
                          Z.UPAZILA,
                          Z.DISTRICT
                     FROM CORONA_IVR_MSISDN@DWH05TODWH01 A,
                          (  SELECT K.V372_CALLINGPARTYNUMBER,
                                    K.DATE_VALUE || K.V387_CHARGINGTIME_HOUR
                                       AS CALL_DATE,
                                    M.LATITUDE,
                                    M.LONGITUDE,
                                    M.UPAZILA,
                                    M.DISTRICT
                               FROM ZONE_DIM@DWH05TODWH01 M,
                                    (  SELECT V381_CALLINGCELLID,
                                              V372_CALLINGPARTYNUMBER,
                                              TO_CHAR (B.DATE_VALUE, 'RRRRMMDD')
                                                 AS DATE_VALUE,
                                              V387_CHARGINGTIME_HOUR
                                         --FROM L3_VOICE A, DATE_DIM B
                                         FROM L2_voice_333@DWH05TODWH01 A,
                                              DATE_DIM B
                                        WHERE     V387_CHARGINGTIME_KEY IN (SELECT A.DATE_KEY
                                                                              FROM DATE_DIM A
                                                                             WHERE A.DATE_VALUE BETWEEN TO_DATE (
                                                                                                             SYSDATE
                                                                                                           - 4,
                                                                                                           'DD/MM/RRRR')
                                                                                                    AND TO_DATE (
                                                                                                             SYSDATE
                                                                                                           - 1,
                                                                                                           'DD/MM/RRRR'))
                                              --AND V373_CALLEDPARTYNUMBER ='333'
                                              --AND V373_CALLEDPARTYNUMBER ='16263'
                                              AND V387_CHARGINGTIME_KEY =
                                                     B.DATE_KEY
                                     GROUP BY V381_CALLINGCELLID,
                                              V372_CALLINGPARTYNUMBER,
                                              B.DATE_VALUE,
                                              V387_CHARGINGTIME_HOUR) K
                              WHERE  V381_CALLINGCELLID=CGI(+)
                           GROUP BY K.V372_CALLINGPARTYNUMBER,
                                    K.DATE_VALUE || K.V387_CHARGINGTIME_HOUR,
                                    M.LATITUDE,
                                    M.LONGITUDE,
                                    M.UPAZILA,
                                    M.DISTRICT
                           ORDER BY K.V372_CALLINGPARTYNUMBER, M.DISTRICT) Z
                    WHERE Z.V372_CALLINGPARTYNUMBER = A.MSISDN) XX) AA
    WHERE LAST_KEY = 1
   --ORDER BY  4 ASC, 5 ASC.
   UNION ALL
   SELECT AA.MSISDN,
          AA.TIMESTAMP,
          AA.LATITUDE,
          AA.LONGITUDE,
          AA.UPAZILA,
          AA.DISTRICT
     FROM (SELECT XX.MSISDN,
                  XX.TIMESTAMP,
                  XX.LATITUDE,
                  XX.LONGITUDE,
                  XX.UPAZILA,
                  XX.DISTRICT,
                  RANK ()
                     OVER (PARTITION BY XX.MSISDN ORDER BY XX.TIMESTAMP DESC)
                     AS LAST_KEY
             FROM (SELECT Z.V372_CALLINGPARTYNUMBER AS MSISDN,
                          TO_CHAR (
                             TO_DATE (Z.CALL_DATE, 'YYYY-MM-DD HH24:MI:SS'),
                             'YYYY-MM-DD HH24:MI:SS')
                             AS TIMESTAMP,
                          Z.LATITUDE,
                          Z.LONGITUDE,
                          Z.UPAZILA,
                          Z.DISTRICT
                     FROM CORONA_IVR_MSISDN@DWH05TODWH01 A,
                          (  SELECT K.V372_CALLINGPARTYNUMBER,
                                    K.DATE_VALUE || K.V387_CHARGINGTIME_HOUR
                                       AS CALL_DATE,
                                    M.LATITUDE,
                                    M.LONGITUDE,
                                    M.UPAZILA,
                                    M.DISTRICT
                               FROM ZONE_DIM@DWH05TODWH01 M,
                                    (  SELECT V381_CALLINGCELLID,
                                              V372_CALLINGPARTYNUMBER,
                                              TO_CHAR (B.DATE_VALUE, 'RRRRMMDD')
                                                 AS DATE_VALUE,
                                              V387_CHARGINGTIME_HOUR
                                         FROM L3_VOICE A, DATE_DIM B
                                        --FROM L2_voice_333@DWH05TODWH01 A, DATE_DIM B
                                        WHERE     V387_CHARGINGTIME_KEY IN (SELECT A.DATE_KEY
                                                                              FROM DATE_DIM A
                                                                             WHERE A.DATE_VALUE BETWEEN TO_DATE (
                                                                                                             SYSDATE
                                                                                                           - 4,
                                                                                                           'DD/MM/RRRR')
                                                                                                    AND TO_DATE (
                                                                                                             SYSDATE
                                                                                                           - 1,
                                                                                                           'DD/MM/RRRR'))
                                              --AND V373_CALLEDPARTYNUMBER ='333'
                                              --AND V373_CALLEDPARTYNUMBER ='16263'
                                              AND V387_CHARGINGTIME_KEY =
                                                     B.DATE_KEY
                                     GROUP BY V381_CALLINGCELLID,
                                              V372_CALLINGPARTYNUMBER,
                                              B.DATE_VALUE,
                                              V387_CHARGINGTIME_HOUR) K
                              WHERE V381_CALLINGCELLID=CGI(+)
                           GROUP BY K.V372_CALLINGPARTYNUMBER,
                                    K.DATE_VALUE || K.V387_CHARGINGTIME_HOUR,
                                    M.LATITUDE,
                                    M.LONGITUDE,
                                    M.UPAZILA,
                                    M.DISTRICT
                           ORDER BY K.V372_CALLINGPARTYNUMBER, M.DISTRICT) Z
                    WHERE Z.V372_CALLINGPARTYNUMBER = A.MSISDN) XX) AA
    WHERE LAST_KEY = 1
--ORDER BY  4 ASC, 5 ASC
;


