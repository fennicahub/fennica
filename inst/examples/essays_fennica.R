#get essay

df.essay <- df.processed

df_essay_filt <- df.essay %>%
  mutate(
    udk_list     = str_split(udk, "\\s*;\\s*"),
    udk_aux_list = str_split(udk_aux, "\\s*;\\s*")
  ) %>%
  filter(
    genre_008 == "Esseet" |
      genre_655 %in% c("Essay", "Essays", "Esseet", "Essäer") |
      str_detect(title, "(?i)\\b(Essay|Essays|Esseet|Essäer|esseitä)\\b") |
      (map_lgl(udk_list, ~ any(.x %in% c("894.511", "839.79"))) &
         map_lgl(udk_aux_list, ~ any(.x == "-4")))
  ) %>%
  distinct()

df_essay_filt <- df_essay_filt %>%
  select(-udk_list, -udk_aux_list)

write.table(
  df_essay_filt,
  file = "essay_fennica.csv",
  sep = "\t",
  row.names = FALSE,
  quote = FALSE,
  fileEncoding = "UTF-8"
)



