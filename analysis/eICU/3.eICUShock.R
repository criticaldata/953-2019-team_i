setwd("~/Documents/Bioinformatics/Classes/FALL/HST.953/Git_Files_Cardiogenic/953-2019-team_i/analysis/eICU")



#Library load

#install.packages("skimr")
#install.packages("RANN")

source("./code/library_load.R")


library(skimr)
library(RANN) 

## Data loading 

eicu <- read_csv("./eICU_CCUdata_March13V2.csv", col_names = TRUE)


## Removing duplicate columns

eicu <- eicu[!duplicated(as.list(eicu))]
eicu <- eicu%>%dplyr::select(-c("gender.x", "uniquepid", "X1", "MeanBP_Mean", "MeanBP_Max", "MeanBP_Min", "patienthealthsystemstayid"))
skimmed2 <- skim_to_wide(eicu)

# Cleaning names

eicu <- eicu%>%clean_names(case="snake")

# Identifying unmatched columns

#mimic <- read_csv("../MIMIC/data/FINAL_MIMIC_all_CCU_patients.csv", col_names = TRUE) %>%dplyr::select(-X1)
m <- sort(colnames(mimic))
e <- sort(colnames(eicu))
unmatched <- e[-which(e%in%m)]
unmatched1 <- m[-which(m%in%e)]

eicu <- eicu%>%rename(
  "age"="age_x",
  "mean_bp_mean"="mean_bp_calc",
  "total_pressors_first_hour"="total_pressors_firsthour",
  "any_pressor_first_hour"="any_pressor_firsthour",
  "tropo_i_max"="troponin_i_max",
  "tropo_i_min"="troponin_i_min",
  "tropo_t_max"="troponin_t_min",
  "gcs"="gcs_min",
  "urine_output"="urineoutput",
  "ph_min"="p_h_mean",
  
)

## Replacing NULL values

# 1. Age ?? Not sure that it is like MIMIC - in MIMIC all AGE > 200 was basically patients > 90. In eICU what do does NULL value mean?
#eicu <- eicu%>%mutate(age=replace_na(eicu$age, 95))

# Dropping rows were mortality information not available --- Must figure out how to get this information

# Following columns missing
# 1. bmi
# 2. pci
# 3. cabg
# 4. ethnicity V
# 5. charlson_score V
# 6. sofa
# 7. vis, nee
# 8. ecmo
# 9. creatinine dummies (delta_creat_0_3, doubled_creat) V

# eicu <- eicu%>%drop_na(age)

eicu <- eicu%>%mutate(
  doubled_creat = ifelse(abs(creatinine_max/creatinine_min) >= 1.5, 1, 0),
  delta_creat_0_3 = ifelse(abs(creatinine_max/creatinine_min) >= 0.3, 1, 0))

## Creating Shock Groups

# This definition is obviously modifiable. 
# We should discuss this further as a group.



eicu <- eicu%>%mutate(
  scai_shock = case_when(
    lactate_max > 2 & doubled_creat == 1 ~ "C",
    any_pressor >= 1  ~ "D", #| total_pressors > total_pressors_first_hour 
    any_pressor_firsthour >= 2 | iabp == 1 ~ "E",
    TRUE ~ "NO"
  )
)

# #MIMIC ratio : 40% and in hospital mortality 28%
# #EICU ratio : 35% and in hospital mortality 17%
# 
# The above criterias slightly differ from MIMIC
# I think that lactate and doubling of creatinine are two clinically relevant criterias that we should keep

# Non-shock table to verify that non-shock patients were not forgotten by mistake


# Exploring inclusion criterias

table(eicu$scai_shock)
shock <- eicu[-which(eicu$scai_shock=="NO"),] 
non_shock <- eicu[which(eicu$scai_shock=="NO"),]  #table(eicu$scai_shock)

table(shock$hospital_mortality)
table(non_shock$hospital_mortality)
table(eicu$scai_shock)

# Adding two variables

eicu <- eicu%>%mutate(
  shock_index = heart_rate_mean/sys_bp_min,
  any_inotrope = ifelse(dobutamine== 1 | dopamine == 1| milrinone == 1 ,1, 0)
  )

# All CCU patients table

write.csv(eicu, file="eICU_March13_ALLV2.csv")

## Final dataset ready for analysis

eicu_shock <- eicu%>%filter(scai_shock%in%c("C","D","E"))


# Final Cardiogenic Shock eICU population
write.csv(eicu_shock, file="eICU_March13_CS_selectedV2.csv")


# Removing more variables for data modeling 

eicu <- eicu_shock%>%
  dplyr::select(-c("patientunitstayid", "intime", "outtime", "los_hours", "dobutamine_first_hour", "dopamine_first_hour","epinephrine_first_hour", "milrinone_first_hour", 
            "norepinephrine_first_hour","phenyl_first_hour","vasopressin_first_hour","total_pressors_firsthour",
            "any_pressor_firsthour", "age_group","icu_mortality", "any_pressor", "scai_shock"))

# Additional cleaning has been done in excel to obtain only the final variables included in the analysis
#write.csv(eicu, file="eICU_March13_CS_selected_trimmmed.csv")

# Must verify age - it seems that age group was included here



