
list.of.packages <- c("bigrquery","plotly","scales","RColorBrewer","data.table","dplyr","knitr","corrplot","Hmisc","stats")
new.packages<-list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
if(length(new.packages)>0)
{install.packages(new.packages)}

library(bigrquery)
library(plotly)
library(scales)
library(RColorBrewer)
library(data.table)
library(dplyr)
library(knitr)
library(corrplot)
library(Hmisc)
library(stats)


project_HST = "hst-953-2019"


project_id <- "hst-953-2019"
options(httr_oauth_cache=TRUE)
run_query <- function(query){
  data <- query_exec(query, project=project_id, use_legacy_sql = FALSE)
  return(data)
}

#CTICU: Cardiothoracic Intensive Care Unit (CTICU) 
# CICU: Cardiac Intensive Care Unit
# CSICU: Cardiac Surgery Intensive Care Unit, we don't want this
ccu_categories <- run_query(
"      SELECT DISTINCT unittype
     FROM `physionet-data.eicu_crd.patient` 
"
)


ccu_patients <- run_query(
" SELECT patientunitstayid
FROM (
     SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn	
     FROM `physionet-data.eicu_crd.patient` 
     WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU'

    ) 
x
WHERE rn = 1
"
)


ccu_diagnoses <- run_query(
"SELECT patientunitstayid, diagnosisid, diagnosisoffset, diagnosisstring, icd9code
FROM `physionet-data.eicu_crd.diagnosis` d
WHERE patientunitstayid in 
(SELECT patientunitstayid
FROM (
     SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn	
     FROM `physionet-data.eicu_crd.patient` 
     WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU'

    ) 
x
WHERE rn = 1
)
"
)
#GROUP BY patientunitstayid, diagnosisid, diagnosisoffset, diagnosisstring, icd9code


