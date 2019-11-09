#setwd("~/Documents/Bioinformatics/Classes/FALL/HST.953/Git_Files_Cardiogenic/953-2019-team_i/analysis/MIMIC")



#Library load

#install.packages("skimr")
#install.packages("RANN")

source("./code/library_load.R")


library(skimr)
library(RANN) 

## Data loading 

mimic <- read_csv("./data/MIMIC_all_CCU_patients.csv", col_names = TRUE) %>% select(-X1)

## Creating Shock Groups

# This definition is obviously modifiable. 
# We should discuss this further as a group.

mimic <- mimic%>%mutate(
  scai_shock = case_when(
    lactate_max > 2 ~ "C", #| delta_creat_0_3 == 1 | urine_output < 720 ~ "C",
    any_pressor >= 1 | total_pressors > total_pressors_first_hour ~ "D",
    any_pressor_first_hour >= 2 | iabp == 1 ~ "E"
  )
)



# All CCU patients table
mimic <- mimic%>%mutate(age=replace_na(mimic$age, 95))

write.csv(mimic, file="mimic_cardiogenic_shock_tableau.csv")

## Final dataset ready for analysis

mimic_shock <- mimic%>%filter(scai_shock%in%c("C","D","E"))
mimic_analysis <- mimic_shock%>%
  select(-c("subject_id", "intime", "outtime", "los", "dobutamine_first_hour", "dopamine_first_hour","epinephrine_first_hour", "milrinone_first_hour", 
            "norepinephrine_first_hour","phenyl_first_hour","vasopressin_first_hour","total_pressors_first_hour",
            "any_pressor_first_hour", "thirty_day_mortality", "age_group"))


# Cardiogenic shock table only

#write.csv(mimic_analysis, file="mimic_cardiogenic_shock_analysis.csv")


# Function to see descriptive statistics of all variables

skimmed <- skim_to_wide(mimic_analysis)  


# Some column deletion was done in EXCEL + column with NULL > 25% and saved as the final csv file.

