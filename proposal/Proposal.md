# Predicting mortality in patients with cardiogenic shock

Eric Yamga, Sheekar Mantena,  Nitinraja Singh, Daren Rosen, Neel Butala

# Background

Despite great therapeutic advances in the field of cardiology recent decades, mortality for
patients in cardiogenic shock remains high. One trial found improvement in mortality with 
coronary revascularization among patients with myocardial infarction and cardiogenic shock. 
However, subsequent trials of medical therapies and devices for patients in cardiogenic shock 
have not found any benefit. Furthermore, the mortality of patients in such trials has remained 
steady at approximately 50%.

Prediction of mortality among patients in cardiogenic shock is important, as it can inform clinical decision making and the quantification of mortality risk can be used to formulate a case mix index for patient populations with cardiogenic shock. Gaining a better understanding of a particular patient’s mortality can guide treatment decisions regarding escalation or de-escalation of care, especially in a population in which only select patients might benefit from mechanical support or advanced therapies. Furthermore, a mortality prediction model can better inform risk adjustment in future studies of patients in cardiogenic shock and inform clinical trials for development of future therapies. The recently published SCAI Shock classification offers an opportunity to define a more homogeneous set of patients for enrollment in clinical trials. However, predictors of mortality within this population remain unknown. 

Most well-established predictive mortality models for patients in the intensive care unit have been derived from heterogeneous patient populations often without primary cardiac conditions. The APACHE III and SOFA scores have been used to assess mortality in heterogenous cardiac ICU populations with relatively good discrimination with area under the receiver operator curve of > 0.80. However, there are no large scale studies which validate these models in cardiogenic shock, and moreover smaller studies suggest these perform much less well in this population. 

Existing predictive mortality scores for cardiogenic shock have variable robustness and most models with good discrimination are concerning for lack of generalizability. Some have been derived from specific regions of the world which may differ in clinical practice or population genetics, which may affect overall cardiac risk and patient complexity. Others have evaluated mortality in the setting of specific interventions such as mechanical support with ECMO.

This project will use large real-world databases, MIMIC-III and eICU, to develop a mortality prediction model among patients in cardiogenic shock in the cardiac ICU defined as SCAI class C. 

We aim to create a predictive model that will be generalizable and robust for predicting mortality in this population. The results of this study can not only be used to guide treatment decisions among patients, but can also inform clinical trials for development of therapies for patients in cardiogenic shock in the future.

 
# Research Hypothesis

We hypothesize will be able to develop a parsimonious risk prediction model among patients with cardiogenic shock in the cardiac ICU. Moreever, we hypothesize that this model will be able to achieve better discrimination than existing models.



# Objectives

1. We will use traditional logistic regression methods to develop a parsimonious prediction model for in-hospital mortality among patients with cardiogenic shock (defined as SCAI Shock C or greater) admitted to the cardiac ICU. We will quantify discrimination by calculating the area under the receiver operator characteristic curve. 

2. We will use other supervised machine learning methods (KNN classifier, LDA, QDA) to similarly predict  in-hospital mortality among patients with cardiogenic shock (defined as SCAI Shock C or greater) admitted to the cardiac ICU. 

3. We will train our model using the MIMIC database and validate it using EICU.  

4. We will finally compare our risk models based on established metrics of fit to other published models of mortality in cardiac ICUs.

 
# Data Sources

We will use the Philips eICU dataset to develop our risk model. The eICU database comprises 200,859 patient unit encounters for 139,367 unique patients admitted between 2014 and 2015. Patients were admitted to one of 335 units at 208 hospitals located throughout the US. The approximate number of patients that meet the definition of cardiogenic shock is not available in the database summary.

The study is exempt from institutional review board approval due to the retrospective design, lack of direct patient intervention, and the security schema, for which the re-identification risk was certified as meeting safe harbor standards by an independent privacy expert (Privacert, Cambridge, MA) (Health Insurance Portability and Accountability Act Certification no. 1031219-2).

We will then use the MICIC dataset to externally validate our model. MIMIC-III contains data associated with 53,423 distinct hospital admissions for adult patients (aged 16 years or above) admitted to critical care units between 2001 and 2012. MIMIC-III integrates deidentiﬁed, comprehensive clinical data of patients admitted to the Beth Israel Deaconess Medical Center. The approximate number of patients that meet the definition of cardiogenic shock is not available in the database summary.

The data in MIMIC-III and MIMIC-CXR has been de-identified, and the institutional review boards of the Massachusetts Institute of Technology (No. 0403000206) and Beth Israel Deaconess Medical Center (2001-P-001699/14) both approved the use of the database for research.


# Study Population

We will include all patients enrolled in cardiac ICUs in cardiogenic shock who meet SCAI Shock C criteria or greater at admission.

Our design cohort will focus on the ICU patients from the MIMIC 3 database who have cardiogenic shock meeting criteria for SCAI Stages C, D, or E. 

The specific criteria that will be used to stratify patients cardiogenic shock stage are the following :

