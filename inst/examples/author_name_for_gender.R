field <- "author_name"
field1 <- "author_name_kanto1"
field2 <- "author_name_kanto2"
field3 <- "access_kanto"
field4 <- "author_700a"
field5 <- "author_name_kantoVAR"

# Full author name (Last, First)
author <- polish_author_multi(df.orig[[field]], verbose = TRUE)
author1 <- polish_author_multi(df.orig[[field1]], verbose = TRUE)
author2 <- polish_author_multi(df.orig[[field2]], verbose = TRUE)
author3 <- polish_author(df.orig$access_kanto, verbose = TRUE)
author4 <- polish_author_multi(df.orig[[field4]], verbose = TRUE)
author5 <- polish_author_multi(df.orig[[field5]], verbose = TRUE)

# Collect the results into a data.frame
df.tmp <- data.frame(melinda_id = df.orig$melinda_id, 
                     author_name = author$full_name, 
                     last_name = author$last, 
                     first_name = author$first,
                     author_name_kanto1 = author1$full_name,
                     last_kanto1 = author1$last,
                     first_kanto1 = author1$first,
                     author_name_kanto2 = author2$full_name,
                     last_kanto2 = author2$last,
                     first_kanto2 = author2$first,
                     access_name = author3$full_name,
                     last_access = author3$last,
                     first_acess = author3$first,
                     name_700a = author4$full_name,
                     last_700a = author4$last,
                     first_700a = author4$first,
                     name_var = author5$full_name,
                     last_var = author5$last,
                     first_var = author5$first, 
                     gender = df.orig$gender)

#create merged list of first names 
first_name_cols <- c("first_name", "first_kanto1", "first_kanto2", "first_acess", "first_700a", "first_var")

# Row-wise merge and clean
df.tmp$first_name_merged <- apply(df.tmp[, first_name_cols], 1, function(row) {
  all_names <- unlist(strsplit(row, ";"))
  all_names <- trimws(tolower(all_names))
  all_names <- all_names[all_names != "" & !is.na(all_names)]
  paste(unique(all_names), collapse = "; ")
})

#clean up 
df.tmp$first_name_merged <- gsub(" ", ";", df.tmp$first_name_merged)
df.tmp$first_name_merged <- gsub(";;", ";", df.tmp$first_name_merged)
df.tmp$first_name_merged[df.tmp$first_name_merged == ""] <- NA


#standardize gender 
df.tmp$gender <- gsub("mies", "Male", df.tmp$gender)
df.tmp$gender <- gsub("pappi", "Male", df.tmp$gender)
df.tmp$gender <- gsub("nainen", "Female", df.tmp$gender)
