
# Loading library + file --------------------------------------------------

setwd("~/Documents/Bioinformatics/Classes/FALL/HST.953/Git_Files_Cardiogenic/953-2019-team_i/analysis/Predictive Models")
source("./library_load.R")
library(caret)
library(caretEnsemble)

library(skimr)
library(RANN) 
library(healthcareai)


library(gbm)
library(glmnet)
library(kknn)
library(knn)
library(MASS)

library(DALEX) # explainers of model
library(esquisse) # https://github.com/dreamRs/esquisse # ggplot addon
library(infer) # stastical analysis with gg grammar


# NULL values cleaning pre-analytics - this file is ready for analysis with only 1 predictor with more 25% of NULL. Others were deleted in Excel before importation.
eicu <- read_csv("./eicu_cardiogenic_shock_selected.csv", col_names = TRUE)%>%dplyr::select(-c("X1"))
mimic <- read_csv("./mimic_cardiogenic_shock_selected.csv", col_names = TRUE)%>%dplyr::select(-"X1")


# Null values imputation --------------------------------------------------

# Missing data observation

missing_eicu<- as.data.frame(arrange(healthcareai::missingness(eicu), desc(percent_missing)))
missing_mimic<- as.data.frame(arrange(healthcareai::missingness(mimic), desc(percent_missing)))

write.csv(missing_eicu, file="missing_eicu.csv")
write.csv(missing_mimic, file="missing_mimic.csv")


# MML imputation
library(mice)

eicu_m <- mice(eicu)
eicu <- complete(eicu_m, 1)

mimic_m <- mice::mice(mimic)
mimic <- complete(mimic_m, 1)

#write.csv(eicu, file="imputed_eicu.csv")
#write.csv(mimic, file="imputed_mimic.csv")
# Weka file

m <- sort(colnames(mimic))
e <- sort(colnames(eicu))
matched <- e[which(e%in%m)]
eicu_w <- eicu[, matched]
mimic_w <- mimic[, matched]
write.arff(eicu_w ,file= "imputed_eicu_w.arff")

eicu <- read_csv("./imputed_eicu.csv", col_names = TRUE)%>%dplyr::select(-c("X1"))
mimic <- read_csv("./imputed_mimic.csv", col_names = TRUE)%>%dplyr::select(-"X1")





# s <- skim_to_wide(mimic_analysis) # verify imputation

#Variable transformation

#paste0(c[44:55], collapse="','")


eicu <- eicu%>%mutate_at(c('acute_cerebrovascular_disease','acute_renal_failure','anemia','atrial_fibrillation','blood_malignancy',
'cardiac_arrest_and_ventricular_fibrillation','chronic_kidney_disease','chronic_obstructive_pulmonary_disease_and_bronchiectasis',
'coronary_atherosclerosis','diabetes_mellitus','heart_valve_disorders','hypertension','neoplasms','nstemi','septicemia',
'shock_cardiogenic','shock_nos','shock_septic','stemi'), function(x){fct_recode(as.factor(x),"yes"="1", "no"="0")})
eicu <- eicu%>%mutate_at('gender', function(x){as.factor(x)}) 
eicu <- eicu%>%mutate_at(c("rrt",'vent','iabp','impella','dopamine','dobutamine','norepinephrine','epinephrine','phenyl','vasopressin','milrinone','total_pressors'), 
                         function(x){fct_recode(as.factor(x),"yes"="1", "no"="0")})
eicu <- eicu%>%mutate_at(c("hospital_mortality","doubled_creat","delta_creat_0_3", "any_inotrope"), function(x){fct_recode(as.factor(x),"yes"="1", "no"="0")})
eicu <- eicu%>%mutate_at("ethnicity", function(x){as.factor(x)})
#eicu <- eicu%>%dplyr::select(-c("delta_creat_0_3", "gender")) 
eicu <- eicu%>%dplyr::select(-c("delta_creat_0_3", "gender","ethnicity")) 
eicu <- eicu%>%dplyr::select(-impella)


mimic <- mimic%>%mutate_at(c('acute_cerebrovascular_disease','acute_renal_failure','anemia','atrial_fibrillation','blood_malignancy',
                           'cardiac_arrest_and_ventricular_fibrillation','chronic_kidney_disease','chronic_obstructive_pulmonary_disease_and_bronchiectasis',
                           'coronary_atherosclerosis','diabetes_mellitus','heart_valve_disorders','hypertension','neoplasms','nstemi','septicemia',
                           'shock_cardiogenic','shock_nos','shock_septic','stemi'), function(x){fct_recode(as.factor(x),"yes"="1", "no"="0")})
mimic <- mimic%>%mutate_at('gender', function(x){as.factor(x)}) 
mimic <- mimic%>%mutate_at(c("rrt",'vent','iabp','impella','dopamine','dobutamine','norepinephrine','epinephrine','phenyl','vasopressin','milrinone','total_pressors',
                             "doubled_creat", "cabg", "pci", "vis_24h", "vis_first_hour", "nee_24h", "nee_first_hour", "any_inotrope"), 
                         function(x){fct_recode(as.factor(x),"yes"="1", "no"="0")})
