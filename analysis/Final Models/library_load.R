# Function to load or install
install_or_load_pack <- function(pack){
  new.pkg <- pack[!(pack %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dependencies = TRUE)
  sapply(pack, require, character.only = TRUE)
}

# Packages used

pack <- c("bigrquery","plotly","scales","RColorBrewer","data.table","tidyverse","knitr","corrplot","Hmisc","stats", "janitor", "lubridate", "testthat", "magrittr",
          "purrr", "healthcareai")

# Loading the pack
install_or_load_pack(pack)