SCAI Shock class C (any of):
- Admission lactate >2 mmol/l  
- Urine output <720 ml during the ﬁrst 24 h  
- Creatinine increased by 0.3 mg/dl during ﬁrst 24 h

SCAI Shock class D (any of):
- Maximum lactate > admission lactate  
- Number of vasoactives during the ﬁrst 24 h > Number of vasoactives during ﬁrst 1 h  
- Maximum VIS* during ﬁrst 24 h > VIS during ﬁrst hour 
- Maximum NEE* during the ﬁrst 24 h > NEE during ﬁrst hour

SCAI Shock class E (any of):
- Mean systolic BP during ﬁrst 1 h <80 and on vasoactives  
- Mean systolic MAP during ﬁrst 1 h <50 and on vasoactives  
- Number of vasoactives during ﬁrst 1 h >2  
- Number of vasoactives during ﬁrst 1 h >1 and IABP during the ﬁrst 24 h  
- Admission lactate >10 mmol/l

*VIS : VIS ¼ dobutamine þ dopamine þ (10 * phenylephrine þ milrinone) þ (100 * [epinephrine þ norepinephrine]) þ (10,000 * units/kg/min vasopressin).

*NEE :  NEE is calculated using the dose equivalency as follows: 0.1 mg/kg/min norepinephrine ¼ 0.1 mg/kg/min epinephrine ¼ 15 mg/kg/min dopamine ¼ 1 mg/kg/ min phenylephrine ¼ 0.04 U/min vasopressin	

Our external validation cohort will be comprised of patients from the Philips eICU database in the cardiac ICU or CVICU who similarly meet criteria for SCAI stages C-E.
The only exclusion criteria expected are: readmissions (we will only consider patient’s first MIMIC admission) and duplicates.


# Study Outcomes

The primary outcome will be in hospital mortality. 
The secondary outcome will be cardiac ICU mortality.
 
# Covariates of interest

We will include all demographic characteristics (Age, Sex, Race), comorbidities as defined by diagnosis codes (MI, CHF, Stroke, CKD, DM, Cancer, Pulmonary disease, Dialysis) and admission diagnoses (ACS, Acute CHF, Cardiac Arrest, Shock, Respiratory Failure)

We will include vital signs, advanced hemodynamic information (via arterial line, PA line), labs (including BNP, pro-calcitonin), CICU therapies (vasoactive medications, ventilatory support, mechanical support, dialysis) and severity of illness scores (qSOFA, APACHE, etc.) upon admission to the ICU and at 24 hours of ICU admission. 

All included variables will need to be present for at least 75% of all patients.



# Confounders

The main confounders expected are the following :

1. Missing variable bias. We might encounter variables that are unobserved or missing in > 25% of patients that will therefore not be included in our prediction model.

2. Identifying the patients meeting a strict definition of cardiogenic shock might be difficult. Patients in shock in the ICU represent a heterogenous group and it will be important to distinguish cardiogenic shock from SIRS and septic shock. 

3. Additionally, we suspect that mechanical therapies can significantly the primary outcome and the subgroup of patients receiving them will be important to identify. 


# Acknowledgements:

The project was conceived, designed and conducted during the 2019 fall course HST.953 Collaborative Data Science in Medicine at the Harvard-MIT Division of Health Science and Technology.

# References:

1. Baran, David A., Cindy L. Grines, Steven Bailey, Daniel Burkhoff, Shelley A. Hall, Timothy D. Henry, Steven M. Hollenberg, et al. “SCAI Clinical Expert Consensus Statement on the Classification of Cardiogenic Shock.” Catheterization and Cardiovascular Interventions 94, no. 1 (2019): 29–37. https://doi.org/10.1002/ccd.28329.

2. Harjola, Veli-Pekka, Johan Lassus, Alessandro Sionis, Lars Køber, Tuukka Tarvasmäki, Jindrich Spinar, John Parissis, et al. “Clinical Picture and Risk Prediction of Short-Term Mortality in Cardiogenic Shock: Clinical Picture and Outcome of Cardiogenic Shock.” European Journal of Heart Failure 17, no. 5 (May 2015): 501–9. https://doi.org/10.1002/ejhf.260.

3. Hochman, J. S., L. A. Sleeper, J. G. Webb, T. A. Sanborn, H. D. White, J. D. Talley, C. E. Buller, et al. “Early Revascularization in Acute Myocardial Infarction Complicated by Cardiogenic Shock. SHOCK Investigators. Should We Emergently Revascularize Occluded Coronaries for Cardiogenic Shock.” The New England Journal of Medicine 341, no. 9 (August 26, 1999): 625–34. https://doi.org/10.1056/NEJM199908263410901.

4. Jentzer, Jacob C., Courtney Bennett, Brandon M. Wiley, Dennis H. Murphree, Mark T. Keegan, Ognjen Gajic, R. Scott Wright, and Gregory W. Barsness. “Predictive Value of the Sequential Organ Failure Assessment Score for Mortality in a Contemporary Cardiac Intensive Care Unit Population.” Journal of the American Heart Association 7, no. 6 (March 20, 2018). https://doi.org/10.1161/JAHA.117.008169.

