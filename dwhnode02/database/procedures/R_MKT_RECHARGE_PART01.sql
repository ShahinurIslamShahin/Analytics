--
-- R_MKT_RECHARGE_PART01  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.R_MKT_RECHARGE_PART01 IS
    VDATE_KEY       NUMBER;
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD');



    --EXECUTE IMMEDIATE  'TRUNCATE TABLE PKPI DROP STORAGE';
    --EXECUTE IMMEDIATE 'ALTER TABLE PKPI TRUNCATE PARTITION PKPI_||VDATE_KEY DROP STORAGE';
    
DELETE MKT_RECHARGE_PART01 WHERE DATE_KEY=VDATE_KEY;
COMMIT;
    
INSERT INTO MKT_RECHARGE_PART01

SELECT DEALER_NAME,ER10_MSISDN,RECHARGE_AMOUNT,VDATE_KEY
FROM
((SELECT /*+PARALLEL(P,10)*/ INITCAP(REPLACE(ER06_DEALER_NAME,' ','') ) DEALER_NAME ,ER10_MSISDN,SUM(ER09_PRICE) RECHARGE_AMOUNT
FROM L3_EVCREC P
WHERE ER12_RECHARGE_DATE_KEY= (SELECT TO_CHAR(DATE_KEY) FROM DATE_DIM WHERE DATE_VALUE = TO_DATE(SYSDATE-2,'DD/MM/RRRR'))
 
AND  ER06_DEALER_NAME IN ('B Kash' ,'bKash') 
GROUP BY INITCAP(REPLACE(ER06_DEALER_NAME,' ','') ),ER10_MSISDN

UNION

SELECT /*+PARALLEL(Q,10)*/ REPLACE(ER06_DEALER_NAME,'Dutch Bangla Bank Ltd.','Rocket'),ER10_MSISDN, SUM(ER09_PRICE) RECHARGE_AMOUNT 
FROM L3_EVCREC Q
WHERE ER12_RECHARGE_DATE_KEY =(SELECT TO_CHAR(DATE_KEY) FROM DATE_DIM WHERE DATE_VALUE = TO_DATE(SYSDATE-2,'DD/MM/RRRR'))

AND ER06_DEALER_NAME='Dutch Bangla Bank Ltd.'
GROUP BY REPLACE(ER06_DEALER_NAME,'Dutch Bangla Bank Ltd.','Rocket'),ER10_MSISDN
));
    COMMIT;
END;
/

