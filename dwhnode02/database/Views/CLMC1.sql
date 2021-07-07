--
-- CLMC1  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.CLMC1
(MSISDN, DATA_REVENUE, VOICE_REVENUE, VAS_REVENUE, SMS_REVENUE)
BEQUEATH DEFINER
AS 
SELECT A.V372_CALLINGPARTYNUMBER MSISDN,
          Data_Revenue,
          Voice_Revenue,
          Vas_Revenue,
          SMS_Revenue
     FROM (SELECT /*+PARALLEL(P,8)*/
                  V372_CALLINGPARTYNUMBER
             FROM L3_voice P
            WHERE V378_SERVICEFLOW=1
            and
            
            V387_CHARGINGTIME_KEY =
                     (SELECT A.DATE_KEY
                        FROM DATE_DIM A
                       WHERE A.DATE_VALUE =
                                TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           UNION
           SELECT /*+PARALLEL(Q,8)*/
                  G372_CALLINGPARTYNUMBER
             FROM L3_Data Q
            WHERE G383_CHARGINGTIME_KEY =
                     (SELECT A.DATE_KEY
                        FROM DATE_DIM A
                       WHERE A.DATE_VALUE =
                                TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           UNION
           SELECT /*+PARALLEL(R,8)*/
                  S372_CALLINGPARTYNUMBER
             FROM L3_sms R
            WHERE S378_SERVICEFLOW=1
            and 
            S387_CHARGINGTIME_KEY =
                     (SELECT A.DATE_KEY
                        FROM DATE_DIM A
                       WHERE A.DATE_VALUE =
                                TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           UNION
           SELECT /*+PARALLEL(S,8)*/
                  R375_CHARGINGPARTYNUMBER
             FROM L3_recurring S
            WHERE R377_CYCLEBEGINTIME_KEY =
                     (SELECT A.DATE_KEY
                        FROM DATE_DIM A
                       WHERE A.DATE_VALUE =
                                TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))) A
          LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(T,8)*/
                   G372_CALLINGPARTYNUMBER,
                    SUM (G448_PAY_DEBIT_AMOUNT) Data_Revenue
               FROM L3_DATA T
              WHERE G383_CHARGINGTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY G372_CALLINGPARTYNUMBER) B
             ON A.V372_CALLINGPARTYNUMBER = B.G372_CALLINGPARTYNUMBER
          LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(U,8)*/
                   V372_CALLINGPARTYNUMBER,
                    SUM (V41_DEBIT_AMOUNT) Voice_Revenue
               FROM L3_VOICE U
              WHERE V387_CHARGINGTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY V372_CALLINGPARTYNUMBER) C
             ON A.V372_CALLINGPARTYNUMBER = C.V372_CALLINGPARTYNUMBER
          LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(V,8)*/
                   R375_CHARGINGPARTYNUMBER,
                    SUM (R41_DEBIT_AMOUNT) Vas_Revenue
               FROM L3_RECURRING V
              WHERE R377_CYCLEBEGINTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY R375_CHARGINGPARTYNUMBER) D
             ON A.V372_CALLINGPARTYNUMBER = D.R375_CHARGINGPARTYNUMBER
          LEFT OUTER JOIN
          (  SELECT /*+PARALLEL(W,8)*/
                   S22_PRI_IDENTITY, SUM (S41_DEBIT_AMOUNT) SMS_Revenue
               FROM L3_sms W
              WHERE S387_CHARGINGTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY S22_PRI_IDENTITY) E
             ON A.V372_CALLINGPARTYNUMBER = E.S22_PRI_IDENTITY;