5. Johnson, Alistair E. W., Tom J. Pollard, Lu Shen, Li-wei H. Lehman, Mengling Feng, Mohammad Ghassemi, Benjamin Moody, Peter Szolovits, Leo Anthony Celi, and Roger G. Mark. “MIMIC-III, a Freely Accessible Critical Care Database.” Scientific Data 3, no. 1 (May 24, 2016): 1–9. https://doi.org/10.1038/sdata.2016.35.

6. Kellner, P., R. Prondzinsky, L. Pallmann, S. Siegmann, S. Unverzagt, H. Lemm, S. Dietz, J. Soukup, K. Werdan, and M. Buerke. “Predictive Value of Outcome Scores in Patients Suffering from Cardiogenic Shock Complicating AMI: APACHE II, APACHE III, Elebute–Stoner, SOFA, and SAPS II.” Medizinische Klinik - Intensivmedizin Und Notfallmedizin 108, no. 8 (November 2013): 666–74. https://doi.org/10.1007/s00063-013-0234-2.

7. Kohsaka, Shun, Venu Menon, April M. Lowe, Michael Lange, Vladimir Dzavik, Lynn A. Sleeper, and Judith S. Hochman. “Systemic Inflammatory Response Syndrome After Acute Myocardial Infarction Complicated by Cardiogenic Shock.” Archives of Internal Medicine 165, no. 14 (July 25, 2005): 1643–50. https://doi.org/10.1001/archinte.165.14.1643.

8. Muller, Grégoire, Erwan Flecher, Guillaume Lebreton, Charles-Edouard Luyt, Jean-Louis Trouillet, Nicolas Bréchot, Matthieu Schmidt, et al. “The ENCOURAGE Mortality Risk Score and Analysis of Long-Term Outcomes after VA-ECMO for Acute Myocardial Infarction with Cardiogenic Shock.” Intensive Care Medicine 42, no. 3 (March 2016): 370–78. https://doi.org/10.1007/s00134-016-4223-9.

9. Ouweneel, Dagmar M., Erlend Eriksen, Melchior Seyfarth, and José P. S. Henriques. “Percutaneous Mechanical Circulatory Support Versus Intra-Aortic Balloon Pump for Treating Cardiogenic Shock: Meta-Analysis.” Journal of the American College of Cardiology 69, no. 3 (January 24, 2017): 358–60. https://doi.org/10.1016/j.jacc.2016.10.026.

10. Pollard, Tom J., Alistair E. W. Johnson, Jesse D. Raffa, Leo A. Celi, Roger G. Mark, and Omar Badawi. “The EICU Collaborative Research Database, a Freely Available Multi-Center Database for Critical Care Research.” Scientific Data 5 (September 11, 2018): 180178. https://doi.org/10.1038/sdata.2018.178.

11. Schrage Benedikt, Ibrahim Karim, Loehn Tobias, Werner Nikos, Sinning Jan-Malte, Pappalardo Federico, Pieri Marina, et al. “Impella Support for Acute Myocardial Infarction Complicated by Cardiogenic Shock.” Circulation 139, no. 10 (March 5, 2019): 1249–58. https://doi.org/10.1161/CIRCULATIONAHA.118.036614.

12. Thiele, Holger, Alexander Jobs, Dagmar M. Ouweneel, Jose P. S. Henriques, Melchior Seyfarth, Steffen Desch, Ingo Eitel, Janine Pöss, Georg Fuernau, and Suzanne de Waha. “Percutaneous Short-Term Active Mechanical Support Devices in Cardiogenic Shock: A Systematic Review and Collaborative Meta-Analysis of Randomized Trials.” European Heart Journal 38, no. 47 (December 14, 2017): 3523–31. https://doi.org/10.1093/eurheartj/ehx363.

13. Thiele, Holger, Uwe Zeymer, Franz-Josef Neumann, Miroslaw Ferenc, Hans-Georg Olbrich, Jörg Hausleiter, Gert Richardt, et al. “Intraaortic Balloon Support for Myocardial Infarction with Cardiogenic Shock.” New England Journal of Medicine 367, no. 14 (October 4, 2012): 1287–96. https://doi.org/10.1056/NEJMoa1208410.

14. Wengenmayer, Tobias, Daniel Duerschmied, Erika Graf, Marco Chiabudini, Christoph Benk, Sven Mühlschlegel, Alois Philipp, Matthias Lubnow, Christoph Bode, and Dawid Leander Staudacher. “Development and Validation of a Prognostic Model for Survival in Patients Treated with Venoarterial Extracorporeal Membrane Oxygenation: The PREDICT VA-ECMO Score.” European Heart Journal: Acute Cardiovascular Care 8, no. 4 (June 2019): 350–59. https://doi.org/10.1177/2048872618789052.
 
 


