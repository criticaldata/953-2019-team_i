run_query <-
function(query){
  data <- query_exec(query, project=project_id, use_legacy_sql = FALSE)
  return(data)
}
