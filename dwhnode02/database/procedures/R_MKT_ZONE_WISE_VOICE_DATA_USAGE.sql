--
-- R_MKT_ZONE_WISE_VOICE_DATA_USAGE  (Procedure) 
--
CREATE OR REPLACE PROCEDURE DWH_USER.R_MKT_ZONE_WISE_VOICE_DATA_USAGE IS
    VDATE_KEY       NUMBER;
BEGIN

SELECT DATE_KEY INTO VDATE_KEY
FROM DATE_DIM WHERE TO_CHAR(DATE_VALUE,'RRRRMMDD')=TO_CHAR(SYSDATE-1,'RRRRMMDD');



    --EXECUTE IMMEDIATE  'TRUNCATE TABLE PKPI DROP STORAGE';
    --EXECUTE IMMEDIATE 'ALTER TABLE PKPI TRUNCATE PARTITION PKPI_||VDATE_KEY DROP STORAGE';
    
DELETE MKT_ZONE_WISE_VOICE_DATA_USAGE WHERE PDR_DATE_KEY=VDATE_KEY;
COMMIT;
    
INSERT INTO MKT_ZONE_WISE_VOICE_DATA_USAGE


SELECT A.MSISDN ,A.PRODUCT_NAME,A.DATE_VALUE,A.CGI,A.SITE_ID, A.UPAZILA, A.DISTRICT, A.DIVISION,DATA_VOLUME_MB,MOC_DURATION,VDATE_KEY,A.CHARGING_HOUR,A.CHARGING_MINUTE FROM 
(
(select /*+PARALLEL(P,15)*/G372_CALLINGPARTYNUMBER MSISDN ,PRODUCT_NAME,DATE_VALUE,CHARGING_HOUR,CHARGING_MINUTE,CGI,SITE_ID, UPAZILA, DISTRICT, DIVISION
from date_dim,zone_dim,product_dim,
(SELECT G372_CALLINGPARTYNUMBER,G401_MAINOFFERINGID,G383_CHARGINGTIME_KEY,CHARGING_HOUR,CHARGING_MINUTE,G379_CALLINGCELLID,SUM(G384_TOTALFLUX)/1048576 DATA_VOLUME_MB FROM
(SELECT /*+PARALLEL(P,15)*/ G372_CALLINGPARTYNUMBER,G401_MAINOFFERINGID,G383_CHARGINGTIME_KEY,SUBSTR(G383_CHARGINGTIME_HOUR,1,2) CHARGING_HOUR,
         SUBSTR(G383_CHARGINGTIME_HOUR,3,2)CHARGING_MINUTE,

CASE 
WHEN LENGTH(G379_CALLINGCELLID)=15
THEN G379_CALLINGCELLID
WHEN LENGTH(G379_CALLINGCELLID)=30
THEN SUBSTR(G379_CALLINGCELLID,16,15)
END G379_CALLINGCELLID,
G384_TOTALFLUX
FROM L3_DATA P
WHERE (G383_CHARGINGTIME_KEY = (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE(sysdate-1,'DD/MM/RRRR')))


)
GROUP BY  G372_CALLINGPARTYNUMBER,G401_MAINOFFERINGID,G383_CHARGINGTIME_KEY,CHARGING_HOUR,CHARGING_MINUTE,G379_CALLINGCELLID

) P
WHERE G401_MAINOFFERINGID= PRODUCT_ID AND  G383_CHARGINGTIME_KEY=DATE_KEY AND G379_CALLINGCELLID=CGI  
)
UNION

(select /*+PARALLEL(P,15)*/V372_CALLINGPARTYNUMBER MSISDN ,PRODUCT_NAME,DATE_VALUE,CHARGING_HOUR,CHARGING_MINUTE,CGI,SITE_ID, UPAZILA, DISTRICT, DIVISION
from date_dim,zone_dim,product_dim,
(SELECT V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID,V387_CHARGINGTIME_KEY,CHARGING_HOUR,CHARGING_MINUTE,V381_CALLINGCELLID,MOC_DURATION  FROM 
(SELECT /*+PARALLEL(P,15)*/  V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID,V387_CHARGINGTIME_KEY,SUBSTR(V387_CHARGINGTIME_HOUR,1,2) CHARGING_HOUR,
         SUBSTR(V387_CHARGINGTIME_HOUR,3,2) CHARGING_MINUTE,V381_CALLINGCELLID, SUM( V35_RATE_USAGE)/60 MOC_DURATION 
FROM  L3_VOICE  P
WHERE  V378_SERVICEFLOW=1 AND
(V387_CHARGINGTIME_KEY = (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE(sysdate-1,'DD/MM/RRRR')))

                                                    
GROUP BY V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID,V387_CHARGINGTIME_KEY,SUBSTR(V387_CHARGINGTIME_HOUR,1,2),SUBSTR(V387_CHARGINGTIME_HOUR,3,2),V381_CALLINGCELLID
)) P
WHERE V397_MAINOFFERINGID= PRODUCT_ID AND  V387_CHARGINGTIME_KEY=DATE_KEY AND V381_CALLINGCELLID=CGI  

))A

