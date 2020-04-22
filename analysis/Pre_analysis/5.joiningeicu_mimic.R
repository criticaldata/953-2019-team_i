# Preparing EICU and MIMIC

# Loading data 
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
mimic_imputed <- mimic_imputed%>%mutate(age, function(x){as.numeric(x)})
eicu_imputed <- eicu_imputed%>%mutate(age= function(x){as.numeric(x)})
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


