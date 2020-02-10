source("./auth.R")

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

ccu_demographics <- run_query(
  " SELECT *
    FROM `physionet-data.eicu_crd_derived.basic_demographics` 
    WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )

"
)

ccu_gender_age <- run_query(
  " SELECT patientunitstayid, gender, age
    FROM `physionet-data.eicu_crd.patient` 
    WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )

"
)

ccu_mortality <- run_query(
  
  " 
SELECT ap.patientunitstayid
, min(CASE WHEN ap.actualicumortality LIKE '%ALIVE%' THEN 0 else 1 END) as icu_mortality
, min(CASE WHEN ap.actualhospitalmortality LIKE '%ALIVE%' THEN 0 else 1 END) as hospital_mortality
  FROM `physionet-data.eicu_crd.apachepatientresult` ap
  #SELECT pt.unitDischargeStatus, pt.hospitalDischargeStatus, ap.actualicumortality, ap. actualhospitalmortality
  #FROM `physionet-data.eicu_crd.patient` pt, `physionet-data.eicu_crd.apachepatientresult` ap
  WHERE ap.patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
 group by patientunitstayid
 order BY patientunitstayid  
"
)

ccu_mortality <- left_join(ccu_mortality, ccu_gender_age, by=c("patientunitstayid"="patientunitstayid"))


#ccu_mortality <- lapply(ccu_mortality, gsub, pattern = "> 89", replacement = "89", fixed = TRUE)

ccu_mortality <- ccu_mortality %>%
  mutate(
    #age = ifelse(age > 89, NA_character_ , age),
    age_group = case_when(
      age == "> 89" ~ '89+',
      age < 11 ~ "< 11",
      age < 20 ~ "11-20",
      age < 30 ~ "20-29",
      age < 40 ~ "30-39",
      age < 50 ~ "40-49",
      age < 60 ~ "50-59",
      age < 70 ~ "60-69",
      age < 80 ~ "70-79",
      age < 90 ~ "80-89",
      age < 100 ~ "90-99",
      age < 120 ~ "100+",
      
      age == NA_character_ ~ NA_character_ 
    )
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


ccu_labs <- run_query(
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
  , min(CASE WHEN labname = 'troponin - I' THEN labresult ELSE null end) as troponinI_min
  , max(CASE WHEN labname = 'troponin - I' THEN labresult ELSE null end) as troponinI_max
  , min(CASE WHEN labname = 'troponin - T' THEN labresult ELSE null end) as troponinT_min
  , max(CASE WHEN labname = 'troponin - T' THEN labresult ELSE null end) as troponinT_max
  , avg(CASE WHEN labname = 'pH' THEN labresult ELSE null end) as pH_mean



FROM
( -- begin query that extracts the data
  SELECT p.uniquepid, p.patienthealthsystemstayid, p.patientunitstayid, le.labname, le.labresultoffset

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
     WHEN labname = 'troponin - I' and le.labresult >  1000 THEN null -- 'Troponin I'
     WHEN labname = 'troponin - T' and le.labresult >  1000 THEN null -- 'Troponin T'
     WHEN labname = 'pH' and le.labresult <= 5.5 and le.labresult >= 9.5 THEN null -- 'pH'

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
    	'WBC x 1000',
    	'troponin - I',
    	'troponin - T',
      'pH'
    )
    AND labresult IS NOT null AND labresult > 0 AND labresultoffset <=1440 -- lab values cannot be 0 and cannot be negative
) pvt
WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY   patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
AND labresultoffset <=1440
GROUP BY pvt.uniquepid, pvt.patienthealthsystemstayid, pvt.patientunitstayid
ORDER BY pvt.uniquepid, pvt.patienthealthsystemstayid, pvt.patientunitstayid;
"
)








