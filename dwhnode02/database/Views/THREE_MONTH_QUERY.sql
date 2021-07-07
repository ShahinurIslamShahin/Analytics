--
-- THREE_MONTH_QUERY  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.THREE_MONTH_QUERY
(MSISDIN_NO, V400_PAYTYPE, FIRST_ACTIVE_DATE, LAST_ACTIVITY_DATE_KEY, REVENUE_LAST_ACTIVITY_DATE, 
 DATA_LAST_ACTIVITY_DATE, VAS_LAST_ACTIVITY_DATE, VOICE_LAST_ACTIVITY_DATE, MONTHLY_CALL_MINUTES, MONTHLY_CALL_MINUTES_RECEIVED, 
 MONTHLY_DATA_VOLUME_USED, MONTHLY_DATA_PACK_BY_COUNT, MONTHLY_PACK_BY_COUNT, MONTHLY_RECHARGE_AMOUNT, MONTHLY_RECHARGE_COUNT, 
 MONTHLY_RECHARGE_REVENUE, MONTHLY_VAS_REVENUE, MONTHLY_SMS_SEND_COUNT)
BEQUEATH DEFINER
AS 
SELECT A.MSISDIN_NO,
          B.V400_PAYTYPE,
          C.FIRST_ACTIVE_DATE,
          H.LAST_ACTIVITY_DATE_KEY,
          D.Revenue_last_activity_date,
          E.Data_last_activity_date,
          F.VAS_last_activity_date,
          G.Voice_last_activity_date,
          L.MONTHLY_Call_Minutes,
          I.MONTHLY_Call_Minutes_Received,
          J.MONTHLY_Data_Volume_Used,
          J.MONTHLY_Data_Pack_by_Count,
          J.MONTHLY_Pack_by_Count,
          O.MONTHLY_Recharge_Amount,
          O.MONTHLY_Recharge_Count,
          O.MONTHLY_RECHARGE_Revenue,
          M.Monthly_Vas_Revenue,
          N.MONTHLY_SMS_SEND_COUNT
     FROM (SELECT MSISDIN_NO FROM ACTIVEBASE) A
          LEFT OUTER JOIN
          (SELECT MSISDIN_NO, LAST_ACTIVITY_DATE_KEY
             FROM ACTIVEBASE
            WHERE LAST_ACTIVITY_DATE_KEY IN (SELECT DATE_KEY
                                               FROM DATE_DIM
                                              WHERE DATE_VALUE =
                                                       TO_DATE (SYSDATE - 7,
                                                                'DD/MM/RRRR')))
          H
             ON H.MSISDIN_NO = A.MSISDIN_NO
          LEFT OUTER JOIN
          (SELECT V372_CALLINGPARTYNUMBER, V400_PAYTYPE
             FROM L3_VOICE
            WHERE V387_CHARGINGTIME_KEY IN (SELECT DATE_KEY
                                              FROM DATE_DIM
                                             WHERE DATE_VALUE =
                                                      TO_DATE (SYSDATE - 7,
                                                               'DD/MM/RRRR')))
          B
             ON B.V372_CALLINGPARTYNUMBER = A.MSISDIN_NO
          LEFT OUTER JOIN
          (SELECT MSISDIN_NO, FIRST_ACTIVE_DATE
             FROM AGEONNETWROK
            WHERE FIRST_ACTIVE_DATE IN (SELECT DATE_KEY
                                          FROM DATE_DIM
                                         WHERE DATE_VALUE =
                                                  TO_DATE (SYSDATE - 7,
                                                           'DD/MM/RRRR'))) C
             ON A.MSISDIN_NO = C.MSISDIN_NO
          LEFT OUTER JOIN
          (SELECT MSISDIN_NO,
                  LAST_ACTIVITY_DATE_KEY Revenue_last_activity_date
             FROM ACTIVEBASERECHARGE
            WHERE LAST_ACTIVITY_DATE_KEY IN (SELECT DATE_KEY
                                               FROM DATE_DIM
                                              WHERE DATE_VALUE =
                                                       TO_DATE (SYSDATE - 7,
                                                                'DD/MM/RRRR')))
          D
             ON A.MSISDIN_NO = D.MSISDIN_NO
          LEFT OUTER JOIN
          (SELECT MSISDIN_NO, LAST_ACTIVITY_DATE_KEY Data_last_activity_date
             FROM ACTIVEBASEDATA
            WHERE LAST_ACTIVITY_DATE_KEY IN (SELECT DATE_KEY
                                               FROM DATE_DIM
                                              WHERE DATE_VALUE =
                                                       TO_DATE (SYSDATE - 7,
                                                                'DD/MM/RRRR')))
          E
             ON A.MSISDIN_NO = E.MSISDIN_NO
          LEFT OUTER JOIN
          (SELECT MSISDIN_NO, LAST_ACTIVITY_DATE_KEY VAS_last_activity_date
             FROM ACTIVEBASERECURRING
            WHERE LAST_ACTIVITY_DATE_KEY IN (SELECT DATE_KEY
                                               FROM DATE_DIM
                                              WHERE DATE_VALUE =
                                                       TO_DATE (SYSDATE - 7,
                                                                'DD/MM/RRRR')))
          F
             ON A.MSISDIN_NO = F.MSISDIN_NO
          LEFT OUTER JOIN
          (SELECT MSISDIN_NO, LAST_ACTIVITY_DATE_KEY Voice_last_activity_date
             FROM ACTIVEBASEVOICE
            WHERE LAST_ACTIVITY_DATE_KEY IN (SELECT DATE_KEY
                                               FROM DATE_DIM
                                              WHERE DATE_VALUE =
                                                       TO_DATE (SYSDATE - 7,
                                                                'DD/MM/RRRR')))
          G
             ON A.MSISDIN_NO = G.MSISDIN_NO
          LEFT OUTER JOIN
          (  SELECT V372_CALLINGPARTYNUMBER,
                    SUM (V35_RATE_USAGE) / 60 MONTHLY_Call_Minutes
               FROM L3_VOICE
              WHERE V387_CHARGINGTIME_KEY IN (SELECT DATE_KEY
                                                FROM DATE_DIM
                                               WHERE DATE_VALUE =
                                                        TO_DATE (SYSDATE - 7,
                                                                 'DD/MM/RRRR'))
           GROUP BY V372_CALLINGPARTYNUMBER) L
             ON L.V372_CALLINGPARTYNUMBER = A.MSISDIN_NO
          LEFT OUTER JOIN
          (  SELECT V372_CALLINGPARTYNUMBER,
                    SUM (V35_RATE_USAGE) / 60 MONTHLY_Call_Minutes_Received
               FROM L3_VOICE
              WHERE     V387_CHARGINGTIME_KEY IN (SELECT DATE_KEY
                                                    FROM DATE_DIM
                                                   WHERE DATE_VALUE =
                                                            TO_DATE (
                                                               SYSDATE - 7,
                                                               'DD/MM/RRRR'))
                    AND V378_SERVICEFLOW = 2
           GROUP BY V372_CALLINGPARTYNUMBER) I
             ON I.V372_CALLINGPARTYNUMBER = A.MSISDIN_NO
          LEFT OUTER JOIN
          (  SELECT G372_CALLINGPARTYNUMBER,
                    SUM (G384_TOTALFLUX) MONTHLY_Data_Volume_Used,
                    COUNT (G384_TOTALFLUX) MONTHLY_Data_Pack_by_Count,
                    COUNT (G384_TOTALFLUX) MONTHLY_Pack_by_Count
               FROM L3_DATA
              WHERE G383_CHARGINGTIME_KEY IN (SELECT DATE_KEY
                                                FROM DATE_DIM
                                               WHERE DATE_VALUE =
                                                        TO_DATE (SYSDATE - 7,
                                                                 'DD/MM/RRRR'))
           GROUP BY G372_CALLINGPARTYNUMBER) J
             ON J.G372_CALLINGPARTYNUMBER = A.MSISDIN_NO
          LEFT OUTER JOIN
          (  SELECT RE6_PRI_IDENTITY,
                    SUM (RE3_RECHARGE_AMT) MONTHLY_Recharge_Amount,
                    COUNT (RE3_RECHARGE_AMT) MONTHLY_Recharge_Count,
                    SUM (RE3_RECHARGE_AMT) MONTHLY_RECHARGE_Revenue
               FROM L3_RECHARGE
              WHERE RE30_ENTRY_DATE_KEY IN (SELECT DATE_KEY
                                              FROM DATE_DIM
                                             WHERE DATE_VALUE =
                                                      TO_DATE (SYSDATE - 7,
                                                               'DD/MM/RRRR'))
           GROUP BY RE6_PRI_IDENTITY) O
             ON A.MSISDIN_NO = O.RE6_PRI_IDENTITY
          LEFT OUTER JOIN
          (  SELECT R375_CHARGINGPARTYNUMBER,
                    SUM (R41_DEBIT_AMOUNT) Monthly_Vas_Revenue
               FROM L3_RECURRING
              WHERE R377_CYCLEBEGINTIME_KEY IN (SELECT DATE_KEY
                                                  FROM DATE_DIM
                                                 WHERE DATE_VALUE =
                                                          TO_DATE (
                                                             SYSDATE - 7,
                                                             'DD/MM/RRRR'))
           GROUP BY R375_CHARGINGPARTYNUMBER) M
             ON A.MSISDIN_NO = M.R375_CHARGINGPARTYNUMBER
          LEFT OUTER JOIN
          (  SELECT S22_PRI_IDENTITY,
                    SUM (S22_PRI_IDENTITY) MONTHLY_SMS_SEND_COUNT
               FROM L3_SMS
              WHERE S387_CHARGINGTIME_KEY IN (SELECT DATE_KEY
                                                FROM DATE_DIM
                                               WHERE DATE_VALUE =
                                                        TO_DATE (SYSDATE - 7,
                                                                 'DD/MM/RRRR'))
           GROUP BY S22_PRI_IDENTITY) N
             ON A.MSISDIN_NO = N.S22_PRI_IDENTITY;


