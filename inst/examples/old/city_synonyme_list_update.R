# List unique cities in the data
unique_cities <- tau::fixEncoding(unique(df$publication_place),latin1=TRUE)

# Find variants for specific cities
city.variants <-  city_synonymes(unique_cities) 

# Add to the publication place synonyme list
f <- system.file("extdata/publication_place_synonymes_fennica.csv", package = "fennica")
sn <- read.csv(f, sep = ";")

# Merge the two synonyme lists
sn.new <- bind_rows(sn, city.variants) %>% arrange(name)
sn.new <- sn.new[!duplicated(sn.new),]

# Write to file
write.table(sn.new, file = "../extdata/publication_place_synonymes_fennica.csv", sep = ";", quote = FALSE, row.names = FALSE)

