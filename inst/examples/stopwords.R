if (is.null(stopwords)) {
  message("No stopwords provided for authors. Using ready-made stopword lists")
  
  f <- system.file("extdata/stopwords.csv", package = "fennica")
  stopwords.general <- as.character(read.csv(f, sep = "\t")[,1])
  stopwords.general <- c(stopwords.general, stopwords("en"))  # <- explicit call
  
  f <- system.file("extdata/stopwords_for_names.csv", package = "fennica")
  stopwords.names <- as.character(read.csv(f, sep = "\t")[,1])
  
  f <- system.file("extdata/organizations.csv", package = "fennica")
  stopwords.organizations <- as.character(read.csv(f, sep = "\t")[,1])
  
  f <- system.file("extdata/stopwords_titles.csv", package = "fennica")
  stopwords.titles <- as.character(read.csv(f, sep = "\t")[,1])
  
  stopwords <- unique(c(
    stopwords.general,
    stopwords.organizations,
    stopwords.names,
    stopwords.titles
  ))
}

f <- system.file("extdata/author_accepted.csv", package = "fennica")
author.accepted <- as.character(read.csv(f, sep = "\t")[,1])
pseudo <- get_pseudonymes()

accept.names <- unique(c(pseudo, author.accepted))
accept.names <- c(accept.names, unique(unlist(strsplit(accept.names, " "))))
accept.names <- unique(condense_spaces(
  gsub(",", " ", gsub("\\.", "", tolower(accept.names)))
))

stopwords <- setdiff(stopwords, accept.names)
