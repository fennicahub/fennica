# library(devtools)
# library(dplyr)
# library(tm)
# library(stringr)
# library(knitr)
# library(R.utils)
# library(ggplot2)
# library(Cairo)
# library(fennica) 
# source("funcs.R")
#source("melindas_19.R")


# Parameters: 
#0) ("260","c") 1809-1917
#take melindas from the df_pubtime19 which were obtained after harmonizing
#publication_time field in df.orig


list <- df.orig %>%  filter(melinda_id %in% melindas_19) 
# write.table(list,file = "julia_list.csv",
#             sep = "\t",
#             row.names = FALSE, 
#             quote = FALSE)



list <- list %>% select(melinda_id, author_name, publication_time, type_of_record,
                         title, title_remainder, `245n`, title_uniform, 
                           language, language_original,
                           signum, UDK,`080x`, `042a`, genre_book, `655a`,`650a`)

#2) only language material

list <- list %>%
  filter(type_of_record == "Language material")

# Check if signum contains "Suom. kaunokirj." or "Ruots. kaunokirj."
kauno_rows <- grepl("Suom\\.kaunokirj.1|Suom\\.kaunokirj.3|Suom\\.kaunokirj.4|Suom\\.kaunokirj.5|
Suom\\.kaunokirj.6|K\\.Suom.kaunokirj.|K\\.Suom.kaunokirj.1|K\\.Suomal.kaunokirj.|K\\.Suom.kaunok.|K\\.Ruots.kaunok.|K\\.Ruots.kaunokirj.|Ruots\\.kaunokirj.1|Ruots\\.kaunokirj.3|Ruots\\.kaunokirj.4|Ruots\\.kaunokirj.5|
Ruots\\.kaunokirj.6", list$signum)
list <- list %>% filter(kauno_rows)

udk_rows <- grepl("839\\.79|894\\.541", list$UDK)

list <- list %>% filter(kauno_rows)

# 3) 041 h (tyhjä) - kieli
list$language_original[list$language_original == ""] <- NA
list <- list[is.na(list$language_original), ]

# 4) 041 a fin OR  swe

list <- list[grepl("fin|swe", list$language) | is.na(list$language), ]

list <- list[grepl("-1|-2|-3|-4", list$`080x`) | is.na(list$`080x`), ]

# 3) 041 h (tyhjä) - kieli

#list <- list[is.na(list$language_original), ]

# # genre
genres_to_keep <- c("Kaunokirjallisuus","Dramaa", "Esseet", "Romaanit", "Huumori, satiiri jne.", "Novellit, kertomukset tai niiden kokoelmat","Runot", "Yhdistelmä", "Tuntematon")

list <- list %>% filter(genre_book %in% genres_to_keep)


# Check if signum contains "Suom. kaunokirj." or "Ruots. kaunokirj."
kauno_rows <- grepl("Suom\\.kaunokirj.1|Suom\\.kaunokirj.3|Suom\\.kaunokirj.4|Suom\\.kaunokirj.5|
Suom\\.kaunokirj.6|K\\.Suom.kaunokirj.|K\\.Suom.kaunokirj.1|K\\.Suomal.kaunokirj.|K\\.Suom.kaunok.|K\\.Ruots.kaunok.|K\\.Ruots.kaunokirj.|Ruots\\.kaunokirj.1|Ruots\\.kaunokirj.3|Ruots\\.kaunokirj.4|Ruots\\.kaunokirj.5|
Ruots\\.kaunokirj.6", list$signum)

udk_rows <- grepl("839\\.79|894\\.541", list$UDK)

list <- list %>% filter(kauno_rows)

#| udk_rows)

#filter out lasten kirjallisuus
list <- list %>% 
  filter(!grepl("Ruots\\.lastenkirj.|Suom\\.lastenkirj|last", list$signum) &!grepl("\\(024\\.7\\)", list$`080x`))



#9) work with unique titles and keep the earliest title
#Filter the DataFrame to keep only one entry per title with the smallest publication_year
result <- list %>%
  group_by(title) %>%
  filter(publication_time == min(publication_time)) %>%
distinct(title,.keep_all = TRUE)
# 
# 
# # If you want to sort the result by publication_year (optional)
list <- result %>% arrange(publication_time)



############################################################################


