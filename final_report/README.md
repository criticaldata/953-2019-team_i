# Final Project Report

# Predicting mortality in patients with cardiogenic shock

Eric Yamga, Sreekar Mantena, Daren Rosen, Neel Butala

# Introduction

Despite great therapeutic advances in the field of cardiology recent decades, mortality for patients in cardiogenic shock remains high. One trial found improvement in mortality with coronary revascularization among patients with myocardial infarction and cardiogenic shock. 

However, subsequent trials of medical therapies and devices for patients in cardiogenic shock have not found any benefit. Furthermore, the mortality of patients in such trials has remained steady at approximately 50%.

Prediction of mortality among patients in cardiogenic shock is important, as it can inform clinical decision making and the quantification of mortality risk can be used to formulate a case mix index for patient populations with cardiogenic shock. Gaining a better understanding of a particular patient’s mortality can guide treatment decisions regarding escalation or de-escalation of care, especially in a population in which only select patients might benefit from mechanical support or advanced therapies. 

Furthermore, a mortality prediction model can better inform risk adjustment in future studies of patients in cardiogenic shock and inform clinical trials for development of future therapies. The recently published SCAI Shock classification offers an opportunity to define a more homogeneous set of patients for enrollment in clinical trials. 

However, predictors of mortality within this population remain unknown. 

Most well-established predictive mortality models for patients in the intensive care unit have been derived from heterogeneous patient populations often without primary cardiac conditions. The APACHE III and SOFA scores have been used to assess mortality in heterogenous cardiac ICU populations with relatively good discrimination with area under the receiver operator curve of > 0.80. However, there are no large scale studies which validate these models in cardiogenic shock, and moreover smaller studies suggest these perform much less well in this population. 

Existing predictive mortality scores for cardiogenic shock have variable robustness and most models with good discrimination are concerning for lack of generalizability. Some have been derived from specific regions of the world which may differ in clinical practice or population genetics, which may affect overall cardiac risk and patient complexity. Others have evaluated mortality in the setting of specific interventions such as mechanical support with ECMO.

This project will use large real-world databases, MIMIC-III and eICU, to develop a mortality prediction model among patients in cardiogenic shock in the cardiac ICU defined as SCAI class C. 

We aim to create a predictive model that will be generalizable and robust for predicting mortality in this population. The results of this study can not only be used to guide treatment decisions among patients, but can also inform clinical trials for development of therapies for patients in cardiogenic shock in the future.

# Research Hypothesis

We hypothesize will be able to develop a parsimonious risk prediction model among patients with cardiogenic shock in the cardiac ICU. Moreever, we hypothesize that this model will be able to achieve better discrimination than existing models.

# Objectives

1. We will use traditional logistic regression methods to develop a parsimonious prediction model for in-hospital mortality among patients with cardiogenic shock (defined as SCAI Shock C or greater) admitted to the cardiac ICU. We will quantify discrimination by calculating the area under the receiver operator characteristic curve. 

2. We will use other supervised machine learning methods (SVM, NN, GBM, RF, DT) to similarly predict  in-hospital mortality among patients with cardiogenic shock (defined as SCAI Shock C or greater) admitted to the cardiac ICU. 

3. We will train our model using the eICU database and validate it using MIMIC.  

4. We will finally compare our risk models based on established metrics of fit to other published models of mortality in cardiac ICUs.

# Methodology

**a) Datasets**

We will use the Philips eICU dataset to develop our risk model. The eICU database comprises 200,859 patient unit encounters for 139,367 unique patients admitted between 2014 and 2015. Patients were admitted to one of 335 units at 208 hospitals located throughout the US. The approximate number of patients that meet the definition of cardiogenic shock is not available in the database summary.

The study is exempt from institutional review board approval due to the retrospective design, lack of direct patient intervention, and the security schema, for which the re-identification risk was certified as meeting safe harbor standards by an independent privacy expert (Privacert, Cambridge, MA) (Health Insurance Portability and Accountability Act Certification no. 1031219-2).

