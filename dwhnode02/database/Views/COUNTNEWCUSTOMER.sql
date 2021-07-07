--
-- COUNTNEWCUSTOMER  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.COUNTNEWCUSTOMER
(A, COUNT1, B, COUNT2)
BEQUEATH DEFINER
AS 
SELECT A,
          COUNT1,
          B,
          COUNT2
     FROM (  SELECT V381_CALLINGCELLID A, COUNT (MSISDIN_NO) Count1
               FROM AGEONNETWROK
                    INNER JOIN L3_VOICE ON MSISDIN_NO = V372_CALLINGPARTYNUMBER
              WHERE     FIRST_ACTIVE_DATE =
                           (SELECT DATE_KEY
                              FROM DATE_DIM
                             WHERE DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                    AND V381_CALLINGCELLID IS NOT NULL
           GROUP BY V381_CALLINGCELLID)
          FULL JOIN
          (  SELECT G379_CALLINGCELLID B, COUNT (MSISDIN_NO) COUNT2
               FROM AGEONNETWROK
                    INNER JOIN L3_DATA ON MSISDIN_NO = G372_CALLINGPARTYNUMBER
              WHERE     FIRST_ACTIVE_DATE =
                           (SELECT DATE_KEY
                              FROM DATE_DIM
                             WHERE DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                    AND G379_CALLINGCELLID IS NOT NULL
           GROUP BY G379_CALLINGCELLID)
             ON A = B;


