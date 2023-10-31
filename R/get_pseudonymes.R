get_pseudonymes <- function (...) {
  pseudo <- as.character(read.csv("custom_pseudonymes.csv", sep = "\t")[,1])

  # Remove extra spaces
  pseudo <- condense_spaces(pseudo)
  pseudo <- tolower(pseudo)  

  # Also consider removing periods, commas, dashes etc ?

  # Organize
  pseudo <- sort(unique(pseudo))

  pseudo

}