We will then use the MIMIC-III dataset to externally validate our model. MIMIC-III contains data associated with 53,423 distinct hospital admissions for adult patients (aged 16 years or above) admitted to critical care units between 2001 and 2012. MIMIC-III integrates deidentiﬁed, comprehensive clinical data of patients admitted to the Beth Israel Deaconess Medical Center. The approximate number of patients that meet the definition of cardiogenic shock is not available in the database summary.

The data in MIMIC-III and MIMIC-CXR has been de-identified, and the institutional review boards of the Massachusetts Institute of Technology (No. 0403000206) and Beth Israel Deaconess Medical Center (2001-P-001699/14) both approved the use of the database for research.

**b) Study Population**

We will include all patients enrolled in cardiac ICUs in cardiogenic shock who meet SCAI Shock C criteria or greater at admission in both the eICU and the MIMIC dataset.

The official diagnostic criterias for the SCAI shock score  arte the following :

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

*VIS : VIS ¼ dobutamine þ dopamine þ (10 * phenylephrine þ milrinone) þ (100 *[epinephrine þ norepinephrine]) þ (10,000 * units/kg/min vasopressin)*

*NEE :  NEE is calculated using the dose equivalency as follows: 0.1 mg/kg/min norepinephrine ¼ 0.1 mg/kg/min epinephrine ¼ 15 mg/kg/min dopamine ¼ 1 mg/kg/ min phenylephrine ¼ 0.04 U/min vasopressin*

Because we did not have access to all the aforementionned variables in our cohorts, we adapated the inclusion criteria and adpated identified the following :

SCAI Shock class C (any of) :

- Admission lactate >2 mmol/l and a doubling of creatinine during ﬁrst 24 h

We included an 'and' logical operator to increase the specificity of our cohort. In fact, using lactate or an elevation of creatinine as the only criteria, resulted in the inclusion of over 50% of the CCU admissions which is not representative of the prevalence of cardiogenic shock. Moreover, we changed the criteria from an increase of 0.3 to a doubling of creatinine, to similarly increase the specificity of our cohort.

SCAI Shock class D :

- Any active vasoactive drug

SCAI Shock class E  :

- IABP 

Using those criterias, we obtained 6626 patients in eICU (training cohort) and 2300 patients in MIMIC-III(validation cohort).

**c) Data Extraction and Analysis**

Once the cohort was selected, our modeling process included : cleaning the data, variable selection and model building. 

The data was queried using SQL and further data processing was done in R Studio. 
The ****table 1[MUST ADD]** provided shows the main characteristics and variables of the two datasets including the percentage of missing variables.

Predictors with more than 25% missing values were discarded from the data analysis. The remaining predictors and missing values were appropriately imputed using the MICE (Multiple Imputation by Chained Equations) method. Multiple imputations has been shown to be superior to handle missing values compared to single imputation methods. 

We began our modeling process by determining the appropriate variables to include for risk prediction. Out of the 70 predictors included from eICU, we performed cross-validated best subset selection on the eICU dataset (training cohort) with logistic regression to determine the most important predictors and recursive feature elimination. We set our objective to obtain a clinical interpretable model with a total of 8 predictors.

First, best subset selection allowed us to compare 2624 different subsets. The best resulting subset contained 34 predictors.
From there, we used domain knowledge to remove potential collinear variables (i.e. we removed diastolic blood pressure and only kept mean blood pressure) and ended up with a subset of 25 predictors. From there, we used recursive feature elimination and kept the top 8 predictors.

We trained our model on the eICU dataset as it had the largest sample size out of the two databases. We also believe that this will improve the generalizability of our model, as eICU is a database regrouping 12 different ICUs across the United States thereby reflecting a more diverse patient population than the MIMIC database.

Moreover, we trained our model on the original dataset and on a modified version of the dataset in which we corrected  for the class imbalance using subsampling.  We compared logistic regression to other statistical learning methods including : support vector machine, neural networks, random forest, gradient boosting and decision tree.

For the logistic regression model, continuous variables were binned (converted to categorical variables) for clinical interpretability.  Our approach was to use the optimal cut-point to maximize specificity while maintaining an optimal level of accuracy.

