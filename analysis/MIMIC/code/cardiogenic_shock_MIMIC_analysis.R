#setwd("~/Documents/Bioinformatics/Classes/FALL/HST.953/Git_Files_Cardiogenic/953-2019-team_i/analysis/MIMIC")



#Library load

#install.packages("skimr")
#install.packages("RANN")

source("./code/library_load.R")
library(caret)
library(caretEnsemble)

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

write.csv(mimic_shock, file="mimic_cardiogenic_shock.csv")

## Final dataset ready for analysis

mimic_shock <- mimic%>%filter(scai_shock%in%c("C","D","E"))
mimic_analysis <- mimic_shock%>%
  select(-c("subject_id", "intime", "outtime", "los", "dobutamine_first_hour", "dopamine_first_hour","epinephrine_first_hour", "milrinone_first_hour", 
            "norepinephrine_first_hour","phenyl_first_hour","vasopressin_first_hour","total_pressors_first_hour",
            "any_pressor_first_hour", "thirty_day_mortality", "age_group"))


# Cardiogenic shock table only

write.csv(mimic_analysis, file="mimic_cardiogenic_shock_analysis.csv")


# Function to see descriptive statistics of all variables

skimmed <- skim_to_wide(mimic_analysis)  


# Some column deletion was done in EXCEL + column with NULL > 25%

mimic_analysis <- read_csv("./data/mimic_cardiogenic_shock_analysis_2.csv", col_names = TRUE) %>% select(-X1)

# Final NULL values cleaning pre-analytics

# Create the knn imputation model on the dataset and replacing using KKN  
preProcess_missingdata_model <- preProcess(mimic_analysis, method='knnImpute')
mimic_analysis <- predict(preProcess_missingdata_model, newdata = mimic_analysis)

#mimic_analysis <- replace_na(mimic_analysis, 0)

# Creating training/test data sets

mimic_analysis <- mimic_analysis %>% mutate(id = row_number()) 
train <- mimic_analysis %>% sample_frac(.70)
test  <- anti_join(mimic_analysis, train, by = "id")

train <- train%>%select(-"id")
test <- test%>%select(-"id")

####-----------------------------------------------------------------------############

###     Data analysis



set.seed(100)


trainControl <- trainControl(method="repeatedcv", 
                             number=10, 
                             repeats=3,
                             savePredictions="all", 
                             index = createFolds(mimic_analysis$hospital_mortality, 5),
                             classProbs=TRUE,
                             na.action = na.pass
                             na.rm)

##

trControl <- trainControl(method  = "cv",
                          number  = 5)

fit <- train(hospital_mortality ~ .,
             method     = "knn",
             tuneGrid   = expand.grid(k = 1:10),
             trControl  = trControl,
             metric     = "Accuracy",
             na.action = na.pass,
             data       = train)





algorithmList <- c('regLogistic', 'gbm', 'qda', 'knn', 'svmRadial')


models <- caretList(hospital_mortality ~ ., data=train2, trControl=trainControl, methodList=algorithmList) 
results <- resamples(models)
summary(results)
scales <- list(x=list(relation="free"), y=list(relation="free"))
bwplot(results, scales=scales)

ionosphere <- fread("https://archive.ics.uci.edu/ml/machine-learning-databases/ionosphere/ionosphere.data")

