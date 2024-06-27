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
# source("melindas_19.R")


# Parameters: 
#0) ("260","c") 1809-1917
#take melindas from the df_pubtime19 which were obtained after harmonizing
#publication_time field in df.orig

melindas_list <- df_pubtime19$melinda_id
list <-  df.orig[df.orig$melinda_id %in% melindas_19, ]
list[list == ''] <- NA
list$signum <- gsub(" ", "", list$signum)

genres_to_keep <- c("Fiction (not further specified)","Dramas", "Essays", 
                    "Novels","Short stories, stories or their collections",
                    "Poems", "No attempt to code", "Combination of genres")

# 2) only language material

list <- list %>%
  filter(type_of_record == "Language material")

# 3) 041 h (tyhjä) - kieli

#list <- list[is.na(list$'250a'), ]

# 4) 041 a fin OR  swe

list <- list[grepl("fin|swe", list$language) | is.na(list$language), ]

list <- list[grepl("-1|-2|-3|-4", list$`080x`) | is.na(list$`080x`), ]

# 3) 041 h (tyhjä) - kieli

list <- list[is.na(list$language_original), ]

# # genre  

#list <- list %>% filter(genre_book %in% genres_to_keep)
# 

# Check if signum contains "Suom. kaunokirj." or "Ruots. kaunokirj."
kauno_rows <- grepl("Suom\\.kaunokirj.1|Suom\\.kaunokirj.3|Suom\\.kaunokirj.4|Suom\\.kaunokirj.5|
Suom\\.kaunokirj.6|K\\.Suom.kaunokirj.1|K\\.Suomal.kaunokirj.|K\\.Suom.kaunok.|K\\.Ruots.kaunok.|K\\.Ruots.kaunokirj.|Ruots\\.kaunokirj.1|Ruots\\.kaunokirj.3|Ruots\\.kaunokirj.4|Ruots\\.kaunokirj.5|
Ruots\\.kaunokirj.6", list$signum)
udk_rows <- grepl("839\\.79|894\\.541", list$UDK)

list <- list %>% filter(kauno_rows | udk_rows)


# 
# #9) work with unique titles and keep the earliest title
# Filter the DataFrame to keep only one entry per title with the smallest publication_year
# result <- list %>%
#   group_by(title) %>%
#   filter(publication_time == min(publication_time)) %>%
  # distinct(title,.keep_all = TRUE)


# If you want to sort the result by publication_year (optional)
# list <- result %>% arrange(publication_time)



############################################################################


