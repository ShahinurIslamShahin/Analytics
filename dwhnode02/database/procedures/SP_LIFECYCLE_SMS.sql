--
-- SP_LIFECYCLE_SMS  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.SP_LIFECYCLE_SMS (P_PROCESS_DATE VARCHAR2) IS
    VDATE_KEY               VARCHAR2(4);
    DAILY_SMS_REVENUE       NUMBER;
    DAILY_SMS_COUNT         NUMBER;
    DAILY_SMS_COUNT_ONNET   NUMBER;
    DAILY_SMS_COUNT_OFFNET  NUMBER;
    VDATE DATE := TO_DATE(TO_DATE(P_PROCESS_DATE,'YYYYMMDD'),'DD/MM/RRRR');
    ---------KPI_LOG STATUS----------
    VSTATUS517                  NUMBER;
    VSTATUS623                  NUMBER;
    VSTATUS624                  NUMBER;
    VSTATUS690                  NUMBER;

BEGIN
    SELECT DATE_KEY INTO VDATE_KEY 
    FROM DATE_DIM
    WHERE DATE_KEY = (SELECT A.DATE_KEY FROM DATE_DIM A WHERE A.DATE_VALUE = VDATE);
    
    ---------------517 Daily Mosms Sms Count------------------
    SELECT COUNT(STATUS) AS STATUS INTO  VSTATUS517
    FROM LIFECYCLE_LOG
    WHERE DATE_KEY = VDATE_KEY
    AND  KPI_KEY = 517;

    IF VSTATUS517 = 0 THEN
        INSERT INTO LIFECYCLE_LOG (PROCEDURE_NAME, KPI_KEY, SOURCE, DATE_KEY, STATUS, INSERT_TIME, REMARKS)
        VALUES                    ('SP_LIFECYCLE_SMS',517,'L3_SMS',VDATE_KEY,30,SYSDATE,'A');
        COMMIT;
    
        SELECT /*+ PARALLEL(L3_SMS,16) */ COUNT(S22_PRI_IDENTITY) INTO DAILY_SMS_COUNT
        FROM L3_SMS
        WHERE S378_SERVICEFLOW=1
        AND S387_CHARGINGTIME_KEY =VDATE_KEY;

        INSERT INTO LIFECYCLE_KPI_FCT(DATE_KEY, KPI_KEY,KPI_VALUE)
        VALUES (VDATE_KEY, 517,DAILY_SMS_COUNT);
        COMMIT;
                
        UPDATE LIFECYCLE_LOG SET 
        STATUS = 96
        WHERE DATE_KEY = VDATE_KEY
        AND KPI_KEY = 517;        
        COMMIT;
    ELSE
        INSERT INTO LIFECYCLE_LOG (PROCEDURE_NAME, KPI_KEY, SOURCE, DATE_KEY, STATUS, INSERT_TIME, REMARKS)
        VALUES                    ('SP_LIFECYCLE_SMS',517,'L3_SMS',VDATE_KEY,34,SYSDATE,'A');
        COMMIT;
    END IF;

    -------------- 623 Daily  On-net SMS Count---------------
    SELECT COUNT(STATUS) AS STATUS INTO  VSTATUS623
    FROM LIFECYCLE_LOG
    WHERE DATE_KEY = VDATE_KEY
    AND  KPI_KEY = 623;

    IF VSTATUS623 = 0 THEN
        INSERT INTO LIFECYCLE_LOG (PROCEDURE_NAME, KPI_KEY, SOURCE, DATE_KEY, STATUS, INSERT_TIME, REMARKS)
        VALUES                    ('SP_LIFECYCLE_SMS',623,'L3_SMS',VDATE_KEY,30,SYSDATE,'A');
        COMMIT;
        
        SELECT /*+ PARALLEL(L3_SMS,16) */ COUNT(S22_PRI_IDENTITY) INTO DAILY_SMS_COUNT_ONNET
        FROM L3_SMS
        WHERE S378_SERVICEFLOW=1 
        AND S401_ONNETINDICATOR=0 
        AND S387_CHARGINGTIME_KEY =VDATE_KEY;
        
        INSERT INTO LIFECYCLE_KPI_FCT(DATE_KEY, KPI_KEY,KPI_VALUE)
        VALUES (VDATE_KEY, 623,DAILY_SMS_COUNT_ONNET);         
        COMMIT;
                
        UPDATE LIFECYCLE_LOG SET 
        STATUS = 96
        WHERE DATE_KEY = VDATE_KEY
        AND KPI_KEY = 623;        
        COMMIT;
    ELSE
        INSERT INTO LIFECYCLE_LOG (PROCEDURE_NAME, KPI_KEY, SOURCE, DATE_KEY, STATUS, INSERT_TIME, REMARKS)
        VALUES                    ('SP_LIFECYCLE_SMS',623,'L3_SMS',VDATE_KEY,34,SYSDATE,'A');
        COMMIT;
    END IF;

    ------------- 624 Daily off net SMS Count---------------- 
    SELECT COUNT(STATUS) AS STATUS INTO  VSTATUS624
    FROM LIFECYCLE_LOG
    WHERE DATE_KEY = VDATE_KEY
    AND  KPI_KEY = 624;

    IF VSTATUS624 = 0 THEN
        INSERT INTO LIFECYCLE_LOG (PROCEDURE_NAME, KPI_KEY, SOURCE, DATE_KEY, STATUS, INSERT_TIME, REMARKS)
        VALUES                    ('SP_LIFECYCLE_SMS',624,'L3_SMS',VDATE_KEY,30,SYSDATE,'A');
        COMMIT;
          
        SELECT /*+ PARALLEL(L3_SMS,16) */COUNT(S22_PRI_IDENTITY) INTO DAILY_SMS_COUNT_OFFNET
        FROM L3_SMS
        WHERE S378_SERVICEFLOW=1 
        AND S401_ONNETINDICATOR=1
        AND S387_CHARGINGTIME_KEY =VDATE_KEY;
        
        INSERT INTO LIFECYCLE_KPI_FCT(DATE_KEY, KPI_KEY,KPI_VALUE)
        VALUES (VDATE_KEY, 624,DAILY_SMS_COUNT_OFFNET);
        COMMIT;
                
        UPDATE LIFECYCLE_LOG SET 
        STATUS = 96
        WHERE DATE_KEY = VDATE_KEY
        AND KPI_KEY = 624;        
        COMMIT;
    ELSE
        INSERT INTO LIFECYCLE_LOG (PROCEDURE_NAME, KPI_KEY, SOURCE, DATE_KEY, STATUS, INSERT_TIME, REMARKS)
        VALUES                    ('SP_LIFECYCLE_SMS',624,'L3_SMS',VDATE_KEY,34,SYSDATE,'A');
        COMMIT;
    END IF;

    -----------------690 Daily SMS Revenue-----------------
    SELECT COUNT(STATUS) AS STATUS INTO  VSTATUS690
    FROM LIFECYCLE_LOG
    WHERE DATE_KEY = VDATE_KEY
    AND  KPI_KEY = 690;

    IF VSTATUS690 = 0 THEN
        INSERT INTO LIFECYCLE_LOG (PROCEDURE_NAME, KPI_KEY, SOURCE, DATE_KEY, STATUS, INSERT_TIME, REMARKS)
        VALUES                    ('SP_LIFECYCLE_SMS',690,'L3_SMS',VDATE_KEY,30,SYSDATE,'A');
        COMMIT;
        SELECT /*+ PARALLEL(L3_SMS,16) */ SUM(S41_DEBIT_AMOUNT) INTO DAILY_SMS_REVENUE
        FROM L3_SMS
        WHERE S387_CHARGINGTIME_KEY =VDATE_KEY;
        
        INSERT INTO LIFECYCLE_KPI_FCT(DATE_KEY, KPI_KEY,KPI_VALUE)
        VALUES (VDATE_KEY, 690,DAILY_SMS_REVENUE);
        COMMIT; 
        UPDATE LIFECYCLE_LOG SET 
        STATUS = 96
        WHERE DATE_KEY = VDATE_KEY
        AND KPI_KEY = 690;        
        COMMIT;
    ELSE
        INSERT INTO LIFECYCLE_LOG (PROCEDURE_NAME, KPI_KEY, SOURCE, DATE_KEY, STATUS, INSERT_TIME, REMARKS)
        VALUES                    ('SP_LIFECYCLE_SMS',690,'L3_SMS',VDATE_KEY,34,SYSDATE,'A');
        COMMIT;
    END IF;
END;
/

