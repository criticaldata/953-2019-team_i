
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

 
data <- run_query(
"
SELECT patientunitstayid, labid, labresult, labname, labmeasurenamesystem FROM `physionet-data.eicu_crd.lab` 
WHERE patientunitstayid in (SELECT patientunitstayid FROM `physionet-data.eicu_crd_demo.patient` WHERE unittype = 'Cardiac ICU')
order by patientunitstayid
"
)

ccupatients <- run_query(
  "
SELECT patientunitstayid FROM `physionet-data.eicu_crd.patient` WHERE unittype = 'Cardiac ICU'
"
)

ccu_query <- "SELECT patientunitstayid, patienthealthsystemstayid, hospitaladmittime24, hospitaldischargetime24	
FROM (
    SELECT subject_id, hadm_id, intime, outtime, los, ROW_NUMBER() OVER(PARTITION BY hadm_id ORDER BY intime) rn
    FROM `physionet-data.eicu.patient`
    WHERE first_careunit = 'CCU' 
    ) 
x
WHERE rn = 1"


# data2 <- run_query("SELECT pt.patientunitstayid, pt.age, pt.apacheadmissiondx
#  FROM `physionet-data.eicu_crd_demo.patient` pt
#  ORDER BY pt.patientunitstayid; ")
# 
# 
# data3 <- run_query("SELECT pt.patientunitstayid, pt.age, pt.apacheadmissiondx,
# CASE WHEN pt.gender = 'Male' THEN 1
# WHEN pt.gender = 'Female' THEN 2
# ELSE NULL END AS gender,
# CASE WHEN pt.hospitaldischargestatus = 'Alive' THEN 0
# WHEN pt.hospitaldischargestatus = 'Expired' THEN 1
# ELSE NULL END AS hosp_mortality,
# ROUND(pt.unitdischargeoffset/60) AS icu_los_hours
# FROM `physionet-data.eicu_crd_demo.patient` pt
# ORDER BY pt.patientunitstayid;")



# patientunitstayid <-2504725
# df_vitals_eicu<-query_exec(paste("SELECT * FROM `physionet-data_demo.eicu_crd_derived.pivoted_vital` WHERE
# chartoffset <= 1440 AND patientunitstayid =", patientunitstayid,
#                                  "ORDER BY chartoffset")
#                            , project = project_HST,use_legacy_sql = F )
# 

# 
# 
# sql_query <- "SELECT i.uniquepid
#               FROM `physionet-data.eicu_crd_demo.patient` i;"
# data <- run_query(sql_query)
# head(data)
# 
# sql2_query <- "SELECT patientunitstayid
#               FROM `physionet-data.eicu_crd_demo.patient` "
# 
# PID <- run_query(sql2_query)
# qList <- list()
# 
# for (ID in PID){
#   print(ID)
#   list.append(qList,ID)
#   
# }
# 
# 
# data3 <- run_query(
#   
#   "SELECT diagnosisid
#    FROM `physionet-data.eicu_crd_demo.diagnosis` 
#    WHERE patientunitstayid = 200026 "
#   
# )


