#this file is created to get the melindas for subset analyses for all other 
#fields exept publication_time 
#see publication_time.R for data conversions and discarded 

field <- "publication_time"

#polish full data
tmp  <- polish_years(df.orig[[field]], check = TRUE)


# Make data.frame
df.tmp <- data.frame(melinda_id = df.orig$melinda_id,
                            publication_year_from = tmp$from,
                            publication_year_till = tmp$till)

# Add publication_year as a separate column (same as "publication_year_from")
df.tmp$publication_year <- df.tmp$publication_year_from

# Add publication_decade
df.tmp$publication_decade <- decade(df.tmp$publication_year) 

#Create subsection for the 19th century only and 
df.tmp$original <- df.orig[[field]]

df_pubtime19 <- df.tmp %>% filter(publication_year >= 1809 & publication_year <= 1917)

melindas_19 <- df_pubtime19$melinda_id

df_pubtime_early <- df.tmp %>% filter(publication_year >= 1488 & publication_year <= 1800)
melindas_early <- df_pubtime_early$melinda_id
