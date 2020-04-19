# Preparing EICU and MIMIC

# Loading data 
# Those are the datasets with all variables from file 3.cardiogenicMIMIC and 3.eICUshock 
#mimic_shock <- read_csv("../MIMIC/data/mimic_cardiogenic_shock.csv", col_names = TRUE) %>%dplyr::select(-X1)
#eicu_shock <- read_csv("../MIMIC/data/eicu_cardiogenic_shock.csv", col_names = TRUE) %>%dplyr::select(-X1)



# Cleaning variables ------------------------------------------------------



# Removing variables that are correlated (i.e. min/max)

# MIMIC
mimic_shock <- mimic_shock%>%select(-c("sp_o2_max", "glucose_max", "aniongap_min",
                                             "chloride_min", "bicarbonate_max", "creatinine_min", "creatinine_max", "hematocrit_min", 
                                             "hemoglobin_max","potassium_min", "inr_min", "pt_min", "sodium_max", "bun_min",
                                             "wbc_min"))
# Removing variables with less than 25% of variables
mimic_shock <- mimic_shock%>%select(-c("lactate_min","lactate_max","bilirubin_min", "bilirubin_max", "bmi", "albumin_min", 
                                             "albumin_max","bands_min", "bands_max", "tropo_i_max", "tropo_i_min", "ptt_max", "ptt_min",
                                             "total_pressors_first_hour", "urine_output")) # total pressors first hour is missing in eICU cohort 65%
# Removing some pressors variables
mimic_shock <- mimic_shock%>%select(-c("dobutamine","dopamine","epinephrine", "milrinone","norepinephrine","phenyl", "vasopressin"))
# Removing variables that we do not want to use for prediction
mimic_shock <- mimic_shock%>%select(-c("shock_cardiogenic", "shock_nos", "shock_septic"))
mimic_shock <- mimic_shock%>%select(-c("cardiac_arrest_and_ventricular_fibrillation", "temp_c_min", "temp_c_max"))


# EICU

eicu_shock <- eicu_shock%>%select(-c("sp_o2_max", "glucose_max", "aniongap_min",
                                             "chloride_min", "bicarbonate_max", "creatinine_min", "creatinine_max", "hematocrit_min", 
                                             "hemoglobin_max","potassium_min", "inr_min", "pt_min", "sodium_max", "bun_min",
                                             "wbc_min"))
# Removing variables with less than 25% of variables
eicu_shock <- eicu_shock%>%select(-c("lactate_min","lactate_max","bilirubin_min", "bilirubin_max", "bmi", "albumin_min", 
                                             "albumin_max","bands_min", "bands_max", "tropo_i_max", "tropo_i_min", "ptt_max", "ptt_min",
                                             "total_pressors_first_hour", "urine_output")) # total pressors first hour is missing in eICU cohort 65%
# Removing some pressors variables
eicu_shock <- eicu_shock%>%select(-c("dobutamine","dopamine","epinephrine", "milrinone","norepinephrine","phenyl", "vasopressin"))
# Removing variables that we do not want to use for prediction
eicu_shock <- eicu_shock%>%select(-c("shock_cardiogenic", "shock_nos", "shock_septic"))
eicu_shock <- eicu_shock%>%select(-c("cardiac_arrest_and_ventricular_fibrillation", "temp_c_min", "temp_c_max"))



# Final check -------------------------------------------------------------

compared <- compare_df_cols(eicu_shock,mimic_shock)

# MML imputation
library(mice)
mimic_m <- mice::mice(mimic_shock)
mimic_imputed <- complete(mimic_m)

eicu_m <- mice::mice(eicu_shock)
eicu_imputed <- complete(eicu_m)
eicu_imputed <- eicu_imputed%>%mutate(age=replace_na(eicu_imputed$age, 90))


# Removing one column

mimic_imputed <- mimic_imputed%>%select(-"delta_creat_0_3")
eicu_imputed <- eicu_imputed%>%select(-"delta_creat_0_3")

# Binning -----------------------------------------------------------------
library(rbin)
library(hablar)
library(rlang)

