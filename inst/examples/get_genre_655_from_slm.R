library(finto)
library(dplyr)

# Get all concepts (full vocabulary)
slm <- get_vocabulary(lang == "fi")
vocabularies <- get_vocabularies(lang = "fi")
print(vocabularies)

library(finto)
slm <- get_slm(uri = "slm", lang = "fi")

udcs <- get_udcs(uri = "udcs", lang = "fi")



# Vector of terms
slm_terms <- slm_list$prefLabel