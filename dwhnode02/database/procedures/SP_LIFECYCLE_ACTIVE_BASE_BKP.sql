--
-- SP_LIFECYCLE_ACTIVE_BASE_BKP  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.SP_LIFECYCLE_ACTIVE_BASE_bkp (P_PROCESS_DATE VARCHAR2) IS
    VDATE_KEY       NUMBER;
    ACTIVATION      NUMBER;
    ONE_DAY         NUMBER;
    THIRTY_DAY      NUMBER;
    VDATE           DATE := TO_DATE(TO_DATE(P_PROCESS_DATE,'YYYYMMDD'),'DD/MM/RRRR');
    ------KPI_LOG STATUS------
    VSTATUS599      NUMBER;
    VSTATUS614      NUMBER;
    VSTATUS664      NUMBER;

BEGIN
    SELECT DATE_KEY INTO VDATE_KEY 
    FROM DATE_DIM
    WHERE DATE_KEY = (SELECT A.DATE_KEY FROM DATE_DIM A WHERE A.DATE_VALUE = VDATE);
    
    -------------599    Activation---------
    SELECT COUNT(STATUS) AS STATUS INTO  VSTATUS599
    FROM LIFECYCLE_LOG
    WHERE DATE_KEY = VDATE_KEY
    AND  KPI_KEY = 599;
    
    IF VSTATUS599 = 0 THEN
        INSERT INTO LIFECYCLE_LOG (PROCEDURE_NAME, KPI_KEY, SOURCE, DATE_KEY, STATUS, INSERT_TIME, REMARKS)
        VALUES                    ('SP_LIFECYCLE_ACTIVE_BASE',599,'ACTIVEBASE',VDATE_KEY,30,SYSDATE,'A');
        COMMIT;
       
        SELECT COUNT(MSISDN) INTO ACTIVATION
        FROM LAST_ACTIVITY_FCT
        WHERE ETL_DATE_KEY=VDATE_KEY
        AND SNAPSHOT_DATE_KEY=VDATE_KEY;
        /*
        SELECT COUNT(MSISDIN_NO) INTO ACTIVATION
        FROM ACTIVEBASE
        WHERE LAST_ACTIVITY_DATE_KEY=VDATE_KEY;
        */
        INSERT INTO LIFECYCLE_KPI_FCT(DATE_KEY, KPI_KEY,KPI_VALUE)
        VALUES (VDATE_KEY, 599,ACTIVATION);        
        COMMIT;
        
        UPDATE LIFECYCLE_LOG SET 
        STATUS = 96
        WHERE DATE_KEY = VDATE_KEY
        AND KPI_KEY = 599;        
        COMMIT;
    ELSE
        INSERT INTO LIFECYCLE_LOG (PROCEDURE_NAME, KPI_KEY, SOURCE, DATE_KEY, STATUS, INSERT_TIME, REMARKS)
        VALUES                    ('SP_LIFECYCLE_ACTIVE_BASE',566,'ACTIVEBASE',VDATE_KEY,34,SYSDATE,'A');
        COMMIT;
    END IF; 
    
    -------614    1 day Active Base-----
    SELECT COUNT(STATUS) AS STATUS INTO  VSTATUS614
    FROM LIFECYCLE_LOG
    WHERE DATE_KEY = VDATE_KEY
    AND  KPI_KEY = 614;
    
    IF VSTATUS614 = 0 THEN
        INSERT INTO LIFECYCLE_LOG (PROCEDURE_NAME, KPI_KEY, SOURCE, DATE_KEY, STATUS, INSERT_TIME, REMARKS)
        VALUES                    ('SP_LIFECYCLE_ACTIVE_BASE',614,'ACTIVEBASE',VDATE_KEY,30,SYSDATE,'A');
        COMMIT; 
        SELECT COUNT(*) INTO ONE_DAY 
        FROM 
        (SELECT MSISDN, SNAPSHOT_DATE_KEY, SNAPSHOT_DATE_KEY - LU_DATE_KEY AS DATE_DIFF  
        FROM LAST_ACTIVITY_FCT
        WHERE ETL_DATE_KEY <=VDATE_KEY
        AND SNAPSHOT_DATE_KEY - LU_DATE_KEY = 0);
              /*
        SELECT COUNT(MSISDIN_NO) INTO ONE_DAY
        FROM DATEDIFFERENCE
        WHERE DATE_DIFF=0
        AND LAST_ACTIVITY_DATE_KEY=VDATE_KEY;
        */
        INSERT INTO LIFECYCLE_KPI_FCT(DATE_KEY, KPI_KEY,KPI_VALUE)
        VALUES (VDATE_KEY, 614,ONE_DAY);
        COMMIT;
        
        UPDATE LIFECYCLE_LOG SET 
        STATUS = 96
        WHERE DATE_KEY = VDATE_KEY
        AND KPI_KEY = 614;        
        COMMIT;
    ELSE
        INSERT INTO LIFECYCLE_LOG (PROCEDURE_NAME, KPI_KEY, SOURCE, DATE_KEY, STATUS, INSERT_TIME, REMARKS)
        VALUES                    ('SP_LIFECYCLE_ACTIVE_BASE',614,'ACTIVEBASE',VDATE_KEY,34,SYSDATE,'A');
        COMMIT;
    END IF;
    
    -----664    30 days active sub base
    SELECT COUNT(STATUS) AS STATUS INTO  VSTATUS664
    FROM LIFECYCLE_LOG
    WHERE DATE_KEY = VDATE_KEY
    AND  KPI_KEY = 664;
    
    IF VSTATUS664 = 0 THEN
        INSERT INTO LIFECYCLE_LOG (PROCEDURE_NAME, KPI_KEY, SOURCE, DATE_KEY, STATUS, INSERT_TIME, REMARKS)
        VALUES                    ('SP_LIFECYCLE_ACTIVE_BASE',664,'ACTIVEBASE',VDATE_KEY,30,SYSDATE,'A');
        COMMIT;

        SELECT COUNT(*) INTO THIRTY_DAY 
        FROM(
        SELECT MSISDN  
        FROM 
        (SELECT MSISDN, SNAPSHOT_DATE_KEY, SNAPSHOT_DATE_KEY - LU_DATE_KEY AS DATE_DIFF  
        FROM LAST_ACTIVITY_FCT
        WHERE ETL_DATE_KEY <=2267
        AND SNAPSHOT_DATE_KEY - LU_DATE_KEY <= 30)
        GROUP BY MSISDN, SNAPSHOT_DATE_KEY);
        /*
        SELECT COUNT(MSISDIN_NO)  INTO THIRTY_DAY
        FROM DATEDIFFERENCE
        WHERE DATE_DIFF<=30
        AND LAST_ACTIVITY_DATE_KEY=VDATE_KEY;
      */

        INSERT INTO LIFECYCLE_KPI_FCT(DATE_KEY, KPI_KEY,KPI_VALUE)
        VALUES (VDATE_KEY, 664,THIRTY_DAY);
        COMMIT;
        UPDATE LIFECYCLE_LOG SET 
        STATUS = 96
        WHERE DATE_KEY = VDATE_KEY
        AND KPI_KEY = 664;        
        COMMIT;
    ELSE
        INSERT INTO LIFECYCLE_LOG (PROCEDURE_NAME, KPI_KEY, SOURCE, DATE_KEY, STATUS, INSERT_TIME, REMARKS)
        VALUES                    ('SP_LIFECYCLE_ACTIVE_BASE',664,'ACTIVEBASE',VDATE_KEY,34,SYSDATE,'A');
        COMMIT;
    END IF;
END;
/

