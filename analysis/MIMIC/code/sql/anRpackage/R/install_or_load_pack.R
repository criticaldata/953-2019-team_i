install_or_load_pack <-
function(pack){
  new.pkg <- pack[!(pack %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dependencies = TRUE)
  sapply(pack, require, character.only = TRUE)
}
