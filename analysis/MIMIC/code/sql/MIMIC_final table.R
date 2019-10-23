source("./code/sql/sql_queries_MIMIC2.R")

tablelist <- list(ccu_vitals, ccu_patients_id_los, wide_ccu_dx, ccu_demographics_dob_gender_death, 
                  ccu_labs, ccu_uo_24h, 
                  ccu_RRT, ccu_RRT24h, ccu_vent, wide_procedures_24, ccu_mortality,ccu_gcs, 
                  ccu_sofa, ccu_oasis, wide_cabg_pci)


remove_unecessary_index <- function(dflist){
  dflist2 <- list(c())
  j <- 1
  for (i in dflist){
    if ("hadm_id" %in% colnames(i)){
      i <- i%>%select(-hadm_id)
    }
    if ("icustay_id" %in% colnames(i)){
      i <- i%>%select(-icustay_id)
    }
  dflist2[j] <- data_frame(i)
  j <- j+1
  }
  return(dflist2)
}
tablelist2 <- remove_unecessary_index(tablelist)



## Automated approach
ccu_analysis_table_test <- tablelist2 %>% purrr::reduce (inner_join, by = "subject_id")

replace_na()

### Manual approach 
ccu_analysis2 <- wide_ccu_dx%>%
  left_join(ccu_vitals, by="subject_id")%>%
  left_join(ccu_patients_id_los, by="subject_id")%>%
  left_join(ccu_demographics_dob_gender_death, by="subject_id")%>%
  left_join(ccu_labs, by="subject_id")%>%
  left_join(ccu_uo_24h, by="subject_id")%>%
  left_join(ccu_RRT, by="subject_id")%>%
  left_join(ccu_RRT24h, by="subject_id")%>%
  left_join(ccu_vent, by="subject_id")%>%
  left_join(wide_procedures_24, by="subject_id")%>%
  left_join(ccu_mortality, by="subject_id")%>%
  left_join(ccu_gcs, by="subject_id")%>%
  left_join(ccu_sofa, by="subject_id")%>%
  left_join(ccu_oasis, by="subject_id")%>%
  left_join(wide_cabg_pci, by="subject_id")

ccu_analysis2 <- ccu_analysis2%>%
  select(-c("hadm_id","hadm_id.x","hadm_id.x.x", 
            "hadm_id.x.x.x","hadm_id.y","hadm_id.y.y","hadm_id.y.y.y","icustay_id",
            "icustay_id.x.x","icustay_id.x.x.x","icustay_id.y", "icustay_id.y.y","icustay_id.y.y.y"))%>%
  rename("RRT_total_stay"="RRT.x")%>%
  rename("RRT24"="RRT.y")

#Replacing NaN by 0 in appropriate sections only

ccu_analysis2$RRT_total_stay <- replace_na(ccu_analysis2$RRT_total_stay, 0)
ccu_analysis2$RRT24 <- replace_na(ccu_analysis2$RRT24, 0)
ccu_analysis2$vent <- replace_na(ccu_analysis2$vent, 0)
ccu_analysis2$ECMO <- replace_na(ccu_analysis2$ECMO, 0)
ccu_analysis2$IMPELLA <- replace_na(ccu_analysis2$IMPELLA, 0)
ccu_analysis2$CABG <- replace_na(ccu_analysis2$CABG, 0)
ccu_analysis2$PCI <- replace_na(ccu_analysis2$PCI, 0)

# Removing duplicates
# There is something wrong, we should have 6548 patients as we started the left join on wide_ccu_dx table
# Must verify the join thing

ccu_analysis2 <- distinct(ccu_analysis2)

write.csv(ccu_analysis2, file="MIMIC_all_CCU_patients")




#Check point, total unique CCU patients = 6802
  
#Here I will mention the tables that do not contain the 3 IDs
#1.ccu_demographics_dob_gender_death- only subject_id
#2. wide_procedures only subject_id
#3. ccu_mortality only subject_id
#4. ccu_gcs only subject_id
#5. ccu_sofa only subject_id
#6. ccu_oasis only subject_id
#7. wide_cabg_pci only subject_id

#Other notes
# ccu_vitals might be the initial table because contains only 6700 vs 6800 patients
# ccu_procedures could me precised by charttime, here only procedures having occured during stay


###### TO DO
## 1. Age correction
## 2. Filter by cardiogenic shock SCAI stage and add that to table
## 3. Correct duplicates