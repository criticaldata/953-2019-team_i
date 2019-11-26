
# Loading library + file --------------------------------------------------

#setwd("~/Documents/Bioinformatics/Classes/FALL/HST.953/Git_Files_Cardiogenic/953-2019-team_i/analysis/Predictive Models")
source("./library_load.R")
library(caret)
library(caretEnsemble)

library(skimr)
library(RANN) 


library(gbm)
library(glmnet)
library(kknn)
library(knn)
library(MASS)

library(DALEX) # explainers of model
library(esquisse) # https://github.com/dreamRs/esquisse # ggplot addon
library(infer) # stastical analysis with gg grammar


# NULL values cleaning pre-analytics - this file is ready for analysis with only 5% of NULL
eicu <- read_csv("./eicu_cardiogenic_shock_selected.csv", col_names = TRUE)%>%dplyr::select(-c("X1"))
mimic <- read_csv("./mimic_cardiogenic_shock_selected.csv", col_names = TRUE)%>%dplyr::select(-"X1")


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



# Null values imputation --------------------------------------------------


# eICU a lot of data weirdly missing
# BPs measurements about 15%
# ph 
# gcs,
# creatinine

# eicu <- eicu%>%dplyr::select(-c("inr_min","inr_max", "pt_max", "pt_min", "ptt_max", "ptt_min", "ph_min"))

# MML imputation

eicu_m <- mice(eicu)
eicu_analysis <- complete(eicu_m, 1)


mimic_m <- mice(mimic)
mimic_analysis <- complete(mimic_m, 1)

write.csv(eicu_analysis, file="imputed_eicu.csv")
write.csv(mimic_analysis, file="imputed_mimic.csv")


# Data partition ----------------------------------------------------------


# Creating training/test data sets

eicu_analysis <- eicu_analysis %>% mutate(id = row_number()) 
train <- eicu_analysis %>% sample_frac(.70)
test  <- anti_join(eicu_analysis , train, by = "id")


# Variables exploration ---------------------------------------------------


# Subset selection

# Exploration of correlation
library(mlbench)
correlation_var <- cor(mimic_analysis_1,mimic_analysis_1$hospital_mortality)
correlationMatrix <- cor(mimic_analysis_1[,-54])
highlyCorrelated <- findCorrelation(correlationMatrix, cutoff=0.5)

# Removing highly correlated

#mimic_analysis_1 <- mimic_analysis_1[,-(51,28,58,23,32,15)]

#Method1 - not Caret

library(MASS)
logistic_reg_model_sub <- logistic_reg_model$finalModel %>% stepAIC(trace = FALSE)
#coef(logistic_reg_model_sub)

#Method2 - Caret RFE

subsets <- c(1, 5, 10, 20, 30, 40, 50, 60)

library(randomForest)

ctrl <- rfeControl(functions = rfFuncs,
                   method = "cv",
                   number = 3,
                   verbose = FALSE)

rfFuncs$summary <- twoClassSummary # did not work ?

# Convert character to factor for RFE algorithm

train=train %>% mutate_if(is.character, as.factor)
lmProfile <- rfe(x=train[,-54], y=train[[54]],
                 sizes = subsets,
                 metric = "ROC",
                 rfeControl = ctrl)

#Method3 - bestglm

library(bestglm)
Xy <- cbind(train[,-54], train[,54])
BestCV <- bestglm(Xy, IC="CV", t=10) # cross-validation
summary(BestCV$BestModel)


#Method4 - PCA
library()
mimic_analysis_1=mimic_analysis %>% mutate_if(is.factor, as.numeric)
mimic.pca <- prcomp(mimic_analysis_1, scale = TRUE, center = TRUE)
summary(mimic.pca)

library(factoextra)

fviz_pca_var(mimic.pca,
             col.var = "contrib", # Color by 
             #contribution to the PC
             repel = TRUE     # Make sure 
             #text doesn't overlap
)









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


#######------------ Logistic Models --------- ######


logistic_reg_model <- train(hospital_mortality ~ .,
                            method     = "glm",
                            metric     = "ROC",
                            trControl  = trControl,
                            data       = train)


