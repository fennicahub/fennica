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

unzip("the_list.zip",exdir=".")
df_list <- read.csv(file = "the_list.csv", skip = 1, head = TRUE, sep="\t")


#rename column names
df_list <- df_list %>% 
  dplyr::rename("melinda_id" = 1, #("035","a")
                "author_name" = 2, # ("100","a")
                "author_date" = 3, # ("100","d")
                "publication_time" = 4, #("260","c")
                "language" = 5, # ("041","a")
                "language_original" = 6, # ("041","h")
                "title" = 7, #("245","a")
                "title_remainder" = 8, #("245","b")
                "udc" = 9, #("080","a")  Universal Decimal Classification number (NR)
                "udc_aux" = 10, #("080","x") Common auxiliary subdivision (R)
                "edition"= 11, # ("250","a"),
                "signum" = 12) # ("callnumbers","a")

# Parameters: 
# 0) ("260","c") 1809-1917
#take melindas from the df_pubtime19 which were obtained after harmonizing
#publication_time field in df.orig

melindas <- df_pubtime19$melinda_id
list <-  df_list[df_list$melinda_id %in% melindas, ]

list$edition <- gsub("Lyh. laitos,", "", list$edition)


# 5) 250 a (tyhjä) (only this gives 47627)

list <- list[is.na(list$edition) | list$edition == "" |  list$edition == "1. p.", ]


# 2) 041 h (tyhjä) (43106)

list <- list[is.na(list$language_original) | list$language_original == "", ]

# 1) 041 a fin ja swe (47160)

list <- list[grepl("fin|swe", list$language), ]


# 3) 080 a 839.79 ja 894.541 (5124)

list <- list[grepl("839.79|894.541", list$udc), ]


# 4) 080 x -1, -2, -3, -4 (only this parameter gives 4993 obs)

list <- list[
              list$udc_aux == "-1" | 
              list$udc_aux == "-2" |
              list$udc_aux == "-3" |
              list$udc_aux == "-4",
             ]

