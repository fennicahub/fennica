source("funcs.R")
field <- "author_name"
field1 <- "author_name_kanto1"
field3 <- "access_kanto"
field4 <- "author_700a"
field5 <- "author_name_kantoVAR"

# Full author name (Last, First)

author <- polish_author(df.orig[[field]], verbose = TRUE)
author1 <- polish_author_multi(df.orig[[field1]], verbose = TRUE)
author3 <- polish_author_multi(df.orig[[field3]], verbose = TRUE)
author4 <- polish_author_multi(df.orig[[field4]], verbose = TRUE)
author5 <- polish_author_multi(df.orig[[field5]], verbose = TRUE)

# Extract part before the colon
df.orig$note_kanto <- gsub("Todellinen nimi: ", "", df.orig$note_kanto, ignore.case = TRUE)
df.orig$note_kanto <- gsub("Täydellinen nimi: ", "", df.orig$note_kanto, ignore.case = TRUE)
df.orig$note_kanto <- gsub("todellinen nimi", "", df.orig$note_kanto, ignore.case = TRUE)
df.orig$note_kanto <- gsub(":", "", df.orig$note_kanto, ignore.case = TRUE)
df.orig$note_kanto <- gsub(
  "Koko nimi:|Syntymänimi:|Aiempi nimi:|Tunnetaan myös nimellä|entinen nimi|Kirjoitti myös nimimerkillä:|maallikkonimi:|Maanmittari|nimi vuoteen|vuodesta|nimi vuodesta|professori|senaattori|valtioneuvos|Ruotsin tiedeakatemian jäsen|Aateloitu 1809|maantieteilijä",
  "",
  df.orig$note_kanto,
  ignore.case = TRUE
)




# Collect the results into a data.frame
all_names <- data.frame(melinda_id = df.orig$melinda_id, 
                     author_name = author$full_name, 
                     last_name = author$last, 
                     first_name = author$first,
                     author_name_kanto1 = author1$full_name,
                     last_kanto1 = author1$last,
                     first_kanto1 = author1$first,
                     access_name = author3$full_name,
                     last_access = author3$last,
                     first_access = author3$first,
                     name_700a = author4$full_name,
                     last_700a = author4$last,
                     first_700a = author4$first,
                     name_var = author5$full_name,
                     last_var = author5$last,
                     first_var = author5$first,
                     note = df.orig$note_kanto)
 

library(data.table)

DT <- as.data.table(all_names)

CN_FULL  <- c("author_name", "author_name_kanto1", "access_name", "name_700a", "name_var")
CN_FIRST <- c("first_name",  "first_kanto1",       "first_access","first_700a","first_var")
CN_LAST  <- c("last_name",   "last_kanto1",        "last_access", "last_700a", "last_var")

mk_long <- function(cols, field) {
  tmp <- melt(DT, id.vars = "melinda_id", measure.vars = cols,
              variable.name = "src", value.name = "value", variable.factor = FALSE)
  tmp[, field := field]
  tmp
}

LONG <- rbindlist(list(
  mk_long(CN_FULL,  "full_name"),
  mk_long(CN_FIRST, "first"),
  mk_long(CN_LAST,  "last")
), use.names = TRUE, fill = TRUE)

# Keep even if all variants NA — just don't split empties prematurely
LONG[, value := trimws(value)]

# split tokens only for non-empty values
LONG_split <- LONG[!is.na(value) & nzchar(value)]
LONG_split[, token := strsplit(value, "\\s*[|;]\\s*", perl = TRUE)]
LONG_split <- LONG_split[, .(token = trimws(unlist(token, use.names = FALSE))),
                         by = .(melinda_id, field, src)]
LONG_split <- LONG_split[nzchar(token)]

# Case-insensitive de-dup within each melinda_id + field
LONG_split[, key := tolower(token)]
LONG_split[, ord := .I]
LONG_split <- LONG_split[!duplicated(paste(melinda_id, field, key))]
setorder(LONG_split, melinda_id, field, ord)

# Recombine tokens per field
WIDE_tokens <- LONG_split[, .(value = paste(token, collapse = " | ")), by = .(melinda_id, field)]

# Now pivot wider, but merge with full ID list to keep all melinda_id (even those with no tokens)
WIDE <- dcast(WIDE_tokens, melinda_id ~ field, value.var = "value")
all_names_final <- merge(
  DT[, .(melinda_id, note)],      # ensures every ID stays
  WIDE,
  by = "melinda_id",
  all.x = TRUE                    # << keeps all IDs from original
)

setcolorder(all_names_final, c("melinda_id", "full_name", "first", "last", "note"))



library(dplyr)

orig_order <- df.orig$melinda_id  # or all_names$melinda_id — whichever order you want to keep
# ... do your joins/build all_names_final ...
all_names_final <- all_names_final[match(orig_order, all_names_final$melinda_id), ]
all_names_final$orig_author <- df.orig$author_name
all_names_final$gender <- df.orig$gender

#standardize gender 
all_names_final$gender <- gsub("mies", "male", all_names_final$gender)
all_names_final$gender <- gsub("pappi", "male", all_names_final$gender)
all_names_final$gender <- gsub("nainen", "female", all_names_final$gender)

df.tmp <- all_names_final
df.tmp$first[df.tmp$first == "NA"] <- NA
df.tmp$last[df.tmp$last == "NA"] <- NA
df.tmp$orig_100[df.tmp$orig_100 == ""] <- NA
df.tmp <- data.frame(melinda_id = df.tmp$melinda_id, 
                 orig_100 = df.orig$author_name,
                 full_name = df.tmp$full_name,
                 first = df.tmp$first, 
                 last = df.tmp$last, 
                 note = all_names_final$note,
                 gender = df.tmp$gender)

df.tmp$full_name[is.na(df.tmp$full_name) & !is.na(df.tmp$note)] <- 
  df.tmp$note[is.na(df.tmp$full_name) & !is.na(df.tmp$note)]
# you need to clean now full_name from numbers , signs like except , 
#and see if there is anything in note



write.table(df.tmp, 
            file = "../extdata/fennica_all_names.csv",
            sep = "\t",
            row.names=FALSE, 
            quote = FALSE,
            fileEncoding = "UTF-8") 


