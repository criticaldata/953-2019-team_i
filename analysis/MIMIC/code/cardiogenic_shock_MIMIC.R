#Library load

source("./code/library_load.R")

## Data loading 

mimic <- read_csv("./data/MIMIC_all_CCU_patients.csv", col_names = TRUE) %>% select(-X1)

## Creating Shock Groups

# This definition is obviously modifiable. 
# We should discuss this further as a group.

mimic <- mimic%>%mutate(
  scai_shock = case_when(
    lactate_max > 2 | delta_creat_0_3 == 1 | urine_output < 720 ~ "C",
    any_pressor >= 1 | total_pressors > total_pressors_first_hour ~ "D",
    any_pressor_first_hour >= 2 | iabp == 1 ~ "E"
  )
)

#table(mimic_shock$scai_shock)


## Final dataset ready for analysis

mimic_shock <- mimic%>%filter(scai_shock%in%c("C","D","E"))

# Analysis below

write.csv(mimic_shock, file="mimic_cardiogenic_shock.csv")
