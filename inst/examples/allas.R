library(aws.s3)
library(tidyverse)
library(dplyr)
library(stringr)
library(curl)
library(httr)

Sys.setenv("AWS_S3_ENDPOINT" = "a3s.fi")


load_aws_credentials <- function(credentials_path = "~/.aws/credentials", profile = "default") {
  # Expand the path to the user's home directory
  credentials_path <- normalizePath(credentials_path, mustWork = TRUE)
  
  # Read the contents of the file
  credentials_lines <- readLines(credentials_path, warn = FALSE)
  
  # Ensure the file ends with a newline to prevent issues with incomplete final line
  if (tail(credentials_lines, n = 1) != "") {
    credentials_lines <- c(credentials_lines, "")
  }
  
  # Find the profile line and extract subsequent lines until the next profile
  profile_line_index <- grep(paste0("^\\[", profile, "\\]$"), credentials_lines)
  
  if (length(profile_line_index) == 0) {
    stop("Profile not found in credentials file.")
  }
  
  next_profile_index <- which(grepl("^\\[.*\\]$", credentials_lines) & seq_along(credentials_lines) > profile_line_index)
  if (length(next_profile_index) == 0) {
    # If there's no next profile, read to the end of the file
    next_profile_index <- length(credentials_lines) + 1
  }
  
  profile_lines <- credentials_lines[(profile_line_index + 1):(next_profile_index - 1)]
  
  # Parse key-value pairs from the profile's lines
  for (line in profile_lines) {
    key_value <- strsplit(line, "=", fixed = TRUE)[[1]]
    if (length(key_value) == 2) {
      # Remove potential leading and trailing quotes from the value
      var_value <- gsub('^"|"$', '', key_value[2])
      var_name <- trimws(key_value[1]) # Trim whitespace around the key
      # Dynamically set environment variables
      Sys.setenv(var_name = var_value)
    }
  }
}

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

