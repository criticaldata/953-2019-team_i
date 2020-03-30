#setwd("~/Documents/Bioinformatics/Classes/FALL/HST.953/Git_Files_Cardiogenic/953-2019-team_i/analysis/MIMIC")

#Loading of libraries

source("./code/library_load.R")
source("./code/sql/sql_access.R")

# Notes loading
notes_query <- "WITH NOTES AS
(
SELECT
notes.hadm_id, notes.charttime, notes.subject_id, ie.intime, notes.text, ie.first_careunit, notes.category
FROM `physionet-data.mimiciii_notes.noteevents` AS notes
LEFT JOIN  `physionet-data.mimiciii_clinical.icustays` AS ie
ON notes.hadm_id = ie.hadm_id
)
SELECT *
FROM NOTES 
WHERE DATETIME_DIFF (CHARTTIME, intime, DAY) < 1.01 
AND
hadm_id in
(
SELECT hadm_id
FROM (
    SELECT subject_id, hadm_id, intime, outtime, los, ROW_NUMBER() OVER(PARTITION BY subject_id ORDER BY intime) rn
    FROM `physionet-data.mimiciii_clinical.icustays`
    WHERE first_careunit = 'CCU'
    ) 
x
WHERE rn = 1
)"



notes_ccu <- run_query(notes_query) 

# Loading cardiogenic shock

shock_m <- read_csv("./data/mimic_cardiogenic_shock_id.csv")

# First 24 hour notes filtration ------------------------------------------



# Cardiogenic shock table for filtration
# We used a the subject_id from the final MIMIC cardiogenic shock cohort
# Contained in file : file="mimic_cardiogenic_shock_id.csv")

# Only keep notes of patient in shock
notes_ccu <- notes_ccu%>%select("subject_id","text", "category")
notes_ccu <- shock_m%>% #the shock_m table is table from another project that only contains the subject id of the cardiogenic shock cohort
  left_join(notes_ccu, by=c("subject_id"="subject_id"))
#notes_ccu3 <- notes_ccu2%>%filter(category!='Radiology') # Removing all radiology notes as less accurate for information on cardiac arrest
#strategy cancelled because reduced the number of patients

finalnotes <- notes_ccu

length(unique(finalnotes$subject_id)) # This allows to verify that there is a note for each single cardiogenic shock patient 


# Discharge Summary notes filtration --------------------------------------

#Only keeping notes from patients in shock
#discharge_ccu <- discharge_summary_ccu%>%select("subject_id","text", "category")
#discharge_ccu <- shock_m%>% #the shock_m table is table from another project that only contains the subject id of the cardiogenic shock cohort
  #left_join(discharge_ccu, by=c("subject_id"="subject_id"))

#length(unique(discharge_ccu$subject_id)) # This allows to verify that there is a note for each single cardiogenic shock patient 

#discharge_ccu2 <- discharge_ccu%>%filter((str_detect(text, regex("discharge",ignore_case = TRUE))
                                                    #==TRUE))


# NLP Regex ---------------------------------------------------------------

#testing <- finalnotes[1:100,] # Test dataset to evaluate the NLP framework

# Function that verifies if evidence of cardiac arrest
extract_arrest<- function(text)
{
  arrestregex <- regex("therapeutic hypothermia|return of spontaneous circulation|\\brosc\\b|cardiac arrest|defilbrillated|\\bcpr\\b|[1-3][0-9][0][J]|vfib|ventricular fibrillation", ignore_case = TRUE) 
  #vfib not added because higher risk of antecedent diagnosis
  match <- str_detect(text, arrestregex)
  return(as.numeric(match))
}

# This function adds 1 in the column arrest if the regex is found to be positive in the corresponding document
finding_arrest <- function(df)
{
  mutate(df, arrest = 0)
  df$arrest <- sapply(df[,"text"], FUN = extract_arrest)
  return(df)
}

# Testing

#testing2 <- finding_arrest(testing)
#head(testing2)
#write.csv(testing2, file="testingnotesnlp.csv")

# Group dataframe with a final condition : if a positive cardiac arrest in >= 1 note, then final diagnostic = cardiac arrest

