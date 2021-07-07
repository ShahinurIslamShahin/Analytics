--
-- KH_BIN36  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.KH_BIN36
(X, Y, Z, MO_REVENUE, DURATION, 
 VOLUME)
BEQUEATH DEFINER
AS 
(SELECT X,
           Y,
           Z,
           MO_REVENUE,
           DURATION,
           VOLUME
      FROM (  select * from kh_mo_revenue)
           FULL JOIN
           (  select * from kh_mo_DURATION)
              ON X = Y
           FULL JOIN
           (  select * from kh_mo_volume)
              ON X = Z OR Y = Z);


