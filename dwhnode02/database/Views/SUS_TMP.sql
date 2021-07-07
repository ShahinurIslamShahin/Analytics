--
-- SUS_TMP  (View) 
--
CREATE OR REPLACE FORCE VIEW DWH_USER.SUS_TMP
(SAF_MSISDN)
BEQUEATH DEFINER
AS 
select /*+parallel(p,16)*/ unique SAF_MSISDN from bi_saf@dwh05toetsaf p
where SAF_ENTRYDATE between to_date('20/12/2020','dd/mm/rrrr') and to_date('09/02/2021','dd/mm/rrrr')
and SAF_REG_TYPE_DESC in ('PREPAID','NEW_POSTPAID','PREPAID_CAMPAIGN','POSTPAID','NEW_PREPAID');


