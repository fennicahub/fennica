field <- "publication_frequency"
tmp <- polish_publication_frequency(df.orig[[field]])

# Add to data.frame
df.tmp <- data.frame(
      publication_frequency_annual = tmp$annual,
      publication_frequency_text   = tmp$freq)

  message("Enrich publication frequency")
  # publication_interval "1-3" etc. does not refer to years but number of publications
  # within the given years. Augment the data based on this logic.
  if ("publication_frequency_text" %in% names(df.preprocessed)) {
    dfo <- df.orig[df.preprocessed$melinda_id, ]
    idx <- grep("^[0-9]{1}-[0-9]{1,2}$", gsub("\\.$", "", dfo$publication_interval))
    if (length(idx) > 0) {
      f <- sapply(strsplit(gsub("\\.$", "", dfo$publication_interval[idx]), "-"), function (x) {diff(sort(as.numeric(x)))+1})
      fa <- f/(df.preprocessed$publication_year_till[idx] - df.preprocessed$publication_year_from[idx] + 1)
      i <- is.na(df.preprocessed$publication_frequency_annual[idx])
      df.preprocessed$publication_frequency_annual[idx[i]] <- fa[i]
      df.preprocessed$publication_frequency_text <- publication_frequency_text(df.preprocessed$publication_frequency_text, df.preprocessed$publication_frequency_annual)
    }
  }
  