LEFT OUTER JOIN


(select /*+PARALLEL(P,15)*/G372_CALLINGPARTYNUMBER MSISDN ,PRODUCT_NAME,DATE_VALUE,CHARGING_HOUR,CHARGING_MINUTE,CGI,SITE_ID, UPAZILA, DISTRICT, DIVISION,DATA_VOLUME_MB
from date_dim,zone_dim,product_dim,
(SELECT G372_CALLINGPARTYNUMBER,G401_MAINOFFERINGID,G383_CHARGINGTIME_KEY,CHARGING_HOUR,CHARGING_MINUTE,G379_CALLINGCELLID,SUM(G384_TOTALFLUX)/1048576 DATA_VOLUME_MB FROM
(SELECT /*+PARALLEL(P,15)*/ G372_CALLINGPARTYNUMBER,G401_MAINOFFERINGID,G383_CHARGINGTIME_KEY,SUBSTR(G383_CHARGINGTIME_HOUR,1,2) CHARGING_HOUR,
         SUBSTR(G383_CHARGINGTIME_HOUR,3,2)CHARGING_MINUTE,

CASE 
WHEN LENGTH(G379_CALLINGCELLID)=15
THEN G379_CALLINGCELLID
WHEN LENGTH(G379_CALLINGCELLID)=30
THEN SUBSTR(G379_CALLINGCELLID,16,15)
END G379_CALLINGCELLID,
G384_TOTALFLUX
FROM L3_DATA P
WHERE (G383_CHARGINGTIME_KEY = (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE(sysdate-1,'DD/MM/RRRR')))


)
GROUP BY  G372_CALLINGPARTYNUMBER,G401_MAINOFFERINGID,G383_CHARGINGTIME_KEY,CHARGING_HOUR,CHARGING_MINUTE,G379_CALLINGCELLID

) P
WHERE G401_MAINOFFERINGID= PRODUCT_ID AND  G383_CHARGINGTIME_KEY=DATE_KEY AND G379_CALLINGCELLID=CGI  
)B ON  A.MSISDN=B.MSISDN AND A.PRODUCT_NAME = B.PRODUCT_NAME AND A.DATE_VALUE=B.DATE_VALUE AND A.CGI=B.CGI AND A.SITE_ID=B.SITE_ID AND 
       A.UPAZILA=B.UPAZILA AND  A.DISTRICT=B.DISTRICT AND A.DIVISION=B.DIVISION AND A.CHARGING_HOUR=B.CHARGING_HOUR AND A.CHARGING_MINUTE=B.CHARGING_MINUTE
 
LEFT OUTER JOIN 


(select /*+PARALLEL(P,15)*/V372_CALLINGPARTYNUMBER MSISDN ,PRODUCT_NAME,DATE_VALUE,CHARGING_HOUR,CHARGING_MINUTE,CGI,SITE_ID, UPAZILA, DISTRICT, DIVISION,MOC_DURATION
from date_dim,zone_dim,product_dim,
(SELECT V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID,V387_CHARGINGTIME_KEY,CHARGING_HOUR,CHARGING_MINUTE,V381_CALLINGCELLID,MOC_DURATION  FROM 
(SELECT /*+PARALLEL(P,15)*/  V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID,V387_CHARGINGTIME_KEY,SUBSTR(V387_CHARGINGTIME_HOUR,1,2) CHARGING_HOUR,
         SUBSTR(V387_CHARGINGTIME_HOUR,3,2) CHARGING_MINUTE,V381_CALLINGCELLID, SUM( V35_RATE_USAGE)/60 MOC_DURATION 
FROM  L3_VOICE  P
WHERE  V378_SERVICEFLOW=1 AND
(V387_CHARGINGTIME_KEY = (SELECT DATE_KEY FROM DATE_DIM  WHERE DATE_VALUE = TO_DATE(sysdate-1,'DD/MM/RRRR')))

                                                    
GROUP BY V372_CALLINGPARTYNUMBER,V397_MAINOFFERINGID,V387_CHARGINGTIME_KEY,SUBSTR(V387_CHARGINGTIME_HOUR,1,2),SUBSTR(V387_CHARGINGTIME_HOUR,3,2),V381_CALLINGCELLID
)) P
WHERE V397_MAINOFFERINGID= PRODUCT_ID AND  V387_CHARGINGTIME_KEY=DATE_KEY AND V381_CALLINGCELLID=CGI  

)C ON  A.MSISDN=C.MSISDN AND A.PRODUCT_NAME = C.PRODUCT_NAME AND A.DATE_VALUE=C.DATE_VALUE AND A.CGI=C.CGI AND A.SITE_ID=C.SITE_ID AND 
       A.UPAZILA=C.UPAZILA AND  A.DISTRICT=C.DISTRICT AND A.DIVISION=C.DIVISION AND A.CHARGING_HOUR=C.CHARGING_HOUR AND A.CHARGING_MINUTE=C.CHARGING_MINUTE
;
    COMMIT;
END;
/

