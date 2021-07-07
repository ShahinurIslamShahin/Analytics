--
-- FIRST_DATE_IN_NETWORK  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.FIRST_DATE_IN_NETWORK
(MSISDIN, DATE_VALUE)
BEQUEATH DEFINER
AS 
SELECT MSISDIN,DATE_VALUE FROM
DATE_DIM,
(
SELECT MSISDIN_NO MSISDIN, FIRST_ACTIVE_DATE
FROM AGEONNETWROK INNER JOIN DATE_DIM ON DATE_KEY = FIRST_ACTIVE_DATE
WHERE  DATE_VALUE  BETWEEN TO_DATE ('2020/01/13', 'yyyy/mm/dd')
AND TO_DATE ('2020/02/01', 'yyyy/mm/dd')
GROUP BY MSISDIN_NO, FIRST_ACTIVE_DATE)
WHERE DATE_KEY=FIRST_ACTIVE_DATE;


