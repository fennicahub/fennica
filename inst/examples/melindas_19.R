#this file is created to get the melindas for subset analyses for all other 
#fields exept publication_time 
#see publication_time.R for data conversions and discarded 

field <- "publication_time"

#polish full data
tmp  <- polish_years(df.orig[[field]], check = TRUE)


# Make data.frame
df.harmonized <- data.frame(melinda_id = df.orig$melinda_id,
                            publication_year_from = tmp$from,
                            publication_year_till = tmp$till)

# Add publication_year as a separate column (same as "publication_year_from")
df.harmonized$publication_year <- df.harmonized$publication_year_from

# Add publication_decade
df.harmonized$publication_decade <- decade(df.harmonized$publication_year) 

#Create subsection for the 19th century only and 
df.harmonized$original <- df.orig[[field]]
df_pubtime19 <- df.harmonized %>% filter(publication_year > 1808 & publication_year < 1918)
melindas_19 <- df_pubtime19$melinda_id