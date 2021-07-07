--
-- BIN12JOINMOREVENUEMTREVENUE  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.BIN12JOINMOREVENUEMTREVENUE
(P, Q, VOICE_REVENUE)
BEQUEATH DEFINER
AS 
SELECT P,
          Q,
          COALESCE (MO_REVENUE, 0) + COALESCE (MT_REVENUE, 0) VOICE_REVENUE
     FROM (  SELECT V381_CALLINGCELLID P, SUM (V41_DEBIT_AMOUNT) MO_REVENUE
               FROM L3_VOICE
              WHERE     V378_SERVICEFLOW = 1
                    AND V403_ROAMSTATE != 3
                    AND ETL_DATE_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY V381_CALLINGCELLID)
          FULL JOIN
          (  SELECT V383_CALLEDCELLID Q, SUM (V41_DEBIT_AMOUNT) MT_REVENUE
               FROM L3_VOICE
              WHERE     V378_SERVICEFLOW = 2
                    AND V403_ROAMSTATE != 3
                    AND ETL_DATE_KEY =
                           (SELECT A.DATE_KEY
                              FROM DATE_DIM A
                             WHERE A.DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY V383_CALLEDCELLID)
             ON P = Q;