ccu_labs1 <- run_query(
"
SELECT
  pvt.uniquepid, pvt.patienthealthsystemstayid, pvt.patientunitstayid
  , min(CASE WHEN labname = 'anion gap' THEN labresult ELSE null END) as ANIONGAP_min
  , max(CASE WHEN labname = 'anion gap' THEN labresult ELSE null END) as ANIONGAP_max
  , min(CASE WHEN labname = 'albumin' THEN labresult ELSE null END) as ALBUMIN_min
  , max(CASE WHEN labname = 'albumin' THEN labresult ELSE null END) as ALBUMIN_max
  , min(CASE WHEN labname = '-bands' THEN labresult ELSE null END) as BANDS_min
  , max(CASE WHEN labname = '-bands' THEN labresult ELSE null END) as BANDS_max
  , min(CASE WHEN labname = 'bicarbonate' THEN labresult ELSE null END) as BICARBONATE_min
  , max(CASE WHEN labname = 'bicarbonate' THEN labresult ELSE null END) as BICARBONATE_max
  , min(CASE WHEN labname = 'HCO3' THEN labresult ELSE null END) as HCO3_min -- HCO3 = bicarb, but eICU has both;
  , max(CASE WHEN labname = 'HCO3' THEN labresult ELSE null END) as HCO3_max -- elected not to combine them.
  , min(CASE WHEN labname = 'total bilirubin' THEN labresult ELSE null END) as BILIRUBIN_min
  , max(CASE WHEN labname = 'total bilirubin' THEN labresult ELSE null END) as BILIRUBIN_max
  , min(CASE WHEN labname = 'creatinine' THEN labresult ELSE null END) as CREATININE_min
  , max(CASE WHEN labname = 'creatinine' THEN labresult ELSE null END) as CREATININE_max
  , min(CASE WHEN labname = 'chloride' THEN labresult ELSE null END) as CHLORIDE_min
  , max(CASE WHEN labname = 'chloride' THEN labresult ELSE null END) as CHLORIDE_max
  , min(CASE WHEN labname = 'glucose' THEN labresult ELSE null END) as GLUCOSE_min
  , max(CASE WHEN labname = 'glucose' THEN labresult ELSE null END) as GLUCOSE_max
  , min(CASE WHEN labname = 'Hct' THEN labresult ELSE null END) as HEMATOCRIT_min
  , max(CASE WHEN labname = 'Hct' THEN labresult ELSE null END) as HEMATOCRIT_max
  , min(CASE WHEN labname = 'Hgb' THEN labresult ELSE null END) as HEMOGLOBIN_min
  , max(CASE WHEN labname = 'Hgb' THEN labresult ELSE null END) as HEMOGLOBIN_max
  , min(CASE WHEN labname = 'lactate' THEN labresult ELSE null END) as LACTATE_min
  , max(CASE WHEN labname = 'lactate' THEN labresult ELSE null END) as LACTATE_max
  , min(CASE WHEN labname = 'platelets x 1000' THEN labresult ELSE null END) as PLATELET_min
  , max(CASE WHEN labname = 'platelets x 1000' THEN labresult ELSE null END) as PLATELET_max
  , min(CASE WHEN labname = 'potassium' THEN labresult ELSE null END) as POTASSIUM_min
  , max(CASE WHEN labname = 'potassium' THEN labresult ELSE null END) as POTASSIUM_max
  , min(CASE WHEN labname = 'PTT' THEN labresult ELSE null END) as PTT_min
  , max(CASE WHEN labname = 'PTT' THEN labresult ELSE null END) as PTT_max
  , min(CASE WHEN labname = 'PT - INR' THEN labresult ELSE null END) as INR_min
  , max(CASE WHEN labname = 'PT - INR' THEN labresult ELSE null END) as INR_max
  , min(CASE WHEN labname = 'PT' THEN labresult ELSE null END) as PT_min
  , max(CASE WHEN labname = 'PT' THEN labresult ELSE null END) as PT_max
  , min(CASE WHEN labname = 'sodium' THEN labresult ELSE null END) as SODIUM_min
  , max(CASE WHEN labname = 'sodium' THEN labresult ELSE null end) as SODIUM_max
  , min(CASE WHEN labname = 'BUN' THEN labresult ELSE null end) as BUN_min
  , max(CASE WHEN labname = 'BUN' THEN labresult ELSE null end) as BUN_max
  , min(CASE WHEN labname = 'WBC x 1000' THEN labresult ELSE null end) as WBC_min
  , max(CASE WHEN labname = 'WBC x 1000' THEN labresult ELSE null end) as WBC_max


FROM
( -- begin query that extracts the data
  SELECT p.uniquepid, p.patienthealthsystemstayid, p.patientunitstayid, le.labname

  -- add in some sanity checks on the values; same checks from original MIMIC version
  -- the where clause below requires all labresult to be > 0, so these are only upper limit checks
  , CASE
     WHEN labname = 'albumin' and le.labresult >    10 THEN null -- g/dL 'ALBUMIN'
     WHEN labname = 'anion gap' and le.labresult > 10000 THEN null -- mEq/L 'ANION GAP'
     WHEN labname = '-bands' and le.labresult <     0 THEN null -- immature band forms, %
     WHEN labname = '-bands' and le.labresult >   100 THEN null -- immature band forms, %
     WHEN labname = 'bicarbonate' and le.labresult > 10000 THEN null -- mEq/L 'BICARBONATE'
     WHEN labname = 'HCO3' and le.labresult > 10000 THEN null -- mEq/L 'BICARBONATE'
     WHEN labname = 'bilirubin' and le.labresult >   150 THEN null -- mg/dL 'BILIRUBIN'
     WHEN labname = 'chloride' and le.labresult > 10000 THEN null -- mEq/L 'CHLORIDE'
     WHEN labname = 'creatinine' and le.labresult >   150 THEN null -- mg/dL 'CREATININE'
     WHEN labname = 'glucose' and le.labresult > 10000 THEN null -- mg/dL 'GLUCOSE'
     WHEN labname = 'Hct' and le.labresult >   100 THEN null -- % 'HEMATOCRIT'
     WHEN labname = 'Hgb' and le.labresult >    50 THEN null -- g/dL 'HEMOGLOBIN'
     WHEN labname = 'lactate' and le.labresult >    50 THEN null -- mmol/L 'LACTATE'
     WHEN labname = 'platelets x 1000' and le.labresult > 10000 THEN null -- K/uL 'PLATELET'
     WHEN labname = 'potassium' and le.labresult >    30 THEN null -- mEq/L 'POTASSIUM'
     WHEN labname = 'PTT' and le.labresult >   150 THEN null -- sec 'PTT'
     WHEN labname = 'PT - INR' and le.labresult >    50 THEN null -- 'INR'
     WHEN labname = 'PT' and le.labresult >   150 THEN null -- sec 'PT'
     WHEN labname = 'sodium' and le.labresult >   200 THEN null -- mEq/L == mmol/L 'SODIUM'
     WHEN labname = 'BUN' and le.labresult >   300 THEN null -- 'BUN'
     WHEN labname = 'WBC x 1000' and le.labresult >  1000 THEN null -- 'WBC'
   ELSE le.labresult
   END AS labresult

  FROM `physionet-data.eicu_crd.patient` p
  
  LEFT JOIN `physionet-data.eicu_crd.lab` le
    ON p.patientunitstayid = le.patientunitstayid
    AND le.labresultoffset <= 1440
    AND le.labname in
    (
    	'anion gap',
    	'albumin',
    	'-bands',
    	'bicarbonate',
    	'HCO3',
    	'total bilirubin',
    	'creatinine',
    	'chloride',
    	'glucose',
    	'Hct',
    	'Hgb',
    	'lactate',
    	'platelets x 1000',
    	'potassium',
    	'PTT',
    	'PT - INR',
    	'PT',
    	'sodium',
    	'BUN',
    	'WBC x 1000'
    )
    AND labresult IS NOT null AND labresult > 0 -- lab values cannot be 0 and cannot be negative
) pvt
WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY   patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )

