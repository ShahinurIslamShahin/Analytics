--
-- GAZIPUR_LEAVE_SATATUS  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.GAZIPUR_LEAVE_SATATUS
(TIMESTAMP, MSISDN, V381_CALLINGCELLID, V383_CALLEDCELLID, UPAZILA, 
 DISTRICT)
BEQUEATH DEFINER
AS 
SELECT Z.TIMESTAMP, Z.MSISDN,Z.V381_CALLINGCELLID, Z.V383_CALLEDCELLID, Z.UPAZILA, Z.DISTRICT
    FROM
    (SELECT X.TIMESTAMP, X.MSISDN,X.V381_CALLINGCELLID, X.V383_CALLEDCELLID, X.UPAZILA, X.DISTRICT,RANK() OVER (PARTITION BY X.MSISDN ORDER BY X.TIMESTAMP DESC) AS LAST_KEY
    FROM
    (SELECT R.TIMESTAMP, R.MSISDN,R.V381_CALLINGCELLID, R.V383_CALLEDCELLID, R.UPAZILA, R.DISTRICT 
    FROM
    (SELECT  Q.MSISDN, Q.TIMESTAMP ,Q.V381_CALLINGCELLID, Q.V383_CALLEDCELLID, Q.UPAZILA,Q.DISTRICT,  RANK() OVER (PARTITION BY Q.MSISDN ORDER BY Q.TIMESTAMP DESC) AS LAST_KEY
    FROM
    (SELECT P.V372_CALLINGPARTYNUMBER AS MSISDN, TO_CHAR(TO_DATE(P.CALL_DATE,'YYYY-MM-DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS') AS TIMESTAMP , P.V381_CALLINGCELLID, P.V383_CALLEDCELLID, P.UPAZILA,P.DISTRICT
    FROM
    (SELECT N.V372_CALLINGPARTYNUMBER,N.DATE_VALUE||N.V387_CHARGINGTIME_HOUR AS CALL_DATE, N.V381_CALLINGCELLID, N.V383_CALLEDCELLID, M.UPAZILA,M.DISTRICT
    FROM ZONE_DIM@DWH05TODWH01 M,
    (SELECT A.V381_CALLINGCELLID ,A.V372_CALLINGPARTYNUMBER, TO_CHAR(B.DATE_VALUE,'RRRRMMDD') AS DATE_VALUE,A.V387_CHARGINGTIME_HOUR,V383_CALLEDCELLID
    FROM L3_VOICE A, DATE_DIM B, gazipur_SATATUS C
    --FROM L2_VOICE_333@DWH05TODWH01 A, DATE_DIM B
    WHERE V387_CHARGINGTIME_KEY IN (SELECT A.DATE_KEY FROM DATE_DIM A WHERE A.DATE_VALUE BETWEEN TO_DATE ('06/04/2020','DD/MM/RRRR') AND TO_DATE ('15/04/2020','DD/MM/RRRR'))
    AND A.V372_CALLINGPARTYNUMBER =C.MSISDN
    AND C.STATUS='N'
    AND A.V387_CHARGINGTIME_KEY=B.DATE_KEY
    GROUP BY A.V381_CALLINGCELLID ,A.V372_CALLINGPARTYNUMBER,B.DATE_VALUE,A.V387_CHARGINGTIME_HOUR,V383_CALLEDCELLID)N
    WHERE M.CGI=N.V381_CALLINGCELLID
    GROUP BY  N.V372_CALLINGPARTYNUMBER,N.DATE_VALUE||N.V387_CHARGINGTIME_HOUR, N.V381_CALLINGCELLID, N.V383_CALLEDCELLID, M.UPAZILA,M.DISTRICT
    ORDER BY N.V372_CALLINGPARTYNUMBER,M.DISTRICT)P
    )Q
    )R
    WHERE LAST_KEY=1
    UNION ALL 
    SELECT R.TIMESTAMP, R.MSISDN,R.V381_CALLINGCELLID, R.V383_CALLEDCELLID, R.UPAZILA, R.DISTRICT 
    FROM
    (SELECT  Q.MSISDN, Q.TIMESTAMP ,Q.V381_CALLINGCELLID, Q.V383_CALLEDCELLID, Q.UPAZILA,Q.DISTRICT,  RANK() OVER (PARTITION BY Q.MSISDN ORDER BY Q.TIMESTAMP DESC) AS LAST_KEY
    FROM
    (SELECT P.V387_CHARGINGTIME_KEY AS MSISDN, TO_CHAR(TO_DATE(P.CALL_DATE,'YYYY-MM-DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS') AS TIMESTAMP , P.V381_CALLINGCELLID, P.V383_CALLEDCELLID, P.UPAZILA,P.DISTRICT
    FROM
    (SELECT N.V387_CHARGINGTIME_KEY,N.DATE_VALUE||N.V387_CHARGINGTIME_HOUR AS CALL_DATE, N.V381_CALLINGCELLID, N.V383_CALLEDCELLID, M.UPAZILA,M.DISTRICT
    FROM ZONE_DIM@DWH05TODWH01 M,
    (SELECT A.V381_CALLINGCELLID ,A.V387_CHARGINGTIME_KEY, TO_CHAR(B.DATE_VALUE,'RRRRMMDD') AS DATE_VALUE,A.V387_CHARGINGTIME_HOUR,V383_CALLEDCELLID
    FROM L3_VOICE A, DATE_DIM B, gazipur_SATATUS C
    --FROM L2_VOICE_333@DWH05TODWH01 A, DATE_DIM B
    WHERE V387_CHARGINGTIME_KEY IN (SELECT A.DATE_KEY FROM DATE_DIM A WHERE A.DATE_VALUE BETWEEN TO_DATE ('06/04/2020','DD/MM/RRRR') AND TO_DATE ('15/04/2020','DD/MM/RRRR'))
    AND A.V387_CHARGINGTIME_KEY =C.MSISDN
    AND C.STATUS='N'
    AND A.V387_CHARGINGTIME_KEY=B.DATE_KEY
    GROUP BY A.V381_CALLINGCELLID ,A.V387_CHARGINGTIME_KEY,B.DATE_VALUE,A.V387_CHARGINGTIME_HOUR,V383_CALLEDCELLID)N
    WHERE M.CGI=N.V383_CALLEDCELLID
    GROUP BY  N.V387_CHARGINGTIME_KEY,N.DATE_VALUE||N.V387_CHARGINGTIME_HOUR, N.V381_CALLINGCELLID, N.V383_CALLEDCELLID, M.UPAZILA,M.DISTRICT
    ORDER BY N.V387_CHARGINGTIME_KEY,M.DISTRICT)P
    )Q
    )R
    WHERE LAST_KEY=1)X
    )Z
    WHERE LAST_KEY=1;


