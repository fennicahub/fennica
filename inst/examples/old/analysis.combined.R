# Read data & combine / Define time span
library(dplyr)

# Check that the combined data file exists AND is newer than
# its components (ie. updated after the latest changes).
# Otherwise update.
if (file.exists("df.combined.Rds") &&

    (as.numeric(file.info("df.combined.Rds")$mtime - file.info("fennica.Rds")$mtime)) > 0 &&
    (as.numeric(file.info("df.combined.Rds")$mtime - file.info("kungliga.Rds")$mtime)) > 0)
    
   {
  
  message("Opening df.combined.Rds")
  df.combined.preprocessed <- readRDS("df.combined.Rds")
  
} else {
  
  message("Creating df.combined.Rds by combining df.Rds-files from Kungliga & Fennica")

  message("Reading the data")
  fen <- readRDS("data/unified/polished/df.Rds") # symbolic link to fennica/inst/examples/df.Rds 
  kun <- readRDS("data_kungliga/unified/polished/df.Rds")  # symbolic link to kungliga/df.Rds 
  
  message("Binding & adding extra fields")
  # LL: I chanced df0 naming to df000 since df0 is the name of a critical base data set
  # used in most analyses, created in analysis.init.R and would be overwritten here.
  df000 <- bind_rows(fen, kun)
  df000$catalog <- factor(c(rep("Fennica", nrow(fen)), rep("Kungliga", nrow(kun))))
  df000$catalog_index <- 0
  df000$catalog_index[1:nrow(fen)] = 1:nrow(fen)
  df000$catalog_index[(nrow(fen)+1):nrow(df000)] <- 1:nrow(kun)
  
  message("Mark duplicates")
  df.combined.preprocessed <- mark_duplicates(df000)

  message("Save combined data")  			   
  saveRDS(object = df.combined.preprocessed, file = "data/unified/df.combined.Rds")
  
}