# data5 = run_query(
# "
# DROP MATERIALIZED VIEW IF EXISTS labsfirstday CASCADE;
# CREATE materialized VIEW labsfirstday AS
# 
# SELECT
# pvt.uniquepid, pvt.patienthealthsystemstayid, pvt.patientunitstayid
# , min(CASE WHEN labname = 'anion gap' THEN labresult ELSE null END) as ANIONGAP_min
# , max(CASE WHEN labname = 'anion gap' THEN labresult ELSE null END) as ANIONGAP_max
# , min(CASE WHEN labname = 'albumin' THEN labresult ELSE null END) as ALBUMIN_min
# , max(CASE WHEN labname = 'albumin' THEN labresult ELSE null END) as ALBUMIN_max
# , min(CASE WHEN labname = '-bands' THEN labresult ELSE null END) as BANDS_min
# , max(CASE WHEN labname = '-bands' THEN labresult ELSE null END) as BANDS_max
# , min(CASE WHEN labname = 'bicarbonate' THEN labresult ELSE null END) as BICARBONATE_min
# , max(CASE WHEN labname = 'bicarbonate' THEN labresult ELSE null END) as BICARBONATE_max
# , min(CASE WHEN labname = 'HCO3' THEN labresult ELSE null END) as HCO3_min -- HCO3 = bicarb, but eICU has both;
# , max(CASE WHEN labname = 'HCO3' THEN labresult ELSE null END) as HCO3_max -- elected not to combine them.
# , min(CASE WHEN labname = 'total bilirubin' THEN labresult ELSE null END) as BILIRUBIN_min
# , max(CASE WHEN labname = 'total bilirubin' THEN labresult ELSE null END) as BILIRUBIN_max
# , min(CASE WHEN labname = 'creatinine' THEN labresult ELSE null END) as CREATININE_min
# , max(CASE WHEN labname = 'creatinine' THEN labresult ELSE null END) as CREATININE_max
# , min(CASE WHEN labname = 'chloride' THEN labresult ELSE null END) as CHLORIDE_min
# , max(CASE WHEN labname = 'chloride' THEN labresult ELSE null END) as CHLORIDE_max
# , min(CASE WHEN labname = 'glucose' THEN labresult ELSE null END) as GLUCOSE_min
# , max(CASE WHEN labname = 'glucose' THEN labresult ELSE null END) as GLUCOSE_max
# , min(CASE WHEN labname = 'Hct' THEN labresult ELSE null END) as HEMATOCRIT_min
# , max(CASE WHEN labname = 'Hct' THEN labresult ELSE null END) as HEMATOCRIT_max
# , min(CASE WHEN labname = 'Hgb' THEN labresult ELSE null END) as HEMOGLOBIN_min
# , max(CASE WHEN labname = 'Hgb' THEN labresult ELSE null END) as HEMOGLOBIN_max
# , min(CASE WHEN labname = 'lactate' THEN labresult ELSE null END) as LACTATE_min
# , max(CASE WHEN labname = 'lactate' THEN labresult ELSE null END) as LACTATE_max
# , min(CASE WHEN labname = 'platelets x 1000' THEN labresult ELSE null END) as PLATELET_min
# , max(CASE WHEN labname = 'platelets x 1000' THEN labresult ELSE null END) as PLATELET_max
# , min(CASE WHEN labname = 'potassium' THEN labresult ELSE null END) as POTASSIUM_min
# , max(CASE WHEN labname = 'potassium' THEN labresult ELSE null END) as POTASSIUM_max
# , min(CASE WHEN labname = 'PTT' THEN labresult ELSE null END) as PTT_min
# , max(CASE WHEN labname = 'PTT' THEN labresult ELSE null END) as PTT_max
# , min(CASE WHEN labname = 'PT - INR' THEN labresult ELSE null END) as INR_min
# , max(CASE WHEN labname = 'PT - INR' THEN labresult ELSE null END) as INR_max
# , min(CASE WHEN labname = 'PT' THEN labresult ELSE null END) as PT_min
# , max(CASE WHEN labname = 'PT' THEN labresult ELSE null END) as PT_max
# , min(CASE WHEN labname = 'sodium' THEN labresult ELSE null END) as SODIUM_min
# , max(CASE WHEN labname = 'sodium' THEN labresult ELSE null end) as SODIUM_max
# , min(CASE WHEN labname = 'BUN' THEN labresult ELSE null end) as BUN_min
# , max(CASE WHEN labname = 'BUN' THEN labresult ELSE null end) as BUN_max
# , min(CASE WHEN labname = 'WBC x 1000' THEN labresult ELSE null end) as WBC_min
# , max(CASE WHEN labname = 'WBC x 1000' THEN labresult ELSE null end) as WBC_max
# 
# 
# FROM
# ( -- begin query that extracts the data
#   SELECT p.uniquepid, p.patienthealthsystemstayid, p.patientunitstayid, le.labname
# 
#   -- add in some sanity checks on the values; same checks from original MIMIC version
#   -- the where clause below requires all labresult to be > 0, so these are only upper limit checks
#   , CASE
#   WHEN labname = 'albumin' and le.labresult >    10 THEN null -- g/dL 'ALBUMIN'
#   WHEN labname = 'anion gap' and le.labresult > 10000 THEN null -- mEq/L 'ANION GAP'
#   WHEN labname = '-bands' and le.labresult <     0 THEN null -- immature band forms, %
#   WHEN labname = '-bands' and le.labresult >   100 THEN null -- immature band forms, %
#   WHEN labname = 'bicarbonate' and le.labresult > 10000 THEN null -- mEq/L 'BICARBONATE'
#   WHEN labname = 'HCO3' and le.labresult > 10000 THEN null -- mEq/L 'BICARBONATE'
#   WHEN labname = 'bilirubin' and le.labresult >   150 THEN null -- mg/dL 'BILIRUBIN'
#   WHEN labname = 'chloride' and le.labresult > 10000 THEN null -- mEq/L 'CHLORIDE'
#   WHEN labname = 'creatinine' and le.labresult >   150 THEN null -- mg/dL 'CREATININE'
#   WHEN labname = 'glucose' and le.labresult > 10000 THEN null -- mg/dL 'GLUCOSE'
#   WHEN labname = 'Hct' and le.labresult >   100 THEN null -- % 'HEMATOCRIT'
#   WHEN labname = 'Hgb' and le.labresult >    50 THEN null -- g/dL 'HEMOGLOBIN'
#   WHEN labname = 'lactate' and le.labresult >    50 THEN null -- mmol/L 'LACTATE'
#   WHEN labname = 'platelets x 1000' and le.labresult > 10000 THEN null -- K/uL 'PLATELET'
#   WHEN labname = 'potassium' and le.labresult >    30 THEN null -- mEq/L 'POTASSIUM'
#   WHEN labname = 'PTT' and le.labresult >   150 THEN null -- sec 'PTT'
#   WHEN labname = 'PT - INR' and le.labresult >    50 THEN null -- 'INR'
#   WHEN labname = 'PT' and le.labresult >   150 THEN null -- sec 'PT'
#   WHEN labname = 'sodium' and le.labresult >   200 THEN null -- mEq/L == mmol/L 'SODIUM'
#   WHEN labname = 'BUN' and le.labresult >   300 THEN null -- 'BUN'
#   WHEN labname = 'WBC x 1000' and le.labresult >  1000 THEN null -- 'WBC'
#   ELSE le.labresult
#   END AS labresult
# 
#   FROM patient p
# 
#   LEFT JOIN lab le
#   ON p.patientunitstayid = le.patientunitstayid
#   AND le.labresultoffset <= 1440
#   AND le.labname in
#   (
#     'anion gap',
#     'albumin',
#     '-bands',
#     'bicarbonate',
#     'HCO3',
#     'total bilirubin',
#     'creatinine',
#     'chloride',
#     'glucose',
#     'Hct',
#     'Hgb',
#     'lactate',
#     'platelets x 1000',
#     'potassium',
#     'PTT',
#     'PT - INR',
#     'PT',
#     'sodium',
#     'BUN',
#     'WBC x 1000'
#   )
#   AND labresult IS NOT null AND labresult > 0 -- lab values cannot be 0 and cannot be negative
# ) pvt
# GROUP BY pvt.uniquepid, pvt.patienthealthsystemstayid, pvt.patientunitstayid
# ORDER BY pvt.uniquepid, pvt.patienthealthsystemstayid, pvt.patientunitstayid;")
