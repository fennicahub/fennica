library(aws.s3)
library(tidyverse)
library(dplyr)
library(curl)
library(httr)

Sys.setenv("AWS_ACCESS_KEY_ID"="84be4dc0746d4116bef002201bfd7702",
"AWS_SECRET_ACCESS_KEY"="6b58dea65c504433b7b059995d92b8ac",
           "AWS_S3_ENDPOINT" = "a3s.fi")

all_files_in_bucket <- get_bucket_df("fennica-container",region='', drop = FALSE, verbose = TRUE)


file_path <- "output.tables/"
csv_files <- list.files(path = file_path, pattern = "\\.csv$", full.names = TRUE)

bucket_name <- "fennica-container"
s3_folder_path <- "output.tables/"

# Retrieve all files in the specified folder within the bucket
all_files_in_folder <- get_bucket_df(bucket_name, prefix = s3_folder_path, region = "", drop = FALSE, verbose = TRUE)

# # Delete files if any are found in the folder
# if(nrow(all_files_in_folder) > 0) {
#     s3_paths <- all_files_in_folder$Key
# 
#     # Delete each file found in the folder
#     lapply(s3_paths, function(path) {
#         delete_object(object = path, bucket = bucket_name, region = "", verbose = TRUE)
#     })
#     message("Deleted all files in ", s3_folder_path, " within ", bucket_name)
# } else {
#     message("No files found to delete in ", s3_folder_path, " within ", bucket_name)
# }


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