mimic <- mimic%>%mutate_at("hospital_mortality", function(x){fct_recode(as.factor(x),"yes"="1", "no"="0")})
mimic <- mimic%>%mutate_at("ethnicity", function(x){as.factor(x)})


eicu <- eicu%>%rename(
  "ph_min"="p_h_mean",
  "mean_bp_mean"="mean_bp_calc"
  )

mimic <- mimic%>%rename(
  "glucose_min"="glucose_min_2",
  "sodium_min" ="sodium_max",
  "urineoutput"="urine_output",
  "gcs_min"="gcs"
)


eicu_analysis <- eicu
mimic_analysis <- mimic


# Data Visualization ------------------------------------------------------



p <-ggplot(mimic, aes(x=temp_c_mean, fill=cardiac_arrest_and_ventricular_fibrillation)) +
  geom_histogram(position="stack", alpha=0.5, bins = 20) +
  theme(legend.position="top", axis.text.x = element_text(angle=90, hjust=1))+
  labs(title="Variables distribution in the dataset",x="Temp", y = "Count", fill="Cardiac Arrest")

p


g <-ggplot(mimic, aes(x=hospital_mortality, fill=hospital_mortality)) +
  geom_bar() +
  stat_count()+
  theme(legend.position="top", axis.text.x = element_text(angle=0, hjust=1))+
  labs(x="MIMIC III Hospital Mortality", y = "Count", fill = "In-hospital mortality")

g 

g <-ggplot(eicu, aes(x=hospital_mortality, fill=hospital_mortality)) +
  geom_bar() +
  stat_count()+
  theme(legend.position="top", axis.text.x = element_text(angle=0, hjust=1))+
  labs(x="eICU Hospital Mortality", y = "Count", fill = "In-hospital mortality")

g 

g <-ggplot(eicu_balanced, aes(x=hospital_mortality, fill=hospital_mortality)) +
  geom_bar() +
  stat_count()+
  theme(legend.position="top", axis.text.x = element_text(angle=0, hjust=1))+
  labs(x="eICU ROSE  Hospital Mortality", y = "Count", fill = "In-hospital mortality")

g 


# Cardiac arrest and temperature 

e <- eicu%>%filter(cardiac_arrest_and_ventricular_fibrillation==1)
m <- mimic%>%filter(cardiac_arrest_and_ventricular_fibrillation==1)

table(e$gcs_min)
table(m$gcs)


# Data partition ----------------------------------------------------------


# Creating training/test data sets

eicu_analysis <- eicu_analysis %>% mutate(id = row_number()) 
train <- eicu_analysis %>% sample_frac(.70)
test  <- anti_join(eicu_analysis , train, by = "id")


# Variables exploration ---------------------------------------------------


# Subset selection

# # A) Exploration of correlation and removing higly correlated samples

# library(mlbench)
# correlation_var <- cor(eicu,eicu$hospital_mortality)
# correlationMatrix <- cor(eicu[,-57])
# highlyCorrelated <- findCorrelation(correlationMatrix, cutoff=0.5)


# #Method1 - not Caret
# 
# library(MASS)
# logistic_reg_model_sub <- logistic_reg_model$finalModel %>% stepAIC(trace = FALSE)
# #coef(logistic_reg_model_sub)

#Method2 - Recursive Feature Elimination

subsets <- c(8,30)

library(randomForest)

ctrl <- rfeControl(functions = rfFuncs,
                   method = "cv",
                   number = 3,
                   verbose = FALSE)

rfFuncs$summary <- twoClassSummary # did not work ?

mimic <- mimic%>%select(-c("vis_24h", "vis_first_hour", "nee_24h", "nee_first_hour"))
# Convert character to factor for RFE algorithm

lmProfile <- rfe(x=mimic[,-65], y=mimic[[65]],
                 sizes = subsets,
                 metric = "ROC",
                 rfeControl = ctrl)

plot(lmProfile)

importance <- varImp(lmProfile, scale=FALSE)

plot(importance)

# #Method3 - bestglm
# 
# library(bestglm)
# Xy <- cbind(eicu_analysis[,-57], eicu_analysis[,57])
# BestCV <- bestglm(Xy, IC="CV", t=10) # cross-validation
# summary(BestCV$BestModel)


# #Method4 - PCA
# library()
# mimic_analysis_1=mimic_analysis %>% mutate_if(is.factor, as.numeric)
# mimic.pca <- prcomp(mimic_analysis_1, scale = TRUE, center = TRUE)
# summary(mimic.pca)
# 
# library(factoextra)
# 
# fviz_pca_var(mimic.pca,
#              col.var = "contrib", # Color by 
#              #contribution to the PC
#              repel = TRUE     # Make sure 
#              #text doesn't overlap
# )






# Model creation/training - Caret parameter ----------------------------------------------------------



