--
-- R_PACKAGE_WISE_VOICE_PROFIT_2020  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.R_PACKAGE_WISE_VOICE_PROFIT_2020 IS
    VDATE_KEY       NUMBER;
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE,'RRRRMMDD');
   

    
INSERT INTO PACKAGE_WISE_VOICE_PROFIT

SELECT a.DATE_KEY,
       A.DATE_VALUE,
       A.PRODUCT_ID,
       A.PRODUCT_NAME,
       A.TOTAL_MINUTES,
       A.ONNET_MIN,
       A.OFFNET_MIN,
       A.FREE_MINUTES,
       A.PAID_MIN,
         ROUND (
            (  (A.GP_OFFNET_MIN * BASE_TARIFF)
             - (A.GP_OFFNET_MIN * 0.14)
             - ( (A.GP_OFFNET_MIN * BASE_TARIFF) * 0.185)),
            2)
       + ROUND (
            (  (A.OTHER_OFFNET_MIN * BASE_TARIFF)
             - (A.OTHER_OFFNET_MIN * 0.16)
             - ( (A.OTHER_OFFNET_MIN * BASE_TARIFF) * 0.185)),
            2)
          OFFNET_PROFIT,
       ROUND (
          (  (A.ONNET_MIN * BASE_TARIFF)
           - ( (A.ONNET_MIN * BASE_TARIFF) *  0.185)),
          2)
          ONNET_PROFIT,
       ROUND (
          ( (A.FREE_MINUTES * 0.45) - ( (A.FREE_MINUTES  * 0.45) * 0.185)),
          2)
          FREE_MIN_PROFIT
  FROM (SELECT DATE_KEY,
               DATE_VALUE,
               PRODUCT_ID,
               PRODUCT_NAME,
               TOTAL_MINUTES,
               ONNET_MIN,
               GP_OFFNET_MIN,
               OFFNET_MIN - GP_OFFNET_MIN OTHER_OFFNET_MIN,
               OFFNET_MIN,
               FREE_MINUTES,
               PAID_MIN
          FROM (  SELECT /*+PARALLEL(P,15)*/
                        DATE_KEY,
                        DATE_VALUE,
                         PRODUCT_ID,
                         PRODUCT_NAME,
                         ROUND (NVL (SUM (V35_RATE_USAGE) / 60, 0), 2)
                            TOTAL_MINUTES,
                         ROUND (
                            NVL (
                                 SUM (
                                    CASE
                                       WHEN V476_ONNETINDICATOR = '0'
                                       THEN
                                            V35_RATE_USAGE
                                          - V50_PAY_FREE_UNIT_DURATION
                                    END)
                               / 60,
                               0),
                            2)
                            ONNET_MIN,
                         ROUND (
                            NVL (
                                 SUM (
                                    CASE
                                       WHEN     V476_ONNETINDICATOR = '1'
                                            AND LENGTH (V373_CALLEDPARTYNUMBER) =
                                                   15
                                            AND SUBSTR (V373_CALLEDPARTYNUMBER,
                                                        4,
                                                        2) = '71'
                                       THEN
                                            V35_RATE_USAGE
                                          - V50_PAY_FREE_UNIT_DURATION
                                       WHEN     V476_ONNETINDICATOR = '1'
                                            AND LENGTH (V373_CALLEDPARTYNUMBER) =
                                                   13
                                            AND SUBSTR (V373_CALLEDPARTYNUMBER,
                                                        4,
                                                        2) = '17'
                                       THEN
                                            V35_RATE_USAGE
                                          - V50_PAY_FREE_UNIT_DURATION
                                       WHEN     V476_ONNETINDICATOR = '1'
                                            AND LENGTH (V373_CALLEDPARTYNUMBER) =
                                                   11
                                            AND SUBSTR (V373_CALLEDPARTYNUMBER,
                                                        2,
                                                        2) = '17'
                                       THEN
                                            V35_RATE_USAGE
                                          - V50_PAY_FREE_UNIT_DURATION
                                       WHEN     V476_ONNETINDICATOR = '1'
                                            AND LENGTH (V373_CALLEDPARTYNUMBER) =
                                                   10
                                            AND SUBSTR (V373_CALLEDPARTYNUMBER,
                                                        1,
                                                        2) = '17'
                                       THEN
                                            V35_RATE_USAGE
                                          - V50_PAY_FREE_UNIT_DURATION
                                       WHEN     V476_ONNETINDICATOR = '1'
                                            AND LENGTH (V373_CALLEDPARTYNUMBER) =
                                                   15
                                            AND SUBSTR (V373_CALLEDPARTYNUMBER,
                                                        4,
                                                        2) = '31'
                                       THEN
                                            V35_RATE_USAGE
                                          - V50_PAY_FREE_UNIT_DURATION
                                       WHEN     V476_ONNETINDICATOR = '1'
                                            AND LENGTH (V373_CALLEDPARTYNUMBER) =
                                                   13
                                            AND SUBSTR (V373_CALLEDPARTYNUMBER,
                                                        4,
                                                        2) = '13'
                                       THEN
                                            V35_RATE_USAGE
                                          - V50_PAY_FREE_UNIT_DURATION
                                       WHEN     V476_ONNETINDICATOR = '1'
                                            AND LENGTH (V373_CALLEDPARTYNUMBER) =
                                                   11
                                            AND SUBSTR (V373_CALLEDPARTYNUMBER,
                                                        2,
                                                        2) = '13'
                                       THEN
                                            V35_RATE_USAGE
                                          - V50_PAY_FREE_UNIT_DURATION
                                       WHEN     V476_ONNETINDICATOR = '1'
                                            AND LENGTH (V373_CALLEDPARTYNUMBER) =
                                                   10
                                            AND SUBSTR (V373_CALLEDPARTYNUMBER,
                                                        1,
                                                        2) = '13'
                                       THEN
                                            V35_RATE_USAGE
                                          - V50_PAY_FREE_UNIT_DURATION
                                    END)
                               / 60,
                               0),
                            2)
                            GP_OFFNET_MIN,
                         ROUND (
                            NVL (
                                 SUM (
                                    CASE
                                       WHEN V476_ONNETINDICATOR = '1'
                                       THEN
                                            V35_RATE_USAGE
                                          - V50_PAY_FREE_UNIT_DURATION
                                    END)
                               / 60,
                               0),
                            2)
                            OFFNET_MIN,
                         ROUND (NVL (SUM (V50_PAY_FREE_UNIT_DURATION) / 60, 0),
                                2)
                            FREE_MINUTES,
                         ROUND (
                            NVL (
                               (  (SUM (V35_RATE_USAGE)
                                - SUM (V50_PAY_FREE_UNIT_DURATION)) / 60),
                               0),
                            2)
                            PAID_MIN
                    FROM DWH_USER.L3_VOICE P, DATE_DIM Q, PRODUCT_DIM R
                   WHERE     (V387_CHARGINGTIME_KEY BETWEEN (SELECT DATE_KEY
                                                               FROM DATE_DIM
                                                              WHERE DATE_VALUE =
                                                                       TRUNC (
                                                                          TO_DATE (
                                                                              '01/04/2020',
                                                                             'DD/MM/RRRR')))
                                                        AND (SELECT DATE_KEY
                                                               FROM DATE_DIM
                                                              WHERE DATE_VALUE =
                                                                       TRUNC (
                                                                          TO_DATE (
                                                                             '31/10/2020',
                                                                             'DD/MM/RRRR'))))
                         AND V378_SERVICEFLOW = '1'
                         AND P.V387_CHARGINGTIME_KEY = Q.DATE_KEY
                         AND V397_MAINOFFERINGID = PRODUCT_ID
                GROUP BY DATE_KEY,DATE_VALUE, PRODUCT_ID, PRODUCT_NAME
                ORDER BY DATE_VALUE)) A,
       BASE_TARIFF_DIM B
 WHERE A.PRODUCT_ID = B.PRODUCT_ID;
             
             
             
      COMMIT;
END;
/