# Verify which columns should be converted to categorical
#categorical <- sapply(mimic_imputed, function(x){(length(unique(x)))})
# Small function converting numeric columns to categorical if <= 13 unique values
mimic_imputed <- mimic_imputed%>%mutate_if(function(x){(length(unique(x)) <= 13)}, function(x){as.factor(x)})
eicu_imputed <- eicu_imputed%>%mutate_if(function(x){(length(unique(x)) <= 13)}, function(x){as.factor(x)})
mimic_imputed$age <- as.numeric(mimic_imputed$age)
eicu_imputed$age <- as.numeric(eicu_imputed$age)

# Adding a random variable for the purpose of the rbin function
eicu_imputed <- eicu_imputed%>%mutate(y=0)
mimic_imputed <- mimic_imputed%>%mutate(y=0)

# Adding training/testing ID 
eicu_imputed <- eicu_imputed%>%mutate(training=1)
eicu_imputed <- eicu_imputed%>%mutate(testing=0)
mimic_imputed <- mimic_imputed%>%mutate(testing=1)
mimic_imputed <- mimic_imputed%>%mutate(training=0)

# Binding the dataset
# This allows us to have an equal bining for both
combined <- rbind(eicu_imputed, mimic_imputed)
# Small function converting numeric columns to categorical if <= 13 unique values
combined <- combined%>%mutate_if(function(x){(length(unique(x)) <= 13)}, function(x){as.factor(x)})
#s <- skim_to_wide(combined)


binning_data <- function(df){
  final <- df
  list <- c()
  for (i in colnames(df[,1:86])){
    # transforming dynamic variable into string
    colName = paste0(quo_name(i)) 
    if (is.numeric(df[,i])){
      # store list of names of continuous columns as those will be deleted and we'll keep only the binned columns
      list[i] = colName
      # Using rbin package to create quantiles of the variables of interest
      bins <- rbin_quantiles(df, y, i, 5)
      # Using those quantiles to create dummy variable 1 hot encoding
      f <- rbin_create(df, i, bins)
      # Create the aggregate dataframe
      final <- merge(final, f)
    }
  }
  # Removing initial continuous columns - We are keeping
  # final <- final%>%select(-list)
  return(final)
}


# Using function to compute binnarization

final <- binning_data(combined)


# Saving the data
write.csv(final, file="final4quantiles.csv")





# Table One ---------------------------------------------------------------


# Data with only selected variables
write.csv(eicu_shock, file="eicu_cardiogenic_shock.csv")
# Data with only selected variables
write.csv(mimic_shock, file="mimic_cardiogenic_shock.csv")


# Converting all columns to appropriate type
mimic_shock <- mimic_shock%>%mutate_if(function(x){(length(unique(x)) <= 13)}, function(x){as.factor(x)})
eicu_shock <- eicu_shock%>%mutate_if(function(x){(length(unique(x)) <= 13)}, function(x){as.factor(x)})
mimic_shock$age <- as.numeric(mimic_shock$age)
eicu_shock$age <- as.numeric(eicu_shock$age)
# s <- skim_to_wide(eicu_shock)

catlist <- names(mimic_shock[sapply(mimic_shock, is.factor)])
alllist <- names(mimic_shock)


# Creating table one
tableOne_eicu <- tableone::CreateTableOne(vars = alllist, data = mimic_shock, factorVars = catlist, test=TRUE) #strata = "trt",

tableone::kableone(tableOne_eicu)

# Creating table one comparing eicu and mimic

eicu_shock_2 <- eicu_shock%>%mutate(group="eicu")
mimic_shock_2 <- mimic_shock%>%mutate(group="mimic")
compared <- rbind(eicu_shock_2, mimic_shock_2)
tableOne_compared <- tableone::CreateTableOne(vars = alllist, data = compared, strata = "group", factorVars = catlist, test=TRUE)

