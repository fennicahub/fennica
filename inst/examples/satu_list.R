#url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/sadun_lista_0423.csv"
#download.file(url, destfile = "sadun_lista.csv")

satu_list <- read.csv(file = "sadun_lista.csv", 
                      header = TRUE, 
                      sep = ";", 
                      fileEncoding = "ISO-8859-1", 
                      stringsAsFactors = FALSE)

# change FCC to FI-MELINDA to match df.orig melindas 
satu_list$MelindaID <- gsub(".*FCC", "FCC", satu_list$MelindaID)
satu_list$MelindaID <- sub("FCC", "", satu_list$MelindaID)
satu_list$MelindaID <- sub(" ", "", satu_list$MelindaID)
satu_list$MelindaID <- sub("(FI-MELINDA)", "", satu_list$MelindaID)

satu_list$MelindaID <- gsub(" ", "",satu_list$MelindaID)
df.orig$melinda_id <- gsub(" ", "",df.orig$melinda_id)
satu_and_full_ids <- setdiff(satu_list$MelindaID, df.orig$melinda_id) #not in df.orig

#now we need to check if these melindas are in xml file
