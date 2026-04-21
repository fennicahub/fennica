# # Download the csv file
url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/priority_fields_042026.csv"
# 
# Read the CSV file, explicitly setting the first column to character
# Count the number of columns in the file
column_count <- ncol(read.csv(url, nrows = 1, sep = "\t"))
#Create colClasses with 'character' for the first column and 'default' for the rest
col_classes <- c("character", rep(NA, column_count - 1))

# Read the file with the specified colClasses
df.orig <- read.csv(url, skip = 2, header = TRUE, sep = "\t", colClasses = col_classes)

names(df.orig) <- c(
  "melinda_id",            # 001
  "leader",                # LDR
  "field_008",             # 008
  "other_system_id",       # 035a
  
  "author_name",           # 100a
  "author_date",          # 100d
  "author_id",             # 1000
  
  "language",              # 041a
  "language_original",     # 041h
  
  "title_uniform",         # 240a
  
  "title",                 # 245a
  "title_remainder",       # 245b
  "title_part_number",     # 245n
  
  "publication_place", # 260a
  "publisher",         # 260b
  
  "publication_place_264", # 264a
  
  "physical_size",         # 300c
  "extent",                # 300a
  
  "publication_frequency", # 310a
  "publication_dates",     # 362a
  
  "UDC",                   # 080a
  "UDC_aux",               # 080x
  
  "genre_655",             # 655a
  "subject_650",           # 650a
  "note_500",              # 500a
  
  "added_author_name",     # 700a
  "added_author_id",       # 7000 
  
  "content_type_336",      # 336a
  "contents_505",          # 505a
  "summary_520",           # 520a
  "variant_title_246",     # 246a
  "series_490",            # 490a
  "dissertation_note_502", # 502a
  "uniform_title_130",     # 130a
  "corporate_author_110",  # 110a
  "event_author_111"       # 111a
)


# Remove duplicate rows
df.orig <- df.orig %>% distinct()
df.orig$title2 <- paste(df.orig$title, "|" ,df.orig$title_remainder)



