
field <- "physical_extent"

 
#df.tmp <- polish_physical_extent(df.orig[[field]], verbose = TRUE)

x <- df.orig[df.orig$melinda_id %in% melindas_early,]


x <- x %>%
  mutate(physical_extent = case_when(
    physical_extent == "" ~ NA_character_,
    TRUE ~ str_replace_all(physical_extent, c(
      "sivua" = "s", 
      "sivu" = "s", 
      "numeroimatonta" = "", 
      "numeroimaton" = "", 
      "[?] s." = "", 
      "1 verkkoaineisto" = "", 
      "verkkoaineisto" = "", 
      "(puutteellinen)" = "", 
      "Kollaatio avoin" = "",
      "(verso tyhjä)" = ""
    ))
  )) %>%
  mutate(physical_extent = str_trim(str_replace(physical_extent, "[:;]+$", "")))

df.tmp <- polish_physical_extent(x$physical_extent, verbose = TRUE)

# Add melinda id info as first column
df.tmp <- bind_cols(melinda_id = x$melinda_id,
                    physical_extent = x$physical_extent, # add field column
                    df.tmp)

df.tmp <- df.tmp %>%
  mutate(pagecount = ifelse(is.na(physical_extent), NA, pagecount))
df.tmp$pagecount <- ifelse(!is.na(df.tmp$pagecount), df.tmp$pagecount - 1, df.tmp$pagecount)
df.tmp$pagecount <- gsub("-", "", df.tmp$pagecount)


df.harmonized_14_17 <- cbind(df.harmonized_14_17,
                       pagecount = df.tmp$pagecount, 
                       pagecount_orig = x$physical_extent)

# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)

# Define output files
file_accepted  <- paste0(output.folder, field, "_accepted.csv")
file_discarded <- paste0(output.folder, field, "_discarded.csv")

# ------------------------------------------------------------

# Generate data summaries

message("Accepted entries in the preprocessed data")
s <- write_xtable(df.tmp[[field]], file_accepted, count = TRUE)

message("Discarded entries in the original data")

# NA values in the final harmonized data
inds <- which(is.na(df.tmp[[field]]))

# Original entries that were converted into NA
original.na <- df.orig[match(df.tmp$melinda_id[inds], df.orig$melinda_id), field]

# .. ie. those are "discarded" cases; list them in a table
tmp <- write_xtable(original.na, file_discarded, count = TRUE)

# ------------------------------------------------------------

# Generate markdown summary 
df <- readRDS(data.file)
# tmp <- knit(input = paste(field, ".Rmd", sep = ""), 
#             output = paste(field, ".md", sep = ""))

# ------------------------------------------------------------

# Run publication_time.R file to get the melindas needed for the 19th century slicing
source("publication_time.R")

df_19 <- df.tmp[df.tmp$melinda_id %in% melindas_19,]
field <- "physical_extent"

# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df_19, file = data.file)

# Define output files
file_accepted_19  <- paste0(output.folder, field, "_accepted_19.csv")
file_discarded_19 <- paste0(output.folder, field, "_discarded_19.csv")

# ------------------------------------------------------------

# Generate data summaries for 1809-1917

message("Accepted entries in the preprocessed data")
s <- write_xtable(df_19[[field]], file_accepted_19, count = TRUE)

message("Discarded entries in the original data")

# NA values in the final harmonized data
inds <- which(is.na(df_19[[field]]))

# Original entries that were converted into NA
original.na <- df.orig[match(df_19$melinda_id[inds], df.orig$melinda_id), field]

# .. ie. those are "discarded" cases; list them in a table
tmp <- write_xtable(original.na, file_discarded_19, count = TRUE)

# ------------------------------------------------------------

# Generate markdown summary in note_source.md
df_19 <- readRDS(data.file)
# tmp <- knit(input = paste(field, ".Rmd", sep = ""), 
# 


