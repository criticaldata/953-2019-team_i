source("./code/library_load.R")
library(caret)
library(caretEnsemble)

library(skimr)
library(RANN) 


library(gbm)
library(glmnet)
library(kknn)
library(knn)
library(MASS)

install.packages("DALEX") # https://rawgit.com/pbiecek/DALEX_docs/master/vignettes/DALEX_caret.html
library(DALEX) # explainers of model
library(esquisse) # https://github.com/dreamRs/esquisse # ggplot addon
library(infer) # stastical analysis with gg grammar


# NULL values cleaning pre-analytics - this file is ready for analysis with only 5% of NULL
mimic_analysis <- read_csv("./eICU_CS_filter_.csv", col_names = TRUE) 

preProcess_missingdata_model <-  preProcess(mimic_analysis, #[,c('Embarked', 'Sex')] if knnImpute and want to only select row/col
                                            method = "bagImpute",   # or *bagImpute* / *medianImpute*
                                            pcaComp = 10,
                                            na.remove = TRUE,
                                            na.action = na.pass,
                                            k = 5,
                                            knnSummary = mean,
                                            outcome = NULL,
                                            fudge = .2,
                                            numUnique = 3,
                                            verbose = TRUE)


mimic_analysis <- predict(preProcess_missingdata_model, newdata = mimic_analysis)

a2 <- skim_to_wide(mimic_analysis)

mimic_analysis_processed <- mimic_analysis # saving at midstep




# Creating training/test data sets

mimic_analysis <- mimic_analysis %>% mutate(id = row_number()) 
train <- mimic_analysis %>% sample_frac(.70)
test  <- anti_join(mimic_analysis, train, by = "id")

train <- train%>%dplyr::select(-"id")
test <- test%>%dplyr::select(-"id")


train$hospital_mortality <- as.factor(train$hospital_mortality) # Must transform Y as outcome
levels(train$hospital_mortality) <- c("life", "death")

test$hospital_mortality <- as.factor(test$hospital_mortality) # Must transform Y as outcome
levels(test$hospital_mortality) <- c("life", "death")

train$gender <- as.factor(train$gender) # Converting gebder to factor for RF algorithm
levels(train$gender) <- c("F", "M") # must verify the coding
#########-----------------------------Data analysis------------------------------------------############


set.seed(100)


#trainControl <- trainControl(method="repeatedcv", 
#                             number=10, 
#                             repeats=3,
#                             savePredictions="all", 
#                             index = createFolds(mimic_analysis$hospital_mortality, 5),
#                             classProbs=TRUE
#                             ))



trControl <- trainControl(method  = "cv",
                          number  = 5,
                          summaryFunction = twoClassSummary, #Needed for ROC metric
                          savePredictions = "all", #Needed for thresholder
                          classProbs = T #Needed for classification
) # classProb T essential to specify classification alternative = transforme outcome as factor




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





#######------------ Logistic Models --------- ######


logistic_reg_model <- train(hospital_mortality ~ .,
                            method     = "glm",
                            metric     = "ROC",
                            trControl  = trControl,
                            data       = train)


logistic_reg_model_sub <- train(hospital_mortality ~ cardiac_arrest_and_ventricular_fibrillation + shock_index + vent + sp_o2_mean + bun_max + charlson_score ,
                                method     = "glm",
                                metric     = "ROC",
                                trControl  = trControl,
                                data       = train)

#Method 5
logistic_reg_model_sub_back <- train(hospital_mortality ~ ., data= train,
                                     trControl = trControl,
                                     method = "glmStepAIC",
                                     family=binomial(link="logit"),
                                     na.action = na.omit)

logistic_reg_model_sub_back$finalModel$coefficients


logistic_reg_model_sub_step <- train(hospital_mortality ~ acute_cerebrovascular_disease + anemia + blood_malignancy + cardiac_arrest_and_ventricular_fibrillation +
                                       + coronary_atherosclerosis  + heart_valve_disorders  + neoplasms +
                                       septicemia + heart_rate_mean + dias_bp_mean + mean_bp_mean + sp_o2_mean + temp_c_mean + aniongap_max + bun_max + ph_min + vent + age + charlson_score + shock_index  ,
                                     method     = "glm",
                                     metric     = "ROC",
                                     trControl  = trControl,
                                     data       = train)

logistic_reg_model_sub_step

# Probability threshold

resample_stats <- thresholder(logistic_reg_model, 
                              threshold = seq(.5, 1, by = 0.05), 
                              final = TRUE)

ggplot(resample_stats, aes(x = prob_threshold, y = J)) + 
  geom_point()

ggplot(resample_stats, aes(x = prob_threshold, y = Dist)) + 
  geom_point()

ggplot(resample_stats, aes(x = prob_threshold, y = Sensitivity)) + 
  geom_point() + 
  geom_point(aes(y = Specificity), col = "red")


#######------------ Model Metrics --------- ######

summary(logistic_reg_model)
confusionMatrix(logistic_reg_model)
varImp(logistic_reg_model)
plot(varImp(logistic_reg_model))

summary(logistic_reg_model_sub)
confusionMatrix(logistic_reg_model_sub)

#######------------ Test Data Evaluation --------- ######

predictions <- predict(logistic_reg_model, test)
levels(predictions) <- c("0", "1") # to make sure levels are the same to allow for logical comparison
levels(test$hospital_mortality) <- c("0", "1")
accuracy_lreg_test   <- mean(predictions == test$hospital_mortality)

test_confusion_M <- confusionMatrix(reference = test$hospital_mortality, data = predictions)


predictions_sub <- predict(logistic_reg_model_sub_step, test)
test_confusion_M_sub <- confusionMatrix(reference = test$hospital_mortality, data = predictions_sub)


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

#######------------ Model comparison --------- ######


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

