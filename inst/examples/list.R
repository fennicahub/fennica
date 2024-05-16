library(devtools)
library(dplyr)
library(tm)
library(stringr)
library(knitr)
library(R.utils)
library(ggplot2)
library(Cairo)
library(fennica) 
source("funcs.R")
source("melindas_19.R")


# Parameters: 
#0) ("260","c") 1809-1917
#take melindas from the df_pubtime19 which were obtained after harmonizing
#publication_time field in df.orig

melindas_list <- df_pubtime19$melinda_id
list <-  df.orig[df.orig$melinda_id %in% melindas_19, ]

# 2) 250 a (tyhjä) - ei luotettava 
#list <- list[is.na(list$"250a") | list$"250a" == "", ]


# 3) 041 h (tyhjä) - kieli

list <- list[is.na(list$language_original) | list$language_original == "", ]

# 4) 041 a fin OR  swe, what about Fin;Swe (kaksikieliset)? 

list <- list[grepl("fin|swe", list$language) | is.na(list$language), ]


# 5) 080 a 839.79 ja (tai) 894.541- UDK

list <- list[grepl("839.79|839.7|894.541|820/89|894.54", list$UDK)| is.na(list$UDK), ]


# 6) 080 x -1, -2, -3, -4


list <- list[grepl("-1|-2|-3|-4", list$'080x') | is.na(list$'080x'), ]

# 7)  genre ? 

genres_to_keep <- c("Fiction (not further specified)", "Dramas", "Essays", "Novels",  
                    "Humor, satires, etc.", "Short stories, stories or their collections",  
                    "Combination of genres", "Poems")

list <- list %>% filter(genre_book %in% genres_to_keep)

# 8) signum? 

#list <- list[grepl("kauno", list$signum) | is.na(list$signum), ]

# 9) verkkoainesto in physical extent exclude 

#list <- list[!grepl("verkkoaineisto", list$physical_extent), ]

############################################################################

#the list has only language material type of record 
unique_counts <- table(list$type_of_record)