For each variable of interest, we used the R cut-point package that automatizes the process and determines the most appropriate cut-off point for a predetermined metric of choice.

**Table 1:**

| Diagnoses/Medications                       |             |             |             |
|---------------------------------------------|-------------|-------------|-------------|
| Variable Name                               | eICU        | MIMIC       | p-value     |
| acute cerebrovascular disease               | 3.92%       | 3.79%       | 0.779050277 |
| acute renal failure                         | 23.54%      | 36.84%      | 2.14E-35    |
| anemia                                      | 5.51%       | 27.16%      | 7.68E-187   |
| atrial fibrillation                         | 18.17%      | 39.71%      | 1.88E-99    |
| blood malignancy                            | 0.83%       | 2.75%       | 4.16E-12    |
| cardiac arrest and ventricular fibrillation | 14.14%      | 15.26%      | 0.189895865 |
| chronic kidney disease                      | 20.89%      | 16.26%      | 1.54E-06    |
| chronic obstructive pulmonary disease       | 11.21%      | 15.04%      | 1.38E-06    |
| coronary atherosclerosis                    | 9.01%       | 56.80%      | 0           |
| diabetes mellitus                           | 5.16%       | 34.79%      | 0           |
| heart valve disorders                       | 6.31%       | 23.89%      | 2.31E-12    |
| hypertension                                | 24.49%      | 57.50%      | 9.54E-19    |
| neoplasms                                   | 3.76%       | 13.12%      | 6.45E-59    |
| nstemi                                      | 8.24%       | 18.31%      | 3.50E-41    |
| septicemia                                  | 17.11%      | 19.79%      | 0.003872368 |
| shock cardiogenic                           | 7.08%       | 22.14%      | 3.36E-90    |
| shock nos                                   | 4.32%       | 2.53%       | 0.000126006 |
| shock septic                                | 5.46%       | 7.19%       | 0.002460714 |
| stemi                                       | 8.98%       | 21.62%      | 6.68E-58    |
| vent                                        | 0.318140658 | 0.577593723 | 2.53E-11    |
| iabp                                        | 0.062481135 | 0.265475153 | 1.59E-15    |
| total pressors                              | 1.25731965  | 1.157802964 | 4.85E-06    |
| hospital mortality                          | 0.172620065 | 0.231037489 | 1.34E-09    |
| age                                         | 65.58366091 | 69.82345248 | 3.64E-31    |
| bmi                                         | 29.66292331 | 28.38716795 | 2.73E-07    |
| charlson score                              | 0.927256263 | 2.309938971 | 0           |
| shock index                                 | 1.085068515 | 0.793292034 | 5.31E-22    |
| any inotrope                                | 0.141865379 | 0.49912816  | 9.28E-28    |


| Labs and Vitals |             |             |             |
|-----------------|-------------|-------------|-------------|
| Variable Name   | eICU        | MIMIC       | p-value     |
| heart rate mean | 85.1432836  | 84.42576915 | 0.051056286 |
| dias bp mean    | 64.87104499 | 57.41271251 | 3.93E-17    |
| resp rate mean  | 19.74364252 | 19.2885117  | 5.30E-07    |
| temp c mean     | 36.72904554 | 36.75643814 | 0.109014925 |
| sp o2 mean      | 96.45046255 | 96.76148088 | 7.56E-05    |
| sys bp mean     | 119.3573355 | 109.1879363 | 2.86E-12    |
| aniongap max    | 13.88322337 | 18.48812665 | 1.04E-17    |
| albumin min     | 3.000669736 | 3.181930334 | 5.59E-17    |
| bicarbonate min | 21.56475359 | 20.50285714 | 3.41E-15    |
| chloride max    | 105.7378996 | 106.9719421 | 4.37E-14    |
| hematocrit max  | 37.01914404 | 38.13734729 | 1.21E-12    |
| hemoglobin min  | 10.53522902 | 10.15564304 | 4.24E-11    |
| platelet max    | 228.1595301 | 269.3015734 | 9.97E-54    |
| potassium max   | 4.707902045 | 5.035486687 | 1.50E-48    |
| ptt max         | 44.98612372 | 73.42105503 | 9.85E-21    |
| inr max         | 1.636463487 | 2.056786038 | 4.51E-29    |
| pt max          | 17.92982352 | 19.15912807 | 2.50E-05    |
| bun max         | 34.6044338  | 38.62292213 | 9.49E-11    |
| wbc max         | 15.0145216  | 15.78574058 | 0.00206848  |

