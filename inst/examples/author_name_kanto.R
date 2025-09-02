field1 <- "author_name_kanto1"
field2 <- "author_name_kanto2"
# Full author name (Last, First)
author1 <- polish_author(df.orig[[field1]], verbose = TRUE)
author2 <- polish_author(df.orig[[field2]], verbose = TRUE)

# Collect the results into a data.frame
df.tmp <- data.frame(melinda_id = df.orig$melinda_id, 
                     author_name_kanto1 = author1$full_name,
                     last_kanto1 = author1$last,
                     first_kanto1 = author1$first,
                     author_name_kanto2 = author2$full_name,
                     last_kanto2 = author2$last,
                     first_kanto2 = author2$first)

#add harmonized fields to df
df.harmonized <- cbind(df.harmonized,
                       last_kanto1 = df.tmp$last_kanto1 ,
                       first_kanto1 = df.tmp$first_kanto1,
                       last_kanto2 = df.tmp$last_kanto1,
                       first_kanto2= df.tmp$first_kanto2)

################################################################

# Store the title field data
data.file <- paste0(field, ".Rds")
saveRDS(df.tmp, file = data.file)
# Generate markdown summary
df <- readRDS(data.file)
# Convert to CSV and store in the output.tables folder
write.table(df, file = paste0(output.folder, paste0(field, ".csv")), quote = FALSE, sep = ";", row.names = FALSE)

##################################################################

# Define output files for the whole dataset
file_accepted  <- paste0(output.folder, field, "_kanto_accepted.csv")
file_discarded <- paste0(output.folder, field, "_kanto_discarded.csv")

# ------------------------------------------------------------

# Generate data summaries for the whole data set

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

# Run publication_time.R file to get the melindas needed for the 19th century slicing

df_19 <- df.tmp[df.tmp$melinda_id %in% melindas_19,]
field <- "author_name_kanto"

# Store the title field data
# FIXME: convert to feather or plain CSV
data.file <- paste0(field, ".Rds")
saveRDS(df_19, file = data.file)

# Generate markdown summary
df_19 <- readRDS(data.file)


# Define output files for the 1807-1917 subset
file_accepted_19  <- paste0(output.folder, field, "_kanto_accepted_19.csv")
file_discarded_19 <- paste0(output.folder, field, "_kanto_discarded_19.csv")

# ------------------------------------------------------------

# Generate data summaries for 1809-1917
message("Accepted entries in the preprocessed data for 1809-1917")
s <- write_xtable(df_19[[field]], file_accepted_19, count = TRUE)

message("Discarded entries for 1809-1917")

# NA values in the final harmonized data
inds <- which(is.na(df_19[[field]]))

# Original entries that were converted into NA
original.na <- df.orig[match(df_19$melinda_id[inds], df.orig$melinda_id), field]

# .. ie. those are "discarded" cases; list them in a table
tmp19 <- write_xtable(original.na, file_discarded_19, count = TRUE)


```{r}
#| include = FALSE
source("author_name_kanto.R")
```

## Author name Kanto

The author information is enriched using the finto R package. It includes extra missing values of author name, author dates and author profession.


-   [Kanto author names](dataTable/data_table.html?path=https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/author_name_kanto.csv)
-   [Unique accepted entries in kanto](dataTable/data_table.html?path=https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/author_name_kanto_accepted.csv): `r length(unique(df[[field]]))`
-   [Unique discarded entries in kantoa](dataTable/data_table.html?path=https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/author_name_kanto_discarded.csv) (excluding NA cases): `r as.vector(countLines(file_discarded) - 1)`
-   Original documents with non-NA titles `r sum(!is.na(df[[field]]))` / `r nrow(df)` (`r round(100*mean(!is.na(df[[field]])), 1)`%)
-   Original documents with missing (NA) titles `r sum(is.na(df[[field]]))` / `r nrow(df)` documents (`r round(100*mean(is.na(df[[field]])), 1)`%)


```{r}
#| include = FALSE
#source("author_name_combined.R")
```

## Author name combined 

This is the combination of Fennica and Kanto author names.

-   [Author name combined](dataTable/data_table.html?path=https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/combined_author_name.csv)

