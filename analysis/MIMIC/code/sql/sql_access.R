#SQL - BigQuery access

project_id <- "hst-953-2019"
options(httr_oauth_cache=TRUE)
run_query <- function(query){
  data <- query_exec(query, project=project_id, use_legacy_sql = FALSE)
  return(data)
}

# Examples of QUERY
#sql_query <- "SELECT row_id
             # FROM `physionet-data.mimiciii_clinical.patients`
             #  WHERE row_id=234"
#data <- run_query(sql_query)
#head(data)

#sql_query <- "SELECT i.subject_id, i.hadm_id, i.los
              #FROM `physionet-data.mimiciii_demo.icustays` i;"
              # here we are using aliases and making references to the rows using them