(A Student's t-test was used to compute p-values).

# Results

**a)  Final model**

The final logistic regression model is shown in figure 1.

**![](https://lh3.googleusercontent.com/JyPkEPu6pzGpoTs-1IjHWvXaeVk4kXdbkQxN8yTDftTnyXy52MjQtKbVL0rod5rTwI1bx1Shhru1OpzU7IlXkralFyKS6cxlomHLGUSdt9bEHqPSESoXQ6QdOw0d7ZOitxh0RkxL34A)**

*Figure 1*

It includes clinically relevant risk factors that can be divided in three categories : comorbidities (stroke, cardiac arrest, age), vital signs (shock index, saturation), labs (anion gap, BUN) and therapies (mechanical ventilation).

The performance of the model is shown in table 2. 



<table><colgroup><col width="93px"><col width="84px"><col width="67px"><col width="56px"><col width="42px"></colgroup><tbody><tr><th>&nbsp;</th><th><span><span>Accuracy</span></span></th><th><span><span>ROC</span></span></th><th><span><span>Se</span></span></th><th><span><span>Sp</span></span></th></tr><tr><td><span><span>5-CV (training)</span></span></td><td><span><span>86,8</span></span></td><td><span><span>85,5</span></span></td><td><span><span>96,7</span></span></td><td><span><span>38</span></span></td></tr><tr><td><span><span>MIMIC-III</span><span>&lt;br&gt;</span><span>(validation)</span></span></td><td><span><span>81,2</span></span></td><td><span><span>80,7</span></span></td><td><span><span>97,4</span></span></td><td><span><span>27</span></span></td></tr></tbody></table>



*Table 2*

**b)  Other statistical learning methods trained**

We compared this model to other machine learning algorithms to see if better accuracy could be achieved.

The results can be shown in the tables below.

In terms of performance on cross-validation (Figure 2 and Figure 3), ROC is slightly superior with random forest and gradient boosting compared to logistic regression. In terms of performance on the validation set however, only SVM and GBM perform better than logistic regression with an accuracy of 82% compared to 81%. In summary, the improvement in prediction accuracy is only slightly improved with those complex machine learning algorithms. 