set.seed(100)

f1 <- function(data, lev = NULL, model = NULL) {
  f1_val <- F1_Score(y_pred = data$pred, y_true = data$obs, positive = lev[1])
  c(F1 = f1_val)
}

twoClassSummaryCustom = function (data, lev = NULL, model = NULL) 
{
  lvls <- levels(data$obs)
  if (length(lvls) > 2)
    stop(paste("Your outcome has", length(lvls), "levels. The twoClassSummary() function isn't appropriate."))
  if (!all(levels(data[, "pred"]) == lvls)) 
    stop("levels of observed and predicted data do not match")
  rocAUC <- ModelMetrics::auc(ifelse(data$obs == lev[2], 0, 
                                     1), data[, lvls[1]])
  out <- c(rocAUC,
           sensitivity(data[, "pred"], data[, "obs"], lev[1]),
           specificity(data[, "pred"], data[, "obs"], lev[2]),
           posPredValue(data[, "pred"], data[, "obs"], lev[1]))
  names(out) <- c("ROC", "Sens", "Spec", "Prec")
  out
}

trControl <- trainControl(method  = "cv",
                          number  = 5,
                          summaryFunction =  twoClassSummaryCustom, #Needed for ROC metric
                          savePredictions = "all", #Needed for thresholder
                          classProbs = T #Needed for classification
                          ) 

finalmodel <- trainControl(method  = "none",
                          summaryFunction =  twoClassSummaryCustom,
                          classProbs = T 
) 




# Class imbalance correction ----------------------------------------------

library(ROSE)
eicu_balanced <- ROSE(hospital_mortality ~ ., data  = eicu)$data                         
table(eicu_balanced$hospital_mortality) 

write.csv(eicu_balanced, file="rose_eicu.csv")

# Logistic Models - not balanced --------- ######

eicu_f <-  eicu%>%dplyr::select(-c("albumin_min"))



logistic_reg_model_f <- train(hospital_mortality ~ .,
                            method     = "glmStepAIC",
                            metric     = "ROC",
                            trControl  = trControl,
                            data       = eicu)

logistic_reg_model <- train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + neoplasms + coronary_atherosclerosis + chronic_obstructive_pulmonary_disease_and_bronchiectasis +
                              age + heart_rate_mean + mean_bp_mean + resp_rate_mean + temp_c_mean + sp_o2_mean + aniongap_max + ph_min + bun_max + doubled_creat +
                              vent + any_inotrope + total_pressors + phenyl + norepinephrine + dopamine + milrinone + dobutamine + epinephrine + vasopressin,
                            method     = "glm",
                            metric     = "ROC",
                            trControl  = trControl,
                            data       = eicu_analysis)

logistic_reg_model_regularized <- caret::train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + neoplasms + coronary_atherosclerosis + chronic_obstructive_pulmonary_disease_and_bronchiectasis +
                              age + heart_rate_mean + mean_bp_mean + resp_rate_mean + temp_c_mean + sp_o2_mean + aniongap_max + ph_min + bun_max + doubled_creat +
                              vent + any_inotrope + total_pressors + phenyl + norepinephrine + dopamine + milrinone + dobutamine + epinephrine + vasopressin,
                            method     = "glmnet",
                            metric     = "ROC",
                            trControl  = trControl,
                            data       = eicu_analysis)

# plot(coef(logistic_reg_model_reg$finalModel, logistic_reg_model_reg$bestTune$lambda))

logistic_reg_model2 <- train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + mean_bp_mean + sp_o2_mean + 
                               resp_rate_mean + heart_rate_mean + bun_max + aniongap_max + age + neoplasms + any_inotrope,
                            method     = "glm",
                            metric     = "ROC",
                            trControl  = trControl,
                            data       = eicu_analysis)


logistic_reg_model3 <- caret::train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + mean_bp_mean + sp_o2_mean + 
                               resp_rate_mean + heart_rate_mean + bun_max + aniongap_max + 
                               age + neoplasms + any_inotrope + total_pressors + vent + temp_c_mean,
                             method     = "glm",
                             metric     = "ROC",
                             trControl  = trControl,
                             data       = eicu)

logistic_reg_model_bestsub <- train(hospital_mortality ~ acute_cerebrovascular_disease + cardiac_arrest_and_ventricular_fibrillation + neoplasms + coronary_atherosclerosis + chronic_obstructive_pulmonary_disease_and_bronchiectasis +
                              age + heart_rate_mean + mean_bp_mean + resp_rate_mean + temp_c_mean + sp_o2_mean + aniongap_max + ph_min + bun_max + doubled_creat +
                              vent + any_inotrope + total_pressors + phenyl + norepinephrine + dopamine + milrinone + dobutamine + epinephrine + vasopressin,
                            method     = "glm",
                            metric     = "ROC",
                            trControl  = trControl,
                            data       = eicu_analysis)



