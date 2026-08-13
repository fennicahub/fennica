
field <- "physical_dimensions"
synonyms <- read.csv("translation_fi_en_pages.csv", sep = ";")
df.orig$physical_dimensions <- map(df.orig$physical_dimensions,
          synonyms, mode = "recursive")

# Fill in missing entries where estimates can be obtained:
# area, width, height, gatherings
# (also keep pure originals before fill in)
#devtools::load_all("~/comhis/rpkg/bibliographica")
df.tmp <- polish_dimensions(df.orig[[field]], fill = TRUE, verbose = TRUE)

# Add melinda id info as first column
df.tmp <- bind_cols(id = df.orig$id,
                    df.tmp)

# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)

# Define output files
file_accepted  <- paste0(output.folder, field, "_accepted.csv")
file_discarded <- paste0(output.folder, field, "_discarded.csv")

# ------------------------------------------------------------

# Generate data summaries

message("Accepted gatheries entries in the preprocessed data")
x <- df.tmp
x <- x %>%
  select(original, gatherings, width, height, obl, area) %>%
  mutate(across(everything(), ~na_if(trimws(as.character(.)), ""))) %>%
  filter(if_any(everything(), ~!is.na(.))) %>%
  count(original, gatherings, width, height, obl, area, sort = TRUE)

s <- write_xtable(x, file_accepted, count = FALSE, sort.by = "n")

message("Discarded entries in the original data")

# NA values in the final harmonized data
inds <- which(is.na(df.tmp[[field]]))

# Original entries that were converted into NA
original.na <- df.orig[match(df.tmp$id[inds], df.orig$id), field]

# .. ie. those are "discarded" cases; list them in a table
tmp <- write_xtable(original.na, file_discarded, count = TRUE)

# ------------------------------------------------------------

# Generate markdown summary 
df <- readRDS(data.file)
# tmp <- knit(input = paste(field, ".Rmd", sep = ""), 
#             output = paste(field, ".md", sep = ""))


# ------------------------------------------------------------

# 1809-1917

df_19 <- df.tmp[df.tmp$id %in% ids_19,]
field <- "physical_dimensions"

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
#s <- write_xtable(df_19[[field]], file_accepted_19, count = TRUE)

# message("Discarded entries in the original data")
# 
# # NA values in the final harmonized data
# inds <- which(is.na(df_19[[field]]))
# 
# # Original entries that were converted into NA
# original.na <- df.orig[match(df_19$id[inds], df.orig$id), field]
# 
# # .. ie. those are "discarded" cases; list them in a table
# tmp <- write_xtable(original.na, file_discarded_19, count = TRUE)

# ------------------------------------------------------------

# Generate markdown summary in note_source.md
df_19 <- readRDS(data.file)
# tmp <- knit(input = paste(field, ".Rmd", sep = ""), 
# 