# Creating labels
library(labelled)
var_label(compared) = list(
  acute_cerebrovascular_disease = "Stroke",
  acute_renal_failure = "AKI",
  atrial_fibrillation = "Atrial Fibrillation",
  chronic_kidney_disease  = "Chronic Kidney Disease",
  chronic_obstructive_pulmonary_disease_and_bronchiectasis = "COPD",
  coronary_atherosclerosis = "CAD",
  diabetes_mellitus = "Diabetes Mellitus II",
  heart_valve_disorders = "Heart valve disorders",
  hypertension   = "Hypertension",
  nstemi = "NSTEMI",
  septicemia = "Septicemia",
  stemi = "STEMI",
  heart_rate_min = "Heart Rate (min)",
  heart_rate_max   = "Heart Rate (max)",
  heart_rate_mean = "Heart Rate (mean)",
  sys_bp_min  = "Systolic BP (min)",
  sys_bp_max  = "Systolic BP (max)",
  sys_bp_mean = "Systolic BP (mean)",
  dias_bp_min   = "Diastolic BP (min)",
  dias_bp_max  = "Diastolic BP (max)",
  dias_bp_mean = "Diastolic BP (mean)",
  mean_bp_min = "MAP (min)",
  mean_bp_max= "MAP (max)",
  mean_bp_mean  = "MAP (mean)",
  resp_rate_min = "Respiratory Rate (min)",
  resp_rate_max = "Respiratory Rate (max)",
  resp_rate_mean = "Respiratory Rate (mean)",
  temp_c_mean  = "Temperature (mean)",
  sp_o2_min   = "SpO2 (min)",
  sp_o2_mean = "SpO2 (mean)",
  glucose_min = "Glucose (min)",
  aniongap_max = "Anion Gap (max)",
  bicarbonate_min  = "Bicarbonate (min)",
  chloride_max = "Chloride (max)",
  hematocrit_max  = "Hematocrit (max)",
  hemoglobin_min   = "Hemoglobin (min)",
  platelet_min  = "Platelet (min)",
  platelet_max = "Platelet (max)",
  inr_max = "INR (max)",
  bicarbonate_min  = "Bicarbonate (min)",
  potassium_max = "Potassium (max)",
  inr_max  = "INR (max)",
  pt_max   = "PT (max)",
  sodium_min   = "Sodium (min)",
  bun_max  = "BUN (max)",
  wbc_max  = "WBC (max)",
  rdw_min = "RDW (min)",
  rdw_max  = "RDW (max)",
  delta_creat_0_3 = "Delta Creatine 0.3",
  doubled_creat  = "Ratio Creatine 1.5",
  rrt   = "Renal Replacement Therapy",
  vent  = "Mechanical Ventilation",
  iabp  = "IABP",
  impella = "Impella",
  total_pressors  = "Total pressors",
  any_pressor = "Any pressor",
  gcs = "First GCS score",
  hospital_mortality  = "Hospital Mortality",
  age = "Age",
  charlson_score  = "Charlson Score",
  ethnicity = "Ethnicity",
  pcd = "Pulmonary Circulation Disorders",
  pcd = "Peripheral Vascular Disorders",
  para = "Paralysis",
  ond = "Other neurological disorders;s",
  hypothy = "Hypothyroidism",
  ld = "Liver Disease",
  pud = "Peptic Ulcer Disease",
  aids = "AIDS/HIV",
  lymph = "Lymphoma",
  metacanc = "Metastatic Cancer",
  solidtum = "Pulmonary Circulation Disorders",
  rheumd = "Rheumatoid Arthritis/Collagen Vascular Disease",
  coag = "Coagulopathy",
  obes = "Obesity",
  wloss = "Weight loss",
  fed = "Fluid and Electrolyte Disorders",
  alcohol = "Alcohol Abuse",
  drug = "Drug Abuse",
  psycho = "Psychoses",
  depre = "Depression",
  scai_shock = "Scai Shock category",
  any_inotrope = "Any inotrope",
  shock_index = "Shock Index",
  group = "Cohort",
  gender = "Gender",
  anemia = "Anemia"
  )

print(tableOne_compared, varLabels = TRUE)
tableone_print <- print(tableOne_compared, quote = FALSE, noSpaces = TRUE, printToggle = FALSE, varLabels = TRUE)
write.csv(tableone_print, file = "myTable.csv")

tableone::kableone(tableOne_compared)%>%
  save_kable(file = "table1.html", self_contained = T)

# Another library

library(table1) 
table1(~ . | group, data=compared)


