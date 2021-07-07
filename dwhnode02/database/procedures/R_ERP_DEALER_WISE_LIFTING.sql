--
-- R_ERP_DEALER_WISE_LIFTING  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.R_ERP_DEALER_WISE_LIFTING IS
    VDATE_KEY       VARCHAR2(64 BYTE);
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD');



    --EXECUTE IMMEDIATE  'TRUNCATE TABLE PKPI DROP STORAGE';
    --EXECUTE IMMEDIATE 'ALTER TABLE PKPI TRUNCATE PARTITION PKPI_||VDATE_KEY DROP STORAGE';
    
DELETE ERP_DEALER_WISE_LIFTING WHERE DATE_KEY=VDATE_KEY;
COMMIT;
    
INSERT INTO ERP_DEALER_WISE_LIFTING


SELECT BU_NAME ,CUSTOMER_NAME,TYPE_NAME CUSTOMER_TYPE,ITEM_NAME,QNTY QUANTITY,RATE,COM_AMT COMMISSION,AIT_AMT AIT ,
       (COALESCE (QNTY, 0)*COALESCE (RATE, 0)) SALES_AMOUNT, 
        (COALESCE (QNTY, 0)*COALESCE (RATE, 0))+COALESCE (COM_AMT, 0)+COALESCE (AIT_AMT, 0) GRAND_TOTAL,VDATE_KEY


 FROM 
(SELECT /*+PARALLEL(A,16)*/ BU_NO, BU_NAME FROM HR_BU@DWH05TOBMS A
)S
INNER JOIN
(SELECT * FROM
(SELECT /*+PARALLEL(A,16)*/  A.SI_NO, A.CUSTOMER_NO, A.INVOICE_DATE, A.BU_NO FROM SL_INVOICE@DWH05TOBMS A
WHERE A.INVOICE_DATE BETWEEN (TO_DATE(sysdate-7,'DD/MM/RRRR')) AND (TO_DATE(sysdate-1,'DD/MM/RRRR'))
)P
INNER JOIN
(SELECT * FROM
(SELECT /*+PARALLEL(A,16)*/ CUSTOMER_NO, CUSTTYPE_NO, CUSTOMER_NAME FROM SL_CUSTOMER@DWH05TOBMS A
)A
INNER JOIN
(SELECT /*+PARALLEL(A,16)*/ CUSTTYPE_NO, TYPE_NAME FROM SL_CUSTTYPE@DWH05TOBMS A
)B ON A.CUSTTYPE_NO=B.CUSTTYPE_NO
)Q ON  P.CUSTOMER_NO=P.CUSTOMER_NO
INNER JOIN
(SELECT/*+PARALLEL(B,16)*/ * FROM
(SELECT B.SI_NO, B.ITEM_NO, B.QNTY, B.RATE, B.COM_AMT, B.AIT_AMT FROM SL_INVOICEDTL@DWH05TOBMS B
)A
INNER JOIN
(
SELECT /*+PARALLEL(A,16)*/ ITEM_NO, ITEM_NAME FROM IN_ITEM@DWH05TOBMS A
)B ON A.ITEM_NO=B.ITEM_NO
)R ON P.SI_NO=R.SI_NO
)T ON S.BU_NO=T.BU_NO;
      COMMIT;
END;
/

