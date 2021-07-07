--
-- R_BIN37_8  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.R_BIN37_8 IS
    VDATE_KEY       NUMBER;
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD');

    
DELETE BIN37_8 WHERE DATE_KEY=VDATE_KEY;
COMMIT;
    
INSERT INTO BIN37_8


select PRODUCT_NAME,PAY_TYPE_NAME,MSISDN_COUNT,V372_CALLINGPARTYNUMBER ,VDATE_KEY from product_dim, paytype_dim,


(SELECT P.V397_MAINOFFERINGID,P.MSISDN_COUNT,Q.V372_CALLINGPARTYNUMBER,Q.V400_PAYTYPE

FROM     

(SELECT /*+PARALLEL(Z,8)*/ V397_MAINOFFERINGID,COUNT(V372_CALLINGPARTYNUMBER) MSISDN_COUNT FROM 
((SELECT /*+PARALLEL(P,8)*/ V397_MAINOFFERINGID,V372_CALLINGPARTYNUMBER
 FROM SUBSCRIPTION_DIM P
 INNER JOIN L3_VOICE ON SERVICE_NUMBER = V372_CALLINGPARTYNUMBER
 WHERE  V402_CALLTYPE !=3 AND    START_DATE =(SELECT DATE_VALUE  FROM DATE_DIM WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
 GROUP BY V397_MAINOFFERINGID,V372_CALLINGPARTYNUMBER )
 
 UNION
 
 (
 SELECT /*+PARALLEL(Q,8)*/ G401_MAINOFFERINGID,G372_CALLINGPARTYNUMBER
 FROM SUBSCRIPTION_DIM Q
 INNER JOIN L3_DATA ON SERVICE_NUMBER = G372_CALLINGPARTYNUMBER
 WHERE     START_DATE =(SELECT DATE_VALUE  FROM DATE_DIM WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
 GROUP BY  G401_MAINOFFERINGID,G372_CALLINGPARTYNUMBER)
 
 UNION
 
 (SELECT /*+PARALLEL(R,8)*/ V397_MAINOFFERINGID,V373_CALLEDPARTYNUMBER
 FROM SUBSCRIPTION_DIM R
 INNER JOIN L3_VOICE ON SERVICE_NUMBER = V373_CALLEDPARTYNUMBER
 WHERE  V402_CALLTYPE !=3 AND    START_DATE =(SELECT DATE_VALUE  FROM DATE_DIM WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
 GROUP BY V397_MAINOFFERINGID,V373_CALLEDPARTYNUMBER )
 
 UNION
 
 (SELECT /*+PARALLEL(S,8)*/ CO396_MAINOFFERINGID,CO372_CALLINGPARTYNUMBER
 FROM SUBSCRIPTION_DIM S
 INNER JOIN L3_CONTENT ON SERVICE_NUMBER = CO372_CALLINGPARTYNUMBER
 WHERE      START_DATE =(SELECT DATE_VALUE  FROM DATE_DIM WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
 GROUP BY CO396_MAINOFFERINGID,CO372_CALLINGPARTYNUMBER )
 
 UNION
 
 (SELECT /*+PARALLEL(T,8)*/ RE489_MAINOFFERINGID,RE6_PRI_IDENTITY
 FROM SUBSCRIPTION_DIM T
 INNER JOIN L3_RECHARGE ON SERVICE_NUMBER = RE6_PRI_IDENTITY
 WHERE      START_DATE =(SELECT DATE_VALUE  FROM DATE_DIM WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
 GROUP BY RE489_MAINOFFERINGID,RE6_PRI_IDENTITY )
 
 UNION
 
 (SELECT /*+PARALLEL(U,8)*/ S395_MAINOFFERINGID,S22_PRI_IDENTITY
 FROM SUBSCRIPTION_DIM U
 INNER JOIN L3_SMS ON SERVICE_NUMBER = S22_PRI_IDENTITY
 WHERE      START_DATE =(SELECT DATE_VALUE  FROM DATE_DIM WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
 GROUP BY S395_MAINOFFERINGID,S22_PRI_IDENTITY )
 
 
  UNION
 
 (SELECT /*+PARALLEL(V,8)*/ R373_MAINOFFERINGID, R375_CHARGINGPARTYNUMBER
 FROM SUBSCRIPTION_DIM V
 INNER JOIN L3_RECURRING ON SERVICE_NUMBER = R375_CHARGINGPARTYNUMBER
 WHERE      START_DATE =(SELECT DATE_VALUE  FROM DATE_DIM WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
 GROUP BY R373_MAINOFFERINGID,R375_CHARGINGPARTYNUMBER )
 
 UNION
 
  (SELECT /*+PARALLEL(W,8)*/ T458_MAINOFFERINGID,T6_PRI_IDENTITY
 FROM SUBSCRIPTION_DIM W
 INNER JOIN L3_TRANSFER ON SERVICE_NUMBER = T6_PRI_IDENTITY
 WHERE      START_DATE =(SELECT DATE_VALUE  FROM DATE_DIM WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
 GROUP BY T458_MAINOFFERINGID,T6_PRI_IDENTITY )
 
 UNION
 
 
   (SELECT /*+PARALLEL(X,8)*/  M376_MAINOFFERINGID, M22_PRI_IDENTITY
 FROM SUBSCRIPTION_DIM X
 INNER JOIN L3_MANAGEMENT ON SERVICE_NUMBER = M22_PRI_IDENTITY
 WHERE      START_DATE =(SELECT DATE_VALUE  FROM DATE_DIM WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
 GROUP BY M376_MAINOFFERINGID, M22_PRI_IDENTITY )
 
 UNION
 
    (SELECT /*+PARALLEL(Y,8)*/ A462_MAINOFFERINGID, A5_PRI_IDENTITY
 FROM SUBSCRIPTION_DIM Y
 INNER JOIN L3_ADJUSTMENT ON SERVICE_NUMBER = A5_PRI_IDENTITY
 WHERE      START_DATE =(SELECT DATE_VALUE  FROM DATE_DIM WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
 GROUP BY A462_MAINOFFERINGID, A5_PRI_IDENTITY )
 
 
 
 )Z
 
 GROUP BY V397_MAINOFFERINGID
 ) P
 
 
 
 
 
 
 
 
 LEFT OUTER JOIN 
 
 
 
 

(SELECT V397_MAINOFFERINGID,V400_PAYTYPE,V372_CALLINGPARTYNUMBER
 FROM
 ((SELECT /*+PARALLEL(P1,8)*/ V397_MAINOFFERINGID,V400_PAYTYPE,V372_CALLINGPARTYNUMBER
 FROM SUBSCRIPTION_DIM P1
 INNER JOIN L3_VOICE ON SERVICE_NUMBER = V372_CALLINGPARTYNUMBER
 WHERE  V402_CALLTYPE !=3 AND    START_DATE =(SELECT DATE_VALUE  FROM DATE_DIM WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
 GROUP BY V397_MAINOFFERINGID,V400_PAYTYPE,V372_CALLINGPARTYNUMBER )
 
 UNION
 
 (
 SELECT /*+PARALLEL(Q1,8)*/ G401_MAINOFFERINGID,G403_PAYTYPE,G372_CALLINGPARTYNUMBER
 FROM SUBSCRIPTION_DIM Q1
 INNER JOIN L3_DATA ON SERVICE_NUMBER = G372_CALLINGPARTYNUMBER
 WHERE     START_DATE =(SELECT DATE_VALUE  FROM DATE_DIM WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
 GROUP BY  G401_MAINOFFERINGID,G403_PAYTYPE,G372_CALLINGPARTYNUMBER)
 
 UNION
 
 (SELECT /*+PARALLEL(R1,8)*/ V397_MAINOFFERINGID,V400_PAYTYPE,V373_CALLEDPARTYNUMBER
 FROM SUBSCRIPTION_DIM R1
 INNER JOIN L3_VOICE ON SERVICE_NUMBER = V373_CALLEDPARTYNUMBER
 WHERE  V402_CALLTYPE !=3 AND    START_DATE =(SELECT DATE_VALUE  FROM DATE_DIM WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
 GROUP BY V397_MAINOFFERINGID,V400_PAYTYPE,V373_CALLEDPARTYNUMBER )
 
 UNION
 
 (SELECT /*+PARALLEL(S1,8)*/ CO396_MAINOFFERINGID,CO410_PAYTYPE,CO372_CALLINGPARTYNUMBER
 FROM SUBSCRIPTION_DIM S1
 INNER JOIN L3_CONTENT ON SERVICE_NUMBER = CO372_CALLINGPARTYNUMBER
 WHERE      START_DATE =(SELECT DATE_VALUE  FROM DATE_DIM WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
 GROUP BY CO396_MAINOFFERINGID,CO410_PAYTYPE,CO372_CALLINGPARTYNUMBER )
 
 UNION
 
 (SELECT /*+PARALLEL(T1,8)*/  RE489_MAINOFFERINGID,RE490_PAYTYPE,RE6_PRI_IDENTITY
 FROM SUBSCRIPTION_DIM T1
 INNER JOIN L3_RECHARGE ON SERVICE_NUMBER = RE6_PRI_IDENTITY
 WHERE      START_DATE =(SELECT DATE_VALUE  FROM DATE_DIM WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
 GROUP BY RE489_MAINOFFERINGID,RE490_PAYTYPE,RE6_PRI_IDENTITY )
 
 UNION
 
 (SELECT /*+PARALLEL(V1,8)*/ S395_MAINOFFERINGID,S398_PAYTYPE,S22_PRI_IDENTITY
 FROM SUBSCRIPTION_DIM V1
 INNER JOIN L3_SMS ON SERVICE_NUMBER = S22_PRI_IDENTITY
 WHERE      START_DATE =(SELECT DATE_VALUE  FROM DATE_DIM WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
 GROUP BY S395_MAINOFFERINGID,S398_PAYTYPE,S22_PRI_IDENTITY )
 
 
  UNION
 
 (SELECT /*+PARALLEL(U1,8)*/ R373_MAINOFFERINGID,R374_PAYTYPE, R375_CHARGINGPARTYNUMBER
 FROM SUBSCRIPTION_DIM U1
 INNER JOIN L3_RECURRING ON SERVICE_NUMBER = R375_CHARGINGPARTYNUMBER
 WHERE      START_DATE =(SELECT DATE_VALUE  FROM DATE_DIM WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
 GROUP BY R373_MAINOFFERINGID,R374_PAYTYPE,R375_CHARGINGPARTYNUMBER )
 
 UNION
 
  (SELECT /*+PARALLEL(W1,8)*/ T458_MAINOFFERINGID,T459_PAYTYPE,T6_PRI_IDENTITY
 FROM SUBSCRIPTION_DIM W1
 INNER JOIN L3_TRANSFER ON SERVICE_NUMBER = T6_PRI_IDENTITY
 WHERE      START_DATE =(SELECT DATE_VALUE  FROM DATE_DIM WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
 GROUP BY T458_MAINOFFERINGID,T459_PAYTYPE,T6_PRI_IDENTITY )
 
 UNION
 
 
   (SELECT /*+PARALLEL(X1,8)*/  M376_MAINOFFERINGID,M377_PAYTYPE, M22_PRI_IDENTITY
 FROM SUBSCRIPTION_DIM X1
 INNER JOIN L3_MANAGEMENT ON SERVICE_NUMBER = M22_PRI_IDENTITY
 WHERE      START_DATE =(SELECT DATE_VALUE  FROM DATE_DIM WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
 GROUP BY M376_MAINOFFERINGID,M377_PAYTYPE, M22_PRI_IDENTITY )
 
 UNION
 
    (SELECT /*+PARALLEL(Z1,8)*/ A462_MAINOFFERINGID,A463_PAYTYPE, A5_PRI_IDENTITY
 FROM SUBSCRIPTION_DIM Z1
 INNER JOIN L3_ADJUSTMENT ON SERVICE_NUMBER = A5_PRI_IDENTITY
 WHERE      START_DATE =(SELECT DATE_VALUE  FROM DATE_DIM WHERE DATE_VALUE = TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
 GROUP BY A462_MAINOFFERINGID,A463_PAYTYPE, A5_PRI_IDENTITY )
 )
 
 
 
 )  Q ON P.V397_MAINOFFERINGID=Q.V397_MAINOFFERINGID
 

 )
 
 
where PRODUCT_ID= V397_MAINOFFERINGID and PAY_TYPE_ID=V400_PAYTYPE;
    COMMIT;
END;
/