ccu_vitals <- run_query(
 "
SELECT patientunitstayid
, min(heartrate) as HeartRate_Min
, max(heartrate) as HeartRate_Max
, avg(heartrate) as HeartRate_Mean
, min(nibp_systolic) as SysBP_Min
, max(nibp_systolic) as SysBP_Max
, min(nibp_diastolic) as DiasBP_Min
, max(nibp_diastolic) as DiasBP_Max
, avg(nibp_diastolic) as DiasBP_Mean
, min(nibp_mean) as MeanBP_Min
, max(nibp_mean) as MeanBP_Max
, avg(nibp_mean) as MeanBP_Mean
, min(RespiratoryRate) as RespRate_Min
, max(RespiratoryRate) as RespRate_Max
, avg(RespiratoryRate) as RespRate_Mean
, min(temperature) as TempC_Min
, max(temperature) as TempC_Max
, avg(temperature) as TempC_Mean
, min(spo2) as SpO2_Min
, max(spo2) as SpO2_Max
, avg(spo2) as SpO2_Mean
, avg(nibp_systolic) as SysBP_Mean
, (avg(nibp_systolic) + 2*avg(nibp_diastolic))/3 as Mean_BP_Calc



FROM

(with nc as
  (
    select
    patientunitstayid
    , nursingchartoffset
    , nursingchartentryoffset
    , case
    when nursingchartcelltypevallabel = 'Heart Rate'
    and nursingchartcelltypevalname = 'Heart Rate'
    and (REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$'))
    and nursingchartvalue not in ('-','.')
    then cast(nursingchartvalue as FLOAT64	)
    else null end
    as heartrate
    , case
    when nursingchartcelltypevallabel = 'Respiratory Rate'
    and nursingchartcelltypevalname = 'Respiratory Rate'
    and (REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$'))
    and nursingchartvalue not in ('-','.')
    then cast(nursingchartvalue as FLOAT64	)
    else null end
    as RespiratoryRate
    , case
    when nursingchartcelltypevallabel = 'O2 Saturation'
    and nursingchartcelltypevalname = 'O2 Saturation'
    and (REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$'))
    and nursingchartvalue not in ('-','.')
    then cast(nursingchartvalue as FLOAT64	)
    else null end
    as o2saturation
    , case
    when nursingchartcelltypevallabel = 'Non-Invasive BP'
    and nursingchartcelltypevalname = 'Non-Invasive BP Systolic'
    and (REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$'))
    and nursingchartvalue not in ('-','.')
    then cast(nursingchartvalue as FLOAT64	)
    else null end
    as nibp_systolic
    , case
    when nursingchartcelltypevallabel = 'Non-Invasive BP'
    and nursingchartcelltypevalname = 'Non-Invasive BP Diastolic'
    and (REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$'))
    and nursingchartvalue not in ('-','.')
    then cast(nursingchartvalue as FLOAT64	)
    else null end
    as nibp_diastolic
    , case
    when nursingchartcelltypevallabel = 'Non-Invasive BP'
    and nursingchartcelltypevalname = 'Non-Invasive BP Mean'
    and (REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$'))
    and nursingchartvalue not in ('-','.')
    then cast(nursingchartvalue as FLOAT64	)
    else null end
    as nibp_mean
    , case
    when nursingchartcelltypevallabel = 'Temperature'
    and nursingchartcelltypevalname = 'Temperature (C)'
    and (REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$'))
    and nursingchartvalue not in ('-','.')
    then cast(nursingchartvalue as FLOAT64	)
    else null end
    as temperature
    , case
    when nursingchartcelltypevallabel = 'Temperature'
    and nursingchartcelltypevalname = 'Temperature Location'
    then nursingchartvalue
    else null end
    as TemperatureLocation
    , case
    when nursingchartcelltypevallabel = 'Invasive BP'
    and nursingchartcelltypevalname = 'Invasive BP Systolic'
    and (REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$'))
    and nursingchartvalue not in ('-','.')
    then cast(nursingchartvalue as FLOAT64	)
    else null end
    as ibp_systolic
    , case
    when nursingchartcelltypevallabel = 'Invasive BP'
    and nursingchartcelltypevalname = 'Invasive BP Diastolic'
    and (REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$'))
    and nursingchartvalue not in ('-','.')
    then cast(nursingchartvalue as FLOAT64	)
    else null end
    as ibp_diastolic
    , case
    when nursingchartcelltypevallabel = 'Invasive BP'
    and nursingchartcelltypevalname = 'Invasive BP Mean'
    and (REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$'))
    and nursingchartvalue not in ('-','.')
    then cast(nursingchartvalue as FLOAT64	)
    -- other map fields
    when nursingchartcelltypevallabel = 'MAP (mmHg)'
    and nursingchartcelltypevalname = 'Value'
    and (REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$'))
    and nursingchartvalue not in ('-','.')
    then cast(nursingchartvalue as FLOAT64	)
    when nursingchartcelltypevallabel = 'Arterial Line MAP (mmHg)'
    and nursingchartcelltypevalname = 'Value'
    and (REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$'))
    and nursingchartvalue not in ('-','.')
    then cast(nursingchartvalue as FLOAT64	)
    else null end
    as ibp_mean
    from `physionet-data.eicu_crd.nursecharting` nursecharting
    -- speed up by only looking at a subset of charted data
    where nursingchartcelltypecat in
    (
      'Vital Signs','Scores','Other Vital Signs and Infusions'
    )
  )
  select
  patientunitstayid
  , nursingchartoffset as chartoffset
  , nursingchartentryoffset as entryoffset
  , avg(case when heartrate >= 25 and heartrate <= 225 then heartrate else null end) as heartrate
  , avg(case when RespiratoryRate >= 0 and RespiratoryRate <= 60 then RespiratoryRate else null end) as RespiratoryRate
  , avg(case when o2saturation >= 0 and o2saturation <= 100 then o2saturation else null end) as spo2
  , avg(case when nibp_systolic >= 25 and nibp_systolic <= 250 then nibp_systolic else null end) as nibp_systolic
  , avg(case when nibp_diastolic >= 1 and nibp_diastolic <= 200 then nibp_diastolic else null end) as nibp_diastolic
  , avg(case when nibp_mean >= 1 and nibp_mean <= 250 then nibp_mean else null end) as nibp_mean
  , avg(case when temperature >= 25 and temperature <= 46 then temperature else null end) as temperature
  , max(temperaturelocation) as temperaturelocation
  , avg(case when ibp_systolic >= 1 and ibp_systolic <= 300 then ibp_systolic else null end) as ibp_systolic
  , avg(case when ibp_diastolic >= 1 and ibp_diastolic <= 200 then ibp_diastolic else null end) as ibp_diastolic
  , avg(case when ibp_mean >= 1 and ibp_mean <= 250 then ibp_mean else null end) as ibp_mean
  from nc
  WHERE heartrate IS NOT NULL
  OR RespiratoryRate IS NOT NULL
  OR o2saturation IS NOT NULL
  OR nibp_systolic IS NOT NULL
  OR nibp_diastolic IS NOT NULL
  OR nibp_mean IS NOT NULL
  OR temperature IS NOT NULL
  OR temperaturelocation IS NOT NULL
  OR ibp_systolic IS NOT NULL
  OR ibp_diastolic IS NOT NULL
  OR ibp_mean IS NOT NULL
  AND patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY   patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
  AND nursingchartentryoffset <= 1440
  group by patientunitstayid, nursingchartoffset, nursingchartentryoffset
  order by patientunitstayid, nursingchartoffset, nursingchartentryoffset)
  WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
  GROUP by patientunitstayid
  order by patientunitstayid
  " )

#Add in code to sort out everything after 24 hrs.













































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

urine <- run_query(

"
SELECT *
FROM `physionet-data.eicu_crd_derived.pivoted_uo`
WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
AND chartoffset <= 1440
"
)


#This gets all the true intake/output from he database using a search
#Only returns ~23k patients, sin't work using

urinev2 <- run_query(
  
  "
SELECT *
FROM `physionet-data.eicu_crd.intakeoutput`
WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
AND intakeoutputoffset <= 1440 AND (celllabel LIKE "%urine%" or celllabel LIKE "%Urine%")
#GROUP BY patientunitstayid
"
)

ccu_uo_24h <- run_query(
  "
SELECT patientunitstayid, max(urineoutput) as urineoutput
FROM `physionet-data.eicu_crd_derived.pivoted_uo`
WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
AND chartoffset <= 1440 and chartoffset >= 0 
GROUP BY patientunitstayid
ORDER BY patientunitstayid
"
)


#Is the urine cumulative?
urine24 <- run_query(
"
SELECT patientunitstayid, max(urineoutput) as urineoutput
FROM `physionet-data.eicu_crd_derived.pivoted_uo`
WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
AND chartoffset <= 1440
GROUP BY patientunitstayid
ORDER BY patientunitstayid
"
)


ccu_gcs <- run_query(
  "
  SELECT min(gcs)as GCS_min, patientunitstayid
  FROM `physionet-data.eicu_crd_derived.pivoted_score`
  WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
  AND chartoffset <= 1440 
  GROUP BY patientunitstayid
  ORDER BY patientunitstayid
  "
)


wide_pressors <- run_query(
  "
  SELECT patientunitstayid, max(dopamine) as dopamine, max(dobutamine) as dobutamine, max(norepinephrine) as norepinephrine, max(epinephrine) as epinephrine, max(phenylephrine) as phenyl, max (vasopressin) as vasopressin, max(milrinone) as milrinone, max(heparin) as heparin, max(warfarin) as warfarin
  FROM `physionet-data.eicu_crd_derived.pivoted_med`
  WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
  AND chartoffset <= 1440 AND chartoffset >= 0
  #ORDER by patientunitstayid
  GROUP by patientunitstayid
  
  "
)

any_pressor <- apply(wide_pressors[, -1], 1, max)
total_pressors = rowSums(wide_pressors[, -1])
wide_pressors <- cbind(wide_pressors, any_pressor, total_pressors)

wide_pressors_firsthour <- run_query(
  "
  SELECT patientunitstayid, max(dopamine) as dopamine_first_hour, max(dobutamine) as dobutamine_first_hour, max(norepinephrine) as norepinephrine_first_hour, max(epinephrine) as epinephrine_first_hour, max(phenylephrine) as phenyl_first_hour, max (vasopressin) as vasopressin_first_hour, max(milrinone) as milrinone_first_hour, max(heparin) as heparin_first_hour, max(warfarin) as warfarin_first_hour
  FROM `physionet-data.eicu_crd_derived.pivoted_med`
  WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
  AND chartoffset <= 60 AND chartoffset >= 0
  #ORDER by patientunitstayid
  GROUP by patientunitstayid
  
  "
)

any_pressor_firsthour <- apply(wide_pressors_firsthour[, -1], 1, max)
total_pressors_firsthour <- rowSums(wide_pressors_firsthour[, -1])
wide_pressors_firsthour <- cbind(wide_pressors_firsthour, total_pressors_firsthour, any_pressor_firsthour)





drug <- run_query(
  "
  SELECT patientunitstayid, drugrate as vaso_rate, drugamount as vaso_amount, infusionoffset
    #DISTINCT drugname
    FROM `physionet-data.eicu_crd.infusiondrug` 
  WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
  AND LOWER(drugname) LIKE '%dobutamine%'
  "
)












#look into icd9 codes use query22
wide_procedures_24 <- run_query(
  
  "
SELECT patientunitstayid
, max(CASE WHEN LOWER(treatmentstring) LIKE '%intraaortic balloon%'  THEN 1 else 0 END) as iabp
, max(CASE WHEN LOWER(treatmentstring) LIKE '%impella%'  THEN 1 else 0 END) as impella
, max(CASE WHEN LOWER(treatmentstring) LIKE '%ECMO%'  THEN 1 else 0 END) as ecmo
  FROM `physionet-data.eicu_crd.treatment` 
  WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
  AND treatmentoffset <= 1440
  Group by patientunitstayid
  
  "
)

procedure_list <- run_query(
  
  "
  SELECT DISTINCT treatmentstring
  FROM `physionet-data.eicu_crd.treatment` 
  WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
  AND treatmentstring LIKE '%cardio%'
#Group by patientunitstayid
  group by treatmentstring
  

  "
)



 cats <- run_query(
   "
   SELECT *
     FROM `physionet-data.eicu_crd_derived.treatment_categories`
  "
 )
 
raw_icd9 <- run_query(
  "
  SELECT patientunitstayid, icd9code as ICD9_code
  FROM `physionet-data.eicu_crd.diagnosis` 
  WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
  ORDER BY patientunitstayid

  "
)

raw_icd9 <- subset(raw_icd9,ICD9_code!="")

# for (row in 1:nrow(raw_icd9)) {
# #   if(all.equal(raw_icd9[row, 2], ""))
# #   
#   
#   print(raw_icd9[row, 2])
# }

ccu_diagnoses <- separate_rows(raw_icd9,2,sep = ",")
ccu_diagnoses$ICD9_code <- str_trim(ccu_diagnoses$ICD9_code)
ccu_diagnoses$ICD9_code <- str_remove(ccu_diagnoses$ICD9_code, "[.]")

clean_icd9 <- ccu_diagnoses
#ccu_diagnoses$ICD9_code <- gsub(".","Q", ccu_diagnoses$ICD9_code)


# CCS classification dictionary table to ease ICD9 codes grouping (level 3 and level 4)
ccsicd <- read_csv("./data/ccsicd.csv")
ccsicd$ICD9 <- gsub("'","\\1", ccsicd$ICD9)
ccsicd$ICD9 <- str_trim(ccsicd$ICD9)
ccsicd$CCS <- gsub("\\[.*","\\1", ccsicd$CCS)
ccsicd$CCS <- str_trim(ccsicd$CCS)

# List to visualize all the ICD9 diagnosis of the CCU patients
dxlist <- sort(unique(ccu_diagnoses$CCS))
# 
# # Final diagnoses table
ccu_diagnoses <- left_join(ccu_diagnoses, ccsicd, by=c("ICD9_code"="ICD9")) %>%
  filter(CCS%in%c("Diabetes mellitus", "Anemia", "STEMI", "NSTEMI", "Acute renal failure", "Acute cerebrovascular disease", "Atrial fibrillation","Blood Malignancy", 
                  "Chronic obstructive pulmonary disease and bronchiectasis","Coronary atherosclerosis", "Chronic kidney disease", "Diabetes mellitus",
                  "Heart valve disorders","Cardiac arrest and ventricular fibrillation", "Hypertension","Neoplasms", "Shock NOS", "Shock Cardiogenic", "Shock Septic", "Septicemia"))%>%
  select(-c("ICD9_code"))%>%
  #This ensure that duplicates of values are only counted once
  group_by(patientunitstayid, CCS)%>%
  summarise()


# 
# # Function that cadds count of each dx in the
get_counts <-function(dataset){
  summary <- dataset %>% group_by(patientunitstayid,CCS) %>% dplyr::summarise(count=n())%>% arrange(desc(count))%>%ungroup(patientunitstayid)
  return(summary)
}

# 
# # Final wide dx table 
# # 0 : no diagnosis 1: diagnosis
narrow_ccu_dx <- get_counts(ccu_diagnoses)
wide_ccu_dx <- narrow_ccu_dx%>%spread(CCS, count, fill=0)
# 
# ## Making sure that patients do not have STEMI and non STEMI
wide_ccu_dx <- wide_ccu_dx %>%
  mutate(NSTEMI=replace(NSTEMI, NSTEMI==1 & STEMI==1, 0))

# test <- left_join(ccu_patients, wide_ccu_dx, by=c("patientunitstayid"))
# 
# for (row in 1:nrow(raw_icd9)) {
#   if(clean_icd9[row, 2] ==  "G610")
#     print("Hello")
#     
#   
# 
#   #print(clean_icd9[row, 2])
# }

#go through and add the diagnoses
#add the VIS score via er
#urine output should be over 24hrs
#add BMI, maybe blood transfusion, blood pH

shock_index = data.frame(ccu_vitals$patientunitstayid, ccu_vitals$MeanBP_Mean/ccu_vitals$HeartRate_Mean)
colnames(shock_index) = c("patientunitstayid", "shock_index")


#approx 3320 patients have it missing
# library(DataExplorer)
# plot_missing(shock_index)
# plot_bar(shock_index)
# 
# 
# wide_cabg_pci <- c('patientunitstayid','cabg','pci')
# #for pci and cabg
# for (row in 1:nrow(clean_icd9)) {
#     icd9 <- raw_icd9[row, 2]
#     #print(icd9)
#     if(icd9 == "66" ||  icd9 == "3604" ||  icd9 == "3606" ||  icd9 == "3607"||  icd9 == "3609") {
#          #wide_cabg_pci.data <- (clean_icd9[row, 1], 1, 0)
#           #print('cabg')
#     } 
#     
#     if(icd9 == "3610" ||  icd9 == "3611" ||  icd9 == "3612" ||  icd9 == "3613"||  icd9 == "3614" ||  icd9 == "3615" ||  icd9 == "3616") {
#       #wide_cabg_pci.data <- (clean_icd9[row, 1], 1, 0)
#       print('pci')
#     } 
#     
#     
#     }


#The below code enables th data collection from the ventilation events table, but only has about 2k unique patients
# vent_raw <- run_query(
#   
#   "
#   SELECT patientunitstayid
#   FROM `physionet-data.eicu_crd_derived.ventilation_events`
#   WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
#   GROUP BY patientunitstayid
#   
#   "
# )

vent_raw <- run_query("
SELECT patientunitstayid
#DISTINCT drugname
  FROM `physionet-data.eicu_crd.treatment` 
  WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
  AND LOWER(treatmentstring) LIKE '%mechanical%'
  AND treatmentoffset <= 1440 
   group by patientunitstayid
  order by patientunitstayid   ")

vent_raw$vent = 1

ccu_vent <- left_join(ccu_patients, vent_raw, by=c("patientunitstayid"="patientunitstayid"))
ccu_vent$vent <- replace_na(ccu_vent$vent, 0)



install.packages("comorbidity")      
library(comorbidity)

charlson <- clean_icd9
# Assigning Charlson index per id
charlson9 <- comorbidity(x = charlson, id = "patientunitstayid", code = "ICD9_code", score = "charlson", icd = "icd9", assign0 = FALSE)
charlson9 <- charlson9%>%dplyr::select(patientunitstayid, score)%>%rename(charlson_score=score)

#Admission contains for all patients, but it's ahrd to process
admissionV1 = run_query(
  "
  SELECT *
  FROM `physionet-data.eicu_crd.admissiondx`
  WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
  
  "
  
)

ccu_patients_id_los <- run_query(
  "
  SELECT patientunitstayid, icu_los_hours as los_hours, hospitaladmitoffset AS intime, hospitaldischargeoffset as outtime
  FROM `physionet-data.eicu_crd_derived.icustay_detail`
  WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
  "
  
)


ccu_demographics_dob_gender_death <- run_query(
  
  "
  SELECT patientunitstayid, (CASE WHEN gender = 'Female' THEN 'F' else 'M' END) as gender
  FROM `physionet-data.eicu_crd.patient`
  WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
  
  "
)

#Not sure if this is fully accurate
#ccu_uo_24h <- 

ccu_RRT24h <- run_query(
  "
  SELECT patientunitstayid, max(dialysis) as RRT
  FROM `physionet-data.eicu_crd.apacheapsvar`
  WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
  group by patientunitstayid
  order by patientunitstayid
  "
  
)


RRTTreatment <- run_query( "SELECT patientunitstayid
  FROM `physionet-data.eicu_crd.treatment` 
  WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
  AND LOWER(treatmentstring) LIKE '%dialysis%'
  AND treatmentoffset <= 1440 
   group by patientunitstayid
  order by patientunitstayid  ")

ccu_race <- run_query(
  
  "
  SELECT patientunitstayid, ethnicity
  FROM `physionet-data.eicu_crd.patient`
  WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
  #group by patientunitstayid
  "
  
)



ccu_bmi <- run_query(
  "
  SELECT patientunitstayid 
  , (CASE WHEN admissionheight > 20  THEN (admissionweight/POW(admissionheight/100,2)) else Null END) as bmi
  FROM `physionet-data.eicu_crd_derived.icustay_detail`
  WHERE patientunitstayid in (SELECT patientunitstayid FROM ( SELECT patientunitstayid, patienthealthsystemstayid, hospitalAdmitOffset, hospitaladmittime24, hospitaldischargetime24,ROW_NUMBER() OVER(PARTITION BY      patienthealthsystemstayid ORDER BY hospitalAdmitOffset) rn FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU' OR unittype = 'CTICU' OR unittype = 'CICU' OR unittype = 'CCU-CTICU' ) x WHERE rn = 1 )
  "
)



