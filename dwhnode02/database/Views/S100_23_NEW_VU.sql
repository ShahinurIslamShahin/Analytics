--
-- S100_23_NEW_VU  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.S100_23_NEW_VU
(V372_CALLINGPARTYNUMBER)
BEQUEATH DEFINER
AS 
select V372_CALLINGPARTYNUMBER from
(
SELECT *
  FROM (  SELECT /*+parallel(p,16)*/
                V387_CHARGINGTIME_KEY,
                 V372_CALLINGPARTYNUMBER,
                 V397_MAINOFFERINGID,
                 COUNT (V372_CALLINGPARTYNUMBER) AS CALL_COUNT,
                 COUNT (DISTINCT V373_CALLEDPARTYNUMBER) AS DIST_COUNT,
                 SUM (V35_RATE_USAGE) / 60 AS DUR,
                 SUM (V35_RATE_USAGE) / COUNT (V372_CALLINGPARTYNUMBER)
                    AS AVG_DUR,
                 COUNT (DISTINCT V381_CALLINGCELLID) AS CELL_COUNT
            FROM L3_VOICE P
           WHERE     V387_CHARGINGTIME_KEY =
                        (SELECT DATE_KEY
                           FROM DATE_DIM
                          WHERE DATE_VALUE =
                                   TO_DATE (SYSDATE - 1, 'dd/mm/rrrr'))
                 AND V378_SERVICEFLOW = '1'
        GROUP BY V387_CHARGINGTIME_KEY,
                 V372_CALLINGPARTYNUMBER,
                 V397_MAINOFFERINGID)
 WHERE     CALL_COUNT > 15
       AND CELL_COUNT <= 6
       AND DUR >= 40
       AND AVG_DUR > 180
       AND (DIST_COUNT / CALL_COUNT) >= .9
       AND V372_CALLINGPARTYNUMBER IN (SELECT UNIQUE MSISDN
                                         FROM L3_MIGRATION_BASE
                                         where date_key=(select date_key from date_dim where date_value=to_date('24/12/2020','dd/mm/rrrr'))));


