#setwd("~/Documents/Bioinformatics/Classes/FALL/HST.953/Git_Files_Cardiogenic/953-2019-team_i/analysis/MIMIC")



#Library load

#install.packages("skimr")
#install.packages("RANN")

source("./code/library_load.R")


library(skimr)
library(RANN) 

## Data loading 

mimic <- read_csv("../MIMIC/data/MIMIC_all_CCU_patients.csv", col_names = TRUE) %>%dplyr::select(-X1)

## Replacing appropriate ages

mimic <- mimic%>%mutate(age=replace_na(mimic$age, 90))

## Creating Shock Groups

# This definition is obviously modifiable. 
# We should discuss this further as a group.

mimic <- mimic%>%mutate(
  scai_shock = case_when(
    lactate_max > 2 & doubled_creat == 1 ~ "C", #| | urine_output < 720 ~ "C", #doubled_creat == 1, & delta_creat_0_3 == 1
    any_pressor >= 1 ~ "D",
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

# Cleaning columns

mimic <- mimic%>%
  select(-c("intime", "outtime", "los","thirty_day_mortality","age_group","icu_mortality"))


mimic <- mimic%>%select(-c("dobutamine_first_hour", "dopamine_first_hour","epinephrine_first_hour", "milrinone_first_hour","norepinephrine_first_hour",
                           "phenyl_first_hour","vasopressin_first_hour", "any_pressor_first_hour", "vis_first_hour","nee_first_hour", 
                           "tropo_t_max", "tropo_t_max", "tropo_t_min", "n_tpro_bnp_max", "n_tpro_bnp_min",
                           "glucose_min_2", "glucose_max_2", "hadm_id", "icustay_id_x_x_x_x", "icustay_id_y_y_y_y", "subject_id", "glucose_mean",
                           "ph_max", "ph_min",
                           "nee_24h", "vis_24h", "sofa", "oasis", "pci", "cabg", "ecmo"))




# ## # # # FROM NOW ON AND BELOW ARE ALL THE VARIABLES AVAILABLE IN BOTH DATASETS 
# ### ###  WE WILL BE LOOKING AT ALL AVAILABLE DATASETS

## Final dataset ready for analysis


write.csv(mimic, file="mimic_ccu_clean.csv")


mimic_shock <- mimic%>%filter(scai_shock%in%c("C","D","E"))


# Final Cardiogenic Shock MIMIC population with all variables
write.csv(mimic_shock, file="mimic_cardiogenic_shock.csv")



