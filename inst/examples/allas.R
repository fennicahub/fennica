library(aws.s3)
library(tidyverse)
library(dplyr)
library(curl)
library(httr)

Sys.setenv("AWS_S3_ENDPOINT" = "a3s.fi")

all_files_in_bucket <- get_bucket_df("fennica-container",region='', drop = FALSE, verbose = TRUE)


file_path <- "output.tables/"
csv_files <- list.files(path = file_path, pattern = "\\.csv$", full.names = TRUE)

bucket_name <- "fennica-container"
s3_folder_path <- "output.tables/"



upload_file_to_s3 <- function(file_path, bucket, s3_folder) {
  if (file.exists(file_path)) {
    file_name <- basename(file_path)
    object_key <- paste0(s3_folder, file_name)
    
    # Use tryCatch to handle potential errors during upload
    tryCatch({
      put_object(file = file_path, object = object_key, bucket = bucket, region="",drop = FALSE,verbose = TRUE)
      message("Uploaded: ", file_name)
    }, error = function(e) {
      message("Failed to upload: ", file_name, ". Error: ", e$message)
    })
  } else {
    message("File does not exist: ", file_path)
  }
}
# Upload each file
for (csv_file in csv_files) {
  upload_file_to_s3(csv_file, bucket_name, s3_folder_path)
}

