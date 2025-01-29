#source("008_field.R")

field <- `008_33`

# Select only the 008 columns from df.orig
df.tmp <- df.orig %>%
  select(
    melinda_id,
    leader,
    `008`, 
    type_of_record, 
    bibliographic_level, 
    Date_entered, 
    publication_status, 
    data_element_008, 
    `008_33`, 
    converted_008_33
  )
df.tmp1 <- df.tmp %>%
  filter(is.na(converted_008_33))
df.tmp2 <- df.tmp %>%
  filter(!is.na(converted_008_33))

# Filter rows where data_element_008 == "Kirjat" and converted_00_33 is NA
filtered_kirja <- df.tmp[df.tmp$data_element_008 == "Kirjat" & is.na(df.tmp$converted_00_33), ]

# Define output files
file_accepted  <- paste0(output.folder, field, "_accepted.csv")
file_discarded <- paste0(output.folder, field, "_discarded.csv")
file_discarded_id <- paste0(output.folder, field, "_discarded_id.csv")

# ------------------------------------------------------------
print(df.tmp$data_element_008))
sum(is.na(df.tmp$data_element_008))

counts <- table(df.orig$data_element_008, useNA = 'always')

# Print the results
print(counts)
percentages <- round(prop.table(counts) * 100, 2)
print(percentages)

counts2 <- table(df.tmp$converted_008_33[df.tmp$data_element_008 == "Kirjat"], useNA = 'always')
# Calculate percentages
percentages <- round(prop.table(counts2) * 100, 2)
result_df <- data.frame(
  data_element = names(counts2),
  count = counts2,
  percentage = percentages
)

result_df <- result_df %>%
  select(data_element, count.Freq, percentage.Freq)


# Filter the original dataframe to include only rows where melinda_id is in melindas_19
filtered_df <- df.orig[df.orig$melinda_id %in% melindas_19, ]

# Create a summary dataframe with unique data elements, count, and percentage (including NA)
summary_df <- df.tmp %>%
  group_by(data_element_008) %>%
  summarise(
    count = n(),
    percentage = (n() / nrow(filtered_df)) * 100
  )

# Convert to a dataframe if necessary
summary_df <- as.data.frame(summary_df)

# Display the resulting dataframe
print(summary_df)



message("Accepted entries in the preprocessed data")
i <- write_xtable(df.tmp$data_element_008, file_accepted, count = TRUE, add.percentages = TRUE)
s <- write_xtable(df.tmp2, file_accepted, count = TRUE, add.percentages = FALSE)


message("Discarded title")
tmp <- write_xtable(df.tmp1,
                    file = file_discarded_id,
                    count = TRUE,
                    add.percentages = FALSE)

# ------------------------------------------------------------

# Store the title field data

data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)
#Load the RDS file
df <- readRDS(data.file)
# Convert to CSV and store in the data.files folder
write.table(df, file = paste0(output.folder, paste0(field, ".csv")))