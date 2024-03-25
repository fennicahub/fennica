
file_path <- "~/git/fennica"

smaller_1488 <- df.harmonized %>%
  filter(publication_year < 1488)

tmp <- write_xtable(julia_not_velka_df, paste(file_path,"_julia_not_velka", sep = ""), count = TRUE)

nolla <- df.harmonized %>%
  filter(publication_year == 0000)

nolla_full <- df.orig %>%
  filter(publication_time == 0000)
