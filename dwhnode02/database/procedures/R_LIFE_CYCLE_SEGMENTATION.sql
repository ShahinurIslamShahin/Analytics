--
-- R_LIFE_CYCLE_SEGMENTATION  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.R_LIFE_CYCLE_SEGMENTATION IS
    VDATE_KEY       NUMBER;
BEGIN

EXECUTE IMMEDIATE  'TRUNCATE TABLE LIFE_CYCLE_SEGMENTATION DROP STORAGE';
COMMIT;
    
INSERT INTO LIFE_CYCLE_SEGMENTATION


(SELECT R375_CHARGINGPARTYNUMBER MSISDN,
          L.PRODUCT_NAME,
          K.ACN_COST,
          LIFETIME LIFETIME_DAYS,
          NO_PURCHASE,
          TOTAL_PURCHASE,
          ROUND (TOTAL_PURCHASE / LIFETIME, 2) CLV,
           ROUND ((TOTAL_PURCHASE / LIFETIME)*225, 2) ACQUISITION_FACTOR
     FROM (SELECT A.R375_CHARGINGPARTYNUMBER,
                  C.SUBCOSID,
                  C.LIFETIME,
                  B.NO_PURCHASE,
                  B.TOTAL_PURCHASE
             FROM (SELECT /*+PARALLEL(Q,16)*/
                          UNIQUE R375_CHARGINGPARTYNUMBER
                     FROM L3_RECURRING Q) A
                  LEFT OUTER JOIN
                  (  SELECT /*+parallel(p,16)*/
                           R375_CHARGINGPARTYNUMBER,
                            COUNT (R385_OFFERINGID) NO_PURCHASE,
                            ROUND (SUM (R41_DEBIT_AMOUNT), 2) TOTAL_PURCHASE
                       FROM L3_RECURRING P
                   GROUP BY R375_CHARGINGPARTYNUMBER) B
                     ON A.R375_CHARGINGPARTYNUMBER =
                           B.R375_CHARGINGPARTYNUMBER
                  LEFT OUTER JOIN
                  (SELECT /*+PARALLEL(R,16)*/
                         '880' || MSISDN MSISDN,
                          SUBCOSID,
                            TO_DATE (SYSDATE, 'DD/MM/RRRR')
                          - TO_DATE (
                               TO_DATE (TIMEENTERACTIVE, 'YYYYMMDDHH24MISS'),
                               'DD/MM/RRRR')
                             LIFETIME
                     FROM L1_FUO_OCS_SUBSCRIBER_ALL@DWH05TODWH01 R
                    WHERE CURRENTSTATE = 2) C
                     ON A.R375_CHARGINGPARTYNUMBER = C.MSISDN),
          ACN_COST K,
          PRODUCT_DIM L
    WHERE SUBCOSID = K.PRODUCT_ID AND SUBCOSID = L.PRODUCT_ID)
;
             
             
             
      COMMIT;
END;
/

