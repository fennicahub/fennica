update.fields <- c(

      "publication_interval", # Some overlap with time.. TODO JM: qmd works
      "publication_frequency", 
      "physical_extent",       
      "physical_dimension", #JM: qmd works 
      "subject_geography", # IT takes care?
      )


df.orig <- df.orig[, update.fields]

# Languages to consider in cleanup.
# TODO: recognize the necessary languages automatically ?
catalog <- "fennica" 
languages <- c("finnish", "latin", "swedish")


## PUBLICATION FREQUENCY ENRICH
message("Enrich publication frequency")
# publication_interval "1-3" etc. does not refer to years but number of publications
# within the given years. Augment the data based on this logic.
df.preprocessed <-read.csv("df.preprocessed.csv")

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


## COMBINE PUBLICATION-YEAR AND PUBLICATION-INTERVAL FIELDS
# Recognize issues: those that have publication interval or frequency defined

  message("Compare with publication year field.")
  inds <- which(is.na(df.harmonized$publication_year))  
  # When the non-NA entries are unique, use the same year for all
  tmp <- cbind(from0 = df.harmonized$publication_year_from[inds],
               till0 = df.harmonized$publication_year_till[inds],
               from = df.harmonized$publication_interval_from[inds],
               till = df.harmonized$publication_interval_till[inds]
               )
  inds2 <- unname(which(apply(tmp, 1, function (x) {length(unique(na.omit(x)))}) == 1))

  y <- unname(apply(matrix(tmp[inds2,], ncol = ncol(tmp)), 1, function (x) {unique(na.omit(x))}))

  df.harmonized$publication_year_from[inds[inds2]] <- y
  df.harmonized$publication_year_till[inds[inds2]] <- y

  message("For conflicting years, select he largest combined span")
  tmp <- cbind(from0 = df.harmonized$publication_year_from[inds],
               till0 = df.harmonized$publication_year_till[inds],
               from = df.harmonized$publication_interval_from[inds],
               till = df.harmonized$publication_interval_till[inds]
               )

  tmp <- matrix(tmp, ncol = ncol(tmp))
  mins <- unname(apply(tmp, 1, function (x) {min(x, na.rm = TRUE)}))
  maxs <- unname(apply(tmp, 1, function (x) {max(x, na.rm = TRUE)}))

  df.harmonized$publication_year_from[inds] <- mins
  df.harmonized$publication_year_till[inds] <- maxs

# LL: this uses publication_interval field from df.orig; if that is
  # processed separately and stored in its own field in
  # df.preprocessed then this can be trivially handled. Note that
  # publication_interval is confusingly mixing (at least) to different
  # types of information: (1) actual years of the publication
  # interval, and (2) the number of publications during the years
  # given in the publication_time (df.orig). These should be
  # identified and separated.

  message("Mark potential first editions")
  df$first_edition <- is_first_edition(df)



# ----------------------------------------------------
#           PREPROCESS DATA
# ----------------------------------------------------

message("Preprocess selected original fields")
source("polish_all.R")

# Store the processed data
saveRDS(df.preprocessed, "df0.Rds", compress = TRUE)
saveRDS(df.orig, "df.raw.Rds", compress = TRUE)  
saveRDS(conversions, "conversions.Rds", compress = TRUE)

# ----------------------------------------------------
#           ENRICH VALIDATED DATA
# ----------------------------------------------------

# NOTE: for Fennica this enrichment is repeated also a second time after
# the fennica-specific parts. It might be sufficient to skip this first round
# and get the same results but cant say without checking more carefully
data.enriched <- enrich_preprocessed_data(df.preprocessed, df.orig)

# General validation and enrichment for the final data one more time
# (for instance, publisher field needs Fennica-specific modifications above
#  but that is just one example)
data.validated <- validate_preprocessed_data(data.enriched)

#See also validation.R!!!

      "author_date" + "author_name" # OK
      # -> Once both name and date are done, we can add the combined part of the summary; pitää synkatat myös publication_year kentän kanssa..
      


print("Saving updates on preprocessed data")
saveRDS(data.validated, "df.Rds")

# Summary analyses
source("analysis.init.R")
source("analysis.run.R")

# ---------------------------------------------------

# Specific analyses (to be updated)
# source("analysis.R")  # Summary md docs
# publisher.Rmd sisälsi myös publication_decade timelinejä yms
# jotka jouduttiin poistamaan - lisää uusia integroivia yhteenvetoja
#

# Data releases
# CCQ 2019 data release - run separately
# source("CCQ_2019/prepare_fnd_datax_for_ccq2019.R")



#fix the plot

#Title count versus paper consumption (top publishers in the 1809-1917):
  
  ```{r}
#| label = "publishertitlespapers",
#| fig.height = 8,
#| fig.width = 8,
#| echo = FALSE,
#| warning = FALSE
#res <- compare_title_paper(df, "publisher", selected = tops)
tops <- names(top(df_19, field = "publisher", n = 10))
res <- compare_title_paper(df_19, "publisher")
print(res$plot)  
kable(subset(res$table, publisher %in% tops), digit = 2)
```

