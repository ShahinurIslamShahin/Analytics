--
-- R_PACKAGE_WISE_SMS_PROFIT_SYS2  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.R_PACKAGE_WISE_SMS_PROFIT_SYS2 IS
    VDATE_KEY       NUMBER;
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE,'RRRRMMDD');
   

    
INSERT INTO PACKAGE_WISE_SMS_PROFIT


SELECT A.DATE_KEY,
        A.DATE_VALUE,
        A.PRODUCT_ID,
        A.PRODUCT_NAME,
        A.SMS_COUNT,
        A.FREE_SMS_COUNT,
          (  (A.SMS_COUNT * SMS_TARIFF)
           - ((A.SMS_COUNT*SMS_TARIFF) * 0.185))
             SMS_PROFIT,
              (  (A.FREE_SMS_COUNT * 0.1)
           - ((A.FREE_SMS_COUNT*0.1) * 0.185))
             FREE_SMS_PROFIT
     FROM (  SELECT /*+PARALLEL(P,15)*/
                   DATE_KEY,
                   DATE_VALUE,
                    PRODUCT_ID,
                    PRODUCT_NAME,
                    COUNT(
                    CASE
                    WHEN S397_CHARGEPARTYINDICATOR!='N' AND S416_SPECIALNUMBERINDICATOR=0
                    THEN P.S372_CALLINGPARTYNUMBER END
                    ) SMS_COUNT,
                    COUNT(
                    CASE
                    WHEN S397_CHARGEPARTYINDICATOR='N' AND S416_SPECIALNUMBERINDICATOR=0
                    THEN P.S372_CALLINGPARTYNUMBER END
                    ) FREE_SMS_COUNT
               FROM DWH_USER.L3_SMS P, DATE_DIM Q, PRODUCT_DIM R
              WHERE     (S387_CHARGINGTIME_KEY =(SELECT DATE_KEY
                                                          FROM DATE_DIM
                                                         WHERE DATE_VALUE =
                                                                  TRUNC (
                                                                     TO_DATE (
                                                                          SYSDATE
                                                                        - 2,
                                                                        'DD/MM/RRRR'))))
                    AND P.S378_SERVICEFLOW = '1'
                    AND P.S387_CHARGINGTIME_KEY = Q.DATE_KEY
                    AND P.S395_MAINOFFERINGID = R.PRODUCT_ID
           GROUP BY DATE_KEY,DATE_VALUE, PRODUCT_ID, PRODUCT_NAME
           ORDER BY DATE_VALUE) A, BASE_TARIFF_DIM B
           WHERE A.PRODUCT_ID=B.PRODUCT_ID;
             
             
             
      COMMIT;
END;
/

