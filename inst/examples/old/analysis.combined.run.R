message("Filtering out rows with remove-tags")
# This is the real removal
# Fast to run, so just run before analysis and do not save
# It is better to have one starting point file and clear operations on top of that
# rather than various intermediate saves
df.filtered.preprocessed <- df.combined.preprocessed %>% filter(!remove)


# LIST DISSERTATIONS
output.folder <- "output.tables/"

# List all dissertations
dissertations <- filter_dissertations(df.filtered.preprocessed)
fields <- c("catalog", "author", "short_title", "title", "dissertation", "publication_place", "publication_year")
dissertations <- dissertations[,fields][order(dissertations$publication_year, dissertations$short_title, dissertations$publication_place, dissertations$catalog),]
write.table(dissertations, paste0(output.folder, "dissertations_all.csv"), quote = FALSE, sep = "\t", row.names = FALSE)

# List dissertations in Fennica
dissertations <- filter_dissertations(df.filtered.preprocessed, catalog_name="Fennica")
fields <- c("catalog", "author", "short_title", "title", "dissertation", "publication_place", "publication_year")
dissertations <- dissertations[,fields][order(dissertations$publication_year, dissertations$short_title, dissertations$publication_place, dissertations$catalog),]
write.table(dissertations, paste0(output.folder, "dissertations_fennica.csv"), quote = FALSE, sep = "\t", row.names = FALSE)

# List dissertations in Kungliga
dissertations <- filter_dissertations(df.filtered.preprocessed, catalog_name="Kungliga")
fields <- c("catalog", "author", "short_title", "title", "dissertation", "publication_place", "publication_year")
dissertations <- dissertations[,fields][order(dissertations$publication_year, dissertations$short_title, dissertations$publication_place, dissertations$catalog),]
write.table(dissertations, paste0(output.folder, "dissertations_kungliga.csv"), quote = FALSE, sep = "\t", row.names = FALSE)

# List dissertations by publication place
town <- "Turku"
dissertations <- filter_dissertations(df.filtered.preprocessed, town=town)
fields <- c("catalog", "author", "short_title", "title", "dissertation", "publication_place", "publication_year")
dissertations <- dissertations[,fields][order(dissertations$publication_year, dissertations$short_title, dissertations$publication_place, dissertations$catalog),]
write.table(dissertations, paste0(output.folder, "dissertations_", town, ".csv"), quote = FALSE, sep = "\t", row.names = FALSE)

# List dissertation mismatches
mismatches <- get_dissertation_mismatch(df.combined.preprocessed)
fields <- c("catalog", "author", "short_title", "title", "dissertation", "publication_place", "publication_year")
mismatches <- mismatches[,fields][order(mismatches$publication_year, mismatches$short_title, mismatches$publication_place, mismatches$catalog),]
write.table(dissertations, paste0(output.folder, "dissertation_mismatches.csv"), quote = FALSE, sep = "\t", row.names = FALSE)

# List anything in Kungliga, which is printed in Finland, town by town
for (town in c("Turku", "Helsinki", "Vyborg", "Vaasa")) {
  publications <- filter_towns(df.filtered.preprocessed, catalog_name="Kungliga", town=town)
  fields <- c("catalog", "author", "short_title", "title", "dissertation", "publication_place", "publication_year")
  publications <- publications[,fields][order(publications$publication_year, publications$short_title, publications$publication_place, publications$catalog),]
  write.table(publications, paste0(output.folder, town, "_in_Kungliga_only.csv"), quote = FALSE, sep = "\t", row.names = FALSE)
}

# List duplicates
duplicates <- filter_duplicates(df.combined.preprocessed)
fields <- c("catalog", "author", "short_title", "title", "dissertation", "publication_place", "publication_year")
duplicates <- duplicates[,fields][order(duplicates$publication_year, duplicates$short_title, duplicates$publication_place, duplicates$catalog),]
write.table(duplicates, paste0(output.folder, "duplicates.csv"), quote = FALSE, sep = "\t", row.names = FALSE)