logistic_reg_model_newest <- train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + shock_index + acute_cerebrovascular_disease + sp_o2_mean + vent +
                                     resp_rate_mean + bun_max + aniongap_max + age,
                             method     = "glm",
                             metric     = "ROC",
                             trControl  = trControl,
                             data       = eicu_analysis)

summary(logistic_reg_model_newest2$finalModel)

logistic_reg_model_newest2 <- train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + shock_index + acute_cerebrovascular_disease  + vent +
                                    bun_max + aniongap_max + neoplasms +  age,
                                   method     = "glm",
                                   metric     = "ROC",
                                   trControl  = trControl,
                                   data       = eicu_analysis)



library
cp <- cutpointr(eicu, sp_o2_mean, hospital_mortality, 
                method = maximize_metric, metric = cohens_kappa, pos_class = "yes")
cp

logistic_reg_model_final <- train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + shock_index + vent + I(sp_o2_mean < 90) + I(bun_max >50)  + I(age > 65) + 
                              I(aniongap_max>15) ,
                            method     = "glm",
                            metric     = "Prec",
                            trControl  = trControl,
                            data       = eicu_analysis)



library(ggstatsplot)
ggstatsplot::ggcoefstats(
  x = logistic_reg_model_newest_cat$finalModel,
  conf.level = 0.95,
  title = "Final Logistic Regression",
  package = "rcartocolor",
  palette = "Vivid"
)

ggstatsplot::ggcoefstats(
  x = logistic_reg_model_newest_cat$finalModel,
  meta.analytic.effect = TRUE,
  statistic = "t",
  package = "LaCroixColoR",
  palette = "paired"
)



# Probability threshold
# 
# resample_stats <- thresholder(logistic_reg_model, 
#                               threshold = seq(.5, 1, by = 0.05), 
#                               final = TRUE)
# 
# ggplot(resample_stats, aes(x = prob_threshold, y = J)) + 
#   geom_point()
# 
# ggplot(resample_stats, aes(x = prob_threshold, y = Dist)) + 
#   geom_point()
# 
# ggplot(resample_stats, aes(x = prob_threshold, y = Sensitivity)) + 
#   geom_point() + 
#   geom_point(aes(y = Specificity), col = "red")



summary(logistic_reg_model)
confusionMatrix(logistic_reg_model)
varImp(logistic_reg_model)
plot(varImp(logistic_reg_model3))

summary(logistic_reg_model)
confusionMatrix(logistic_reg_model)


# CV testing accuracy 


predictions <- predict(logistic_reg_model, test)
accuracy_lreg_test   <- mean(predictions == test$hospital_mortality)
test_confusion_M <- confusionMatrix(reference = test$hospital_mortality, data = predictions)



# Logistic Models - balanced ----------------------------------------------

logistic_reg_model_balanced <- train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + neoplasms + coronary_atherosclerosis + chronic_obstructive_pulmonary_disease_and_bronchiectasis +
                                  age + heart_rate_mean + mean_bp_mean + resp_rate_mean + temp_c_mean + sp_o2_mean + aniongap_max + ph_min + bun_max + doubled_creat +
                                  vent + any_inotrope + total_pressors + phenyl + norepinephrine + dopamine + milrinone + dobutamine + epinephrine + vasopressin,
                                method     = "glmStepAIC",
                                metric     = "ROC",
                                trControl  = trControl,
                                data       = eicu_balanced)


logistic_reg_model_sub_balanced <- train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + mean_bp_mean + sp_o2_mean + 
                               resp_rate_mean + heart_rate_mean + bun_max + aniongap_max + 
                               age + neoplasms + vent + temp_c_mean + coronary_atherosclerosis + charlson_score,
                             method     = "glm",
                             metric     = "ROC",
                             trControl  = trControl,
                             data       = eicu_balanced)




# Determining cut-points --------------------------------------------------

install.packages("cutpointr")
library(cutpointr)

# Cut-off using balanced - in that case, total utility is relevant

cp <- cutpointr(eicu_balanced, mean_bp_mean, hospital_mortality, 
                method = maximize_metric, metric = total_utility, pos_class = "yes")

cp <- cutpointr(eicu_balanced, heart_rate_mean, hospital_mortality, 
                method = maximize_metric, metric = total_utility, pos_class = "yes")

cp <- cutpointr(eicu_balanced, resp_rate_mean, hospital_mortality, 
                method = maximize_metric, metric = total_utility, pos_class = "yes")

cp <- cutpointr(eicu_balanced, bun_max, hospital_mortality, 
                method = maximize_metric, metric = total_utility, pos_class = "yes")

cp <- cutpointr(eicu_balanced, aniongap_max, hospital_mortality, 
                method = maximize_metric, metric = total_utility, pos_class = "yes")

cp <- cutpointr(eicu_balanced, sp_o2_mean, hospital_mortality, 
                method = maximize_metric, metric = total_utility, pos_class = "yes")

cp <- cutpointr(eicu_balanced, age, hospital_mortality, 
                method = maximize_metric, metric = total_utility, pos_class = "yes")

