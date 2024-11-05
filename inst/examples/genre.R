#genre

df_genre <- data.frame("melinda_id" = df.orig$melinda_id,
                       "author" = df.orig$author_name,
                       "language" = df.orig$language,
             "title" = df.orig$title, 
             "genre" = df.orig$`655a`, 
             "topical_term" = df.orig$`655a`,
             "udk" = df.orig$UDK, 
             "literary_genre" = df.orig$literary_genre_book, 
             "signum" = df.orig$signum)

df_genre[df_genre == ""] <- NA
df_genre[df_genre == " "] <- NA

df_genre_19 <- df_genre[df_genre$melinda_id %in% melindas_19,]
sum(is.na(df_genre_19$literary_genre)) #7869
sum(is.na(df_genre_19$genre)) #44484
sum(is.na(df_genre_19$signum)) #23413
sum(is.na(df_genre_19$udk)) #35190
sum(is.na(df_genre_19$topical_term))#44484
