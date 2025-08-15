#use this function for multiple authors entries such as marc21 field 700a. 
#based polish_author
#modified by Julia Matveeva
polish_author_multi <- function(s, stopwords = NULL, verbose = FALSE) {
  sorig <- s
  
  if (is.null(stopwords)) {
    message("No stopwords provided for authors. Using ready-made stopword lists")
    
    f <- system.file("extdata/stopwords.csv", package = "fennica")
    stopwords.general <- as.character(read.csv(f, sep = "\t")[,1])
    stopwords.general <- c(stopwords.general, stopwords(kind = "en"))
    
    f <- system.file("extdata/stopwords_for_names.csv", package = "fennica")
    stopwords.names <- as.character(read.csv(f, sep = "\t")[,1])
    
    f <- system.file("extdata/organizations.csv", package = "fennica")
    stopwords.organizations <- as.character(read.csv(f, sep = "\t")[,1])
    
    f <- system.file("extdata/stopwords_titles.csv", package = "fennica")
    stopwords.titles <- as.character(read.csv(f, sep = "\t")[,1])
    
    stopwords <- unique(c(stopwords.general, stopwords.organizations, stopwords.names, stopwords.titles))
  }
  
  f <- system.file("extdata/author_accepted.csv", package = "fennica")
  author.accepted <- as.character(read.csv(f, sep = "\t")[,1])
  pseudo <- get_pseudonymes()
  
  accept.names <- unique(c(pseudo, author.accepted))
  accept.names <- c(accept.names, unique(unlist(strsplit(accept.names, " "))))
  accept.names <- unique(condense_spaces(gsub(",", " ", gsub("\\.", "", tolower(accept.names)))))
  stopwords <- setdiff(stopwords, accept.names)
  
  # Handle multiple authors separated by '|'
  s <- as.character(s)
  
  # Split by '|' and trim whitespace
  split_s <- lapply(s, function(x) {
    parts <- unlist(strsplit(x, "\\|"))
    tolower(trimws(parts))
  })
  
  orig_group_lengths <- lengths(split_s)
  flat_s <- unlist(split_s, use.names = FALSE)
  group_idx <- rep(seq_along(split_s), times = orig_group_lengths)
  
  # Clean the flat list of authors
  s <- gsub("[0-9]", " ", flat_s)
  s <- gsub("[\\[\\]()?]", " ", s)
  s <- gsub("-+", "-", s)
  s <- stringr::str_trim(s)
  s <- gsub("[\\.|,]+$", "", s)
  
  suniq <- unique(s)
  if (verbose) message(paste("Polishing author field:", length(suniq), "unique entries"))
  
  # Initialize name components for suniq
  first <- last <- character(length(suniq))
  pseudo.inds <- which(suniq %in% pseudo)
  
  inds1 <- setdiff(grep(",", suniq), pseudo.inds)
  if (length(inds1) > 0) {
    first[inds1] <- pick_firstname(suniq[inds1], format = "last, first")
    last[inds1]  <- pick_lastname(suniq[inds1], format = "last, first")
  }
  
  inds2 <- setdiff(setdiff(grep(" ", suniq), inds1), pseudo.inds)
  if (length(inds2) > 0) {
    first[inds2] <- pick_firstname(suniq[inds2], format = "first last")
    last[inds2]  <- pick_lastname(suniq[inds2], format = "first last")
  }
  
  inds3 <- setdiff(which(is.na(first) & is.na(last)), pseudo.inds)
  if (length(inds3) > 0) {
    last[inds3] <- suniq[inds3]
  }
  
  inds4 <- pseudo.inds
  if (length(inds4) > 0) {
    first[inds4] <- suniq[inds4]
  }
  
  if (verbose) message("Formatting names")
  
  inds <- which(!is.na(first) | !is.na(last))
  for (i in inds) {
    fi <- first[[i]]
    if (!is.na(fi)) fi <- unlist(strsplit(fi, " "), use.names = FALSE)
    
    la <- last[[i]]
    if (!is.na(la)) la <- unlist(strsplit(la, " "), use.names = FALSE)
    
    if (length(fi) == 0) fi <- NA
    if (length(la) == 0) la <- NA
    
    if (all(!is.na(fi)) && all(!is.na(la))) {
      if (la[[1]] == fi[[length(fi)]]) {
        fi <- fi[-length(fi)]
      }
    }
    
    first[[i]] <- paste(fi, collapse = " ")
    last[[i]]  <- paste(la, collapse = " ")
  }
  
  if (verbose) message("Creating name table")
  
  nametab <- data.frame(
    last = unname(last),
    first = unname(first),
    stringsAsFactors = FALSE
  )
  
  nametab$last[nchar(nametab$last) == 1] <- NA
  
  if (verbose) message("Capitalizing names")
  
  nametab$last  <- capitalize(nametab$last, "all.words")
  nametab$first <- capitalize(nametab$first, "all.words")
  
  nametab$first <- condense_spaces(gsub("\\.", " ", nametab$first))
  nametab$last  <- condense_spaces(gsub("\\.", " ", nametab$last))
  
  first <- nametab$first
  last <- nametab$last
  
  first[first == "NA"] <- NA
  last[last == "NA"] <- NA
  first <- gsub("[ ,\\-]+$", "", first)
  last <- gsub("[ ,\\-]+$", "", last)
  
  if (verbose) message("Constructing full names")
  
  full.name <- paste(last, first, sep = ", ")
  full.name[full.name == "NA, NA"] <- NA
  full.name <- gsub(", NA$", "", full.name)
  full.name <- gsub("^NA, ", "", full.name)
  full.name <- gsub("[ ,\\-]+$", "", full.name)
  
  name_map <- data.frame(
    orig = suniq,
    first = first,
    last = last,
    full = full.name,
    stringsAsFactors = FALSE
  )
  
  matched_first <- name_map$first[match(s, name_map$orig)]
  matched_last  <- name_map$last[match(s, name_map$orig)]
  matched_full  <- name_map$full[match(s, name_map$orig)]
  
  recombine_grouped <- function(x) {
    x <- unique(na.omit(x))
    if (length(x) == 0) return(NA_character_) else paste(x, collapse = "; ")
  }
  
  # Use `vapply` or `sapply` instead of `tapply` for safety
  final_first <- vapply(split(matched_first, group_idx), recombine_grouped, character(1))
  final_last  <- vapply(split(matched_last, group_idx),  recombine_grouped, character(1))
  final_full  <- vapply(split(matched_full, group_idx),  recombine_grouped, character(1))
  
  # Match the original row indices (1:N)
  final_first <- final_first[as.character(seq_along(split_s))]
  final_last  <- final_last[as.character(seq_along(split_s))]
  final_full  <- final_full[as.character(seq_along(split_s))]
  
  
  final_df <- data.frame(
  first = unname(final_first),
  last = unname(final_last),
  full_name = unname(final_full),
  stringsAsFactors = FALSE
  )
  
  return(final_df)
}

