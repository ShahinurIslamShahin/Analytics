--
-- R_BIN37_1  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.R_BIN37_1 IS
    VDATE_KEY       NUMBER;
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD');



    --EXECUTE IMMEDIATE  'TRUNCATE TABLE PKPI DROP STORAGE';
    --EXECUTE IMMEDIATE 'ALTER TABLE PKPI TRUNCATE PARTITION PKPI_||VDATE_KEY DROP STORAGE';
    
DELETE BIN37_1 WHERE DATE_KEY=VDATE_KEY;
COMMIT;
    
INSERT INTO BIN37_1


SELECT MSISDN, PRODUCT_NAME,PAY_TYPE_NAME,MO_DURATION,MT_DURATION,TOTAL_DATA_VOLUME,SMS_COUNT ,REVENUE,VDATE_KEY
FROM PRODUCT_DIM,PAYTYPE_dim,  
(SELECT A.V372_CALLINGPARTYNUMBER MSISDN, A.V397_MAINOFFERINGID, A.V400_PAYTYPE ,MO_DURATION/60 MO_DURATION,MT_DURATION/60 MT_DURATION ,TOTAL_DATA_VOLUME/1048576 TOTAL_DATA_VOLUME,SMS_COUNT,COALESCE(VOICE_REVENUE,0) + COALESCE(DATAPAYG_REVENUE,0)+COALESCE(SMS_REVENUE,0) + COALESCE(CONTENT_REVENUE,0) REVENUE FROM


(SELECT /*+PARALLEL(P,8)*/ V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID,V400_PAYTYPE FROM L3_VOICE P WHERE V402_CALLTYPE !=3 AND  V378_SERVICEFLOW=1 AND V387_CHARGINGTIME_KEY in (SELECT A.DATE_KEY FROM DATE_DIM A WHERE A.DATE_VALUE >= TO_DATE(SYSDATE - 7,'DD/MM/RRRR')) 
UNION
SELECT /*+PARALLEL(Q,8)*/ V373_CALLEDPARTYNUMBER,V397_MAINOFFERINGID,V400_PAYTYPE FROM L3_VOICE Q WHERE V402_CALLTYPE !=3 AND  V378_SERVICEFLOW=2 AND V387_CHARGINGTIME_KEY in (SELECT A.DATE_KEY FROM DATE_DIM A WHERE A.DATE_VALUE >= TO_DATE(SYSDATE - 7,'DD/MM/RRRR')) 
UNION
SELECT /*+PARALLEL(R,8)*/ G372_CALLINGPARTYNUMBER,G401_MAINOFFERINGID,  G403_PAYTYPE FROM L3_DATA R WHERE G383_CHARGINGTIME_KEY in (SELECT A.DATE_KEY FROM DATE_DIM A WHERE A.DATE_VALUE >= TO_DATE(SYSDATE - 7,'DD/MM/RRRR'))
UNION
SELECT /*+PARALLEL(S,8)*/ S372_CALLINGPARTYNUMBER, S395_MAINOFFERINGID, S398_PAYTYPE FROM L3_SMS S WHERE S378_SERVICEFLOW=1 and S400_SMSTYPE !=3 AND S387_CHARGINGTIME_KEY in (SELECT A.DATE_KEY FROM DATE_DIM A WHERE A.DATE_VALUE >= TO_DATE(SYSDATE - 7,'DD/MM/RRRR'))
UNION
SELECT /*+PARALLEL(T,8)*/  CO372_CALLINGPARTYNUMBER,  CO396_MAINOFFERINGID,CO410_PAYTYPE FROM L3_CONTENT T WHERE CO402_STARTTIMEOFBILLCYL_KEY in (SELECT A.DATE_KEY FROM DATE_DIM A WHERE A.DATE_VALUE >= TO_DATE(SYSDATE - 7,'DD/MM/RRRR')))


A



LEFT OUTER JOIN



(
SELECT /*+PARALLEL(U,8)*/ V372_CALLINGPARTYNUMBER, V397_MAINOFFERINGID ,V400_PAYTYPE, SUM(V35_RATE_USAGE)  MO_DURATION,sum(V41_DEBIT_AMOUNT) VOICE_REVENUE
FROM L3_VOICE U WHERE V402_CALLTYPE !=3 AND  V378_SERVICEFLOW=1 AND  V387_CHARGINGTIME_KEY in (SELECT A.DATE_KEY FROM DATE_DIM A WHERE A.DATE_VALUE >= TO_DATE(SYSDATE - 7,'DD/MM/RRRR')) 
GROUP BY V372_CALLINGPARTYNUMBER, V397_MAINOFFERINGID ,V400_PAYTYPE
)B ON A.V372_CALLINGPARTYNUMBER=B.V372_CALLINGPARTYNUMBER and  A.V397_MAINOFFERINGID=B.V397_MAINOFFERINGID and A.V400_PAYTYPE=B.V400_PAYTYPE




LEFT OUTER JOIN



(
SELECT /*+PARALLEL(V,8)*/ V373_CALLEDPARTYNUMBER,V397_MAINOFFERINGID,V400_PAYTYPE , SUM(V35_RATE_USAGE) MT_DURATION
FROM L3_VOICE V WHERE V402_CALLTYPE !=3 AND  V378_SERVICEFLOW=2 AND  V387_CHARGINGTIME_KEY in (SELECT A.DATE_KEY FROM DATE_DIM A WHERE A.DATE_VALUE >= TO_DATE(SYSDATE - 7,'DD/MM/RRRR')) 
GROUP BY V373_CALLEDPARTYNUMBER,V397_MAINOFFERINGID,V400_PAYTYPE
)C ON A.V372_CALLINGPARTYNUMBER=C.V373_CALLEDPARTYNUMBER and  A.V397_MAINOFFERINGID=C.V397_MAINOFFERINGID and A.V400_PAYTYPE=C.V400_PAYTYPE



LEFT OUTER JOIN




(SELECT /*+PARALLEL(W,8)*/ G372_CALLINGPARTYNUMBER,G401_MAINOFFERINGID,  G403_PAYTYPE ,SUM(G384_TOTALFLUX) TOTAL_DATA_VOLUME, sum(G41_DEBIT_AMOUNT) DATAPAYG_REVENUE
FROM L3_DATA W WHERE G383_CHARGINGTIME_KEY in (SELECT A.DATE_KEY FROM DATE_DIM A WHERE A.DATE_VALUE >= TO_DATE(SYSDATE - 7,'DD/MM/RRRR')) 
GROUP BY G372_CALLINGPARTYNUMBER,G401_MAINOFFERINGID,  G403_PAYTYPE
)D ON A.V372_CALLINGPARTYNUMBER=D.G372_CALLINGPARTYNUMBER and  A.V397_MAINOFFERINGID=D.G401_MAINOFFERINGID and A.V400_PAYTYPE=D.G403_PAYTYPE




LEFT OUTER JOIN




(SELECT /*+PARALLEL(X,8)*/  S372_CALLINGPARTYNUMBER, S395_MAINOFFERINGID, S398_PAYTYPE  ,COUNT( S22_PRI_IDENTITY) SMS_COUNT,sum(S41_DEBIT_AMOUNT) SMS_REVENUE
FROM L3_SMS X WHERE S400_SMSTYPE !=3 AND  S387_CHARGINGTIME_KEY in (SELECT A.DATE_KEY FROM DATE_DIM A WHERE A.DATE_VALUE >= TO_DATE(SYSDATE - 7,'DD/MM/RRRR')) 
GROUP BY S372_CALLINGPARTYNUMBER, S395_MAINOFFERINGID, S398_PAYTYPE
)E ON A.V372_CALLINGPARTYNUMBER=E.S372_CALLINGPARTYNUMBER and  A.V397_MAINOFFERINGID=E.S395_MAINOFFERINGID and A.V400_PAYTYPE=E.S398_PAYTYPE

left outer join

(SELECT /*+PARALLEL(Y,8)*/ CO372_CALLINGPARTYNUMBER,  CO396_MAINOFFERINGID,CO410_PAYTYPE  ,sum( CO41_DEBIT_AMOUNT) CONTENT_REVENUE
FROM L3_content Y WHERE  CO402_STARTTIMEOFBILLCYL_KEY in (SELECT A.DATE_KEY FROM DATE_DIM A WHERE A.DATE_VALUE >= TO_DATE(SYSDATE - 7,'DD/MM/RRRR')) 
GROUP BY CO372_CALLINGPARTYNUMBER,  CO396_MAINOFFERINGID,CO410_PAYTYPE
)F ON A.V372_CALLINGPARTYNUMBER=F.CO372_CALLINGPARTYNUMBER and  A.V397_MAINOFFERINGID=F.CO396_MAINOFFERINGID and A.V400_PAYTYPE=F.CO410_PAYTYPE




)



WHERE PRODUCT_ID=V397_MAINOFFERINGID and PAY_TYPE_ID=V400_PAYTYPE ;
    COMMIT;
END;
/

