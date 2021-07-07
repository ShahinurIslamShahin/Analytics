--
-- R_BIN16  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.R_BIN16 IS
    VDATE_KEY       NUMBER;
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD');



    --EXECUTE IMMEDIATE  'TRUNCATE TABLE PKPI DROP STORAGE';
    --EXECUTE IMMEDIATE 'ALTER TABLE PKPI TRUNCATE PARTITION PKPI_||VDATE_KEY DROP STORAGE';
    
DELETE BIN16 WHERE DATE_KEY=VDATE_KEY;
COMMIT;
    
INSERT INTO BIN16

select PRODUCT_NAME, (VOLUME3G/1073741824) VOLUME3G, (VOLUME2G/1073741824) VOLUME2G , (VOLUME4G/1073741824) VOLUME4G, MO_DURATION, MT_DURATION, SMS_COUNT,VDATE_KEY
from PRODUCT_DIM,
(select X, VOLUME3G, VOLUME2G, VOLUME4G, MO_DURATION, MT_DURATION, SMS_COUNT
from 

(

SELECT A.V397_MAINOFFERINGID X,
          MO_Duration,
          MT_Duration,
          VOLUME3G,
          VOLUME2G,
          VOLUME4G,
          SMS_Count
     FROM (SELECT V397_MAINOFFERINGID
             FROM L3_Voice
            WHERE     V387_CHARGINGTIME_KEY =
                         (SELECT A.DATE_KEY
                            FROM DATE_DIM A
                           WHERE A.DATE_VALUE =
                                    TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                  AND V402_CALLTYPE != 3
           UNION
           SELECT S395_MAINOFFERINGID
             FROM L3_SMS
            WHERE     S387_CHARGINGTIME_KEY =
                         (SELECT A.DATE_KEY
                            FROM DATE_DIM A
                           WHERE A.DATE_VALUE =
                                    TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                  AND S400_SMSTYPE != 3
           UNION
           SELECT G401_MAINOFFERINGID
             FROM L3_data
            WHERE G383_CHARGINGTIME_KEY =
                     (SELECT A.DATE_KEY
                        FROM DATE_DIM A
                       WHERE A.DATE_VALUE =
                                TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))) A
          LEFT OUTER JOIN
          (  SELECT V397_MAINOFFERINGID, SUM (V35_RATE_USAGE) MO_Duration
               FROM L3_VOICE
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
          (  SELECT V397_MAINOFFERINGID, SUM (V35_RATE_USAGE) MT_Duration
               FROM L3_VOICE
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
          (  SELECT G401_MAINOFFERINGID, SUM (G384_TOTALFLUX) VOLUME3G
               FROM L3_DATA
              WHERE     G429_RATTYPE = 1
                    AND G383_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY G401_MAINOFFERINGID) D
             ON A.V397_MAINOFFERINGID = D.G401_MAINOFFERINGID
          LEFT OUTER JOIN
          (  SELECT G401_MAINOFFERINGID, SUM (G384_TOTALFLUX) VOLUME2G
               FROM L3_DATA
              WHERE     G429_RATTYPE = 2
                    AND G383_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY G401_MAINOFFERINGID) E
             ON A.V397_MAINOFFERINGID = E.G401_MAINOFFERINGID
          LEFT OUTER JOIN
          (  SELECT G401_MAINOFFERINGID, SUM (G384_TOTALFLUX) VOLUME4G
               FROM L3_DATA
              WHERE     G429_RATTYPE = 6
                    AND G383_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY G401_MAINOFFERINGID) F
             ON A.V397_MAINOFFERINGID = F.G401_MAINOFFERINGID
          LEFT OUTER JOIN
          (  SELECT S395_MAINOFFERINGID, COUNT (S22_PRI_IDENTITY) SMS_Count
               FROM L3_SMS
              WHERE     S387_CHARGINGTIME_KEY =
                           (SELECT DATE_KEY
                              FROM DATE_DIM
                             WHERE DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                    AND S400_SMSTYPE != 3
           GROUP BY S395_MAINOFFERINGID) G
             ON A.V397_MAINOFFERINGID = G.S395_MAINOFFERINGID


)

)
where  PRODUCT_ID=X;
    COMMIT;
END;
/

