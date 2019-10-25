
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
#Install if the package doesn't exist 
#install.packages('DataExplorer')
# library(DataExplorer)
# plot_missing(ccu_labs1)
# #plot_bar(ccu_labs1)


project_HST = "hst-953-2019"


project_id <- "hst-953-2019"
options(httr_oauth_cache=TRUE)
run_query <- function(query){
  data <- query_exec(query, project=project_id, use_legacy_sql = FALSE)
  return(data)
}