-   [Unique accepted entries in combined](dataTable/data_table.html?path=https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/combined_author_name_accepted.csv): `r length(unique(df[[field]]))`
-   [Unique discarded entries in combined](dataTable/data_table.html?path=https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/combined_author_name_discarded.csv) (excluding NA cases): `r as.vector(countLines(file_discarded) - 1)`
-   Original documents with non-NA titles `r sum(!is.na(df[[field]]))` / `r nrow(df)` (`r round(100*mean(!is.na(df[[field]])), 1)`%)
-   Original documents with missing (NA) titles `r sum(is.na(df[[field]]))` / `r nrow(df)` documents (`r round(100*mean(is.na(df[[field]])), 1)`%)

<!-- !```{r} -->
  <!-- #| label = "combined-author-name", -->
  <!-- #| echo = FALSE, -->
  <!-- #| message = FALSE, -->
  <!-- #| warning = FALSE, -->
  <!-- #| fig.width = 8, -->
  <!-- #| fig.height = 6 -->
  
  <!-- library(ggplot2) -->
  <!-- library(comhis) -->
  
  <!-- # Set ggplot theme -->
  <!-- theme_set(theme_bw(base_size = 12)) -->
  
  <!-- # Load saved data -->
  <!-- df_19 <- readRDS("combined_author_name.Rds") -->
  
  <!-- # Plot top authors -->
  <!-- p <- top_plot(df_19, "combined_author_name", ntop = ntop, log10 = TRUE) + -->
  <!--   labs(y = "Entries (n)", title = "Top authors") -->
  
  <!-- print(p) -->
  
  <!-- ```! -->
  
  
  
  ```{r}
#| include = FALSE
source("author_date.R")
```
## Author Date/Lifetime Fennica


MARC: [100d](https://www.loc.gov/marc/bibliographic/bd100.html)

The author's lifetime section furnishes concise summaries following an extensive cleaning process, delineating the accepted and discarded years pertaining to each author.The accepted years signify the refined and validated data, while insights into the discarded years offer valuable context, shedding light on the challenges encountered and decisions made during the cleaning procedure.

### Complete Dataset Overview

[Author date accepted for the complete Fennica](dataTable/data_table.html?path=https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/author_date_accepted.csv)

[Author date discarded for the complete Fennica](dataTable/data_table.html?path=https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/author_date_discarded.csv)

### Subset Analysis: 1809-1917

[Author date accepted for 1809-1917](dataTable/data_table.html?path=https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/author_date_accepted_19.csv)

[Author date discarded for 1809-1917](dataTable/data_table.html?path=https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/author_date_discarded_19.csv)


<!-- <!```{r} -->
<!-- #| include = FALSE -->
<!-- source("author_date_kanto.R") -->
<!-- ```!> -->
## Author Date/Lifetime Kanto

[Author date kanto](dataTable/data_table.html?path=https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/author_date_kanto.csv)
[Author date accepted for the kanto](dataTable/data_table.html?path=https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/author_date_kanto_accepted.csv)

[Author date discarded for the kanto](dataTable/data_table.html?path=https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/author_date_kanto_discarded.csv)

<!-- !```{r} -->
<!-- #| include = FALSE -->
<!-- source("author_date_combined.R") -->
<!-- ```! -->




```{r} 
#| include = FALSE
 source("author_profession_kanto.R") 
```

## Author Profession

The profession of the author is only available via Kanto.


[Author profession](dataTable/data_table.html?path=https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/author_profession_kanto_fi.csv)

[Author profession accepted for the kanto](dataTable/data_table.html?path=https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/author_profession_kanto_fi_accepted.csv)

[Author profession discarded for the kanto](dataTable/data_table.html?path=https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/author_profession_kanto_fi_discarded.csv)

[Author profession accepted for the kanto 19th century](dataTable/data_table.html?path=https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/author_profession_kanto_fi_accepted_19.csv)

[Author profession discarded for the kanto 19th century](dataTable/data_table.html?path=https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/author_profession_kanto_fi_discarded_19.csv)


```{r}
#| label = "author-profession",
#| echo = FALSE,
#| message = FALSE,
#| warning = FALSE,
#| fig.width = 8,
#| fig.height = 6

library(ggplot2)
#library(comhis)

# Set ggplot theme
theme_set(theme_bw(base_size = 12))

# Load saved data
df <- readRDS("author_profession_kanto_fi.Rds")

# Plot top authors
p <- top_plot(df, "author_profession_kanto_fi", ntop = ntop, log10 = TRUE) +
  labs(y = "Entries (n)", title = "Top authors profession")

print(p)

```


