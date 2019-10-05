
list.of.packages <- c("bigrquery","plotly","scales","RColorBrewer","data.table","dplyr","knitr","corrplot","Hmisc","stats")
new.packages<-list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
if(length(new.packages)>0)
{install.packages(new.packages)}

library(bigrquery)
library(plotly)
library(scales)
library(RColorBrewer)
library(data.table)
library(dplyr)
library(knitr)
library(corrplot)
library(Hmisc)
library(stats)

#install.packages("bigrquery")

project_HST = "hst-953-2019"


project_id <- "hst-953-2019"
options(httr_oauth_cache=TRUE)
run_query <- function(query){
  data <- query_exec(query, project=project_id, use_legacy_sql = FALSE)
  return(data)
}

# 
# patientunitstayid <-2504725
# df_vitals_eicu<-query_exec(paste("SELECT * FROM `physionet-data_demo.eicu_crd_derived.pivoted_vital` WHERE
# chartoffset <= 1440 AND patientunitstayid =", patientunitstayid,
#                                  "ORDER BY chartoffset")
#                            , project = project_HST,use_legacy_sql = F )
# 



sql_query <- "SELECT i.uniquepid
              FROM `physionet-data.eicu_crd_demo.patient` i;"
data <- run_query(sql_query)
head(data)

sql2_query <- "SELECT patientunitstayid
              FROM `physionet-data.eicu_crd_demo.patient` "

PID <- run_query(sql2_query)
qList <- list()

for (ID in PID){
  print(ID)
  list.append(qList,ID)
  
}


data3 <- run_query(
  
  "SELECT diagnosisid
   FROM `physionet-data.eicu_crd_demo.diagnosis` 
   WHERE patientunitstayid = 200026 "
  
)


data4 <- run_query(
  
  "SELECT labid, labname, labresult, labresulttext
   FROM `physionet-data.eicu_crd_demo.lab` 
   WHERE patientunitstayid = 200026 
   WHERE labid = 46086609"
)

data4 <- run_query(
  
  "SELECT unittype
   FROM `physionet-data.eicu_crd_demo.lab` "
  
)
002-10715