cp <- cutpointr(eicu_balanced, temp_c_mean, hospital_mortality, 
                method = maximize_metric, metric = total_utility, pos_class = "yes")

# Cut-off using original dataset - in that case, specificity increase is relevant

cp <- cutpointr(eicu, mean_bp_mean, hospital_mortality, 
                method = maximize_metric, metric = spec_constrain, constrain_metric=sum_sens_spec, min_constrain = 1.1, pos_class = "yes")

cp <- cutpointr(eicu, heart_rate_mean, hospital_mortality, 
                method = maximize_metric, metric = spec_constrain, constrain_metric=sum_sens_spec, min_constrain = 1.1, pos_class = "yes")

cp <- cutpointr(eicu, resp_rate_mean, hospital_mortality, 
                method = maximize_metric, metric = spec_constrain, constrain_metric=sum_sens_spec, min_constrain = 1.1, pos_class = "yes")

cp <- cutpointr(eicu, bun_max, hospital_mortality, 
                method = maximize_metric, metric = spec_constrain, constrain_metric=sum_sens_spec, min_constrain = 1.1, pos_class = "yes")

cp <- cutpointr(eicu, aniongap_max, hospital_mortality, 
                method = maximize_metric, metric = spec_constrain, constrain_metric=sum_sens_spec, min_constrain = 1.1, pos_class = "yes")

cp <- cutpointr(eicu, sp_o2_mean, hospital_mortality, 
                method = maximize_metric, metric = spec_constrain, constrain_metric=sum_sens_spec, min_constrain = 1.1, pos_class = "yes")

cp <- cutpointr(eicu, temp_c_mean, hospital_mortality, 
                method = maximize_metric, metric = spec_constrain, constrain_metric=sum_sens_spec, min_constrain = 1.1, pos_class = "yes")

cp <- cutpointr(eicu, shock_index, hospital_mortality, 
                method = maximize_metric, metric = spec_constrain, constrain_metric=sum_sens_spec, min_constrain = 1.1, pos_class = "yes")



# Final - logisitic reg model with categorical variables (balanced & unbalanced) ------------------



logistic_final_balanced <- train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + I(mean_bp_mean < 65) + I(sp_o2_mean < 92) + 
                                           I(resp_rate_mean > 22) + I(heart_rate_mean > 95) + I(bun_max > 45) + I(aniongap_max > 18) + 
                                           I(age > 65) + neoplasms + vent + I(temp_c_mean < 36) + coronary_atherosclerosis,
                                         method     = "glm",
                                         metric     = "ROC",
                                         trControl  = trControl,
                                         data       = eicu_balanced)




logistic_final_unbalanced <- caret::train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + I(mean_bp_mean < 70) + I(sp_o2_mean < 90) + 
                                   I(resp_rate_mean > 26) + I(heart_rate_mean > 110) + I(heart_rate_mean < 60) + I(bun_max > 60) + I(aniongap_max > 26) + 
                                   I(age > 65) + neoplasms + vent + I(temp_c_mean < 35) ,
                                 method     = "glm",
                                 metric     = "ROC",
                                 trControl  = trControl,
                                 data       = eicu)

logistic_final_mayo<- caret::train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + shock_cardiogenic + I(sp_o2_mean < 90) + 
                                            I(bun_max > 23) + I(aniongap_max > 14) +  I(age > 65) + I(hematocrit_max > 50),
                                          method     = "glm",
                                          metric     = "ROC",
                                          trControl  = trControl,
                                          data       = eicu)


logistic_reg_model_newest_cat <- caret::train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + I(shock_index>1.35) + acute_cerebrovascular_disease  + vent +
                                         I(bun_max > 36) + I(aniongap_max>19) +  I(age>75) + I(sp_o2_mean < 92),
                                       method     = "glm",
                                       metric     = "ROC",
                                       trControl  = trControl,
                                       data       = eicu)


#######------------ Other Models - Not balanced --------- ######






logistic_gam <- caret::train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + neoplasms + coronary_atherosclerosis + chronic_obstructive_pulmonary_disease_and_bronchiectasis +
                               age + heart_rate_mean + mean_bp_mean + resp_rate_mean + temp_c_mean + sp_o2_mean + aniongap_max + ph_min + bun_max +
                               vent + total_pressors,
                      method     = "gamSpline",
                      metric     = "ROC",
                      trControl  = trControl,
                      data       = eicu)


# Adapted predictors from previous models

# Bookmark of selected predictors
# gbm_model <- caret::train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation  +
#                             age + heart_rate_mean + mean_bp_mean + resp_rate_mean + temp_c_mean + sp_o2_mean + aniongap_max  + bun_max +
#                             vent + total_pressors + any_inotrope + rrt + shock_cardiogenic, 
#                           data       = eicu, 
#                           method = "gbm", 
#                           trControl = trControl, 
#                           metric = "ROC",
#                           tuneGrid = tg, 
#                           verbose = FALSE)


