--
-- CLM_J_1_CAMPAIGNTARGETING  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.CLM_J_1_CAMPAIGNTARGETING
(MSISDN, TOTAL_REVENUE)
BEQUEATH DEFINER
AS 
SELECT A.V372_CALLINGPARTYNUMBER MSISDN,
          COALESCE (Data_Revenue, 0)
                  + COALESCE (Voice_Revenue, 0)
                  + COALESCE (Vas_Revenue, 0)
                  + COALESCE (SMS_Revenue, 0)
                     TOTAL_REVENUE
     FROM (SELECT V372_CALLINGPARTYNUMBER
             FROM L3_voice
            WHERE V387_CHARGINGTIME_KEY =
                     (SELECT A.DATE_KEY
                        FROM DATE_DIM A
                       WHERE A.DATE_VALUE =
                                TO_DATE (SYSDATE - 10, 'DD/MM/RRRR'))
           UNION
           SELECT G372_CALLINGPARTYNUMBER
             FROM L3_Data
            WHERE G383_CHARGINGTIME_KEY =
                     (SELECT A.DATE_KEY
                        FROM DATE_DIM A
                       WHERE A.DATE_VALUE =
                                TO_DATE (SYSDATE - 10, 'DD/MM/RRRR'))
           UNION
           SELECT S372_CALLINGPARTYNUMBER
             FROM L3_sms
            WHERE S387_CHARGINGTIME_KEY =
                     (SELECT A.DATE_KEY
                        FROM DATE_DIM A
                       WHERE A.DATE_VALUE =
                                TO_DATE (SYSDATE - 10, 'DD/MM/RRRR'))
           UNION
           SELECT R375_CHARGINGPARTYNUMBER
             FROM L3_recurring
            WHERE R377_CYCLEBEGINTIME_KEY =
                     (SELECT A.DATE_KEY
                        FROM DATE_DIM A
                       WHERE A.DATE_VALUE =
                                TO_DATE (SYSDATE - 10, 'DD/MM/RRRR'))) A
          LEFT OUTER JOIN
          (  SELECT G372_CALLINGPARTYNUMBER,
                    SUM (G448_PAY_DEBIT_AMOUNT) Data_Revenue
               FROM L3_DATA
              WHERE G383_CHARGINGTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 10, 'DD/MM/RRRR'))
           GROUP BY G372_CALLINGPARTYNUMBER) B
             ON A.V372_CALLINGPARTYNUMBER = B.G372_CALLINGPARTYNUMBER
          LEFT OUTER JOIN
          (  SELECT V372_CALLINGPARTYNUMBER,
                    SUM (V41_DEBIT_AMOUNT) Voice_Revenue
               FROM L3_VOICE
              WHERE V387_CHARGINGTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 10, 'DD/MM/RRRR'))
           GROUP BY V372_CALLINGPARTYNUMBER) C
             ON A.V372_CALLINGPARTYNUMBER = C.V372_CALLINGPARTYNUMBER
          LEFT OUTER JOIN
          (  SELECT R375_CHARGINGPARTYNUMBER,
                    SUM (R41_DEBIT_AMOUNT) Vas_Revenue
               FROM L3_RECURRING
              WHERE R377_CYCLEBEGINTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 10, 'DD/MM/RRRR'))
           GROUP BY R375_CHARGINGPARTYNUMBER) D
             ON A.V372_CALLINGPARTYNUMBER = D.R375_CHARGINGPARTYNUMBER
          LEFT OUTER JOIN
          (  SELECT S22_PRI_IDENTITY, SUM (S41_DEBIT_AMOUNT) SMS_Revenue
               FROM L3_sms
              WHERE S387_CHARGINGTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 10, 'DD/MM/RRRR'))
           GROUP BY S22_PRI_IDENTITY) E
             ON A.V372_CALLINGPARTYNUMBER = E.S22_PRI_IDENTITY;