finalnotes_arrest <- finding_arrest(finalnotes) # Adding column for each note

finalnotes_arrest2 <- finalnotes_arrest%>%group_by(subject_id, arrest)%>% # Grouping patient individually bi subject_id
  summarise()

table(finalnotes_arrest2$arrest)


# Testing accuracy --------------------------------------------------------

# We look at 50 positive and 50 negative for a total of 100 notes

positives_NLP <- finalnotes_arrest2%>%filter(arrest==1)%>%select(subject_id)
negatives_NLP <- finalnotes_arrest2%>%filter(arrest==0)%>%select(subject_id)
postives_NLP50 <- positives_NLP[1:51,]
negatives_NLP50 <- negatives_NLP [1:51,]


paste(negatives_NLP50 , sep="", collapse = "," )


# Querying discharge summaries from notes above

discharge_summary_query1 <- "WITH NOTES AS
(
SELECT
notes.hadm_id, notes.charttime, notes.subject_id, notes.text, ie.first_careunit, notes.category
FROM `physionet-data.mimiciii_notes.noteevents` AS notes
LEFT JOIN  `physionet-data.mimiciii_clinical.icustays` AS ie
ON notes.hadm_id = ie.hadm_id
)
SELECT *
FROM NOTES 
WHERE notes.category = 'Discharge summary'
AND
subject_id in
(318, 320, 608, 653, 710, 840, 924, 1041, 1734, 1767, 1777, 1855, 1924, 2025, 2071, 2115, 2223, 2237, 2649, 2889, 3011, 3652, 3735, 3794, 
4032, 4053, 4147, 4316, 4323, 4324, 4331, 4477, 4568, 4590, 4802, 4875, 4956, 5039, 5126, 5145, 5252, 5481, 5738, 5951, 6189, 6204, 6349, 6362, 6375, 6534, 6673)"


discharge_summary_query2 <- "WITH NOTES AS
(
SELECT
notes.hadm_id, notes.charttime, notes.subject_id, notes.text, ie.first_careunit, notes.category
FROM `physionet-data.mimiciii_notes.noteevents` AS notes
LEFT JOIN  `physionet-data.mimiciii_clinical.icustays` AS ie
ON notes.hadm_id = ie.hadm_id
)
SELECT *
FROM NOTES 
WHERE notes.category = 'Discharge summary'
AND
subject_id in
(
13, 21, 25, 38, 55, 62, 94, 146, 151, 163, 177, 199, 205, 222, 228, 234, 270, 275, 308, 318, 320, 328, 346, 354, 379, 391, 426, 
439, 445, 456, 462, 472, 491, 495, 515, 539, 554, 557, 589, 608, 619, 638, 653, 698, 702, 710, 731, 738, 745, 749, 792
)
"

# Discharge summary from positives NLP
discharge_summary_ccu1 <- run_query(discharge_summary_query1)%>%mutate(
  NLP_arrest = "positive"
) 

# Discharge summary from negatives NLP

discharge_summary_ccu2 <- run_query(discharge_summary_query2)%>%mutate(
  NLP_arrest = "negative"
) 

# Creating a dataframe with all discharge summaries
discharge_summary <- bind_rows(discharge_summary_ccu1, discharge_summary_ccu2)
discharge_summary <- discharge_summary%>%group_by(subject_id, text, NLP_arrest, category)%>% # Grouping patient individually bi subject_id
  summarise()%>%distinct()

# Creating final dataframe for review by also adding coded ICD9

# Loading datasets with ICD9 info for MIMIC patient

mimic_shock <- read_csv("../MIMIC/data/mimic_cardiogenic_shock.csv", col_names = TRUE) %>%dplyr::select(subject_id, cardiac_arrest_and_ventricular_fibrillation)

# Final dataframe adding back the original ICD9 codes
discharge_summary <- discharge_summary%>%left_join(mimic_shock, by=c("subject_id"="subject_id"))

# length(unique(discharge_summary$subject_id))
# 96 out of 100 patients had a discharge summary. More notes because a lot of duplicates.
 
# Saving out the dataset
write.csv(discharge_summary, file="testingnotesnlp.csv")



