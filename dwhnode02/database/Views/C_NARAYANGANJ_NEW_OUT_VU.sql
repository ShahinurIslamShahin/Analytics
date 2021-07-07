--
-- C_NARAYANGANJ_NEW_OUT_VU  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.C_NARAYANGANJ_NEW_OUT_VU
(MSISDN, OUT_TIME, UPAZILA, DISTRICT)
BEQUEATH DEFINER
AS 
select z.msisdn,z.timestamp as out_time, z.upazila, z.district
    from
    (select x.timestamp, x.msisdn,x.v381_callingcellid, x.v383_calledcellid, x.upazila, x.district,rank() over (partition by x.msisdn order by x.timestamp) as last_key
    from
    (select r.timestamp, r.msisdn,r.v381_callingcellid, r.v383_calledcellid, r.upazila, r.district 
    from
    (select  q.msisdn, q.timestamp ,q.v381_callingcellid, q.v383_calledcellid, q.upazila,q.district,  rank() over (partition by q.msisdn order by q.timestamp ) as last_key
    from
    (select p.v372_callingpartynumber as msisdn, to_char(to_date(p.call_date,'YYYY-MM-DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS') as timestamp , p.v381_callingcellid, p.v383_calledcellid, p.upazila,p.district
    from
    (select n.v372_callingpartynumber,n.date_value||n.v387_chargingtime_hour as call_date, n.v381_callingcellid, n.v383_calledcellid, m.upazila,m.district
    from zone_dim@dwh05todwh01 m,
    (select a.v381_callingcellid ,a.v372_callingpartynumber, to_char(b.date_value,'RRRRMMDD') as date_value,a.v387_chargingtime_hour,v383_calledcellid
    from l3_voice a, date_dim b, C_NARAYANGANJ_NEW_OUT c
    --FROM L2_VOICE_333@DWH05TODWH01 A, DATE_DIM B
    where v387_chargingtime_key  = (select a.date_key from date_dim a where a.date_value = to_date (sysdate-1,'DD/MM/RRRR'))--IN (SELECT A.DATE_KEY FROM DATE_DIM A WHERE A.DATE_VALUE BETWEEN TO_DATE ('06/04/2020','DD/MM/RRRR') AND TO_DATE ('17/04/2020','DD/MM/RRRR'))
    and a.v372_callingpartynumber =c.msisdn
    --AND C.STATUS='N'
    and c.date_key = (select a.date_key from date_dim a where a.date_value = to_date (sysdate-1,'DD/MM/RRRR'))
    and a.v387_chargingtime_key=b.date_key
    group by a.v381_callingcellid ,a.v372_callingpartynumber,b.date_value,a.v387_chargingtime_hour,v383_calledcellid)n
    where m.cgi=n.v381_callingcellid
    --and m.zila_code='67'
    group by  n.v372_callingpartynumber,n.date_value||n.v387_chargingtime_hour, n.v381_callingcellid, n.v383_calledcellid, m.upazila,m.district
    order by n.v372_callingpartynumber,m.district)p
    )q
    )r
    where last_key=1
    union all 
    select r.timestamp, r.msisdn,r.v381_callingcellid, r.v383_calledcellid, r.upazila, r.district 
    from
    (select  q.msisdn, q.timestamp ,q.v381_callingcellid, q.v383_calledcellid, q.upazila,q.district,  rank() over (partition by q.msisdn order by q.timestamp) as last_key
    from
    (select p.v373_calledpartynumber as msisdn, to_char(to_date(p.call_date,'YYYY-MM-DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS') as timestamp , p.v381_callingcellid, p.v383_calledcellid, p.upazila,p.district
    from
    (select n.v373_calledpartynumber,n.date_value||n.v387_chargingtime_hour as call_date, n.v381_callingcellid, n.v383_calledcellid, m.upazila,m.district
    from zone_dim@dwh05todwh01 m,
    (select a.v381_callingcellid ,a.v373_calledpartynumber, to_char(b.date_value,'RRRRMMDD') as date_value,a.v387_chargingtime_hour,v383_calledcellid
    from l3_voice a, date_dim b, C_NARAYANGANJ_NEW_OUT c
    --FROM L2_VOICE_333@DWH05TODWH01 A, DATE_DIM B
    where v387_chargingtime_key  = (select a.date_key from date_dim a where a.date_value = to_date (sysdate-1,'DD/MM/RRRR'))--IN (SELECT A.DATE_KEY FROM DATE_DIM A WHERE A.DATE_VALUE BETWEEN TO_DATE ('06/04/2020','DD/MM/RRRR') AND TO_DATE ('17/04/2020','DD/MM/RRRR'))
    and a.v373_calledpartynumber =c.msisdn
    --AND C.STATUS='N'
    and c.date_key = (select a.date_key from date_dim a where a.date_value = to_date (sysdate-1,'DD/MM/RRRR'))
    and a.v387_chargingtime_key=b.date_key
    group by a.v381_callingcellid ,a.v373_calledpartynumber,b.date_value,a.v387_chargingtime_hour,v383_calledcellid)n
    where m.cgi=n.v383_calledcellid
    --and m.zila_code='67'
    group by  n.v373_calledpartynumber,n.date_value||n.v387_chargingtime_hour, n.v381_callingcellid, n.v383_calledcellid, m.upazila,m.district
    order by n.v373_calledpartynumber,m.district)p
    )q
    )r
    where last_key=1)x
    )z
    where last_key=1;


