--
-- CLMA18  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.CLMA18
(CELL_NAME, TOTAL_REVENUE)
BEQUEATH DEFINER
AS 
select CELL_NAME, TOTAL_REVENUE from location_dim,
   (SELECT A.V381_CALLINGCELLID,
          COALESCE (MO_VOICE_REVENUE, 0) + COALESCE (SMS_REVENUE, 0)+COALESCE (DATA_REVENUE, 0) + COALESCE (MT_VOICE_REVENUE, 0) TOTAL_REVENUE
     FROM (  SELECT V381_CALLINGCELLID
               FROM L3_VOICE
              WHERE V387_CHARGINGTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 4, 'DD/MM/RRRR'))
           GROUP BY V381_CALLINGCELLID
           UNION
             SELECT V383_CALLEDCELLID
               FROM L3_VOICE
              WHERE V387_CHARGINGTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 4, 'DD/MM/RRRR'))
           GROUP BY V383_CALLEDCELLID
           UNION
             SELECT G379_CALLINGCELLID
               FROM L3_data
              WHERE G383_CHARGINGTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 4, 'DD/MM/RRRR'))
           GROUP BY G379_CALLINGCELLID
           UNION
             SELECT S381_CALLINGCELLID
               FROM L3_sms
              WHERE S387_CHARGINGTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 4, 'DD/MM/RRRR'))
           GROUP BY S381_CALLINGCELLID) A
          LEFT OUTER JOIN
          (  SELECT V381_CALLINGCELLID, SUM (V41_DEBIT_AMOUNT) MO_VOICE_REVENUE
               FROM L3_VOICE
              WHERE     V387_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 4, 'DD/MM/RRRR'))
                    AND V403_ROAMSTATE != 3
           GROUP BY V381_CALLINGCELLID) B
             ON A.V381_CALLINGCELLID = B.V381_CALLINGCELLID
          LEFT OUTER JOIN
          (  SELECT G379_CALLINGCELLID, SUM (G41_DEBIT_AMOUNT) DATA_REVENUE
               FROM L3_DATA
              WHERE G383_CHARGINGTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 4, 'DD/MM/RRRR'))
           GROUP BY G379_CALLINGCELLID) C
             ON A.V381_CALLINGCELLID = C.G379_CALLINGCELLID
          LEFT OUTER JOIN
          (  SELECT S381_CALLINGCELLID, SUM (S41_DEBIT_AMOUNT) SMS_REVENUE
               FROM L3_SMS
              WHERE S387_CHARGINGTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 4, 'DD/MM/RRRR'))
           GROUP BY S381_CALLINGCELLID) D
             ON A.V381_CALLINGCELLID = D.S381_CALLINGCELLID
          LEFT OUTER JOIN
          (  SELECT V383_CALLEDCELLID, SUM (V41_DEBIT_AMOUNT) MT_VOICE_REVENUE
               FROM L3_VOICE
              WHERE     V387_CHARGINGTIME_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 4, 'DD/MM/RRRR'))
                    AND V403_ROAMSTATE != 3
           GROUP BY V383_CALLEDCELLID) E
             ON A.V381_CALLINGCELLID = E.V383_CALLEDCELLID
             
 )
where CGI_ECGI=V381_CALLINGCELLID;


