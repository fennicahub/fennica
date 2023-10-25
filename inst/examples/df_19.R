
df_19 <- data.frame(melinda_id = df.orig$melinda_id)

conversions <- list()

# Define the fields
update.fields <- c("author_date", "author_name", "publication_time")



# ---------------------------------------------------

# Harmonize the rest of the fields
for (field in update.fields) {
  
  message(field)
  
  # Run the processing script for this field
  source(paste0(field, ".R"))
  
  # List the output fields for this input field to output fields
  conversions[[field]] <- names(df.tmp)
  
  # Add the newly preprocessed field
  # FIXME: collect afterwards
  df_19 <- cbind(df_19, df.tmp) 
  
  # Remove the temporary data.frame for clarity
  rm(df.tmp)
}

#remove duplicate Column Names
duplicated_names <- duplicated(colnames(df_19))
df_19 <- df_19[!duplicated_names]

#slice the data for 1809-1917 years

df_19 <- df_19 %>% filter(publication_year > 1808 & publication_year < 1918)

message("Field preprocessing ok.")

write.csv(df_19,"df_19.csv", row.names = FALSE)
