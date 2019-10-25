# This document explains the main variables of the MIMIC cardiogenic shock cohort 

The purpose of this document is to facilitate data analysis for everyone who will be working with the dataset and avoid possible traps that one could easily fall into.

## Summary

The dataset contains only the patients meeting the definition of SCAI shock >= C Cardiogenic Shock criteria as per the Jentzer et al. Cardiogenic Shock Classiﬁcation to Predict Mortality in the Cardiac Intensive Care Unit paper.
To access the dataset simply open the R file in : ./code/cardiogenic_shock_MIMIC.R

The reason I did not export this final file as a CSV is because I wanted to give you the flexibility to change the inclusion criteria.

##  How did we define Shock ?

So we took all the CCU patients and stratified them as follow :

#### 1. Hypoperfusion (SCAI shock C)
Presence of any of the following criteria:

a) Admission lactate >2 mmol/l 
b) Urine output <720 ml during ﬁrst 24 h 
c) Creatinine increased by 0.3 mg/dl during ﬁrst 24 h

#### 2. Deterioration (SCAI shock D)

a )Number of vasoactives during ﬁrst 24 h > number of vasoactives during ﬁrst 1 h
b) Patient on any pressor and meeting C [this is not a definition used on the paper, tell me if you agree..]

#### 3. Refractory shock (SCAI shock E)

a) Number of vasoactives during ﬁrst 1 h >2 
b) IABP

You will notice that the paper has more criterias for class D and E but with MIMIC those criterias were the easiest to use.

I find the criteria 1. to be a bit loose so if you want to tighten it up, share your suggestions before we go to deep in the analysis.

Total cohort using the definition above :
C : 3461
D : 543
E : 134


##  Columns

Those are the main groups of col of the dataset, total 127. 

#### Non-clinical data

  [1] "subject_id" | Beware to exclude it when running any analysis, easy to forget
  
#### Diagnosis

  Those are ICD9 codes. 
  Unclear if we can interpret it as discharge diagnoses or as comorbidities
  
  
  
      "acute_cerebrovascular_disease"                           
  [3] "acute_renal_failure"                                      "anemia"                                                  
  [5] "atrial_fibrillation"                                      "blood_malignancy"                                        
  [7] "chronic_kidney_disease"                                   "chronic_obstructive_pulmonary_disease_and_bronchiectasis"
  [9] "coronary_atherosclerosis"                                 "diabetes_mellitus"                                       
 [11] "heart_valve_disorders"                                    "hypertension"                                            
 [13] "neoplasms"                                                "nstemi"                                                  
 [15] "septicemia"                                               "shock_cardiogenic"    -> per interest only 559 were coded that way                                   
 [17] "shock_nos"                                                "shock_septic"  
 [19] "stemi"                                                    

#### Vital Signs and Labs

All are available > 25%.
Strangely enough, the only variable missings > 25% are : lactate (35%), bilirubin and troponins
 
 "heart_rate_min"                                          
 [21] "heart_rate_max"                                           "heart_rate_mean"                                         
 [23] "sys_bp_min"                                               "sys_bp_max"                                              
 [25] "sys_bp_mean"                                              "dias_bp_min"                                             
 [27] "dias_bp_max"                                              "dias_bp_mean"                                            
 [29] "mean_bp_min"                                              "mean_bp_max"                                             
 [31] "mean_bp_mean"                                             "resp_rate_min"                                           
 [33] "resp_rate_max"                                            "resp_rate_mean"                                          
 [35] "temp_c_min"                                               "temp_c_max"                                              
 [37] "temp_c_mean"                                              "sp_o2_min"                                               
 [39] "sp_o2_max"                                                "sp_o2_mean"                                              
 [41] "glucose_min"                                              "glucose_max"                                             
 [43] "glucose_mean"                                             "aniongap_min"                                            
 [45] "aniongap_max"                                             "albumin_min"                                             
 [47] "albumin_max"                                              "bands_min"                                               
 [49] "bands_max"                                                "bicarbonate_min"                                         
 [51] "bicarbonate_max"                                          "bilirubin_min"                                           
 [53] "bilirubin_max"                                            "creatinine_min"                                          
 [55] "creatinine_max"                                           "chloride_min"                                            
 [57] "chloride_max"                                             "glucose_min_2"                                           
 [59] "glucose_max_2"                                            "hematocrit_min"                                          
 [61] "hematocrit_max"                                           "hemoglobin_min"                                          
 [63] "hemoglobin_max"                                           "lactate_min"                                             
 [65] "lactate_max"                                              "platelet_min"                                            
 [67] "platelet_max"                                             "potassium_min"                                           
 [69] "potassium_max"                                            "ptt_min"                                                 
 [71] "ptt_max"                                                  "inr_min"                                                 
 [73] "inr_max"                                                  "pt_min"                                                  
 [75] "pt_max"                                                   "sodium_min"                                              
 [77] "sodium_max"                                               "bun_min"                                                 
 [79] "bun_max"                                                  "wbc_min"                                                 
 [81] "wbc_max"                                                  "tropo_i_min"                                             
 [83] "tropo_i_max"                                              "tropo_t_min"                                             
 [85] "tropo_t_max"                                              "n_tpro_bnp_min"                                          
 [87] "n_tpro_bnp_max"                                           "delta_creat_0_3"
 
 [93] "urine_output"   
  
#### Demographics

 [89] "intime"                                                   "outtime"                                                 
 [91] "los"                                                      "gender"  
[125] "age"                                                      "age_group"    

#### Mechanical Intervention
 
 All interventions occured in the first 24 hours except for PCI and CABG for which we only know they occured during admission.
 
 "rrt"                                                     
 [95] "vent"                                                     "ecmo"                                                    
 [97] "iabp"                                                     "impella"    
      "cabg"                                                    
[121] "pci"     

#### Medication
 
 The pressors were coded 0 or 1 for each patient. This will facilitate any regression-type of analysis.
 However the data is duplicated for first hour VS longer than 24 hours.
 It is absolutely key that you remove all the _first_hour elements if you decide to only look at what was received in the first 24 hours of stay.
 
 Also, I created a category anypressor (if at least >= 1, value 1 otherwise 0) and total_pressors (which is the total number of different pressors received.
 Once again, if any of those two categorical variables is used, the other pressors_related variables cannot be used.
 
 
 [99] "dobutamine"                                               "dopamine"                                                
[101] "epinephrine"                                              "milrinone"                                               
[103] "norepinephrine"                                           "phenyl"                                                  
[105] "vasopressin"                                              "total_pressors"                                          
[107] "any_pressor"                                              "dobutamine_first_hour"                                   
[109] "dopamine_first_hour"                                      "epinephrine_first_hour"                                  
[111] "milrinone_first_hour"                                     "norepinephrine_first_hour"                               
[113] "phenyl_first_hour"                                        "vasopressin_first_hour"                                  
[115] "total_pressors_first_hour"                                "any_pressor_first_hour"

#### Severity Scores
[117] "gcs"                                                                                                      
[119] "oasis"    
      "sofa"                                            
[127] "scai_shock" category  coded : "C", "D", "E"

#### Outcomes and response variable 

3 mortality outcomes. They were coded 0 or 1.

 "icu_mortality"                                           
[123] "hospital_mortality"                                       
"thirty_day_mortality"              
