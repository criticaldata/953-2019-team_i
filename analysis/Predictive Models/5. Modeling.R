
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
eicu <- read_csv("./eicu_cardiogenic_shock_selected.csv", col_names = TRUE) 
mimic <- read_csv("./mimic_cardiogenic_shock_analysis_selected.csv", col_names = TRUE) 


#Variable transformation

colnames <- colnames(eicu)
eicu <- eicu%>%mutate_at(colnames[1:19], function(x){fct_recode(as.factor(x),"yes"="1", "no"="0")})
mimic <- mimic%>%mutate_at(colnames[49], function(x){as.factor(x)}) #gender
eicu <- eicu%>%mutate_at(colnames[51:55], function(x){fct_recode(as.factor(x),"yes"="1", "no"="0")})
eicu <- eicu%>%mutate_at(colnames[57], function(x){fct_recode(as.factor(x),"yes"="1", "no"="0")})
eicu <- eicu%>%mutate_at(colnames[59], function(x){fct_recode(as.factor(x),"yes"="1", "no"="0")})
eicu <- eicu%>%mutate_at(colnames[61], function(x){fct_recode(as.factor(x),"yes"="1", "no"="0")})


colnames <- colnames(mimic)
d <- as.data.frame(colnames)
mimic <- mimic%>%mutate_at(colnames[1:19], function(x){fct_recode(as.factor(x),"yes"="1", "no"="0")})
mimic <- mimic%>%mutate_at(colnames[41], function(x){fct_recode(as.factor(x),"yes"="1", "no"="0")})
mimic <- mimic%>%mutate_at(colnames[42], function(x){as.factor(x)}) #gender
mimic <- mimic%>%mutate_at(colnames[44:49], function(x){fct_recode(as.factor(x),"yes"="1", "no"="0")})
mimic <- mimic%>%mutate_at(colnames[52:54], function(x){fct_recode(as.factor(x),"yes"="1", "no"="0")})
mimic <- mimic%>%mutate_at(colnames[56:57], function(x){fct_recode(as.factor(x),"yes"="1", "no"="0")})
mimic <- mimic%>%mutate_at(colnames[60], function(x){fct_recode(as.factor(x),"yes"="1", "no"="0")})





# Null values imputation --------------------------------------------------
skimmed <- skim_to_wide(eicu)
skimmed2 <- skim_to_wide(mimic)


# eICU a lot of data weirdly missing
# BPs measurements about 15%
# ph 
# gcs,
# creatinine

eicu <- eicu%>%dplyr::select(-c("inr_min","inr_max", "pt_max", "pt_min", "ptt_max", "ptt_min", "ph_min"))

# MML imputation

eicu_m <- mice(eicu)
eicu_analysis <- complete(eicu_m, 1)


mimic_m <- mice(mimic)
mimic_analysis <- complete(mimic_m, 1)

write.csv(eicu_analysis, file="imputed_eicu.csv")
write.csv(mimic_analysis, file="imputed_mimiccsv")


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


predictions <- predict(logistic_reg_model, mimic_analysis)
accuracy_lreg_test   <- mean(predictions == mimic_analysis$hospital_mortality, na.rm=F)
test_confusion_M <- confusionMatrix(reference = mimic_analysis$hospital_mortality, data = predictions)
library(ROCR)
library(pROC)
perf_AUC=performance(logistic_reg_model, mimic_analysis,"auc")
auc(mimic_analysis, predictions)
result.roc <- pROC::roc(mimic_analysis, predictions) # Draw ROC curve.


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