tg <- expand.grid(shrinkage = seq(0.1, 1, by = 0.2), 
                  interaction.depth = c(1, 3, 7, 10),
                  n.minobsinnode = c(2, 5, 10),
                  n.trees = c(100, 300, 500, 1000))
  
gbm_model <- caret::train(hospital_mortality ~ ., 
                   data       = eicu, 
                   method = "gbm", 
                   trControl = trControl, 
                   metric = "ROC",
                   tuneGrid = tg, 
                   verbose = FALSE)


nn_model <- caret::train(hospital_mortality ~ ., 
                          data       = eicu, 
                          method = "avNNet", 
                          trControl = trControl, 
                          metric = "ROC",
                          verbose = FALSE)


modelSvm <- caret::train(hospital_mortality ~ ., 
                  data=eicu, 
                  method="svmRadial", 
                  trControl=trControl)



modelrf <- caret::train(hospital_mortality ~ ., 
                        data=eicu, 
                        method="rf", 
                        trControl=trControl)

modeldt <- caret::train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + neoplasms + coronary_atherosclerosis + chronic_obstructive_pulmonary_disease_and_bronchiectasis +
                          age + heart_rate_mean + mean_bp_mean + resp_rate_mean + temp_c_mean + sp_o2_mean + aniongap_max + ph_min + bun_max +
                          vent + total_pressors, 
                        data=eicu, 
                        method="rpart", 
                        trControl=trControl)

# model_lda <- caret::train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + neoplasms + coronary_atherosclerosis + chronic_obstructive_pulmonary_disease_and_bronchiectasis +
#                           age + heart_rate_mean + mean_bp_mean + resp_rate_mean + temp_c_mean + sp_o2_mean + aniongap_max + ph_min + bun_max +
#                           vent + total_pressors,
#                         data=eicu,
#                         method="lda",
#                         trControl=trControl)


# # Ensemble model
# 
# library(caretEnsemble)
# alg_list <- c("rf", "gbm", "treebag", "glmnet")
# multi_mod <- caretEnsemble(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + neoplasms + coronary_atherosclerosis + chronic_obstructive_pulmonary_disease_and_bronchiectasis +
#                          age + heart_rate_mean + mean_bp_mean + resp_rate_mean + temp_c_mean + sp_o2_mean + aniongap_max + ph_min + bun_max +
#                          vent + total_pressors, 
#                        data=eicu, trControl = trControl, model = alg_list, metric = "ROC")
# 
# greedy_ensemble <- caretEnsemble(
#   multi_mod, 
#   metric="ROC",
#   trControl= trControl
#   )
# 
# res <- resamples(multi_mod)
# 
# 
# # Quick assestment on validation set
# 
# predictions_new<- stats::predict(greedy_ensemble, mimic_analysis)
# acc_new <- base::mean(predictions_new == mimic_analysis$hospital_mortality, na.rm=F)



#######------------ Other Models - Balanced --------- ######




# Adapted predictors from previous models
gbm_model_b <- caret::train(hospital_mortality ~ ., 
                          data       = eicu_balanced, 
                          method = "gbm", 
                          trControl = trControl, 
                          metric = "ROC",
                          tuneGrid = tg, 
                          verbose = FALSE)


nn_model_b <- caret::train(hospital_mortality ~ ., 
                         data       = eicu_balanced, 
                         method = "avNNet", 
                         trControl = trControl, 
                         metric = "ROC",
                         verbose = FALSE)


modelSvm_b <- caret::train(hospital_mortality ~ ., 
                         data=eicu_balanced, 
                         method="svmRadial", 
                         trControl=trControl)




modeldt_b <- caret::train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + neoplasms + coronary_atherosclerosis + chronic_obstructive_pulmonary_disease_and_bronchiectasis +
                          age + heart_rate_mean + mean_bp_mean + resp_rate_mean + temp_c_mean + sp_o2_mean + aniongap_max + ph_min + bun_max +
                          vent + total_pressors, 
                        data=eicu_balanced, 
                        method="rpart", 
                        trControl=trControl)

model_lda_b <- caret::train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + neoplasms + coronary_atherosclerosis + chronic_obstructive_pulmonary_disease_and_bronchiectasis +
                            age + heart_rate_mean + mean_bp_mean + resp_rate_mean + temp_c_mean + sp_o2_mean + aniongap_max + ph_min + bun_max +
                            vent + total_pressors, 
                          data=eicu_balanced, 
                          method="lda", 
                          trControl=trControl)

modelrf_b <- caret::train(hospital_mortality ~ .,
                          data=eicu_balanced, 
                          method="rf", 
                          trControl=trControl)

# Ensemble model

library(caretEnsemble)
alg_list <- c("rf", "gbm", "treebag", "glmnet")
multi_mod <- caretEnsemble(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + neoplasms + coronary_atherosclerosis + chronic_obstructive_pulmonary_disease_and_bronchiectasis +
                             age + heart_rate_mean + mean_bp_mean + resp_rate_mean + temp_c_mean + sp_o2_mean + aniongap_max + ph_min + bun_max +
                             vent + total_pressors, 
                           data=eicu, trControl = trControl, model = alg_list, metric = "ROC")