GROUP BY pvt.uniquepid, pvt.patienthealthsystemstayid, pvt.patientunitstayid
ORDER BY pvt.uniquepid, pvt.patienthealthsystemstayid, pvt.patientunitstayid;
"
)

ccu_vitals1 <- run_query(
  
  
  
  
  
  
)



#Another way of doing the labs, there are mutiple rows per patient

"
-- remove duplicate labs if they exist at the same time
with vw0 as
(
  select
  patientunitstayid
  , labname
  , labresultoffset
  , labresultrevisedoffset
  from `physionet-data.eicu_crd.lab` lab
  where labname in
  (
    'albumin'
    , 'total bilirubin'
    , 'BUN'
    , 'calcium'
    , 'chloride'
    , 'creatinine'
    , 'bedside glucose', 'glucose'
    , 'bicarbonate' -- HCO3
    , 'Total CO2'
    , 'Hct'
    , 'Hgb'
    , 'PT - INR'
    , 'PTT'
    , 'lactate'
    , 'platelets x 1000'
    , 'potassium'
    , 'sodium'
    , 'WBC x 1000'
    , '-bands'
    -- Liver enzymes
    , 'ALT (SGPT)'
    , 'AST (SGOT)'
    , 'alkaline phos.'
  )
  group by patientunitstayid, labname, labresultoffset, labresultrevisedoffset
  having count(distinct labresult)<=1
)
-- get the last lab to be revised
, vw1 as
(
  select
  lab.patientunitstayid
  , lab.labname
  , lab.labresultoffset
  , lab.labresultrevisedoffset
  , lab.labresult
  , ROW_NUMBER() OVER
  (
    PARTITION BY lab.patientunitstayid, lab.labname, lab.labresultoffset
    ORDER BY lab.labresultrevisedoffset DESC
  ) as rn
  from `physionet-data.eicu_crd.lab` lab
  inner join vw0
  ON  lab.patientunitstayid = vw0.patientunitstayid
  AND lab.labname = vw0.labname
  AND lab.labresultoffset = vw0.labresultoffset
  AND lab.labresultrevisedoffset = vw0.labresultrevisedoffset
  -- only valid lab values
  WHERE
  (lab.labname = 'albumin' and lab.labresult >= 0.5 and lab.labresult <= 6.5)
  OR (lab.labname = 'total bilirubin' and lab.labresult >= 0.2 and lab.labresult <= 70.175)
  OR (lab.labname = 'BUN' and lab.labresult >= 1 and lab.labresult <= 280)
  OR (lab.labname = 'calcium' and lab.labresult > 0 and lab.labresult <= 9999)
  OR (lab.labname = 'chloride' and lab.labresult > 0 and lab.labresult <= 9999)
  OR (lab.labname = 'creatinine' and lab.labresult >= 0.1 and lab.labresult <= 28.28)
  OR (lab.labname in ('bedside glucose', 'glucose') and lab.labresult >= 25 and lab.labresult <= 1500)
  OR (lab.labname = 'bicarbonate' and lab.labresult >= 0 and lab.labresult <= 9999)
  OR (lab.labname = 'Total CO2' and lab.labresult >= 0 and lab.labresult <= 9999)
  -- will convert hct unit to fraction later
  OR (lab.labname = 'Hct' and lab.labresult >= 5 and lab.labresult <= 75)
  OR (lab.labname = 'Hgb' and lab.labresult >  0 and lab.labresult <= 9999)
  OR (lab.labname = 'PT - INR' and lab.labresult >= 0.5 and lab.labresult <= 15)
  OR (lab.labname = 'lactate' and lab.labresult >= 0.1 and lab.labresult <= 30)
  OR (lab.labname = 'platelets x 1000' and lab.labresult >  0 and lab.labresult <= 9999)
  OR (lab.labname = 'potassium' and lab.labresult >= 0.05 and lab.labresult <= 12)
  OR (lab.labname = 'PTT' and lab.labresult >  0 and lab.labresult <= 500)
  OR (lab.labname = 'sodium' and lab.labresult >= 90 and lab.labresult <= 215)
  OR (lab.labname = 'WBC x 1000' and lab.labresult > 0 and lab.labresult <= 100)
  OR (lab.labname = '-bands' and lab.labresult >= 0 and lab.labresult <= 100)
  OR (lab.labname = 'ALT (SGPT)' and lab.labresult > 0)
  OR (lab.labname = 'AST (SGOT)' and lab.labresult > 0)
  OR (lab.labname = 'alkaline phos.' and lab.labresult > 0)
)
select
patientunitstayid
, labresultoffset as chartoffset
, MAX(case when labname = 'albumin' then labresult else null end) as albumin
, MAX(case when labname = 'total bilirubin' then labresult else null end) as bilirubin
, MAX(case when labname = 'BUN' then labresult else null end) as BUN
, MAX(case when labname = 'calcium' then labresult else null end) as calcium
, MAX(case when labname = 'chloride' then labresult else null end) as chloride
, MAX(case when labname = 'creatinine' then labresult else null end) as creatinine
, MAX(case when labname in ('bedside glucose', 'glucose') then labresult else null end) as glucose
, MAX(case when labname = 'bicarbonate' then labresult else null end) as bicarbonate
, MAX(case when labname = 'Total CO2' then labresult else null end) as TotalCO2
, MAX(case when labname = 'Hct' then labresult else null end) as hematocrit
, MAX(case when labname = 'Hgb' then labresult else null end) as hemoglobin
, MAX(case when labname = 'PT - INR' then labresult else null end) as INR
, MAX(case when labname = 'lactate' then labresult else null end) as lactate
, MAX(case when labname = 'platelets x 1000' then labresult else null end) as platelets
, MAX(case when labname = 'potassium' then labresult else null end) as potassium
, MAX(case when labname = 'PTT' then labresult else null end) as ptt
, MAX(case when labname = 'sodium' then labresult else null end) as sodium
, MAX(case when labname = 'WBC x 1000' then labresult else null end) as wbc
, MAX(case when labname = '-bands' then labresult else null end) as bands
, MAX(case when labname = 'ALT (SGPT)' then labresult else null end) as alt
, MAX(case when labname = 'AST (SGOT)' then labresult else null end) as ast
, MAX(case when labname = 'alkaline phos.' then labresult else null end) as alp
from vw1
where rn = 1
group by patientunitstayid, labresultoffset
order by patientunitstayid, labresultoffset;
"






