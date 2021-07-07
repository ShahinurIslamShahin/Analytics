--
-- R_PACKAGE_WISE_PROFIT_PERCENTILE  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.R_PACKAGE_WISE_PROFIT_PERCENTILE IS
    VDATE_KEY       NUMBER;
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE,'RRRRMMDD');
   

    
INSERT INTO PACKAGE_WISE_PROFIT_PERCENTILE



SELECT J. DATE_KEY,
       K.DATE_VALUE,
       J.PRODUCT_ID,
       P.PRODUCT_NAME,
       J.VOICE_PROFIT,
       J.SMS_PROFIT,
       J.DATA_PROFIT,
       J.TOTAL_PROFIT,
       ROUND((J.VOICE_PROFIT/J.TOTAL_PROFIT)*100,2) VOICE_PROFIT_PERCENTILE,
       ROUND((J.SMS_PROFIT/J.TOTAL_PROFIT)*100,2) SMS_PROFIT_PERCENTILE,
       ROUND((J.DATA_PROFIT/J.TOTAL_PROFIT)*100,2) DATA_PROFIT_PERCENTILE
       FROM
(SELECT D.DATE_KEY,
       D.PRODUCT_ID,
       NVL (E.VOICE_PROFIT, 0) VOICE_PROFIT,
       ROUND (NVL (F.SMS_PROFIT, 0), 2) SMS_PROFIT,
       NVL (H.DATA_PROFIT, 0) DATA_PROFIT,
       (  NVL (E.VOICE_PROFIT, 0)
        + ROUND (NVL (F.SMS_PROFIT, 0), 2)
        + NVL (H.DATA_PROFIT, 0))
          TOTAL_PROFIT
       
  FROM (SELECT UNIQUE A.DATE_KEY, A.PRODUCT_ID
          FROM PACKAGE_WISE_VOICE_PROFIT A
          where a.date_key=(select date_key from date_dim where date_value=to_date(sysdate-1,'dd/mm/rrrr'))
        UNION
        SELECT UNIQUE B.DATE_KEY, B.PRODUCT_ID
          FROM PACKAGE_WISE_SMS_PROFIT B
          where b.date_key=(select date_key from date_dim where date_value=to_date(sysdate-1,'dd/mm/rrrr'))
        UNION
        SELECT UNIQUE C.DATE_KEY, C.PRODUCT_ID
          FROM PACKAGE_WISE_DATA_PROFIT C
          where c.date_key=(select date_key from date_dim where date_value=to_date(sysdate-1,'dd/mm/rrrr'))) D
       LEFT OUTER JOIN
       (  SELECT V.DATE_KEY,
                 V.PRODUCT_ID,
                 SUM (V.OFFNET_PROFIT + V.ONNET_PROFIT + V.FREE_MIN_PROFIT)
                    VOICE_PROFIT
            FROM PACKAGE_WISE_VOICE_PROFIT V
            where v.date_key=(select date_key from date_dim where date_value=to_date(sysdate-1,'dd/mm/rrrr'))
        GROUP BY V.DATE_KEY, V.PRODUCT_ID) E
          ON D.DATE_KEY = E.DATE_KEY AND D.PRODUCT_ID = E.PRODUCT_ID
       LEFT OUTER JOIN
       (  SELECT S.DATE_KEY,
                 S.PRODUCT_ID,
                 SUM (S.SMS_PROFIT + S.FREE_SMS_PROFIT) SMS_PROFIT
            FROM PACKAGE_WISE_SMS_PROFIT S
            where s.date_key=(select date_key from date_dim where date_value=to_date(sysdate-1,'dd/mm/rrrr'))
        GROUP BY S.DATE_KEY, S.PRODUCT_ID) F
          ON D.DATE_KEY = F.DATE_KEY AND D.PRODUCT_ID = F.PRODUCT_ID
       LEFT OUTER JOIN
       (  SELECT G.DATE_KEY,
                 G.PRODUCT_ID,
                 SUM (G.FREE_DATA_PROFIT + G.PPU_DATA_PROFIT) DATA_PROFIT
            FROM PACKAGE_WISE_DATA_PROFIT G
            where g.date_key=(select date_key from date_dim where date_value=to_date(sysdate-1,'dd/mm/rrrr'))
        GROUP BY G.DATE_KEY, G.PRODUCT_ID) H
          ON D.DATE_KEY = H.DATE_KEY AND D.PRODUCT_ID = H.PRODUCT_ID) J
          INNER JOIN DATE_DIM K ON K.DATE_KEY=J.DATE_KEY
          INNER JOIN PRODUCT_DIM P ON P.PRODUCT_ID=J.PRODUCT_ID
          WHERE J.TOTAL_PROFIT>0;
             
             
             
      COMMIT;
END;
/