greedy_ensemble <- caretEnsemble(
  multi_mod, 
  metric="ROC",
  trControl= trControl
)

res <- resamples(multi_mod)


# Quick assestment on validation set

predictions_new<- stats::predict(greedy_ensemble, mimic_analysis)
acc_new <- base::mean(predictions_new == mimic_analysis$hospital_mortality, na.rm=F)




#######------------ Model comparison graphs on CV--------- ######

listmodels <- list(RF=modelrf, SVM=modelSvm, LR=logistic_reg_model, DT = modeldt, GBM = gbm_model, NN=nn_model)
listmodels_balanced <- list(RF_balanced = modelrf_b, SVM_balanced=modelSvm_b,  LR_balanced=logistic_reg_model_balanced, DT_balanced = modeldt_b, GBM_balanced = gbm_model_b, NN=nn_model_b)

results_balanced <- resamples(listmodels_balanced)
results_unbalanced <- resamples(listmodels)

# summarize the distributions
summary(results)
# boxplots of results
bwplot(results_balanced)
# dot plots of results
dotplot(results_unbalanced)

# parallelplot
parallelplot(results_balanced)

#pvalues
# difference in model predictions
diffs <- diff(results)
# summarize p-values for pair-wise comparisons
summary(diffs)

# density plots of accuracy
scales <- list(x=list(relation="free"), y=list(relation="free"))
densityplot(results, scales=scales, pch = "|")


# ROC plotting on training set --------------------------------------------


library(MLeval)

roc_unbalanced <- evalm(listmodels,gnames=c('RF','SVM', "LR", "DT", "GBM", "NN"),rlinethick=0.8,fsize=8,
  plots='r')

roc_balanced <- evalm(listmodels_balanced,gnames=c('RF','SVM', "LR", "DT", "GBM", "NN"),rlinethick=0.8,fsize=8,
                      plots='r')

roc_unbalanced$roc+
  labs(title="ROC curves of different models trained on original dataset", fill = "Models trained")+
  scale_color_brewer(palette="Set1")+
  theme(plot.title = element_text(color="black", size=14, face="bold"))
        
roc_balanced$roc+
  labs(title="ROC curves of different models trained on the balanced dataset", fill = "Models trained")+
  scale_color_brewer(palette="Set1")+
  theme(plot.title = element_text(color="black", size=14, face="bold"))


# HealthcareAI ------------------------------------------------------------




eicu_analysis2 <- eicu_analysis%>%dplyr::select(c("cardiac_arrest_and_ventricular_fibrillation", "mean_bp_mean", "sp_o2_mean", "resp_rate_mean",
                                                  "heart_rate_mean", "bun_max", "aniongap_max",
                                                  "neoplasms", "any_inotrope", "total_pressors",
                                                  "vent", "temp_c_mean", "doubled_creat", "shock_cardiogenic", "rrt",
                                                  "hospital_mortality"))

models <- machine_learn(eicu_analysis, outcome = hospital_mortality) # All variables

models_sub <- machine_learn(eicu_analysis2, outcome = hospital_mortality) # Subset

predictions <- predict(models_sub, outcome_groups = TRUE)
plot(predictions)

ggplot()
get_variable_importance(models) %>%
  plot()

interpret(models_sub) %>% 
  plot()

explore(models_sub) %>% 
  plot(n_use=4)


test_predictions <- predict(models_sub, mimic_analysis, type = 'response')
predicted <- if_else(test_predictions$predicted_hospital_mortality >= 0.5, "yes", "no")
accuracy_ai   <- mean(predicted == mimic_analysis$hospital_mortality, na.rm=F)

# Validation set testing --------------------------------------------------


# Creating predictions

# Type prob optimal for AUC but not for accuracy calculation

predictions_balanced <- predict(logistic_reg_model_balanced, mimic_analysis)
predictions_unbalanced <- predict(modelrf, mimic_analysis, type = 'prob')
predictions_unbalanced_no_cat <- predict(logistic_reg_model3, mimic_analysis, type = 'prob')

predictions_balanced <- predict(logistic_reg_model_bestsub, mimic_analysis)
accuracy_balanced   <- mean(predictions_balanced == mimic_analysis$hospital_mortality, na.rm=F)
confusion_balanced <- confusionMatrix(reference = mimic_analysis$hospital_mortality, data = predictions_balanced)

accuracy_unbalanced   <- mean(predictions_unbalanced == mimic_analysis$hospital_mortality, na.rm=F)
confusion_unbalanced <- confusionMatrix(reference = mimic_analysis$hospital_mortality, data = predictions_unbalanced)

