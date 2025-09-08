

field1 <- "author_name_h"
field <- "author_name"
field2 <- "author_name_kantoVAR"

g <- df.orig

df.orig<- df.orig[df.orig$melinda_id %in% melindas_19,]

df.orig <- df.orig %>%
  mutate(
    across(
      c(author_name, author_name_kanto1, author_name_kanto2, access_kanto, author_700a),
      ~ na_if(., "")
    )
  ) %>%
  mutate(
    author_name_h = coalesce(
      author_name,
      author_name_kanto1,
      author_name_kanto2,
      access_kanto,
      author_700a
    )
  )

# Full author name (Last, First, Full)
author <- polish_author_multi(df.orig[[field2]], verbose = TRUE)
author <- cbind(df_19, df.orig$author_name_kantoVAR, author)

author$first_name <- gsub(" ","",author$first_name)
author$first_name <- gsub("-","",author$first_name)

# 1) Start with a copy of first_name
author$first_name_h <- author$first_name

# 2) Rows to merge: last_name == last, first_name has < 3 chars, and 'first' exists
mask <- !is.na(author$last_name) &
  !is.na(author$last) &
  (is.na(author$first_name) | (nchar(author$first_name) < 4)) &
  (author$last_name == author$last) &
  !is.na(author$first) & nzchar(trimws(author$first))

# 3) Use integer indices (avoids NA in subscripts)
ii <- which(mask)

# 4) Merge

author$first_name_h[ii] <- paste(author$first_name[ii], author$first[ii], sep = ";")
author$first_name_h <- gsub("NA;", "", author$first_name_h)





 # Collect the results into a data.frame
df.tmp <- data.frame(melinda_id = df.orig$melinda_id, 
                     author_name = author$full_name, 
                     last_name = author$last, 
                     first_name = author$first)