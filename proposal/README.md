# Project Title

Predicting mortality in patients with cardiogenic shock

Background
Despite great therapeutic advances in the field of cardiology recent decades, mortality for
patients in cardiogenic shock remains high. One trial found improvement in mortality with 
coronary revascularization among patients with myocardial infarction and cardiogenic shock. 
However, subsequent trials of medical therapies and devices for patients in cardiogenic shock 
have not found any benefit. Furthermore, the mortality of patients in such trials has remained 
steady at approximately 50%.

Prediction of mortality among patients in cardiogenic shock is important, as it can inform clinical decision making and the quantification of mortality risk can be used to formulate a case mix index for patient populations with cardiogenic shock. Gaining a better understanding of a particular patient’s mortality can guide treatment decisions regarding escalation or de-escalation of care, especially in a population in which only select patients might benefit from mechanical support or advanced therapies. Furthermore, a mortality prediction model can better inform risk adjustment in future studies of patients in cardiogenic shock and inform clinical trials for development of future therapies. The recently published SCAI Shock classification offers an opportunity to define a more homogeneous set of patients for enrollment in clinical trials. However, predictors of mortality within this population remain unknown. 
Most well-established predictive mortality models for patients in the intensive care unit have been derived from heterogeneous patient populations often without primary cardiac conditions. The APACHE III and SOFA scores have been used to assess mortality in heterogenous cardiac ICU populations with relatively good discrimination with area under the receiver operator curve of > 0.80. However, there are no large scale studies which validate these models in cardiogenic shock, and moreover smaller studies suggest these perform much less well in this population. Existing predictive mortality scores for cardiogenic shock have variable robustness and most models with good discrimination are concerning for lack of generalizability. Some have been derived from specific regions of the world which may differ in clinical practice or population genetics, which may affect overall cardiac risk and patient complexity. Others have evaluated mortality in the setting of specific interventions such as mechanical support with ECMO.
This project will use large real-world databases, MIMIC-III and eICU, to develop a mortality prediction model among patients in cardiogenic shock in the cardiac ICU defined as SCAI class C. By leveraging the Philips eICU database, which includes patients from over 200 US hospitals, we aim to create a predictive model that will be generalizable and robust for predicting mortality in this population. The results of this study can not only be used to guide treatment decisions among patients, but can also inform clinical trials for development of therapies for patients in cardiogenic shock in the future.
 
Research Hypothesis
We hypothesize will be able to develop a parsimonious risk prediction model among patients with cardiogenic shock in the cardiac ICU. Moreever, we hypothesize that this model will be able to achieve better discrimination than existing models.



Objectives
1.     We will use traditional logistic regression methods to develop a parsimonious prediction model for in-hospital mortality among patients with cardiogenic shock (defined as SCAI Shock C or greater) admitted to the cardiac ICU. We will quantify discrimination by calculating the area under the receiver operator characteristic curve. 
2.     We will use unstructured machine learning methods to develop a parsimonious prediction model for in-hospital mortality among patients with cardiogenic shock (defined as SCAI Shock C or greater) admitted to the cardiac ICU
3.     We will use similar methods to develop prediction models among patients based on characteristics at 24 hours of ICU admission.
4.     We will compare risk models based on established metrics of fit to other published models of mortality in ICUs
 
Data Sources
We will use the Philips eICU dataset to develop our risk model. The eICU database comprises 200,859 patient unit encounters for 139,367 unique patients admitted between 2014 and 2015. Patients were admitted to one of 335 units at 208 hospitals located throughout the US. The approximate number of patients that meet the definition of cardiogenic shock is not available in the database summary.
We will then use the MICIC dataset to externally validate our model. MIMIC-III contains data associated with 53,423 distinct hospital admissions for adult patients (aged 16 years or above) admitted to critical care units between 2001 and 2012. MIMIC-III integrates deidentiﬁed, comprehensive clinical data of patients admitted to the Beth Israel Deaconess Medical Center. The approximate number of patients that meet the definition of cardiogenic shock is not available in the database summary.

 Study Population
We will include all patients enrolled in cardiac ICUs in cardiogenic shock who meet SCAI Shock C criteria or greater at admission.
The only exclusion criteria expected are: readmissions and duplicates.



Study Outcomes
The primary outcome will be in hospital mortality. The secondary outcome will be cardiac ICU mortality.
 
Covariates of interest
We will include all demographic characteristics (Age, Sex, Race), comorbidities as defined by diagnosis codes (MI, CHF, Stroke, CKD, DM, Cancer, Pulmonary disease, Dialysis) and admission diagnoses (ACS, Acute CHF, Cardiac Arrest, Shock, Respiratory Failure)
We will include vital signs, advanced hemodynamic information (via arterial line, PA line), labs (including BNP, pro-calcitonin), CICU therapies (vasoactive medications, ventilatory support, mechanical support, dialysis) and severity of illness scores (qSOFA, APACHE, etc.) upon admission to the ICU and at 24 hours of ICU admission. 
All included variables will need to be present for at least 75% of all patients.
We will identify the most important predictors using backward selection for the logistic regression component of our predictive model. 

Confounders
The main confounders expected are the following :
Missing variable bias. We might encounter variables that are unobserved or missing in > 25% of patients that will therefore not be included in our prediction model.
Identifying the patients meeting a strict definition of cardiogenic shock might be difficult. Patients in shock in the ICU represent a heterogenous group and it will be important to distinguish cardiogenic shock from SIRS and septic shock. 
Additionally, we suspect that mechanical therapies can significantly the primary outcome and the subgroup of patients receiving them will be important to identify. 
Additional analysis
We will repeat the aforementioned analysis by limiting our cohort to those meeting the IABP-SHOCK II trial inclusion criteria. This will provide an additional benchmark for the SCAI Shock C criteria as they have never been validated in a clinical study yet. 
Acknowledgements:
We would like to thank the MIT-HST 953 team without whom this project would not have been possible. 

References:
See above. 

 
 


