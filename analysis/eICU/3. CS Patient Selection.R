#setwd("~/Documents/Bioinformatics/Classes/FALL/HST.953/Git_Files_Cardiogenic/953-2019-team_i/analysis/MIMIC")



#Library load

install.packages("skimr")
install.packages("RANN")

#source("./code/library_load.R")


library(skimr)
library(RANN) 

## Data loading 

mimic <- read_csv("./eICU_CCUdata_Nov18V2.csv", col_names = TRUE) %>% select(-X1)

## Replacing appropriate ages

#mimic <- mimic%>%mutate(age=replace_na(mimic$age, 95))

## Creating Shock Groups

# This definition is obviously modifiable. 
# We should discuss this further as a group.

mimic <- mimic%>%mutate(
  scai_shock = case_when(
    LACTATE_max > 2   ~ "C", #| | urine_output < 720 ~ "C", #doubled_creat == 1, & delta_creat_0_3 == 1
    any_pressor >= 1 | total_pressors > total_pressors_firsthour ~ "D",
    any_pressor_firsthour >= 2 | iabp == 1 ~ "E",
    TRUE ~ "NO"
  )
)

# Non-shock table to verify that non-shock patients were not forgotten by mistake
non_shock <- mimic[-which(mimic$scai_shock=="NO"),]  #table(mimic$scai_shock)


# Adding two variables

mimic <- mimic%>%mutate(
  shock_index = Mean_BP_Calc/SysBP_Mean,
  any_inotrope = ifelse(dobutamine== 1 | dopamine == 1| milrinone == 1 ,1, 0)
)

# All CCU patients table

write.csv(mimic, file="eICU_filter_.csv")

## Final dataset ready for analysis

mimic_shock <- mimic%>%filter(scai_shock%in%c("C","D","E"))


# Final Cardiogenic Shock MIMIC population
write.csv(mimic_shock, file="eICU_CS_filter_.csv")



### We did pre cleaning of the columns in excel
mimic_analysis <- mimic_shock%>%
  select(-c("patientunitstayid", "intime", "outtime", "los_hours", "dobutamine_first_hour", "dopamine_first_hour","epinephrine_first_hour", "milrinone_first_hour", 
            "norepinephrine_first_hour","phenyl_first_hour","vasopressin_first_hour","total_pressors_firsthour",
            "any_pressor_firsthour", "age_group","icu_mortality", "any_pressor", "scai_shock"))
