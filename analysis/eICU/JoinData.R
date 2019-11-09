source("./code/sql/sql_queries_MIMIC2.R")

# tablelist <- list(wide_ccu_dx, ccu_vitals, ccu_labs, ccu_patients_id_los, ccu_demographics_dob_gender_death,
#                   ccu_uo_24h, ccu_RRT24h, ccu_vent, wide_procedures_24, wide_pressors, wide_pressors_firsthour,
#                   ccu_gcs, ccu_sofa, ccu_oasis, wide_cabg_pci, ccu_mortality)

tablelist <- list(ccu_vitals, sum_pressor, ccu_demographics, ccu_diagnoses, ccu_gender_age, ccu_labs1)
#remove_unecessary_index <- function(dflist){
dflist2 <- list(c())
# j <- 1
# for (i in dflist){
#   if ("hadm_id" %in% colnames(i)){
#     i <- i%>%select(-hadm_id)
#   }
#   if ("icustay_id" %in% colnames(i)){
#     i <- i%>%select(-icustay_id)
#   }
#   dflist2[j] <- data_frame(i)
#   j <- j+1
# }
# return(dflist2)
# }
#tablelist2 <- remove_unecessary_index(tablelist)


# 
# ## Automated merge approach
library(purrr)
ccu_analysis_table <- tablelist %>% purrr::reduce (left_join, by = "patientunitstayid")
# 
# 
# ### Manual merge approach 
# #ccu_analysis2 <- wide_ccu_dx%>%
# #left_join(ccu_vitals, by="subject_id")%>%
# # left_join(ccu_patients_id_los, by="subject_id")%>%
# #left_join(ccu_demographics_dob_gender_death, by="subject_id")%>%
# #left_join(ccu_labs, by="subject_id")%>%
# # left_join(ccu_uo_24h, by="subject_id")%>%
# #we removed RRT of hospital stay not relevant 
# #left_join(ccu_RRT, by="subject_id")%>%
# # left_join(ccu_RRT24h, by="subject_id")%>%
# # left_join(ccu_vent, by="subject_id")%>%
# #left_join(wide_procedures_24, by="subject_id")%>%
# # left_join(ccu_mortality, by="subject_id")%>%
# #left_join(ccu_gcs, by="subject_id")%>%
# # left_join(ccu_sofa, by="subject_id")%>%
# #  left_join(ccu_oasis, by="subject_id")%>%
# # left_join(wide_cabg_pci, by="subject_id")%>$%
# # left_join(wide_pressors, by="subject_id")%>$%
# #left_join(wide_pressors_firsthour, by="subject_id")
# 
# ### FINAL CLEANING
# # Removing identifiers
# # Removing duplicates caused by the merge
# # Transform appropriate variables to good format
# 
# ccu_analysis2<- ccu_analysis_table%>%
#   select(-c("hadm_id.x","hadm_id.x.x", "hadm_id.x.x.x","hadm_id.x.x.x.x",
#             "hadm_id.y","hadm_id.y.y","hadm_id.y.y.y","hadm_id.y.y.y.y",
#             "icustay_id.x.x","icustay_id.x.x.x",
#             "icustay_id.y", "icustay_id.y.y","icustay_id.y.y.y", "icustay_id.y.y.y.y"))%>%
#   distinct(subject_id, .keep_all=TRUE)%>%
#   clean_names(case="snake")
# 
# 
# #Replacing NaN by 0 in appropriate sections only *** WE KEPT ALL THE NAN in places where we did not have the data
# 
# ccu_analysis2$rrt <- replace_na(ccu_analysis2$rrt, 0)
# ccu_analysis2$vent <- replace_na(ccu_analysis2$vent, 0)
# ccu_analysis2$ecmo <- replace_na(ccu_analysis2$ecmo, 0)
# ccu_analysis2$impella <- replace_na(ccu_analysis2$impella, 0)
# ccu_analysis2$cabg <- replace_na(ccu_analysis2$cabg, 0)
# ccu_analysis2$pci <- replace_na(ccu_analysis2$pci, 0)
# ccu_analysis2$iabp <- replace_na(ccu_analysis2$iabp, 0)
# ccu_analysis2$dobutamine <- replace_na(ccu_analysis2$dobutamine, 0)
# ccu_analysis2$dopamine <- replace_na(ccu_analysis2$dopamine, 0)
# ccu_analysis2$epinephrine <- replace_na(ccu_analysis2$epinephrine, 0)
# ccu_analysis2$milrinone <- replace_na(ccu_analysis2$milrinone, 0)
# ccu_analysis2$norepinephrine <- replace_na(ccu_analysis2$norepinephrine, 0)
# ccu_analysis2$vasopressin <- replace_na(ccu_analysis2$vasopressin, 0)
# ccu_analysis2$total_pressors <- replace_na(ccu_analysis2$total_pressors, 0)
# ccu_analysis2$any_pressor <- replace_na(ccu_analysis2$any_pressor, 0)
# ccu_analysis2$dobutamine_first_hour <- replace_na(ccu_analysis2$dobutamine_first_hour, 0)
# ccu_analysis2$dopamine_first_hour <- replace_na(ccu_analysis2$dopamine_first_hour, 0)
# ccu_analysis2$epinephrine_first_hour<- replace_na(ccu_analysis2$epinephrine_first_hour, 0)
# ccu_analysis2$milrinone_first_hour <- replace_na(ccu_analysis2$milrinone_first_hour, 0)
# ccu_analysis2$norepinephrine_first_hour <- replace_na(ccu_analysis2$norepinephrine_first_hour, 0)
# ccu_analysis2$vasopressin_first_hour <- replace_na(ccu_analysis2$vasopressin_first_hour, 0)
# ccu_analysis2$total_pressors_first_hour <- replace_na(ccu_analysis2$total_pressors_first_hour, 0)
# ccu_analysis2$any_pressor_first_hour <- replace_na(ccu_analysis2$any_pressor_first_hour, 0)
# ccu_analysis2$phenyl<- replace_na(ccu_analysis2$phenyl, 0)
# ccu_analysis2$phenyl_first_hour<- replace_na(ccu_analysis2$phenyl_first_hour, 0)
# 
# # Last check of patient
# 
# str(ccu_analysis2, list.len = 150)
# ccu_analysis2 <- ccu_analysis2%>%select(-c("icustay_id_x_x_x_x", "icustay_id_x"))



## Table is final for all MIMIC CCU patients
write.csv(ccu_analysis_table, file="eICU_CCUdata_V1")
