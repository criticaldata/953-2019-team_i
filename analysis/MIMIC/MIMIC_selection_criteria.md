# MIMIC Criterias for patients selection

This file intends to systematically indicate the filters that have been used to identify the subset of interest for this particular study.

# MIMIC organization

5 different ICU units but only one that is relative to coronary care (which differs in that regards to eICU) 
CCU unit

##Tables that will serve to select :

**Determining ICU unit type**

1) ICUSTAYS
Identifiers : SUBJECT_ID, HADM_ID, ICUSTAY_ID
LOS (for one ICU stay)
FIRST_CAREUNIT

Determining age of patients and genders

1)PATIENTS
Identifiers : SUBJECT_ID (alone)
Characteristics : DOB, DOD, GENDER

2) ADMISSIONS
Identifiers : SUBJECT_ID, HADM_ID
Characteristics :  ETHINICITY
Death in hospital : DEATHTIME

NB Comorbidities are identified using the DIAGNOSES_ICD table

**Determining procedures**


1) CPTEVENTS
Identifiers : SUBJECT_ID, HADM_ID, ROW_ID
CPT_CD : CPT code
CPT_NUMBER : CPT code
date : CHARTDATE
DESCRIPTION : necessary to distinguish MV from NMV

2) D_CPT (dict)
Not that useful
D_CPT maps range of values

*Alternative*

1) PROCEDURES_ICD
Identifiers : ROW_ID SUBJECT_ID	HADM_ID
Code for procedure : ICD9_CODE
NB : no date, codes using for billing at discharge

2) D_ICD_PROCEDURES
Code for procedure : ICD9_CODE
Name of procedure : SHORT_TITLE, LONG_TITLE

*Alternative #2*

Only Metavision ICU thereby incomplete?


1) PROCEDUREEVENTS_MV
Identifiers : SUBJECT_ID, HADM_ID, ICUSTAY_ID
STARTTIME
ENDTIME
?? not clear how to link with 2


**Determining diagnosis**

1)DIAGNOSES_ICD
Identifiers : SUBJECT_ID, HADM_ID, ROW_ID
Code of dx : ICD9_CODE

2) D_ICD_DIAGNOSES (dict)
Code for dx : ICD9_CODE
Name of dx : SHORT_TITLE, LONG_TITLE


**Determining labs**

1) LABEVENTS
Identifiers : SUBJECT_ID, HADM_ID
Lab item : ITEMID
Value of lab : VALUE, VALUENUM
Time of measurement : CHARTTIME

2) D_LABITEMS
Lab item : ITEMID
Concept of lab : LABEL
loinc code : LOINC_CODE

3) MICROBIOLOGYEVENTS
Identifiers : SUBJECT_ID, HADM_ID
Organisms : ORG_ITEMID,ORG_NAME  (null if negative)

**Vital signs**


1) CHARTEVENTS
Identifiers : SUBJECT_ID, HADM_ID, ICUSTAY_ID
Item of interest : ITEMID
Value of if item : VALUE, VALUENUM
Time of item : CHARTTIME



2) D_ITEMS
NB - A lot of duplicates because to distinct databases
NB - All items except for labs (heart rate, etc.)
Item : ITEMID
Concept of item : LABEL


**Determining medication**


1) PRESCRIPTIONS
Identifiers : SUBJECT_ID, HADM_ID, ICUSTAY_ID
Class of med : DRUG_TYPE 
Drug name : DRUG, DRUG_NAME_GENERIC (different level of representation)
Date : STARTDATE, ENDDATE (NB not specified if drug was cancelled or note, so make sure too look the enddate)
Dose : DOSE_UNIT_RX, DOSE_VAL_RX


**Notes**

1) NOTEEVENTS
Identifiers : SUBJECT_ID, HADM_ID
Note : TEXT (each note is contained individually!)
Timing : CHARTDATE, CHARTTIME (for each note)
Category of the note : CATEGORY (ex : discharge, ecg, echo)
Description of the note : DESCRIPTION  (ex : summary)



# CICU patients

Selection relatively easy
Only using ICUSTAYS database



# Cardiogenic shock patients class SCAI > C

## Inclusion criteria :
	
SCAI shock c

Medication : inotropes, pressors
Mechanical support : 
Biochemical markers
Hemodynamics


## Exclusion  criteria :

Septic shock
Remove patients with positive blood cultures our on antibiotics within 24hours?
