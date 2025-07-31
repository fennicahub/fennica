
df.gradu <- df.processed
julkaisuvuosi <- df.processed19$publication_year
julkaisupaikka <- df.processed19$publication_place
kustantaja <- df.processed19$publisher
kirjallisuuslaji <- df.processed19$genre_008

# Funktio, joka laskee NA:t ja tyhjät merkkijonot
count_missing <- function(x) {
  sum(is.na(x) | x == "")
}

# Lasketaan puuttuvat/tyhjät arvot jokaiselle muuttujalle
julkaisuvuosi_missing <- count_missing(df.processed19$publication_year)
julkaisupaikka_missing <- count_missing(df.processed19$publication_place)
kustantaja_missing <- count_missing(df.processed19$publisher)
kirjallisuuslaji_missing <- count_missing(df.processed19$genre_008)

# Tulostetaan tulokset
cat("Puuttuvat tai tyhjät arvot:\n")
cat("Julkaisuvuosi: ", julkaisuvuosi_missing, "\n")
cat("Julkaisupaikka: ", julkaisupaikka_missing, "\n")
cat("Kustantaja: ", kustantaja_missing, "\n")
cat("Kirjallisuuslaji: ", kirjallisuuslaji_missing, "\n")
