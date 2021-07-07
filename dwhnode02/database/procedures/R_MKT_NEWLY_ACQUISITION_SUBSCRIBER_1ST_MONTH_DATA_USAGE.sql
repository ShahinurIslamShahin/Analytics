--
-- R_MKT_NEWLY_ACQUISITION_SUBSCRIBER_1ST_MONTH_DATA_USAGE  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.R_MKT_NEWLY_ACQUISITION_SUBSCRIBER_1ST_MONTH_DATA_USAGE IS
    VDATE_KEY       VARCHAR2(64 BYTE);
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE,'RRRRMMDD');



    --EXECUTE IMMEDIATE  'TRUNCATE TABLE PKPI DROP STORAGE';
    --EXECUTE IMMEDIATE 'ALTER TABLE PKPI TRUNCATE PARTITION PKPI_||VDATE_KEY DROP STORAGE';
    
DELETE MKT_NEWLY_ACQUISITION_SUBSCRIBER_1ST_MONTH_DATA_USAGE WHERE DATE_KEY=VDATE_KEY;
COMMIT;
    
INSERT INTO MKT_NEWLY_ACQUISITION_SUBSCRIBER_1ST_MONTH_DATA_USAGE

SELECT /*+PARALLEL(P,14)*/ G372_CALLINGPARTYNUMBER, G401_MAINOFFERINGID,SUM(G384_TOTALFLUX)/1048576 FIRST_MONTH_DATA ,VDATE_KEY
FROM L3_dATA P
WHERE (G383_CHARGINGTIME_KEY BETWEEN (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE(SYSDATE-90,'DD/MM/RRRR'))
                                                       AND  (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE(SYSDATE-61,'DD/MM/RRRR')))

      
      
GROUP BY  G372_CALLINGPARTYNUMBER, G401_MAINOFFERINGID;
      COMMIT;
END;
/

