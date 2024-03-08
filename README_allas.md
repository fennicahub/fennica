## General steps to fetch and push data to allas

**1. Login to puhti**

``` r
 ssh 'username@puhti.csc.fi'
```

**2. After Login**

``` r
 module load allas
 grep key $HOME/.s3cfg
```

out out will be

``` r
access_key = ******
kms_key = 
secret_key = ******
ssl_client_key_file = 
```

Then we use the access key and secret key to edit our `~/.aws/credentials`

**3.Update your `~/.Renviron-file`**

Add a new row to `~/.Renviron-file` the following

``` r
AWS_S3_ENDPOINT=a3s.fi
```

Then Finally add the code at `Final.R`

``` r
library("aws.s3")
library("tidyverse")
library(dplyr)
library(stringr)
all_files_in_bucket <- get_bucket_df("fennica-container",region="")

csv_files <- all_files_in_bucket[grep("\\.csv$", all_files_in_bucket$Key), "Key", drop = FALSE]

file_path <- "/Users/akasia/fennica_allas/renv/fennica_parsed.csv"
bucket_name <- "fennica-container"
object_key <- "fennica_parsed.csv" # The name you want the file to have in the S3 bucket
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

put_object(file = file_path, object = object_key, bucket = bucket_name,region="",drop = FALSE,verbose = TRUE)
```
