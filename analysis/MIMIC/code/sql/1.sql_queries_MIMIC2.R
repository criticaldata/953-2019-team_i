#SQL databases queries for MIMIC-III
setwd("~/Documents/Bioinformatics/Classes/FALL/HST.953/Git_Files_Cardiogenic/953-2019-team_i/analysis/MIMIC")
#Loading of libraries
source("./code/library_load.R")
source("./code/sql/sql_access.R")


# We should modify the script to join everything by HADMID and not Subject ID if possible!!! (except for demographics)

##CCU query

# Challenge is getting only the first ICU stay of each of the CCU patients (there about 250 patients with two CCUs admissions and we kept the first)
# ROW_NUMBER() if your RDBMS supports it: this works by ranking records by increasing intime within groups of records having the same ham_id,
# and then filtering in the outer query on the top record per group.

ccu_query <- "SELECT subject_id , hadm_id, icustay_id, intime, outtime, los
FROM (
    SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
    FROM `physionet-data.mimiciii_clinical.icustays`
    WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1"

# Contains  HADM_ID, INTIME, OUT TIME AND LOS
ccu_patients_id_los <- run_query(ccu_query)



##Comoborbidities

ccu_query_1 <- "SELECT d.hadm_id, d.subject_id, ICD9_code
FROM `physionet-data.mimiciii_clinical.diagnoses_icd` d
WHERE hadm_id in 
(
SELECT hadm_id
FROM (
    SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
    FROM `physionet-data.mimiciii_clinical.icustays`
    WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)

"

# Contains  hadm_id, subject_id and icd9 codes for all CCU patients
ccu_diagnoses <- run_query(ccu_query_1)

# CCS classification dictionary table to ease ICD9 codes grouping (level 3 and level 4)
ccsicd <- read_csv("./data/ccsicd.csv")
ccsicd$ICD9 <- gsub("'","\\1", ccsicd$ICD9)
ccsicd$ICD9 <- str_trim(ccsicd$ICD9)
ccsicd$CCS <- gsub("\\[.*","\\1", ccsicd$CCS)
ccsicd$CCS <- str_trim(ccsicd$CCS)

# List to visualize all the ICD9 diagnosis of the CCU patients
dxlist <- sort(unique(ccu_diagnoses$CCS))

# Final diagnoses table
ccu_diagnoses <- left_join(ccu_diagnoses, ccsicd, by=c("ICD9_code"="ICD9")) %>%
  filter(CCS%in%c("Diabetes mellitus", "Anemia", "STEMI", "NSTEMI", "Acute renal failure", "Acute cerebrovascular disease", "Atrial fibrillation", 
                  "Chronic obstructive pulmonary disease and bronchiectasis","Coronary atherosclerosis", "Chronic kidney disease", "Diabetes mellitus",
                  "Heart valve disorders","Cardiac arrest and ventricular fibrillation", "Hypertension", "Shock NOS", "Shock Cardiogenic", "Shock Septic", "Septicemia"))%>%
  dplyr::select(-c("ICD9_code","hadm_id"))%>%
  #This ensure that duplicates of values are only counted once
  group_by(subject_id, CCS)%>%
  summarise()

# Function that cadds count of each dx in the
get_counts <-function(dataset){       
  summary <- dataset %>% group_by(subject_id,CCS) %>% dplyr::summarise(count=n())%>% arrange(desc(count))%>%ungroup(subject_id) 
  return(summary)
}

# Final wide dx table 
# 0 : no diagnosis 1: diagnosis
narrow_ccu_dx <- get_counts(ccu_diagnoses)
wide_ccu_dx <- narrow_ccu_dx%>%spread(CCS, count, fill=0)

## Making sure that patients do not have STEMI and non STEMI
wide_ccu_dx <- wide_ccu_dx %>%
  mutate(NSTEMI=replace(NSTEMI, NSTEMI==1 & STEMI==1, 0))


# Elixhauser
library(comorbidity)

# Assigning Elixhauser index per id
elix <- run_query(ccu_query_1)%>%dplyr::select(-hadm_id)
elix_table <- comorbidity(x = elix, id = "subject_id", code = "ICD9_code", score = "elixhauser", icd = "icd9", assign0 = TRUE)
elix_table <- elix_table%>%dplyr::select(-c("wscore_ahrq","wscore_vw","windex_ahrq","windex_vw"))
# chf added back
elix_table <- elix_table%>%dplyr::select(-c("carit","valv","hypunc", "hypc", "cpd", "diabc", "diabunc", "rf", "blane", "dane", "score", "index"))

##Demographics
ccu_query_2 <- "SELECT subject_id, dob, dod, gender, expire_flag
FROM `physionet-data.mimiciii_clinical.patients`
WHERE subject_id in 
(SELECT subject_id
FROM (
    SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
    FROM `physionet-data.mimiciii_clinical.icustays`
    WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)
"

# Contains  subject_id(NOT HADM), dob, dod, gender, and flag for death (flag includes outside of hospital death)
ccu_demographics_dob_gender_death <- run_query(ccu_query_2)
ccu_demographics_dob_gender_death <- ccu_demographics_dob_gender_death%>%select("subject_id","gender")

## First 24 hours labs

ccu_query_3 <- "SELECT
  pvt.hadm_id, pvt.subject_id, pvt.icustay_id

  , min(CASE WHEN label = 'ANION GAP' THEN valuenum ELSE null END) as ANIONGAP_min
  , max(CASE WHEN label = 'ANION GAP' THEN valuenum ELSE null END) as ANIONGAP_max
  , min(CASE WHEN label = 'ALBUMIN' THEN valuenum ELSE null END) as ALBUMIN_min
  , max(CASE WHEN label = 'ALBUMIN' THEN valuenum ELSE null END) as ALBUMIN_max
  , min(CASE WHEN label = 'BANDS' THEN valuenum ELSE null END) as BANDS_min
  , max(CASE WHEN label = 'BANDS' THEN valuenum ELSE null END) as BANDS_max
  , min(CASE WHEN label = 'BICARBONATE' THEN valuenum ELSE null END) as BICARBONATE_min
  , max(CASE WHEN label = 'BICARBONATE' THEN valuenum ELSE null END) as BICARBONATE_max
  , min(CASE WHEN label = 'BILIRUBIN' THEN valuenum ELSE null END) as BILIRUBIN_min
  , max(CASE WHEN label = 'BILIRUBIN' THEN valuenum ELSE null END) as BILIRUBIN_max
  , min(CASE WHEN label = 'CREATININE' THEN valuenum ELSE null END) as CREATININE_min
  , max(CASE WHEN label = 'CREATININE' THEN valuenum ELSE null END) as CREATININE_max
  , min(CASE WHEN label = 'CHLORIDE' THEN valuenum ELSE null END) as CHLORIDE_min
  , max(CASE WHEN label = 'CHLORIDE' THEN valuenum ELSE null END) as CHLORIDE_max
  , min(CASE WHEN label = 'GLUCOSE' THEN valuenum ELSE null END) as GLUCOSE_min
  , max(CASE WHEN label = 'GLUCOSE' THEN valuenum ELSE null END) as GLUCOSE_max
  , min(CASE WHEN label = 'HEMATOCRIT' THEN valuenum ELSE null END) as HEMATOCRIT_min
  , max(CASE WHEN label = 'HEMATOCRIT' THEN valuenum ELSE null END) as HEMATOCRIT_max
  , min(CASE WHEN label = 'HEMOGLOBIN' THEN valuenum ELSE null END) as HEMOGLOBIN_min
  , max(CASE WHEN label = 'HEMOGLOBIN' THEN valuenum ELSE null END) as HEMOGLOBIN_max
  , min(CASE WHEN label = 'LACTATE' THEN valuenum ELSE null END) as LACTATE_min
  , max(CASE WHEN label = 'LACTATE' THEN valuenum ELSE null END) as LACTATE_max
  , min(CASE WHEN label = 'PLATELET' THEN valuenum ELSE null END) as PLATELET_min
  , max(CASE WHEN label = 'PLATELET' THEN valuenum ELSE null END) as PLATELET_max
  , min(CASE WHEN label = 'POTASSIUM' THEN valuenum ELSE null END) as POTASSIUM_min
  , max(CASE WHEN label = 'POTASSIUM' THEN valuenum ELSE null END) as POTASSIUM_max
  , min(CASE WHEN label = 'PTT' THEN valuenum ELSE null END) as PTT_min
  , max(CASE WHEN label = 'PTT' THEN valuenum ELSE null END) as PTT_max
  , min(CASE WHEN label = 'INR' THEN valuenum ELSE null END) as INR_min
  , max(CASE WHEN label = 'INR' THEN valuenum ELSE null END) as INR_max
  , min(CASE WHEN label = 'PT' THEN valuenum ELSE null END) as PT_min
  , max(CASE WHEN label = 'PT' THEN valuenum ELSE null END) as PT_max
  , min(CASE WHEN label = 'SODIUM' THEN valuenum ELSE null END) as SODIUM_min
  , max(CASE WHEN label = 'SODIUM' THEN valuenum ELSE null end) as SODIUM_max
  , min(CASE WHEN label = 'BUN' THEN valuenum ELSE null end) as BUN_min
  , max(CASE WHEN label = 'BUN' THEN valuenum ELSE null end) as BUN_max
  , min(CASE WHEN label = 'WBC' THEN valuenum ELSE null end) as WBC_min
  , max(CASE WHEN label = 'WBC' THEN valuenum ELSE null end) as WBC_max
  , min(CASE WHEN label = 'TROPONIN I' THEN valuenum ELSE null end) as TropoI_min
  , max(CASE WHEN label = 'TROPONIN I' THEN valuenum ELSE null end) as TropoI_max
  , min(CASE WHEN label = 'TROPONIN T' THEN valuenum ELSE null end) as TropoT_min
  , max(CASE WHEN label = 'TROPONIN T' THEN valuenum ELSE null end) as TropoT_max
  , min(CASE WHEN label = 'NTproBNP' THEN valuenum ELSE null end) as NTproBNP_min
  , max(CASE WHEN label = 'NTproBNP' THEN valuenum ELSE null end) as NTproBNP_max
  , min(CASE WHEN label = 'PH' THEN valuenum ELSE null end) as PH_min
  , max(CASE WHEN label = 'PH' THEN valuenum ELSE null end) as PH_max
  , min(CASE WHEN label = 'RDW' THEN valuenum ELSE null end) as RDW_min
  , max(CASE WHEN label = 'RDW' THEN valuenum ELSE null end) as RDW_max
FROM
( -- begin query that extracts the data
  SELECT ie.subject_id, ie.hadm_id, ie.icustay_id
  -- here we assign labels to ITEMIDs
  -- this also fuses together multiple ITEMIDs containing the same data
  , CASE
        WHEN itemid = 50868 THEN 'ANION GAP'
        WHEN itemid = 50862 THEN 'ALBUMIN'
        WHEN itemid = 51144 THEN 'BANDS'
        WHEN itemid = 50882 THEN 'BICARBONATE'
        WHEN itemid = 50885 THEN 'BILIRUBIN'
        WHEN itemid = 50912 THEN 'CREATININE'
        WHEN itemid = 50806 THEN 'CHLORIDE'
        WHEN itemid = 50902 THEN 'CHLORIDE'
        WHEN itemid = 50809 THEN 'GLUCOSE'
        WHEN itemid = 50931 THEN 'GLUCOSE'
        WHEN itemid = 50810 THEN 'HEMATOCRIT'
        WHEN itemid = 51221 THEN 'HEMATOCRIT'
        WHEN itemid = 50811 THEN 'HEMOGLOBIN'
        WHEN itemid = 51222 THEN 'HEMOGLOBIN'
        WHEN itemid = 50813 THEN 'LACTATE'
        WHEN itemid = 51265 THEN 'PLATELET'
        WHEN itemid = 50822 THEN 'POTASSIUM'
        WHEN itemid = 50971 THEN 'POTASSIUM'
        WHEN itemid = 51275 THEN 'PTT'
        WHEN itemid = 51237 THEN 'INR'
        WHEN itemid = 51274 THEN 'PT'
        WHEN itemid = 50824 THEN 'SODIUM'
        WHEN itemid = 50983 THEN 'SODIUM'
        WHEN itemid = 51006 THEN 'BUN'
        WHEN itemid = 51300 THEN 'WBC'
        WHEN itemid = 51301 THEN 'WBC'
        WHEN itemid = 51002 THEN 'TROPONIN I'
        WHEN itemid = 51003 THEN 'TROPONIN T'
        WHEN itemid = 50963 THEn 'NTproBNP'
        WHEN itemid = 50820 THEN 'PH'
        WHEN itemid = 50831 THEN 'PH'
        WHEN itemid = 51277 THEN 'RDW'
      ELSE null
    END AS label
  , -- add in some sanity checks on the values
  -- the where clause below requires all valuenum to be > 0, so these are only upper limit checks
    CASE
      WHEN itemid = 50862 and valuenum >    10 THEN null -- g/dL 'ALBUMIN'
      WHEN itemid = 50868 and valuenum > 10000 THEN null -- mEq/L 'ANION GAP'
      WHEN itemid = 51144 and valuenum <     0 THEN null -- immature band forms, %
      WHEN itemid = 51144 and valuenum >   100 THEN null -- immature band forms, %
      WHEN itemid = 50882 and valuenum > 10000 THEN null -- mEq/L 'BICARBONATE'
      WHEN itemid = 50885 and valuenum >   150 THEN null -- mg/dL 'BILIRUBIN'
      WHEN itemid = 50806 and valuenum > 10000 THEN null -- mEq/L 'CHLORIDE'
      WHEN itemid = 50902 and valuenum > 10000 THEN null -- mEq/L 'CHLORIDE'
      WHEN itemid = 50912 and valuenum >   150 THEN null -- mg/dL 'CREATININE'
      WHEN itemid = 50809 and valuenum > 10000 THEN null -- mg/dL 'GLUCOSE'
      WHEN itemid = 50931 and valuenum > 10000 THEN null -- mg/dL 'GLUCOSE'
      WHEN itemid = 50810 and valuenum >   100 THEN null -- % 'HEMATOCRIT'
      WHEN itemid = 51221 and valuenum >   100 THEN null -- % 'HEMATOCRIT'
      WHEN itemid = 50811 and valuenum >    50 THEN null -- g/dL 'HEMOGLOBIN'
      WHEN itemid = 51222 and valuenum >    50 THEN null -- g/dL 'HEMOGLOBIN'
      WHEN itemid = 50813 and valuenum >    50 THEN null -- mmol/L 'LACTATE'
      WHEN itemid = 51265 and valuenum > 10000 THEN null -- K/uL 'PLATELET'
      WHEN itemid = 50822 and valuenum >    30 THEN null -- mEq/L 'POTASSIUM'
      WHEN itemid = 50971 and valuenum >    30 THEN null -- mEq/L 'POTASSIUM'
      WHEN itemid = 51275 and valuenum >   150 THEN null -- sec 'PTT'
      WHEN itemid = 51237 and valuenum >    50 THEN null -- 'INR'
      WHEN itemid = 51274 and valuenum >   150 THEN null -- sec 'PT'
      WHEN itemid = 50824 and valuenum >   200 THEN null -- mEq/L == mmol/L 'SODIUM'
      WHEN itemid = 50983 and valuenum >   200 THEN null -- mEq/L == mmol/L 'SODIUM'
      WHEN itemid = 51006 and valuenum >   300 THEN null -- 'BUN'
      WHEN itemid = 51300 and valuenum >  1000 THEN null -- 'WBC'
      WHEN itemid = 51301 and valuenum >  1000 THEN null -- 'WBC'
    ELSE le.valuenum
    END AS valuenum

  FROM `physionet-data.mimiciii_clinical.icustays` ie

  LEFT JOIN `physionet-data.mimiciii_clinical.labevents` le
    ON le.subject_id = ie.subject_id AND le.hadm_id = ie.hadm_id
    AND DATETIME_DIFF (le.charttime, ie.intime, DAY) < 1.01
    AND le.ITEMID in
    (
      -- comment is: LABEL | CATEGORY | FLUID | NUMBER OF ROWS IN LABEVENTS
      50868, -- ANION GAP | CHEMISTRY | BLOOD | 769895
      50862, -- ALBUMIN | CHEMISTRY | BLOOD | 146697
      51144, -- BANDS - hematology
      50882, -- BICARBONATE | CHEMISTRY | BLOOD | 780733
      50885, -- BILIRUBIN, TOTAL | CHEMISTRY | BLOOD | 238277
      50912, -- CREATININE | CHEMISTRY | BLOOD | 797476
      50902, -- CHLORIDE | CHEMISTRY | BLOOD | 795568
      50806, -- CHLORIDE, WHOLE BLOOD | BLOOD GAS | BLOOD | 48187
      50931, -- GLUCOSE | CHEMISTRY | BLOOD | 748981
      50809, -- GLUCOSE | BLOOD GAS | BLOOD | 196734
      51221, -- HEMATOCRIT | HEMATOLOGY | BLOOD | 881846
      50810, -- HEMATOCRIT, CALCULATED | BLOOD GAS | BLOOD | 89715
      51222, -- HEMOGLOBIN | HEMATOLOGY | BLOOD | 752523
      50811, -- HEMOGLOBIN | BLOOD GAS | BLOOD | 89712
      50813, -- LACTATE | BLOOD GAS | BLOOD | 187124
      51265, -- PLATELET COUNT | HEMATOLOGY | BLOOD | 778444
      50971, -- POTASSIUM | CHEMISTRY | BLOOD | 845825
      50822, -- POTASSIUM, WHOLE BLOOD | BLOOD GAS | BLOOD | 192946
      51275, -- PTT | HEMATOLOGY | BLOOD | 474937
      51237, -- INR(PT) | HEMATOLOGY | BLOOD | 471183
      51274, -- PT | HEMATOLOGY | BLOOD | 469090
      50983, -- SODIUM | CHEMISTRY | BLOOD | 808489
      50824, -- SODIUM, WHOLE BLOOD | BLOOD GAS | BLOOD | 71503
      51006, -- UREA NITROGEN | CHEMISTRY | BLOOD | 791925
      51301, -- WHITE BLOOD CELLS | HEMATOLOGY | BLOOD | 753301
      51300,  -- WBC COUNT | HEMATOLOGY | BLOOD | 2371
      51002,  -- TROPONIN I
      51003,  -- TROPONIN T
      50963,  -- NTproBNP
      51277 -- 'RDW'
    )
    AND valuenum IS NOT null AND valuenum > 0 -- lab values cannot be 0 and cannot be negative
) pvt
WHERE pvt.icustay_id in
(
SELECT icustay_id
FROM (
    SELECT subject_id, hadm_id, icustay_id, intime, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
    FROM `physionet-data.mimiciii_clinical.icustays`
    WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)
GROUP BY pvt.subject_id, pvt.hadm_id, pvt.icustay_id
ORDER BY pvt.subject_id, pvt.hadm_id, pvt.icustay_id;
"

# hadm_id, short_title, long_title
ccu_labs <- run_query(ccu_query_3)
ccu_labs <- ccu_labs%>%
  mutate(Delta_creat_0.3 = ifelse(abs(CREATININE_max-CREATININE_min) >= 0.3, 1, 0))%>%
  mutate(Doubled_creat = ifelse(abs(CREATININE_max/CREATININE_min) >= 1.5, 1, 0))
ccu_labs <- ccu_labs%>%select(-hadm_id)


## CCU  24 hours vital signs

ccu_query_4 <- "  SELECT pvt.hadm_id, pvt.subject_id, pvt.icustay_id

-- Easier names
, min(case when VitalID = 1 then valuenum else null end) as HeartRate_Min
, max(case when VitalID = 1 then valuenum else null end) as HeartRate_Max
, avg(case when VitalID = 1 then valuenum else null end) as HeartRate_Mean
, min(case when VitalID = 2 then valuenum else null end) as SysBP_Min
, max(case when VitalID = 2 then valuenum else null end) as SysBP_Max
, avg(case when VitalID = 2 then valuenum else null end) as SysBP_Mean
, min(case when VitalID = 3 then valuenum else null end) as DiasBP_Min
, max(case when VitalID = 3 then valuenum else null end) as DiasBP_Max
, avg(case when VitalID = 3 then valuenum else null end) as DiasBP_Mean
, min(case when VitalID = 4 then valuenum else null end) as MeanBP_Min
, max(case when VitalID = 4 then valuenum else null end) as MeanBP_Max
, avg(case when VitalID = 4 then valuenum else null end) as MeanBP_Mean
, min(case when VitalID = 5 then valuenum else null end) as RespRate_Min
, max(case when VitalID = 5 then valuenum else null end) as RespRate_Max
, avg(case when VitalID = 5 then valuenum else null end) as RespRate_Mean
, min(case when VitalID = 6 then valuenum else null end) as TempC_Min
, max(case when VitalID = 6 then valuenum else null end) as TempC_Max
, avg(case when VitalID = 6 then valuenum else null end) as TempC_Mean
, min(case when VitalID = 7 then valuenum else null end) as SpO2_Min
, max(case when VitalID = 7 then valuenum else null end) as SpO2_Max
, avg(case when VitalID = 7 then valuenum else null end) as SpO2_Mean
, min(case when VitalID = 8 then valuenum else null end) as Glucose_Min
, max(case when VitalID = 8 then valuenum else null end) as Glucose_Max
, avg(case when VitalID = 8 then valuenum else null end) as Glucose_Mean

FROM  (
  select ie.subject_id, ie.hadm_id, ie.icustay_id
  , case
    when itemid in (211,220045) and valuenum > 0 and valuenum < 300 then 1 -- HeartRate
    when itemid in (51,442,455,6701,220179,220050) and valuenum > 0 and valuenum < 400 then 2 -- SysBP
    when itemid in (8368,8440,8441,8555,220180,220051) and valuenum > 0 and valuenum < 300 then 3 -- DiasBP
    when itemid in (456,52,6702,443,220052,220181,225312) and valuenum > 0 and valuenum < 300 then 4 -- MeanBP
    when itemid in (615,618,220210,224690) and valuenum > 0 and valuenum < 70 then 5 -- RespRate
    when itemid in (223761,678) and valuenum > 70 and valuenum < 120  then 6 -- TempF, converted to degC in valuenum call
    when itemid in (223762,676) and valuenum > 10 and valuenum < 50  then 6 -- TempC
    when itemid in (646,220277) and valuenum > 0 and valuenum <= 100 then 7 -- SpO2
    when itemid in (807,811,1529,3745,3744,225664,220621,226537) and valuenum > 0 then 8 -- Glucose

    else null end as VitalID
      -- convert F to C
  , case when itemid in (223761,678) then (valuenum-32)/1.8 else valuenum end as valuenum

  from `physionet-data.mimiciii_clinical.icustays` ie
  left join `physionet-data.mimiciii_clinical.chartevents` ce
  on ie.subject_id = ce.subject_id and ie.hadm_id = ce.hadm_id and ie.icustay_id = ce.icustay_id
  AND DATETIME_DIFF (ce.charttime, ie.intime, DAY) < 1.01
  -- exclude rows marked as error # DISTINCT FROM 1 is not supported in BigQuery
  WHERE ce.error != 1 OR ce.error IS NULL
  AND ce.itemid in
  
  (
  -- HEART RATE
  211, --Heart Rate
  220045, --Heart Rate

  -- Systolic/diastolic

  51, --	Arterial BP [Systolic]
  442, --	Manual BP [Systolic]
  455, --	NBP [Systolic]
  6701, --	Arterial BP #2 [Systolic]
  220179, --	Non Invasive Blood Pressure systolic
  220050, --	Arterial Blood Pressure systolic

  8368, --	Arterial BP [Diastolic]
  8440, --	Manual BP [Diastolic]
  8441, --	NBP [Diastolic]
  8555, --	Arterial BP #2 [Diastolic]
  220180, --	Non Invasive Blood Pressure diastolic
  220051, --	Arterial Blood Pressure diastolic


  -- MEAN ARTERIAL PRESSURE
  456, --NBP Mean
  52, --Arterial BP Mean
  6702, --	Arterial BP Mean #2
  443, --	Manual BP Mean(calc)
  220052, --Arterial Blood Pressure mean
  220181, --Non Invasive Blood Pressure mean
  225312, --ART BP mean

  -- RESPIRATORY RATE
  618,--	Respiratory Rate
  615,--	Resp Rate (Total)
  220210,--	Respiratory Rate
  224690, --	Respiratory Rate (Total)


  -- SPO2, peripheral
  646, 220277,

  -- GLUCOSE, both lab and fingerstick
  807,--	Fingerstick Glucose
  811,--	Glucose (70-105)
  1529,--	Glucose
  3745,--	BloodGlucose
  3744,--	Blood Glucose
  225664,--	Glucose finger stick
  220621,--	Glucose (serum)
  226537,--	Glucose (whole blood)

  -- TEMPERATURE
  223762, -- Temperature Celsius
  676,	-- Temperature C
  223761, -- Temperature Fahrenheit
  678 --	Temperature F

  )
) 
pvt

WHERE pvt.icustay_id in
(
SELECT icustay_id
FROM (
    SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
    FROM `physionet-data.mimiciii_clinical.icustays`
    WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)

GROUP BY pvt.subject_id, pvt.hadm_id, pvt.icustay_id
ORDER BY pvt.subject_id, pvt.hadm_id, pvt.icustay_id;

 " 
vitalsfull <- "SELECT pvt.hadm_id, pvt.subject_id, pvt.icustay_id

-- Easier names
, min(case when VitalID = 1 then valuenum else null end) as HeartRate_Min
, max(case when VitalID = 1 then valuenum else null end) as HeartRate_Max
, avg(case when VitalID = 1 then valuenum else null end) as HeartRate_Mean
, min(case when VitalID = 2 then valuenum else null end) as SysBP_Min
, max(case when VitalID = 2 then valuenum else null end) as SysBP_Max
, avg(case when VitalID = 2 then valuenum else null end) as SysBP_Mean
, min(case when VitalID = 3 then valuenum else null end) as DiasBP_Min
, max(case when VitalID = 3 then valuenum else null end) as DiasBP_Max
, avg(case when VitalID = 3 then valuenum else null end) as DiasBP_Mean
, min(case when VitalID = 4 then valuenum else null end) as MeanBP_Min
, max(case when VitalID = 4 then valuenum else null end) as MeanBP_Max
, avg(case when VitalID = 4 then valuenum else null end) as MeanBP_Mean
, min(case when VitalID = 5 then valuenum else null end) as RespRate_Min
, max(case when VitalID = 5 then valuenum else null end) as RespRate_Max
, avg(case when VitalID = 5 then valuenum else null end) as RespRate_Mean
, min(case when VitalID = 6 then valuenum else null end) as TempC_Min
, max(case when VitalID = 6 then valuenum else null end) as TempC_Max
, avg(case when VitalID = 6 then valuenum else null end) as TempC_Mean
, min(case when VitalID = 7 then valuenum else null end) as SpO2_Min
, max(case when VitalID = 7 then valuenum else null end) as SpO2_Max
, avg(case when VitalID = 7 then valuenum else null end) as SpO2_Mean
, min(case when VitalID = 8 then valuenum else null end) as Glucose_Min
, max(case when VitalID = 8 then valuenum else null end) as Glucose_Max
, avg(case when VitalID = 8 then valuenum else null end) as Glucose_Mean

FROM  (
  select ie.subject_id, ie.hadm_id, ie.icustay_id
  , case
  when itemid in (211,220045) and valuenum > 0 and valuenum < 300 then 1 -- HeartRate
  when itemid in (51,442,455,6701,220179,220050) and valuenum > 0 and valuenum < 400 then 2 -- SysBP
  when itemid in (8368,8440,8441,8555,220180,220051) and valuenum > 0 and valuenum < 300 then 3 -- DiasBP
  when itemid in (456,52,6702,443,220052,220181,225312) and valuenum > 0 and valuenum < 300 then 4 -- MeanBP
  when itemid in (615,618,220210,224690) and valuenum > 0 and valuenum < 70 then 5 -- RespRate
  when itemid in (223761,678) and valuenum > 70 and valuenum < 120  then 6 -- TempF, converted to degC in valuenum call
  when itemid in (223762,676) and valuenum > 10 and valuenum < 50  then 6 -- TempC
  when itemid in (646,220277) and valuenum > 0 and valuenum <= 100 then 7 -- SpO2
  when itemid in (807,811,1529,3745,3744,225664,220621,226537) and valuenum > 0 then 8 -- Glucose
  
  else null end as VitalID
  -- convert F to C
  , case when itemid in (223761,678) then (valuenum-32)/1.8 else valuenum end as valuenum
  
  from `physionet-data.mimiciii_clinical.icustays` ie
  left join `physionet-data.mimiciii_clinical.chartevents` ce
  on ie.subject_id = ce.subject_id and ie.hadm_id = ce.hadm_id and ie.icustay_id = ce.icustay_id
  AND DATETIME_DIFF (ce.charttime, ie.intime, DAY) < 1.01
  -- exclude rows marked as error # DISTINCT FROM 1 is not supported in BigQuery
  WHERE ce.error != 1 OR ce.error IS NULL
  AND ce.itemid in
  
  (
    -- HEART RATE
    211, --Heart Rate
    220045, --Heart Rate
    
    -- Systolic/diastolic
    
    51, --	Arterial BP [Systolic]
    442, --	Manual BP [Systolic]
    455, --	NBP [Systolic]
    6701, --	Arterial BP #2 [Systolic]
    220179, --	Non Invasive Blood Pressure systolic
    220050, --	Arterial Blood Pressure systolic
    
    8368, --	Arterial BP [Diastolic]
    8440, --	Manual BP [Diastolic]
    8441, --	NBP [Diastolic]
    8555, --	Arterial BP #2 [Diastolic]
    220180, --	Non Invasive Blood Pressure diastolic
    220051, --	Arterial Blood Pressure diastolic
    
    
    -- MEAN ARTERIAL PRESSURE
    456, --NBP Mean
    52, --Arterial BP Mean
    6702, --	Arterial BP Mean #2
    443, --	Manual BP Mean(calc)
    220052, --Arterial Blood Pressure mean
    220181, --Non Invasive Blood Pressure mean
    225312, --ART BP mean
    
    -- RESPIRATORY RATE
    618,--	Respiratory Rate
    615,--	Resp Rate (Total)
    220210,--	Respiratory Rate
    224690, --	Respiratory Rate (Total)
    
    
    -- SPO2, peripheral
    646, 220277,
    
    -- GLUCOSE, both lab and fingerstick
    807,--	Fingerstick Glucose
    811,--	Glucose (70-105)
    1529,--	Glucose
    3745,--	BloodGlucose
    3744,--	Blood Glucose
    225664,--	Glucose finger stick
    220621,--	Glucose (serum)
    226537,--	Glucose (whole blood)
    
    -- TEMPERATURE
    223762, -- Temperature Celsius
    676,	-- Temperature C
    223761, -- Temperature Fahrenheit
    678 --	Temperature F
    
  )
) 
pvt

GROUP BY pvt.subject_id, pvt.hadm_id, pvt.icustay_id
ORDER BY pvt.subject_id, pvt.hadm_id, pvt.icustay_id;"

# VS including BP, HR, T, Glucose, Sat, RR, MUST merge table
ccu_vitals <- run_query(ccu_query_4)

# First 24 hours urinary output
ccu_query_5 <- "SELECT * FROM `physionet-data.mimiciii_derived.uofirstday`
WHERE icustay_id in
(
SELECT icustay_id
FROM (
    SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
    FROM `physionet-data.mimiciii_clinical.icustays`
    WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)"

# UO in cc for first 24 hours
ccu_uo_24h <- run_query(ccu_query_5)


## ccu-RRT during first ICU stay

ccu_query_6 <-  "SELECT subject_id, icustay_id, hadm_id, RRT FROM `physionet-data.mimiciii_derived.rrt`
WHERE icustay_id in
(
SELECT icustay_id
FROM (
    SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
    FROM `physionet-data.mimiciii_clinical.icustays`
    WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)"


## hadm_id, RRT col with 0 if none and 1 if positive
ccu_RRT <- run_query(ccu_query_6)

## ccu_RRT during first 24 hours

ccu_query_7 <- "SELECT subject_id, icustay_id, hadm_id, RRT FROM `physionet-data.mimiciii_derived.rrtfirstday`
WHERE icustay_id in
(
SELECT icustay_id
FROM (
    SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
    FROM `physionet-data.mimiciii_clinical.icustays`
    WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)
"

## ccu_rrt_24h, hadm_id, RRT col

ccu_RRT24h <- run_query(ccu_query_7)


## ccu_ventiltation query

ccu_query_8 <- "SELECT subject_id, icustay_id, hadm_id, vent FROM `physionet-data.mimiciii_derived.ventfirstday`
WHERE icustay_id in
(
SELECT icustay_id
FROM (
    SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
    FROM `physionet-data.mimiciii_clinical.icustays`
    WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)
"
## ccu vent in first 24 hours, hadm_id, vent col (0 or 1)

ccu_vent <- run_query(ccu_query_8)

### All the vasopressors queries are below. Initially individually queried and after merged in R
### Must note that pressors table only contain icu_stay_id BEFORE merge
### table of each
### NB duplicates of individuals in all table because drug was stopped and restarted in short periods

# adds duration, adds pressor type col + filters out patients who have received pressors in the first 24 hours
# function to specify when how early the pressor must have been started, we will use this to stratify the SCAI stages
optimize_pressor <- function(df, nameofpressor, hours){
  df <- df %>% mutate(pressor_type = nameofpressor) %>% 
    mutate(duration_hours=difftime(endtime, starttime, units = "hours")) %>% 
    left_join(ccu_patients_id_los, by.x="hadm_id", by.y="hadm_id") %>%
    filter(starttime < intime + lubridate::hours(hours)) %>%
    select(-c('intime',"outtime",'los'))
  #second part of function and MERGING
  #function that merges pressors dose into one if close in time and removes pressors administration of less than an hours
  df <- df %>% arrange(icustay_id,starttime) %>% 
    group_by(icustay_id) %>% 
    mutate(pause = difftime(starttime, lag(endtime), units = "hours")) %>% 
    replace_na(list(pause = 0)) %>% 
    mutate(vaso_id = cumsum(pause >= 1))%>%
    group_by(subject_id,icustay_id, hadm_id, pressor_type, vaso_id) %>% 
    summarise(
      starttime = min(starttime), 
      endtime = max(endtime),
      duration_hours = sum(duration_hours),
      vaso_rate = mean(vaso_rate),
      vaso_amount = sum(vaso_amount))
  return (df)
}

# Same function for milrinone because the milrinone data table is different

optimize_pressorm <- function(df, nameofpressor, hours){
  df <- df %>% mutate(pressor_type = nameofpressor) %>% 
    mutate(duration_hours=difftime(endtime, starttime, units = "hours")) %>% 
    left_join(ccu_patients_id_los, by.x="hadm_id", by.y="hadm_id") %>%
    filter(starttime < intime + lubridate::hours(hours)) %>%
    select(-c('intime',"outtime",'los'))
  #second part of function and MERGING
  #function that merges pressors dose into one if close in time and removes pressors administration of less than an hours
  df <- df %>% arrange(icustay_id,starttime) %>% 
    group_by(icustay_id) %>% 
    mutate(pause = difftime(starttime, lag(endtime), units = "hours")) %>% 
    replace_na(list(pause = 0)) %>% 
    mutate(vaso_id = cumsum(pause >= 1))%>%
    group_by(subject_id,icustay_id, hadm_id, pressor_type, vaso_id) %>% 
    summarise(
      starttime = min(starttime), 
      endtime = max(endtime),
      duration_hours = sum(duration_hours))
  return (df)
}

# Dobutamine

ccu_query_9 <- "SELECT * FROM `physionet-data.mimiciii_derived.dobutamine_dose` 
WHERE icustay_id in 
(
SELECT icustay_id
FROM (
    SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
    FROM `physionet-data.mimiciii_clinical.icustays`
    WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)"

dobutamine_ccu_24 <- optimize_pressor(run_query(ccu_query_9), "dobutamine", 24)
dobutamine_ccu_1 <- optimize_pressor(run_query(ccu_query_9), "dobutamine", 1)


# Dopamine

ccu_query_10 <- "SELECT * FROM `physionet-data.mimiciii_derived.dopamine_dose`
WHERE icustay_id in 
(
SELECT icustay_id
FROM (
    SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
    FROM `physionet-data.mimiciii_clinical.icustays`
    WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)"

dopamine_ccu_24 <- optimize_pressor(run_query(ccu_query_10), "dopamine", 24)
dopamine_ccu_1 <- optimize_pressor(run_query(ccu_query_10), "dopamine", 1)

# epinephrine

ccu_query_11 <- "SELECT * FROM `physionet-data.mimiciii_derived.epinephrine_dose`
WHERE icustay_id in 
(
SELECT icustay_id
FROM (
    SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
    FROM `physionet-data.mimiciii_clinical.icustays`
    WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)"

epi_ccu_24 <- optimize_pressor(run_query(ccu_query_11), "epinephrine", 24)
epi_ccu_1 <- optimize_pressor(run_query(ccu_query_11), "epinephrine", 1)

#

ccu_query_12 <- "SELECT * FROM `physionet-data.mimiciii_derived.norepinephrine_dose`
WHERE icustay_id in 
(
SELECT icustay_id
FROM (
    SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
    FROM `physionet-data.mimiciii_clinical.icustays`
    WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)"

norepi_ccu_24 <- optimize_pressor(run_query(ccu_query_12), "norepinephrine", 24)
norepi_ccu_1 <- optimize_pressor(run_query(ccu_query_12), "norepinephrine", 1)

ccu_query_13 <- "SELECT * FROM `physionet-data.mimiciii_derived.milrinonedurations`
WHERE icustay_id in 
(
SELECT icustay_id
FROM (
    SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
    FROM `physionet-data.mimiciii_clinical.icustays`
    WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)"

## NO DOSAGE For milrinone... should not be processed with this function....
milri_ccu_24 <- optimize_pressorm(run_query(ccu_query_13), "milrinone", 24)
milri_ccu_1 <- optimize_pressorm(run_query(ccu_query_13), "milrinone", 1)


#Phenyl
ccu_query_14 <- "SELECT * FROM `physionet-data.mimiciii_derived.phenylephrine_dose`
WHERE icustay_id in 
(
SELECT icustay_id
FROM (
    SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
    FROM `physionet-data.mimiciii_clinical.icustays`
    WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)"

phenyl_ccu_24 <- optimize_pressor(run_query(ccu_query_14), "phenyl", 24)
phenyl_ccu_1 <- optimize_pressor(run_query(ccu_query_14), "phenyl", 1)
# Vasopressin

ccu_query_15 <- "SELECT * FROM `physionet-data.mimiciii_derived.vasopressin_dose`
WHERE icustay_id in 
(
SELECT icustay_id
FROM (
    SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
    FROM `physionet-data.mimiciii_clinical.icustays`
    WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)"

vasopressin_ccu_24 <- optimize_pressor(run_query(ccu_query_15), "vasopressin", 24)
vasopressin_ccu_1 <- optimize_pressor(run_query(ccu_query_15), "vasopressin", 1)


#  Query of number of all pressors

ccu_query_16 <- "SELECT * FROM `physionet-data.mimiciii_derived.vasopressordurations`
WHERE icustay_id in 
(
SELECT icustay_id
FROM (
    SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
    FROM `physionet-data.mimiciii_clinical.icustays`
    WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)"


# Merged tables by HST, not really useful
# Before must remove duplicates from table above
# Must also coutain a col with number of pressors for an individual patient

allpressors <- run_query(ccu_query_16)

### allpressors <- optimize_pressor(run_query(ccu_query_16), "all", 24) - function not designed for this table



# CUSTOM table with merged pressors for all CCU patients with associated column featuring total number of pressors per patient
# In this table : less granularity -> no distinction with start and stop time
# This is a filtered table, no start,endtime. Only the type of pressor.

### This is the table for first 24 hours

mergedpressors <- bind_rows(dobutamine_ccu_24 , dopamine_ccu_24, epi_ccu_24, milri_ccu_24, norepi_ccu_24, vasopressin_ccu_24, phenyl_ccu_24)%>%
  group_by(subject_id,icustay_id, hadm_id, pressor_type) %>% 
  summarise(
    starttime = min(starttime), 
    endtime = max(endtime),
    duration_hours = sum(duration_hours),
    vaso_rate = mean(vaso_rate),
    vaso_amount = sum(vaso_amount))%>%
  select(-c("starttime","endtime","duration_hours","vaso_rate","vaso_amount"))


### This the merged table for pressors received in the first hour
### I removed the amount and rate from the table but if we wanted more granularity, it would be easy to add them back in.

mergedpressors_firsthour <- bind_rows(dobutamine_ccu_1 , dopamine_ccu_1, epi_ccu_1, milri_ccu_1, norepi_ccu_1, vasopressin_ccu_1, phenyl_ccu_1)%>%
  group_by(subject_id,icustay_id, hadm_id, pressor_type) %>% 
  summarise(
    starttime = min(starttime), 
    endtime = max(endtime),
    duration_hours = sum(duration_hours),
    vaso_rate = mean(vaso_rate),
    vaso_amount = sum(vaso_amount))%>%
  select(-c("starttime","endtime","duration_hours","vaso_rate","vaso_amount"))




# Function that adds a count to each pressor, that will facilitate the spread of the table
get_counts2 <-function(dataset){       
  summary <- dataset %>% group_by(hadm_id,subject_id,icustay_id,pressor_type) %>% dplyr::summarise(count=n())%>% arrange(desc(count))%>%ungroup(subject_id) 
  return(summary)
}


# Long table with each pressor per patient
mergedpressors <- get_counts2(mergedpressors)
mergedpressors_firsthour <- get_counts2(mergedpressors_firsthour)

# Pressors table widened + 2 additionnal columns : (1) any pressor (2) total number of pressors

wide_pressors <- mergedpressors%>%spread(pressor_type, count, fill=0)%>% 
  mutate(total_pressors = rowSums(.[4:10]))%>%
  mutate(any_pressor = ifelse(total_pressors>= 1, 1, 0))


wide_pressors_firsthour <- mergedpressors_firsthour%>%spread(pressor_type, count, fill=0)%>% 
  mutate(total_pressors_first_hour = rowSums(.[4:10]))%>%
  mutate(any_pressor_first_hour = ifelse(total_pressors_first_hour>= 1, 1, 0))

colnames(wide_pressors_firsthour)[4:10]<- paste(colnames(wide_pressors_firsthour)[4:10], "first_hour", sep = "_")


# CCU procedures 1 : ECMO, IABP, IMPELLA and charttime

ccu_query_17 <- "WITH table1 AS 
(
SELECT subject_id, hadm_id, icustay_id, itemid, charttime, CASE
        WHEN itemid = 5931 THEN 'ECMO'
        WHEN itemid = 6758 THEN 'ECMO'
        WHEN itemid = 224660 THEN 'ECMO'
        WHEN itemid = 43928 THEN 'ECMO'
        WHEN itemid = 7018 THEN 'ECMO'
        WHEN itemid = 3265 THEN 'ECMO'
        WHEN itemid = 2957 THEN 'ECMO'
        WHEN itemid = 7449 THEN 'ECMO'
        WHEN itemid = 6931 THEN 'ECMO'
        WHEN itemid = 7015 THEN 'ECMO'
        WHEN itemid = 5798 THEN 'ECMO'
        WHEN itemid = 5937 THEN 'ECMO'
        WHEN itemid = 7892 THEN 'ECMO'

        WHEN itemid = 225981 THEN 'IABP'
        WHEN itemid = 225341 THEN 'IABP'
        WHEN itemid = 225986 THEN 'IABP'
        WHEN itemid = 225982 THEN 'IABP'
        WHEN itemid = 6424 THEN 'IABP'

        WHEN itemid = 225335 THEN 'IABP'
        WHEN itemid = 225336 THEN 'IABP'
        WHEN itemid = 225337 THEN 'IABP'
        WHEN itemid = 227355 THEN 'IABP'       
        WHEN itemid = 225778 THEN 'IABP'
        WHEN itemid = 225985 THEN 'IABP'
        WHEN itemid = 225338 THEN 'IABP'        
        WHEN itemid = 224272 THEN 'IABP'
        WHEN itemid = 225727 THEN 'IABP' 
        WHEN itemid = 224 THEN 'IABP'  
        WHEN itemid = 224322 THEN 'IABP'
        WHEN itemid = 226110 THEN 'IABP'
        WHEN itemid = 227754 THEN 'IABP' 
        WHEN itemid = 225988 THEN 'IABP'        
        WHEN itemid = 225987 THEN 'IABP'
        WHEN itemid = 225 THEN 'IABP'
        WHEN itemid = 225339 THEN 'IABP'
        WHEN itemid = 225979 THEN 'IABP'        
        WHEN itemid = 225984 THEN 'IABP'
        WHEN itemid = 225340 THEN 'IABP'
        WHEN itemid = 225980 THEN 'IABP'
        WHEN itemid = 225342 THEN 'IABP'
        WHEN itemid = 2515 THEN 'IABP'
        WHEN itemid = 2865 THEN 'IABP'

        WHEN itemid = 228154 THEN 'IMPELLA'
        WHEN itemid = 228160 THEN 'IMPELLA'
        WHEN itemid = 228162 THEN 'IMPELLA'
        WHEN itemid = 228163 THEN 'IMPELLA'
        WHEN itemid = 228164 THEN 'IMPELLA'
        WHEN itemid = 228165 THEN 'IMPELLA'

        WHEN itemid = 228166 THEN 'IMPELLA'
        WHEN itemid = 228167 THEN 'IMPELLA'
        WHEN itemid = 228168 THEN 'IMPELLA'
        WHEN itemid = 228169 THEN 'IMPELLA'
        WHEN itemid = 228170 THEN 'IMPELLA'
        WHEN itemid = 228174 THEN 'IMPELLA'
        
        WHEN itemid = 228171 THEN 'IMPELLA'
        WHEN itemid = 228173 THEN 'IMPELLA'
        WHEN itemid = 228172 THEN 'IMPELLA'
ELSE NULL 
END AS label
FROM `physionet-data.mimiciii_clinical.chartevents`
)
,
table2 as
(
SELECT label, subject_id, hadm_id, icustay_id, charttime
FROM table1
WHERE label = 'ECMO' OR label='IABP' OR label='IMPELLA' 
)
SELECT label, subject_id, hadm_id, icustay_id, MIN(charttime) as charttime FROM table2
GROUP BY label, subject_id, hadm_id, icustay_id
"
  
### Contains All identifiers, Charttime, procedures (IABP, IMPELLA, ECMO) BUT  not PCI or CABG among all ICU patients
### In this form all entries of the same event are counted must therefore summarize

ccu_procedures <- run_query(ccu_query_17) 


### Only procedures having occured in the first 24 hours

ccu_procedures_24 <- ccu_procedures %>%
  inner_join(ccu_patients_id_los, by=c("hadm_id"))%>%
  filter(charttime < intime + lubridate::hours(24))%>%
  select(c("label","subject_id.x","hadm_id","icustay_id.x"))%>%
  rename(
    "subject_id"="subject_id.x",
    "icustay_id"="icustay_id.x"
  )


# Adding count number for each procedure to facilitate widening

get_counts3 <-function(dataset){       
  summary <- dataset %>% group_by(subject_id,label) %>% dplyr::summarise(count=n())%>% arrange(desc(count))%>%ungroup(subject_id) 
  return(summary)
}

mergedprocedures <- get_counts3(ccu_procedures_24)

# Final procedures table, only subject id
# 0 : no diagnosis 1: diagnosis
wide_procedures_24<- mergedprocedures%>%spread(label, count, fill=0)




### Mortality

ccu_query_18 <- "WITH tmp as
(
    SELECT adm.hadm_id, adm.admittime, adm.dischtime, adm.deathtime, pat.dod, pat.dob
    FROM `physionet-data.mimiciii_clinical.admissions` adm
    INNER JOIN `physionet-data.mimiciii_clinical.patients` pat
    ON adm.subject_id = pat.subject_id
)
SELECT *
FROM tmp
WHERE hadm_id in 
  (
    SELECT hadm_id
      FROM (
      SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
      FROM `physionet-data.mimiciii_clinical.icustays`
      WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)"


## Mortality table in ICU, in-hospital, 30 day, 1 year.
## NB this table contains NULL value for 30 day and 1 year mortality ONLY. 
## also contains AGE from admission -> but a lot > 300 ?!? Weird.
## Must add age group by stratification of 10

ccu_mortality <- run_query(ccu_query_18)



### CCU motality table (ICU, hospital, 30 day) with subject_id only
ccu_mortality <- ccu_mortality %>%
  left_join(y=ccu_patients_id_los, by=c("hadm_id"="hadm_id")) %>%
  mutate(
    icu_mortality = ifelse(deathtime <= outtime, 0, 1),
    icu_mortality = coalesce(icu_mortality, 0),
    hospital_mortality = ifelse(!is.na(deathtime), 1, 0),
    thirty_day_mortality = ifelse(dod < admittime + lubridate::days(30), 1, 0),
    survival_days = difftime(dod,admittime, units='days'),
    age = as.integer(time_length(difftime(admittime,dob), "years"))
    ) %>%
  select(
    -c("admittime","dischtime","deathtime","dod", "dob","intime", "outtime", "hadm_id", "icustay_id", "los", "survival_days")
  )
  
### CCU mortality wide table with additional age groups

# Transforming all aberrant values of age to NULL and creating age_group

ccu_mortality <- ccu_mortality %>%
  mutate(
    age = ifelse(age > 200, NA_character_ , age),
    age_group = case_when(
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
      age == NA_character_ ~ "90-99" 
      )
    )



ccu_query_19 <- "-- ITEMIDs used:

-- CAREVUE
--    723 as GCSVerbal
--    454 as GCSMotor
--    184 as GCSEyes

-- METAVISION
--    223900 GCS - Verbal Response
--    223901 GCS - Motor Response
--    220739 GCS - Eye Opening

-- The code combines the ITEMIDs into the carevue itemids, then pivots those
-- So 223900 is changed to 723, then the ITEMID 723 is pivoted to form GCSVerbal

-- Note:
--  The GCS for sedated patients is defaulted to 15 in this code.
--  This is in line with how the data is meant to be collected.
--  e.g., from the SAPS II publication:
--    For sedated patients, the Glasgow Coma Score before sedation was used.
--    This was ascertained either from interviewing the physician who ordered the sedation,
--    or by reviewing the patient's medical record.

with base as
(
  SELECT pvt.ICUSTAY_ID
  , pvt.charttime

  -- Easier names - note we coalesced Metavision and CareVue IDs below
  , max(case when pvt.itemid = 454 then pvt.valuenum else null end) as GCSMotor
  , max(case when pvt.itemid = 723 then pvt.valuenum else null end) as GCSVerbal
  , max(case when pvt.itemid = 184 then pvt.valuenum else null end) as GCSEyes

  -- If verbal was set to 0 in the below select, then this is an intubated patient
  , case
      when max(case when pvt.itemid = 723 then pvt.valuenum else null end) = 0
    then 1
    else 0
    end as EndoTrachFlag

  , ROW_NUMBER ()
          OVER (PARTITION BY pvt.ICUSTAY_ID ORDER BY pvt.charttime ASC) as rn

  FROM  (
  select l.ICUSTAY_ID
  -- merge the ITEMIDs so that the pivot applies to both metavision/carevue data
  , case
      when l.ITEMID in (723,223900) then 723
      when l.ITEMID in (454,223901) then 454
      when l.ITEMID in (184,220739) then 184
      else l.ITEMID end
    as ITEMID

  -- convert the data into a number, reserving a value of 0 for ET/Trach
  , case
      -- endotrach/vent is assigned a value of 0, later parsed specially
      when l.ITEMID = 723 and l.VALUE = '1.0 ET/Trach' then 0 -- carevue
      when l.ITEMID = 223900 and l.VALUE = 'No Response-ETT' then 0 -- metavision

      else VALUENUM
      end
    as VALUENUM
  , l.CHARTTIME
  from `physionet-data.mimiciii_clinical.chartevents` l

  -- get intime for charttime subselection
  inner join `physionet-data.mimiciii_clinical.icustays` b
    on l.icustay_id = b.icustay_id

  -- Isolate the desired GCS variables
  where l.ITEMID in
  (
    -- 198 -- GCS
    -- GCS components, CareVue
    184, 454, 723
    -- GCS components, Metavision
    , 223900, 223901, 220739
  )
  -- Only get data for the first 24 hours
  and DATETIME_DIFF (l.charttime, b.intime, DAY) < 1.01
  -- exclude rows marked as error
  ) pvt
  group by pvt.ICUSTAY_ID, pvt.charttime
)
, gcs as (
  select b.*
  , b2.GCSVerbal as GCSVerbalPrev
  , b2.GCSMotor as GCSMotorPrev
  , b2.GCSEyes as GCSEyesPrev
  -- Calculate GCS, factoring in special case when they are intubated and prev vals
  -- note that the coalesce are used to implement the following if:
  --  if current value exists, use it
  --  if previous value exists, use it
  --  otherwise, default to normal
  , case
      -- replace GCS during sedation with 15
      when b.GCSVerbal = 0
        then 15
      when b.GCSVerbal is null and b2.GCSVerbal = 0
        then 15
      -- if previously they were intub, but they aren't now, do not use previous GCS values
      when b2.GCSVerbal = 0
        then
            coalesce(b.GCSMotor,6)
          + coalesce(b.GCSVerbal,5)
          + coalesce(b.GCSEyes,4)
      -- otherwise, add up score normally, imputing previous value if none available at current time
      else
            coalesce(b.GCSMotor,coalesce(b2.GCSMotor,6))
          + coalesce(b.GCSVerbal,coalesce(b2.GCSVerbal,5))
          + coalesce(b.GCSEyes,coalesce(b2.GCSEyes,4))
      end as GCS

  from base b
  -- join to itself within 6 hours to get previous value
  left join base b2
    on b.ICUSTAY_ID = b2.ICUSTAY_ID and b.rn = b2.rn+1 and DATETIME_DIFF (b2.charttime, b.charttime , HOUR) > 6.01
)
, gcs_final as (
  select gcs.*
  -- This sorts the data by charttime, so rn=1 is the the first GCS values to keep
  , ROW_NUMBER ()
          OVER (PARTITION BY gcs.ICUSTAY_ID
                #ORDER BY gcs.GCS
                ORDER BY gcs.charttime
               ) as IsMinGCS
  from gcs
)


select ie.SUBJECT_ID, ie.HADM_ID, ie.ICUSTAY_ID
-- The minimum GCS is determined by the above row partition, we only join if IsMinGCS=1
, GCS as MinGCS
, coalesce(GCSMotor,GCSMotorPrev) as GCSMotor
, coalesce(GCSVerbal,GCSVerbalPrev) as GCSVerbal
, coalesce(GCSEyes,GCSEyesPrev) as GCSEyes
, EndoTrachFlag as EndoTrachFlag

-- subselect down to the cohort of eligible patients
from `physionet-data.mimiciii_clinical.icustays` ie
left join gcs_final gs
  on ie.ICUSTAY_ID = gs.ICUSTAY_ID and gs.IsMinGCS = 1
#ORDER BY ie.ICUSTAY_ID;
WHERE ie.icustay_id in
(
SELECT icustay_id
FROM (
    SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
    FROM `physionet-data.mimiciii_clinical.icustays` d
    WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)
"


# Contains gcs and all patient IDs and filter datframee contains all ids + GCS
ccu_gcs <- run_query(ccu_query_19)
ccu_gcs <- ccu_gcs %>% 
  select("SUBJECT_ID", "HADM_ID", "ICUSTAY_ID", "MinGCS") %>%
  clean_names("snake") %>%
  rename("GCS"="min_gcs") %>%
  select(subject_id, GCS)


## SOFA at 24 hours for CCU patients

ccu_query_20 <- "SELECT * FROM `physionet-data.mimiciii_derived.sofa`
WHERE icustay_id in 
  (
    SELECT icustay_id
      FROM (
      SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
      FROM `physionet-data.mimiciii_clinical.icustays`
      WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)"

ccu_sofa <- run_query(ccu_query_20)
ccu_sofa <- ccu_sofa %>% 
  select("subject_id", "SOFA") 


## OASIS  score at 24 hours for CCU patients

ccu_query_21 <- "SELECT  subject_id, icustay_id, hadm_id, ICUSTAY_AGE_GROUP, OASIS FROM `physionet-data.mimiciii_derived.oasis`
WHERE icustay_id in 
  (
    SELECT icustay_id
      FROM (
      SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
      FROM `physionet-data.mimiciii_clinical.icustays`
      WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)"

ccu_oasis <- run_query(ccu_query_21) %>%select("subject_id", "OASIS") 


# Patients who had PCI OR CABG during stay

ccu_query22 <- "WITH PCI AS
(
SELECT *, CASE 
  WHEN icd9_code IN (66, 3604, 3606, 3607, 3609) THEN 'PCI'
  WHEN icd9_code IN (3610, 3611, 3612, 3613, 3614, 3615, 3616) THEN 'CABG'
  ELSE NULL
  END AS diagnosis 
  FROM `physionet-data.mimiciii_clinical.procedures_icd`
)
SELECT subject_id, hadm_id, diagnosis FROM PCI 
WHERE diagnosis = 'PCI' OR diagnosis = 'CABG' 
AND hadm_id in 
  (
    SELECT hadm_id
      FROM (
      SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
      FROM `physionet-data.mimiciii_clinical.icustays`
      WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)
GROUP BY hadm_id, subject_id, diagnosis

"

# CCU patients with CABG : hadm_IM, subject_id, diagnosis with value CABG or PCI"
ccu_cabg_pci <- run_query(ccu_query22)%>%
  filter(hadm_id %in% ccu_patients_id_los$hadm_id)

# Wide transformation 

get_counts4 <-function(dataset){       
  summary <- dataset %>% group_by(subject_id,diagnosis) %>% dplyr::summarise(count=n())%>% arrange(desc(count))%>%ungroup(subject_id) 
  return(summary)
}

# Final wide PCI/CABG table  for each CCU patient
# 0 : no diagnosis 1: diagnosis
# Must note that : not sure if all new interventions OR BEFORE because found in ICD9 procedures table and NO CHARTTIME available
ccu_cabg_pci <- get_counts4(ccu_cabg_pci)
wide_cabg_pci <- ccu_cabg_pci%>%spread(diagnosis, count, fill=0)

#*************

## BMI

ccu_query_23 <- "SELECT * FROM `physionet-data.mimiciii_derived.heightweight` 
WHERE icustay_id in
(
SELECT icustay_id
FROM (
    SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
    FROM `physionet-data.mimiciii_clinical.icustays`
    WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)
"



# Query did not work so exported the CSV file from BigQuery
# ccu_bmi <- run_query(ccu_query_23)
ccu_bmi <- read.csv("./data/bmi_ccu.csv")



## ccu_bmi by icustay_id 
ccu_bmi <- ccu_bmi%>%mutate(bmi = weight_first/((height_first)*0.01)^2)%>%
  dplyr::select(-c("weight_first","weight_min", "weight_max","height_first","height_min", "height_max"))


## Charlson Index

library(comorbidity)

charlson <- run_query(ccu_query_1)%>%dplyr::select(-hadm_id)
# Assigning Charlson index per id
charlson9 <- comorbidity(x = charlson, id = "subject_id", code = "ICD9_code", score = "charlson", icd = "icd9", assign0 = FALSE)
charlson9 <- charlson9%>%dplyr::select(subject_id, score)%>%rename(charlson_score=score)



#VIS score at 24 hour
mergedpressors2 <- bind_rows(dobutamine_ccu_24 , dopamine_ccu_24, epi_ccu_24, milri_ccu_24, norepi_ccu_24, vasopressin_ccu_24, phenyl_ccu_24)%>%
  select(-c("hadm_id", "icustay_id")) %>%
  group_by(subject_id, pressor_type) %>% 
  summarise(
    starttime = min(starttime), 
    endtime = max(endtime),
    duration_hours = sum(duration_hours),
    vaso_rate = mean(vaso_rate),
    vaso_amount = sum(vaso_amount))%>%
  dplyr::select(-c("starttime","endtime","duration_hours","vaso_amount"))


# Convert all vasopressin doses at same unit (some are in U/min and some in U/h)
mergedpressors2[which(mergedpressors2$pressor_type=="vasopressin"),] <- mergedpressors2[which(mergedpressors2$pressor_type=="vasopressin"),]%>%
  mutate(vaso_rate = ifelse(vaso_rate<= 0.2, vaso_rate*60, vaso_rate))

# VIS score for each pressor
# MIMIC does not have the rates for milrinone, thus the 0 value
mergedpressors2 <- mergedpressors2%>%mutate(
  vis=case_when(
    pressor_type == "phenyl" ~ vaso_rate*10,
    pressor_type == "milrinone" ~ 0,
    pressor_type == "dobutamine" ~ vaso_rate,
    pressor_type == "dopamine" ~ vaso_rate,
    pressor_type == "norepinephrine" ~ vaso_rate*100,
    pressor_type == "epinephrine" ~ vaso_rate*100,
    pressor_type == "vasopressin" ~ vaso_rate*10000/60 ## that seems way too high # if you copy this remove the division by 60 if U/min
  )
) 

# VIS score summed up for patients on many pressors
vis_24h <- mergedpressors2%>%group_by(subject_id)%>%
  summarise(vis_24h = sum(vis))


##### VIS at 1 hour

mergedpressors_firsthour <- bind_rows(dobutamine_ccu_1 , dopamine_ccu_1, epi_ccu_1, milri_ccu_1, norepi_ccu_1, vasopressin_ccu_1, phenyl_ccu_1)%>%
  group_by(subject_id,icustay_id, hadm_id, pressor_type) %>% 
  summarise(
    starttime = min(starttime), 
    endtime = max(endtime),
    duration_hours = sum(duration_hours),
    vaso_rate = mean(vaso_rate),
    vaso_amount = sum(vaso_amount))%>%
  select(-c("starttime","endtime","duration_hours","vaso_amount"))

# Convert all vasopressin doses at same unit (some are in U/min and some in U/h)
mergedpressors_firsthour[which(mergedpressors2$pressor_type=="vasopressin"),] <- mergedpressors_firsthour[which(mergedpressors_firsthour$pressor_type=="vasopressin"),]%>%
  mutate(vaso_rate = ifelse(vaso_rate<= 0.2, vaso_rate*60, vaso_rate))

# VIS score for each pressor
# MIMIC does not have the rates for milrinone, thus the 0 value
mergedpressors_firsthour2 <- mergedpressors_firsthour%>%mutate(
  vis=case_when(
    pressor_type == "phenyl" ~ vaso_rate*10,
    pressor_type == "milrinone" ~ 0,
    pressor_type == "dobutamine" ~ vaso_rate,
    pressor_type == "dopamine" ~ vaso_rate,
    pressor_type == "norepinephrine" ~ vaso_rate*100,
    pressor_type == "epinephrine" ~ vaso_rate*100,
    pressor_type == "vasopressin" ~ vaso_rate*10000/60 ## that seems way too high # if you copy this remove the division by 60 if U/min
  )
) 

# VIS score summed up for patients on many pressors
vis_first_hour <- mergedpressors_firsthour2%>%group_by(subject_id)%>%
  summarise(vis_first_hour = sum(vis))


#NEE

#NEE score at 24h
mergedpressors3 <- bind_rows(dobutamine_ccu_24 , dopamine_ccu_24, epi_ccu_24, milri_ccu_24, norepi_ccu_24, vasopressin_ccu_24, phenyl_ccu_24)%>%
  select(-c("hadm_id", "icustay_id")) %>%
  group_by(subject_id, pressor_type) %>% 
  summarise(
    starttime = min(starttime), 
    endtime = max(endtime),
    duration_hours = sum(duration_hours),
    vaso_rate = mean(vaso_rate),
    vaso_amount = sum(vaso_amount))%>%
  dplyr::select(-c("starttime","endtime","duration_hours","vaso_amount"))


# Convert all vasopressin doses at same unit (some are in U/min and some in U/h)
mergedpressors3[which(mergedpressors3$pressor_type=="vasopressin"),] <- mergedpressors3[which(mergedpressors3$pressor_type=="vasopressin"),]%>%
  mutate(vaso_rate = ifelse(vaso_rate<= 0.2, vaso_rate*60, vaso_rate))

# VIS score for each pressor
# MIMIC does not have the rates for milrinone, thus the 0 value
mergedpressors3 <- mergedpressors3%>%mutate(
  nee=case_when(
    pressor_type == "phenyl" ~ vaso_rate*0.1,
    pressor_type == "milrinone" ~ 0, #data not available in MIMIC
    pressor_type == "dobutamine" ~ vaso_rate*0.1/15,
    pressor_type == "dopamine" ~ vaso_rate,
    pressor_type == "norepinephrine" ~ vaso_rate,
    pressor_type == "epinephrine" ~ vaso_rate,
    pressor_type == "vasopressin" ~ vaso_rate*2.5/60 #60 because dose here is U/h -> want to convert to U/min then NEE by multiplicating by 2.5
  )
) 



# NEE score summed up for patients on many pressors
nee_24h <- mergedpressors3%>%group_by(subject_id)%>%
  summarise(nee_24h = sum(nee))

                                                                                                    

### NEE at 1 hour

mergedpressors_firsthour3 <- mergedpressors_firsthour%>%mutate(
  nee=case_when(
    pressor_type == "phenyl" ~ vaso_rate*0.1,
    pressor_type == "milrinone" ~ 0, #data not available in MIMIC
    pressor_type == "dobutamine" ~ vaso_rate*0.1/15,
    pressor_type == "dopamine" ~ vaso_rate,
    pressor_type == "norepinephrine" ~ vaso_rate,
    pressor_type == "epinephrine" ~ vaso_rate,
    pressor_type == "vasopressin" ~ vaso_rate*2.5/60 #60 because dose here is U/h -> want to convert to U/min then NEE by multiplicating by 2.5
  )
) 


# VIS score summed up for patients on many pressors
nee_first_hour <- mergedpressors_firsthour3%>%group_by(subject_id)%>%
  summarise(nee_first_hour = sum(nee))                                                                                                   
                                                                                                    
                                                                                                    
### Ethnicity

ccu_query_25 <- "SELECT hadm_id,subject_id, ethnicity FROM `physionet-data.mimiciii_clinical.admissions` 
WHERE hadm_id in 
  (
    SELECT hadm_id
      FROM (
      SELECT subject_id, hadm_id, intime, icustay_id, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
      FROM `physionet-data.mimiciii_clinical.icustays`
      WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)"



ccu_race <- run_query(ccu_query_25)
ccu_race$ethnicity[grep("WHITE",ccu_race$ethnicity)] <- "WHITE"
ccu_race$ethnicity[grep("HISPANIC",ccu_race$ethnicity)] <- "HISPANIC"
ccu_race$ethnicity[grep("HISPANIC",ccu_race$ethnicity)] <- "HISPANIC"
ccu_race$ethnicity[grep("BLACK",ccu_race$ethnicity)] <- "BLACK"
ccu_race$ethnicity[grep("ASIAN",ccu_race$ethnicity)] <- "ASIAN"
ccu_race[-which(ccu_race$ethnicity%in%c("WHITE","HISPANIC","BLACK","ASIAN")),]$ethnicity <- 'OTHER'

# CCU race contains ethinicity of all CCU patients and subject_id
ccu_race <- ccu_race%>%dplyr::select(-hadm_id)


