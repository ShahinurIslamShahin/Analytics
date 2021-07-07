--
-- R_MKT_VOICE_REVENUE_WITH_MSISDN  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.R_MKT_VOICE_REVENUE_WITH_MSISDN IS
    VDATE_KEY       NUMBER;
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD');



    --EXECUTE IMMEDIATE  'TRUNCATE TABLE PKPI DROP STORAGE';
    --EXECUTE IMMEDIATE 'ALTER TABLE PKPI TRUNCATE PARTITION PKPI_||VDATE_KEY DROP STORAGE';
    
DELETE MKT_VOICE_REVENUE_WITH_MSISDN WHERE DATE_KEY=VDATE_KEY;
COMMIT;
    
INSERT INTO MKT_VOICE_REVENUE_WITH_MSISDN



SELECT V372_CALLINGPARTYNUMBER,PRODUCT_NAME,COALESCE (BASE_TARIFF_REVENUE, 0) BASE_TARIFF_REVENUE,COALESCE (MIN_REVENUE, 0)MIN_REVENUE,
          COALESCE (COMBO_REVENUE, 0) COMBO_REVENUE, COALESCE (RATE_CUTTER_REVENUE, 0) RATE_CUTTER_REVENUE,  COALESCE (RATE_INCREASER_REVENUE, 0) RATE_INCREASER_REVENUE,
          COALESCE (SHORT_CODE_REVENUE, 0) SHORT_CODE_REVENUE,COALESCE (FNF_REVENUE, 0) FNF_REVENUE,COALESCE (VIDEO_REVENUE, 0)VIDEO_REVENUE,
          COALESCE (CLOSED_SIM_REVENUE, 0) CLOSED_SIM_REVENUE,COALESCE (IN_VOICE_REVENUE, 0) IN_VOICE_REVENUE,
          COALESCE (BASE_TARIFF_REVENUE, 0)+COALESCE (MIN_REVENUE, 0)+COALESCE (COMBO_REVENUE, 0)+COALESCE (RATE_CUTTER_REVENUE, 0)+COALESCE (RATE_INCREASER_REVENUE, 0)+
          COALESCE (SHORT_CODE_REVENUE, 0)+COALESCE (FNF_REVENUE, 0)+COALESCE (VIDEO_REVENUE, 0)+COALESCE (CLOSED_SIM_REVENUE, 0)+COALESCE (IN_VOICE_REVENUE, 0)+
          COALESCE (DISCOUNT_REVENUE, 0) TOTAL_VOICE_REVNUE,VDATE_KEY,COALESCE (DISCOUNT_REVENUE, 0)DISCOUNT_REVENUE
          
FROM PRODUCT_DIM M,