![](https://lh5.googleusercontent.com/kXr8Uba5u8INKIVurDF6jFPT1vhvsL3XocCSkI6WwcTGIlkqhP65P93vblEMKCiovkAlmB8c_gARCV0g1mkjNcFqjUMHO4LmYaNTbTAETG7GkCj_kN4NREBa3V6EFHfMa-q-uyEklY4)**

*Figure 2*

**![](https://lh4.googleusercontent.com/n6bCWMbQq3V8Cw5VT6fu8if7OaiKMY1GgVAoM5cserYrwiI2xe8-ak_1a6saQmkRv8NyxAlpPiaAbuEw1P3hc036WZTGZnGajns6SVxTmE5S6dnYNtgyC55xsQhe5dvRSBOZdCkmp-0)**

*Figure 3*

**![](https://lh5.googleusercontent.com/gHJ_3sbA13xY40q3csUglQAxo6-76m5ozNgKOX1O0wk8h6UJcyCHqac_YMlK1EMPn8DBWbSfQa5GqN_0D9fskYMntlBGnhziYB02guqfucuJ7yuPkIzGGLBQ5CjbDdKhSZHmhf69K9E)**

*Figure 4*

# Discussion

## Findings

Overall, our model is the best-performing predictive mortality model that currently exists for cardiogenic shock patients. 

Our logistic regression model uses a combination of 7 readily-available vital signs and lab values (SpO2, Age, Anion Gap, BUN, Mechanical Ventilation, Stroke, Shock Index, and Cardiac Arrest) to predict mortality. We trained our model on a subset of the eICU dataset, and we saw a strong ROC of .86 when performing validation on the eICU dataset. We also cross-validated our model on the MIMIC dataset, and achieved an ROC of .81.

When considering the differences in the eICU and MIMIC patient populations, this drop in cross-validation accuracy makes sense. The MIMIC population is derived from a single-center dataset at a tertiary care facility in Boston, MA. The eICU population is derived from a much more diverse multicenter dataset from hospitals all over the country. Our exploratory data analysis revealed that the MIMIC population has higher mortality (17% in eICU vs 23% in MIMIC), and has higher use of inotropes (14% in eICU vs 49% in MIMIC) and ventilation (32% in eICU vs 58% in MIMIC). These metrics indicate that the MIMIC population has sicker patients in a more serious condition than those patients in the eICU dataset, and this difference in patient populations helps to explain the difference in eICU validation versus MIMIC cross-validation accuracy.

As discussed earlier, cardiogenic shock patients still face mortality of over ~30% and our risk-prediction model could be used at both the bedside and in research. In clinical care, it could be used to inform physicians of whether or not to escalate care. Clinical trial coordinators could also use this tool to stratify patient populations to ensure the control and treatment arms have similar characteristics.

Currently available models are not specifically designed to predict mortality in cardiogenic shock, and their performance is still weak. The IABP Shock II trial's prediction model was trained on only 480 patients, and has a poor AUC of .73. Similarly, the recently-published CCU mortality score from researchers at the Mayo Clinic has a 12,000 patient cohort and an internal validation ROC of 0.87 (which is similar to our eICU validation of 0.86), but has no external validation cohort.

So, our model performs similarly or better than current risk prediction models and is the first risk prediction model specifically for patients in cardiogenic shock.

## Limitations

One of the key limitations with our model is that it may not be fully generalizable to all patient populations while maintaining the same predictive power. We experienced a 6-point drop in ROC when moving to from internal validation in the eICU dataset to external validation on the MIMIC dataset. We hope to increase our model's generalizability and accuracy by using more advanced modeling strategies.

Additionally, a possible criticism of our approach to stratifying patients into cardiogenic shock class C, D, and E is that we only used a subset of the SCAI consensus clinical definition of cardiogenic shock criteria. Due to limitations with the dataset, we were unable to extract data for the dosage of vasopressors, urine output, and other variables. Therefore, we were required to revise our inclusion criteria to ensure compatibility with the data we had available.

## Future Work

We are planning to work throughout January and February on improving the accuracy and performance of our model. As discussed in the results section, we are currently using a logistic regression model. We hope to work on improving our modeling strategy by testing and evaluating a variety of more advance modeling techniques. Furthermore, the MIMIC-IV dataset will be released in February 2020 and all our code will be intercompatible with the new database. We are going to rerun our training and validation on the MIMIC-IV dataset once it's released to increase our sample size.


# Reproducibility

All code used to generate the analyses is available in the team i github repository, and is both fully commented and readily executable. The code is in the 'analysis' folder, and the eICU and MIMIC-specific code are in subfolders. Our code for probing both databases is organized into three key R files. The first script (1. Data Extraction) uses BigQuery and extracts all the relevant data from MIMIC and eICU, and all variables are loaded into the R workspace memory. The second script (2. Join Data) joins all the data by a unique patient identifier into a csv file and exports the csv file. The third script (3. CS Patient Selection) goes through the variables and filters patients, determining whether or not they are experiencing cardiogenic shock and what class (C, D, or E) they're in. If the patient is in cardiogenic shock by our criteria, they are included in the csv file that is exported by this final third script.

Both our eICU code and MIMIC code have this three-script structure to parse the database, extract information, and output the final .csv that is analyzed. Then, we used the script called '5. Modeling' under the 'Predictive Models' folder to develop the models we discussed above. All the models were trained and validated in the same script, and the model parameters and model types can be changed and rerun to perform future optimization. Comments are provided in the script to indicate how the model is trained and validated.

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
