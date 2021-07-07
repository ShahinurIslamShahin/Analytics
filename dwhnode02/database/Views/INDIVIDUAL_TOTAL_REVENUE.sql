--
-- INDIVIDUAL_TOTAL_REVENUE  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.INDIVIDUAL_TOTAL_REVENUE
(V397_MAINOFFERINGID, VOICE_REVENUE, DATA_REVENUE, SMS_REVENUE, RECURRING_REVENUE)
BEQUEATH DEFINER
AS 
SELECT A.V397_MAINOFFERINGID,
          B.VOICE_REVENUE,
          C.DATA_REVENUE,
          D.SMS_REVENUE,
          E.RECURRING_REVENUE
     FROM (  SELECT V397_MAINOFFERINGID
               FROM L3_VOICE
           GROUP BY V397_MAINOFFERINGID
           UNION
             SELECT G401_MAINOFFERINGID
               FROM L3_data
           GROUP BY G401_MAINOFFERINGID
           UNION
             SELECT S395_MAINOFFERINGID
               FROM L3_sms
           GROUP BY S395_MAINOFFERINGID
           UNION
             SELECT R373_MAINOFFERINGID
               FROM L3_Recurring
           GROUP BY R373_MAINOFFERINGID) A
          LEFT OUTER JOIN
          (  SELECT V397_MAINOFFERINGID, SUM (V41_DEBIT_AMOUNT) VOICE_REVENUE
               FROM L3_VOICE
              WHERE     V402_CALLTYPE != 3
                    AND V387_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                    AND V403_ROAMSTATE != 3
           GROUP BY V397_MAINOFFERINGID) B
             ON A.V397_MAINOFFERINGID = B.V397_MAINOFFERINGID
          LEFT OUTER JOIN
          (  SELECT G401_MAINOFFERINGID, SUM (G41_DEBIT_AMOUNT) DATA_REVENUE
               FROM L3_DATA
              WHERE G383_CHARGINGTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY G401_MAINOFFERINGID) C
             ON A.V397_MAINOFFERINGID = C.G401_MAINOFFERINGID
          LEFT OUTER JOIN
          (  SELECT S395_MAINOFFERINGID, SUM (S41_DEBIT_AMOUNT) SMS_REVENUE
               FROM L3_SMS
              WHERE     S400_SMSTYPE != 3
                    AND S387_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY S395_MAINOFFERINGID) D
             ON A.V397_MAINOFFERINGID = D.S395_MAINOFFERINGID
          LEFT OUTER JOIN
          (  SELECT R373_MAINOFFERINGID,
                    SUM (R41_DEBIT_AMOUNT) RECURRING_REVENUE
               FROM L3_RECURRING
              WHERE R377_CYCLEBEGINTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY R373_MAINOFFERINGID) E
             ON A.V397_MAINOFFERINGID = E.R373_MAINOFFERINGID;


