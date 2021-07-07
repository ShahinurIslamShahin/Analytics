--
-- BIN7JOINVOICEDATA  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.BIN7JOINVOICEDATA
(V_CELLID, G_CELLID, TOTAL_COUNT)
BEQUEATH DEFINER
AS 
SELECT V_CELLID,
          G_CELLID,
          COALESCE (MSISDN, 0) + COALESCE (MSISDN1, 0) AS TOTAL_COUNT
     FROM (   
 select V_CELLID,COUNT (V372_CALLINGPARTYNUMBER) MSISDN
 from
 (SELECT V381_CALLINGCELLID V_CELLID,
                    V372_CALLINGPARTYNUMBER
               FROM L3_VOICE A
              WHERE     V387_CHARGINGTIME_KEY =
                           (SELECT DATE_KEY
                              FROM DATE_DIM
                             WHERE DATE_VALUE =
                                      TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
                    AND V402_CALLTYPE != 3
           GROUP BY V381_CALLINGCELLID,V372_CALLINGPARTYNUMBER
           )
           
           
      group by V_CELLID)
          FULL JOIN
          (  SELECT G_CELLID,COUNT (G372_CALLINGPARTYNUMBER) MSISDN1
 from
 (SELECT G379_CALLINGCELLID G_CELLID,
                    G372_CALLINGPARTYNUMBER
               FROM L3_DATA C
              WHERE G383_CHARGINGTIME_KEY =
                       (SELECT A.DATE_KEY
                          FROM DATE_DIM A
                         WHERE A.DATE_VALUE =
                                  TO_DATE (SYSDATE - 1, 'DD/MM/RRRR'))
           GROUP BY G379_CALLINGCELLID,G372_CALLINGPARTYNUMBER
           )
           
           
           group by G_CELLID
           
           )
             ON V_CELLID = G_CELLID;


