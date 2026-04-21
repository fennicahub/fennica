# # Download the csv file
url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/priority_fields_holdingsit_042026.csv"
# 
# Read the CSV file, explicitly setting the first column to character
# Count the number of columns in the file
column_count <- ncol(read.csv(url, nrows = 1, sep = "\t"))
#Create colClasses with 'character' for the first column and 'default' for the rest
col_classes <- c("character", rep(NA, column_count - 1))

# Read the file with the specified colClasses
df.holdingsit <- read.csv(url, skip = 2, header = TRUE, sep = "\t", colClasses = col_classes)

names(df.holdingsit) <- c(
    "record_id_004",     # 004
    
    "location_a",        # 852a (location)
    "institution_code",  # 852b (holding institution)
    "sublocation",       # 852c
    "shelving_location", # 852d
    "address",           # 852e
    "coded_location",    # 852f
    "noncoded_location", # 852g
    "url",               # 852u
    
    "call_number",       # 852h
    "item_part",         # 852i
    "shelving_control",  # 852j
    "call_number_prefix",# 852k
    "call_number_suffix",# 852l
    "piece_designation", # 852m
    
    "nonpublic_note",    # 852x
    "public_note"        # 852z
  )



# Remove duplicate rows
df.holdingsit <- df.holdingsit %>% distinct()

df.holdingsit_unique <- df.holdingsit[!duplicated(df.holdingsit$record_id_004), ]

df.merged <- merge(
  df.orig,
  df.holdingsit_unique,
  by.x = "melinda_id",
  by.y = "record_id_004",
  all.x = TRUE
)

df.orig <- df.merged
