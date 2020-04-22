#setwd("~/Documents/Bioinformatics/Classes/FALL/HST.953/Git_Files_Cardiogenic/953-2019-team_i/analysis/MIMIC")



#Library load

#install.packages("skimr")
#install.packages("RANN")

source("./code/library_load.R")


library(skimr)
library(RANN) 

## Data loading 

mimic <- read_csv("../MIMIC/data/FINAL_MIMIC_all_CCU_patients.csv", col_names = TRUE) %>%dplyr::select(-X1)

## Replacing appropriate ages

mimic <- mimic%>%mutate(age=replace_na(mimic$age, 90))

## Creating Shock Groups

# This definition is obviously modifiable. 
# We should discuss this further as a group.

mimic <- mimic%>%mutate(
  scai_shock = case_when(
    lactate_max > 2 & doubled_creat == 1 ~ "C", #| | urine_output < 720 ~ "C", #doubled_creat == 1, & delta_creat_0_3 == 1
    any_pressor >= 1 | total_pressors > total_pressors_first_hour ~ "D",
    any_pressor_first_hour >= 2 | iabp == 1 ~ "E",
    TRUE ~ "NO"
  )
)

# Non-shock table to verify that non-shock patients were not forgotten by mistake
non_shock_m <- mimic[which(mimic$scai_shock=="NO"),]  #table(mimic$scai_shock)
shock_m <- mimic[-which(mimic$scai_shock=="NO"),]  #
table(mimic_shock$scai_shock)
#shock_m <- shock_m%>%select(subject_id) Only the index of patients in shock
#write.csv(shock_m, file="mimic_cardiogenic_shock_id.csv")
table(shock_m$hospital_mortality)


# Adding two variables

mimic <- mimic%>%mutate(
  shock_index = heart_rate_mean/sys_bp_mean,
  any_inotrope = ifelse(dobutamine== 1 | dopamine == 1| milrinone == 1 ,1, 0)
  )

# All CCU patients table

write.csv(mimic, file="mimic_ccu.csv")

## Final dataset ready for analysis

mimic_shock <- mimic%>%filter(scai_shock%in%c("C","D","E"))


# Final Cardiogenic Shock MIMIC population
write.csv(mimic_shock, file="mimic_cardiogenic_shock.csv")



### Variables selection
mimic_analysis <- mimic_shock%>%
  select(-c("intime", "outtime", "los", "dobutamine_first_hour", "dopamine_first_hour","epinephrine_first_hour", "milrinone_first_hour", 
            "norepinephrine_first_hour","phenyl_first_hour","vasopressin_first_hour", "any_pressor_first_hour", "thirty_day_mortality", 
            "age_group","icu_mortality", "delta_creat_0_3"))

#colnames(mimic_analysis)

# Removing duplicate vitals and labs
mimic_analysis <- mimic_analysis%>%select(-c("heart_rate_min","heart_rate_max", "sys_bp_min","sys_bp_max", "dias_bp_max", "dias_bp_min",
                                             "mean_bp_min", "mean_bp_max", "resp_rate_min", "resp_rate_max", "temp_c_min", "temp_c_max",
                                             "sp_o2_min", "sp_o2_max", "glucose_min", "glucose_max", "bands_min", "bands_max", "aniongap_min",
                                             "chloride_min", "tropo_i_max",
                                             "bilirubin_min", "bilirubin_max","albumin_min", "albumin_max", "bicarbonate_max", "creatinine_min",
                                             "creatinine_max", "glucose_min_2", "glucose_max_2", "hematocrit_min", "hemoglobin_max","lactate_min",
                                             "lactate_max", "platelet_min", "potassium_min", "ptt_min", "inr_min", "pt_min", "sodium_max", "bun_min",
                                             "wbc_min", "tropo_i_max", "tropo_i_min", "tropo_t_max", "tropo_t_max", "tropo_t_min", "n_tpro_bnp_max", "n_tpro_bnp_min",
                                             "ph_max", "rdw_min"))

# Removing some pressors variables
mimic_analysis <- mimic_analysis%>%select(-c("dobutamine","dopamine","epinephrine", "milrinone","norepinephrine","phenyl", "vasopressin", "total_pressors_first_hour", 
                         "vis_first_hour","nee_first_hour"))

# Removing some identification variables 
mimic_analysis <- mimic_analysis%>%select(-c("subject_id", "icustay_id", "hadm_id", "scai_shock"))

# Removing potential arrest surrogates temp and gcs
mimic_analysis <- mimic_analysis%>%select(-c("gcs", "temp_c_mean"))

# Must add here the NLP variable for cardiac arrest

# Final MIMIC cardiogenic shock ready for analysis
write.csv(mimic_analysis, file="mimic_cardiogenic_shock_analysis.csv")