(SELECT A.V372_CALLINGPARTYNUMBER,A.V397_MAINOFFERINGID,BASE_TARIFF_REVENUE,MIN_REVENUE,COMBO_REVENUE,RATE_CUTTER_REVENUE,RATE_INCREASER_REVENUE,
          SHORT_CODE_REVENUE,FNF_REVENUE,VIDEO_REVENUE,CLOSED_SIM_REVENUE,IN_VOICE_REVENUE,DISCOUNT_REVENUE
FROM
(
(SELECT /*+PARALLEL(P,10)*/V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID  FROM L3_VOICE   P
WHERE V387_CHARGINGTIME_KEY  = TO_CHAR((SELECT DATE_KEY FROM DATE_DIM WHERE DATE_VALUE = TRUNC(TO_DATE(SYSDATE-1,'DD/MM/RRRR'))))
AND V378_SERVICEFLOW=1
GROUP BY V372_CALLINGPARTYNUMBER, V397_MAINOFFERINGID
)
UNION
(SELECT /*+PARALLEL(Q,10)*/R375_CHARGINGPARTYNUMBER, R373_MAINOFFERINGID  FROM L3_RECURRING   Q
WHERE R377_CYCLEBEGINTIME_KEY  = TO_CHAR((SELECT DATE_KEY FROM DATE_DIM WHERE DATE_VALUE = TRUNC(TO_DATE(SYSDATE-1,'DD/MM/RRRR'))))
GROUP BY  R375_CHARGINGPARTYNUMBER,R373_MAINOFFERINGID
) 
)A

LEFT OUTER JOIN

(SELECT /*+PARALLEL(P,10)*/V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID ,SUM(V41_DEBIT_AMOUNT) BASE_TARIFF_REVENUE FROM L3_VOICE   P
WHERE V387_CHARGINGTIME_KEY  = TO_CHAR((SELECT DATE_KEY FROM DATE_DIM WHERE DATE_VALUE = TRUNC(TO_DATE(SYSDATE-1,'DD/MM/RRRR'))))
AND V378_SERVICEFLOW=1
AND V397_MAINOFFERINGID=V436_LASTEFFECTOFFERING
AND V402_CALLTYPE !=3
GROUP BY V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID
)B ON A.V397_MAINOFFERINGID=B.V397_MAINOFFERINGID AND A.V372_CALLINGPARTYNUMBER=B.V372_CALLINGPARTYNUMBER

LEFT OUTER JOIN


(SELECT /*+PARALLEL(Q,10)*/ R375_CHARGINGPARTYNUMBER,R373_MAINOFFERINGID ,SUM(R41_DEBIT_AMOUNT) MIN_REVENUE FROM L3_RECURRING   Q
WHERE R377_CYCLEBEGINTIME_KEY  = TO_CHAR((SELECT DATE_KEY FROM DATE_DIM WHERE DATE_VALUE = TRUNC(TO_DATE(SYSDATE-1,'DD/MM/RRRR'))))
AND R385_OFFERINGID IN ( SELECT OFFERING_ID FROM OFFER_DIM WHERE OFFER_TYPE='Voice')
GROUP BY R375_CHARGINGPARTYNUMBER, R373_MAINOFFERINGID
) C ON A.V397_MAINOFFERINGID=C.R373_MAINOFFERINGID AND  A.V372_CALLINGPARTYNUMBER=C.R375_CHARGINGPARTYNUMBER

LEFT OUTER JOIN

(SELECT /*+PARALLEL(R,10)*/ R375_CHARGINGPARTYNUMBER,R373_MAINOFFERINGID ,SUM(R41_DEBIT_AMOUNT) COMBO_REVENUE FROM L3_RECURRING   R
WHERE R377_CYCLEBEGINTIME_KEY  = TO_CHAR((SELECT DATE_KEY FROM DATE_DIM WHERE DATE_VALUE = TRUNC(TO_DATE(SYSDATE-1,'DD/MM/RRRR'))))
AND R385_OFFERINGID IN ( SELECT OFFERING_ID FROM OFFER_DIM WHERE OFFER_TYPE='Combo')
GROUP BY R375_CHARGINGPARTYNUMBER, R373_MAINOFFERINGID
)D ON A.V397_MAINOFFERINGID=D.R373_MAINOFFERINGID AND  A.V372_CALLINGPARTYNUMBER=D.R375_CHARGINGPARTYNUMBER

LEFT OUTER JOIN

(SELECT /*+PARALLEL(S,10)*/V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID ,SUM(V41_DEBIT_AMOUNT) RATE_CUTTER_REVENUE FROM L3_VOICE   S
WHERE V387_CHARGINGTIME_KEY  = TO_CHAR((SELECT DATE_KEY FROM DATE_DIM WHERE DATE_VALUE = TRUNC(TO_DATE(SYSDATE-1,'DD/MM/RRRR'))))
AND V378_SERVICEFLOW=1
AND V436_LASTEFFECTOFFERING IN ( SELECT OFFERING_ID FROM OFFER_DIM WHERE OFFER_TYPE='Tariff')
AND V402_CALLTYPE !=3
GROUP BY V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID
)E ON A.V397_MAINOFFERINGID=E.V397_MAINOFFERINGID AND  A.V372_CALLINGPARTYNUMBER=E.V372_CALLINGPARTYNUMBER



LEFT OUTER JOIN

(SELECT /*+PARALLEL(SS,10)*/V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID ,SUM(V41_DEBIT_AMOUNT) RATE_INCREASER_REVENUE FROM L3_VOICE   SS
WHERE V387_CHARGINGTIME_KEY  = TO_CHAR((SELECT DATE_KEY FROM DATE_DIM WHERE DATE_VALUE = TRUNC(TO_DATE(SYSDATE-1,'DD/MM/RRRR'))))
AND V436_LASTEFFECTOFFERING=598878
AND V402_CALLTYPE !=3
GROUP BY V372_CALLINGPARTYNUMBER, V397_MAINOFFERINGID
)J on A.V397_MAINOFFERINGID=J.V397_MAINOFFERINGID AND  A.V372_CALLINGPARTYNUMBER=J.V372_CALLINGPARTYNUMBER

LEFT OUTER JOIN

(SELECT /*+PARALLEL(T,10)*/V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID ,SUM(V41_DEBIT_AMOUNT) SHORT_CODE_REVENUE FROM L3_VOICE  T
WHERE V387_CHARGINGTIME_KEY  = TO_CHAR((SELECT DATE_KEY FROM DATE_DIM WHERE DATE_VALUE = TRUNC(TO_DATE(SYSDATE-1,'DD/MM/RRRR'))))
AND V378_SERVICEFLOW=1
AND V402_CALLTYPE !=3
AND V436_LASTEFFECTOFFERING NOT IN (SELECT PRODUCT_ID FROM PRODUCT_DIM UNION SELECT OFFERING_ID FROM OFFER_DIM)
GROUP BY V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID
)F ON A.V397_MAINOFFERINGID=F.V397_MAINOFFERINGID AND A.V372_CALLINGPARTYNUMBER=F.V372_CALLINGPARTYNUMBER

LEFT OUTER JOIN 

(SELECT /*+PARALLEL(P,10)*/V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID ,SUM(V41_DEBIT_AMOUNT) FNF_REVENUE FROM L3_VOICE  P
WHERE V387_CHARGINGTIME_KEY  = TO_CHAR((SELECT DATE_KEY FROM DATE_DIM WHERE DATE_VALUE = TRUNC(TO_DATE(SYSDATE-1,'DD/MM/RRRR'))))
AND V436_LASTEFFECTOFFERING IN ( SELECT OFFERING_ID FROM OFFER_DIM WHERE OFFER_TYPE='FNF')
AND V402_CALLTYPE !=3
GROUP BY V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID
)A1 ON A.V397_MAINOFFERINGID=A1.V397_MAINOFFERINGID  AND A.V372_CALLINGPARTYNUMBER=A1.V372_CALLINGPARTYNUMBER

LEFT OUTER JOIN

(SELECT /*+PARALLEL(P,10)*/V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID ,SUM(V41_DEBIT_AMOUNT) VIDEO_REVENUE FROM L3_VOICE  P
WHERE V387_CHARGINGTIME_KEY  = TO_CHAR((SELECT DATE_KEY FROM DATE_DIM WHERE DATE_VALUE = TRUNC(TO_DATE(SYSDATE-1,'DD/MM/RRRR'))))
AND V436_LASTEFFECTOFFERING IN ( SELECT OFFERING_ID FROM OFFER_DIM WHERE OFFER_TYPE='Video')
AND V402_CALLTYPE !=3
GROUP BY V372_CALLINGPARTYNUMBER, V397_MAINOFFERINGID
)A2 ON A.V397_MAINOFFERINGID=A2.V397_MAINOFFERINGID AND A.V372_CALLINGPARTYNUMBER=A2.V372_CALLINGPARTYNUMBER

LEFT OUTER JOIN

(SELECT /*+PARALLEL(P,10)*/V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID ,SUM(V41_DEBIT_AMOUNT) CLOSED_SIM_REVENUE FROM L3_VOICE  P
WHERE V387_CHARGINGTIME_KEY  = TO_CHAR((SELECT DATE_KEY FROM DATE_DIM WHERE DATE_VALUE = TRUNC(TO_DATE(SYSDATE-1,'DD/MM/RRRR'))))
AND V436_LASTEFFECTOFFERING =585067
AND V402_CALLTYPE !=3
GROUP BY V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID
)A3 ON A.V397_MAINOFFERINGID=A3.V397_MAINOFFERINGID AND A.V372_CALLINGPARTYNUMBER=A3.V372_CALLINGPARTYNUMBER

LEFT OUTER JOIN

(SELECT /*+PARALLEL(U,10)*/ V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID ,SUM(V41_DEBIT_AMOUNT) IN_VOICE_REVENUE FROM L3_VOICE    U
WHERE V387_CHARGINGTIME_KEY  = TO_CHAR((SELECT DATE_KEY FROM DATE_DIM WHERE DATE_VALUE = TRUNC(TO_DATE(SYSDATE-1,'DD/MM/RRRR'))))
AND V402_CALLTYPE=3
GROUP BY V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID
)A4 ON A.V397_MAINOFFERINGID=A4.V397_MAINOFFERINGID AND A.V372_CALLINGPARTYNUMBER=A4.V372_CALLINGPARTYNUMBER


LEFT OUTER JOIN

(SELECT /*+PARALLEL(U,10)*/ V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID ,SUM(V41_DEBIT_AMOUNT) DISCOUNT_REVENUE FROM L3_VOICE    U
WHERE V387_CHARGINGTIME_KEY  = TO_CHAR((SELECT DATE_KEY FROM DATE_DIM WHERE DATE_VALUE = TRUNC(TO_DATE(SYSDATE-1,'DD/MM/RRRR'))))
AND V436_LASTEFFECTOFFERING =402326
AND V402_CALLTYPE !=3
GROUP BY V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID
)A5 ON A.V397_MAINOFFERINGID=A5.V397_MAINOFFERINGID AND A.V372_CALLINGPARTYNUMBER=A5.V372_CALLINGPARTYNUMBER



)N
WHERE M.PRODUCT_ID=N.V397_MAINOFFERINGID
;
    COMMIT;
END;
/

