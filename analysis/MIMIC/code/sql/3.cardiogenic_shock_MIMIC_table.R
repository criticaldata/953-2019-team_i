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

mimic <- mimic%>%mutate(age=replace_na(mimic$age, 95))

## Creating Shock Groups

# This definition is obviously modifiable. 
# We should discuss this further as a group.

mimic <- mimic%>%mutate(
  scai_shock = case_when(
    lactate_max > 2   ~ "C", #| | urine_output < 720 ~ "C", #doubled_creat == 1, & delta_creat_0_3 == 1
    any_pressor >= 1 | total_pressors > total_pressors_first_hour ~ "D",
    any_pressor_first_hour >= 2 | iabp == 1 ~ "E",
    TRUE ~ "NO"
  )
)

# Non-shock table to verify that non-shock patients were not forgotten by mistake
non_shock_m <- mimic[which(mimic$scai_shock=="NO"),]  #table(mimic$scai_shock)
shock_m <- mimic[-which(mimic$scai_shock=="NO"),]  #
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



### We did pre cleaning of the columns in excel
mimic_analysis <- mimic_shock%>%
  select(-c("subject_id", "intime", "outtime", "los", "dobutamine_first_hour", "dopamine_first_hour","epinephrine_first_hour", "milrinone_first_hour", 
            "norepinephrine_first_hour","phenyl_first_hour","vasopressin_first_hour","total_pressors_first_hour",
            "any_pressor_first_hour", "thirty_day_mortality", "age_group","icu_mortality", "any_pressor", 
            "delta_creat_0_3", "scai_shock"))