accuracy_unbalanced_no_cat   <- mean(predictions_unbalanced_no_cat == mimic_analysis$hospital_mortality, na.rm=F)
confusion_unbalanced_no_cat <- confusionMatrix(reference = mimic_analysis$hospital_mortality, data = predictions_unbalanced_no_cat)

validation_plot <- function(list){
  accuracy <- c(0)
  for (i in seq(6)){
    predmodel <- list[[i]]
    predictions <- predict(predmodel, mimic_analysis)
    accuracy[i]  <- mean(predictions == mimic_analysis$hospital_mortality, na.rm=F)
  }
  names(accuracy) <- c("RF", "SVM", "LR", "DT", "GBM", "NN")
  return(accuracy)
}

balanced_validation  <- validation_plot(listmodels_balanced)
unbalanced_validation <- validation_plot(listmodels)

confusion_matrix <- function(list){
  confusion <- list(0)
  for (i in seq(6)){
    predmodel <- list[[i]]
    predictions <- predict(predmodel, mimic_analysis)
    confusion[[i]]  <- confusionMatrix(reference = mimic_analysis$hospital_mortality, data = predictions)

  }
  names(confusion) <- c("RF", "SVM", "LR", "DT", "GBM", "NN")
  return(confusion)
}

dotplot(unbalanced_validation, labels=names(balanced_validation), xlim=c(0.65, 0.85), xlab="Accuracy", main="Comparison of accuracy on validation set", pch=18, cex=3, col="blue")+
  dotplot(balanced_validation, pch=20, col="red", cex=3)


confusion <- confusionMatrix(reference = mimic_analysis$hospital_mortality, data = predictions_t)
plot(varImp(nn_model), top = 20)

# Alternative for AUC
# predictions_new<- stats::predict(modelrf, mimic_analysis)
# acc_new <- base::mean(predictions_new == mimic_analysis$hospital_mortality, na.rm=F)



# ROC plotting on validation set ------------------------------------------


library(ROCR)
# library(pROC)
# library(mlr)

#pred_b <- ROCR::prediction(predictions_unbalanced[,2], mimic_analysis$hospital_mortality)

pred_b <- ROCR::prediction(predictions_unbalanced[,2], mimic_analysis$hospital_mortality)
perf_b <- ROCR::performance(pred_b,"tpr","fpr")
auc_b <- ROCR::performance(pred_b,"auc")
auc_b@y.values[[1]]
plot(perf_b)


pred_ub <- ROCR::prediction(predictions_unbalanced[,2], mimic_analysis$hospital_mortality)
perf_ub <- ROCR::performance(pred_ub,"tpr","fpr")
auc_ub <- ROCR::performance(pred_ub,"auc")
auc_ub@y.values[[1]]
plot(perf_ub)

pred_no_cat <- ROCR::prediction(predictions_unbalanced_no_cat[,2], mimic_analysis$hospital_mortality)
perf_no_cat <- ROCR::performance(pred_no_cat,"tpr","fpr")
auc_ub_no_cat <- ROCR::performance(pred_no_cat,"auc")
auc_ub_no_cat@y.values[[1]]



# ROC plots of validation and training set on same graph

logistic_reg_model_f
predictions_unbalanced <- predict(logistic_reg_model_newest_cat, mimic, type="prob")
accuracy_unbalanced   <- mean(predictions_unbalanced == mimic$hospital_mortality, na.rm=F)

pred_threshold <- as.numeric(predictions_unbalanced[,2] > 0.45)
mimic_t <- as.numeric(mimic$hospital_mortality=="yes")
accuracy_thres <- mean(pred_threshold== mimic_t, na.rm=F)

##

threshold_values      <- seq(from = 0.00, to = 0.99, by = 0.01)
error_rates           <- matrix(0, 
                                nrow = length(threshold_values),
                                ncol = 1)
indx                  <- 0
for (threshold in threshold_values) {
  indx                <- indx + 1
  class_predictions   <- as.numeric(predictions_unbalanced[,2]> threshold)
  accuracy_thres <- mean(pred_threshold== mimic_t, na.rm=F)
  error_rates[indx,]  <- accuracy_thres
}




predictions_unbalanced1 <- predict(logistic_reg_model_finak, mimic_analysis, type="prob")

confusion_unbalanced <- confusionMatrix(reference = mimic_analysis$hospital_mortality, data = predictions_unbalanced)


pred_b <- ROCR::prediction(predictions_unbalanced[,2], mimic_analysis$hospital_mortality)
perf_b <- ROCR::performance(pred_b,"tpr","fpr")
auc_b <- ROCR::performance(pred_b,"auc")
auc_b@y.values[[1]]

plot(perf_b)

roc_balanced2 <- evalm(perf_b, rlinethick=0.8,fsize=8,
                      plots='r')

roc_balanced <- evalm(logistic_reg_model_newest_cat,rlinethick=0.8,fsize=8,
                      plots='r')

plot(roc_balanced$roc+
  labs(title="ROC - Logistic Regression (stepwise)")+
  theme(plot.title = element_text(color="black", size=14, face="bold"))
  )

library(MLeval)



