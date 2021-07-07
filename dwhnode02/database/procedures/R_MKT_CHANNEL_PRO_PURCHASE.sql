--
-- R_MKT_CHANNEL_PRO_PURCHASE  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.R_MKT_CHANNEL_PRO_PURCHASE IS
    VDATE_KEY       NUMBER;
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD');



    --EXECUTE IMMEDIATE  'TRUNCATE TABLE PKPI DROP STORAGE';
    --EXECUTE IMMEDIATE 'ALTER TABLE PKPI TRUNCATE PARTITION PKPI_||VDATE_KEY DROP STORAGE';
    
DELETE MKT_CHANNEL_PRO_PURCHASE WHERE DATE_KEY=VDATE_KEY;
COMMIT;
    
INSERT INTO MKT_CHANNEL_PRO_PURCHASE

select MSISDN, PRODUCT_NAME,WITHOUT_RECHARGE_AVAIL_SERVICE,RECHARGE_COUNT_AVAIL_SERVICE,OFFERING_NAME,
       PRODUCT_PURCHASE_PRICE,COUNT_AVAIL_SERVICE,VDATE_KEY from product_dim,
(select P.MSISDN,P.R373_MAINOFFERINGID,WITHOUT_RECHARGE_AVAIL_SERVICE,RECHARGE_COUNT_AVAIL_SERVICE,OFFERING_NAME,
       PRODUCT_PURCHASE_PRICE,COUNT_AVAIL_SERVICE

 from
((SELECT /*+PARALLEL(P,10)*/  R375_CHARGINGPARTYNUMBER MSISDN,R373_MAINOFFERINGID
FROM 
  L3_RECURRING P ,OFFER_CHNL_DIM Q

WHERE R377_CYCLEBEGINTIME_KEY = (SELECT TO_CHAR(DATE_KEY) FROM DATE_DIM WHERE DATE_VALUE = TO_DATE(SYSDATE-1,'DD/MM/RRRR'))
 AND P.R385_OFFERINGID=Q.OFFERING_ID

GROUP BY R375_CHARGINGPARTYNUMBER,R373_MAINOFFERINGID
)

)P

LEFT OUTER JOIN

(SELECT A.MSISDN,A.R373_MAINOFFERINGID,COALESCE (ALL_COUNT_AVAIL_SERVICE, 0)- COALESCE (RECHARGE_COUNT_AVAIL_SERVICE, 0) WITHOUT_RECHARGE_AVAIL_SERVICE,
       COALESCE (RECHARGE_COUNT_AVAIL_SERVICE, 0) RECHARGE_COUNT_AVAIL_SERVICE

 FROM
(SELECT /*+PARALLEL(P,10)*/  R375_CHARGINGPARTYNUMBER MSISDN, R373_MAINOFFERINGID,
                             COUNT(*) ALL_COUNT_AVAIL_SERVICE
FROM 
 L3_RECURRING P ,OFFER_CHNL_DIM Q

WHERE R377_CYCLEBEGINTIME_KEY = (SELECT TO_CHAR(DATE_KEY) FROM DATE_DIM WHERE DATE_VALUE = TO_DATE(SYSDATE-1,'DD/MM/RRRR'))
 AND P.R385_OFFERINGID=Q.OFFERING_ID

GROUP BY R373_MAINOFFERINGID, R375_CHARGINGPARTYNUMBER
)A

LEFT OUTER JOIN
 
(SELECT /*+PARALLEL(Q,10)*/ RE6_PRI_IDENTITY MSISDN, RE489_MAINOFFERINGID,
                             COUNT(*) RECHARGE_COUNT_AVAIL_SERVICE
FROM 
 L3_RECHARGE Q
WHERE RE30_ENTRY_DATE_KEY =(SELECT TO_CHAR(DATE_KEY) FROM DATE_DIM WHERE DATE_VALUE = TO_DATE(SYSDATE-1,'DD/MM/RRRR'))

AND RE3_RECHARGE_AMT IN( SELECT RCG_AMOUNT FROM RCG_AMNT_DIM)
GROUP BY RE489_MAINOFFERINGID, RE6_PRI_IDENTITY
)B ON A.R373_MAINOFFERINGID=B.RE489_MAINOFFERINGID AND A.MSISDN=B.MSISDN
)Q ON P.MSISDN=Q.MSISDN AND P.R373_MAINOFFERINGID=Q.R373_MAINOFFERINGID

LEFT OUTER JOIN

(SELECT MSISDN,R373_MAINOFFERINGID,OFFERING_NAME,PRODUCT_PURCHASE_PRICE , COUNT_AVAIL_SERVICE 
FROM  OFFER_CHNL_DIM,
(SELECT /*+PARALLEL(P,10)*/ R373_MAINOFFERINGID, R375_CHARGINGPARTYNUMBER MSISDN, R385_OFFERINGID,SUM (R41_DEBIT_AMOUNT) PRODUCT_PURCHASE_PRICE ,
                             COUNT(*) COUNT_AVAIL_SERVICE
FROM 
  L3_RECURRING 

WHERE R377_CYCLEBEGINTIME_KEY = (SELECT TO_CHAR(DATE_KEY) FROM DATE_DIM WHERE DATE_VALUE = TO_DATE(SYSDATE-1,'DD/MM/RRRR'))

GROUP BY R373_MAINOFFERINGID, R375_CHARGINGPARTYNUMBER, R385_OFFERINGID
)
WHERE R385_OFFERINGID=OFFERING_ID
GROUP BY MSISDN,R373_MAINOFFERINGID,OFFERING_NAME,PRODUCT_PURCHASE_PRICE , COUNT_AVAIL_SERVICE 
)R ON P.MSISDN=R.MSISDN AND P.R373_MAINOFFERINGID=R.R373_MAINOFFERINGID
)
WHERE  PRODUCT_ID=R373_MAINOFFERINGID 
;
    COMMIT;
END;
/