logistic_reg_model_sub_back <- train(hospital_mortality ~ ., data= train,
                                     trControl = trControl,
                                     method = "glmStepAIC",
                                     family=binomial(link="logit"),
                                     na.action = na.omit)

logistic_reg_model <- train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + shock_index + vent + sp_o2_mean + bun_max + age + aniongap_max ,
                                method     = "glm",
                                metric     = "Prec",
                                trControl  = trControl,
                                data       = train)

logistic_reg_model <- train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + shock_index + vent + I(sp_o2_mean < 90) + I(bun_max >50)  + I(age > 65) + 
                              I(aniongap_max>15) ,
                            method     = "glm",
                            metric     = "Prec",
                            trControl  = trControl,
                            data       = train)


logistic_reg_model_final <- train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + shock_index + vent + I(sp_o2_mean < 90) + I(bun_max >50)  + I(age > 65) + 
                              I(aniongap_max>15) ,
                            method     = "glm",
                            metric     = "Prec",
                            trControl  = finalmodel,
                            data       = eicu_analysis)



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
plot(varImp(logistic_reg_model_final))

summary(logistic_reg_model)
confusionMatrix(logistic_reg_model)


# CV testing accuracy 


predictions <- predict(logistic_reg_model, test)
accuracy_lreg_test   <- mean(predictions == test$hospital_mortality)
test_confusion_M <- confusionMatrix(reference = test$hospital_mortality, data = predictions)




#######------------ Other Models --------- ######


knn_model <- train(hospital_mortality ~ .,
                   method     = "knn",
                   tuneLength  = 5,
                   trControl  = trControl,
                   metric     = "ROC",
                   data       = train)


qda_model <- train(hospital_mortality ~ .,
                   method     = "qda",
                   trControl  = trControl,
                   metric = "ROC",
                   data       = train)

lasso_model <- train(hospital_mortality ~ ., 
                     data       = train, 
                     preProcess = c("center", "scale"),
                     method = "glmnet", 
                     metric = "ROC",
                     trControl = trControl)

tg <- expand.grid(shrinkage = seq(0.1, 1, by = 0.2), 
                  interaction.depth = c(1, 3, 7, 10),
                  n.minobsinnode = c(2, 5, 10),
                  n.trees = c(100, 300, 500, 1000))

gbm_model <- train(hospital_mortality ~ ., 
                   data       = train, 
                   method = "gbm", 
                   trControl = trControl, 
                   metric = "ROC",
                   tuneGrid = tg, 
                   verbose = FALSE)




# Validation set testing --------------------------------------------------

# Gotta figure out how to measure ROC on test set?! 
predictions <- predict(logistic_reg_model, mimic_analysis)
accuracy_lreg_test   <- mean(predictions == mimic_analysis$hospital_mortality, na.rm=F)
test_confusion_M <- confusionMatrix(reference = mimic_analysis$hospital_mortality, data = predictions)
library(ROCR)
library(pROC)
perf_AUC=performance(logistic_reg_model, mimic_analysis,"auc")
auc(roc(predictions,mimic_analysis))
result.roc <- pROC::roc(mimic_analysis, predictions) # Draw ROC curve.

pred_ROCR <- prediction(logistic_reg_model_final$finalModel$y, mimic_analysis$hospital_mortality)



#######------------ Model comparison graphs--------- ######


models_compare <- resamples(
  list(glm = logistic_reg_model , glmnet = lasso_model, gbm = gbm_model)) # Must read on resampling for comparison

summary(models_compare) # NB this only compares on the traning sets.

bwplot(models_compare,metric="ROC",main="4 Models comparison")	# boxplot
dotplot(models_compare,metric="ROC",main="4 Models comparison")  #dot plot

# Model assesstment
# summary(logistic_reg_model$finalModel)$r.squared  # unrealstic value of accuracy if bootstrap
# logistic_reg_model #accuracy results on test set
# logistic_reg_model$results
#mods <- resamples(list(knn = knn_model, glm = logistic_reg_model , glmnet = lasso_model, gbm = gbm_model))
#summary(mods)
#parallelplot(allResamples)


