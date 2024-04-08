
#' @title Remove Special Chars
#' @description Remove special characters.
#' @param x Character vector
#' @param chars Characters to be removed
#' @param niter Number of iterations 
#' @return Polished vector
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples x2 <- remove_special_chars("test;")
#' @keywords utilities
remove_special_chars <- function (x, chars = c(",", ";", ":", "\\(", "\\)", "\\?", "--", "\\&"), niter = 5) {

  for (n in 1:niter) {
  
    x <- str_trim(x)

    for (char in chars) {
      x <- gsub(paste(char, "$", sep = ""), " ", x)
      x <- gsub(paste("^", char, sep = ""), " ", x)
      x <- gsub(char, " ", x)
    }

    for (char in c("\\[", "]")) {
      x <- gsub(paste(char, "$", sep = ""), "", x)
      x <- gsub(paste("^", char, sep = ""), "", x)
      x <- gsub(char, "", x)
    }
  }

  x <- condense_spaces(x)
   
  x[x == ""] <- NA

  x

}



#' @title Polish Dimensions
#' @description Polish dimension field for many documents at once.
#' @param x A vector of dimension notes
#' @param fill Logical. Estimate and fill in the missing information: TRUE/FALSE
#' @param dimtab Dimension mapping table
#' @param verbose verbose
#' @param synonyms Synonyme table
#' @param sheet.dimension.table Sheet dimension info
#' @return Dimension table
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples # polish_dimensions(c("2fo", "14cm"), fill = TRUE)
#' @keywords utilities
polish_dimensions <- function (x, fill = TRUE, dimtab = NULL, verbose = FALSE, synonyms = NULL, sheet.dimension.table = NULL) {

  s <- as.character(x)

  if (is.null(dimtab)) {
    if (verbose) {
      message("dimtab dimension mapping table not provided, using the default table dimension_table()")
    }
    dimtab <- comhis::dimension_table()

  }

  if (is.null(sheet.dimension.table)) {
    sheet.dimension.table <- sheet_area(verbose = FALSE)
  }


  if (is.null(synonyms)) {
    f <- "harmonize_dimensions.csv"
    synonyms <- read_mapping(f, sep = "\t", mode = "table",encoding = "UTF-8")
  } 


  if (verbose) { message("Initial harmonization..") }
  s <- tolower(s)

  sorig <- s
  s <- suniq <- unique(s)

  # 75,9 -> 75.9  
  s <- gsub(",", ".", s)
  s <- gsub("lon.", "long ", s)   
  s <- gsub(" /", "/", s)

  # Harmonize the terms
  s <- map(s, synonyms, mode = "recursive")

  # Remove brackets
  s <- gsub("\\(", " ", gsub("\\)", " ", s)) 
  s <- gsub("\\[", " ", gsub("\\]", " ", s))
  # Add spaces
  s <- gsub("cm\\. {0,1}", " cm ", s)  
  s <- gsub("x", " x ", s)
  s <- gsub("oblong", "obl ", s)
  s <- gsub("obl\\.{0,1}", "obl ", s)  
  # Remove extra spaces
  s <- gsub(" /", "/", s)
  s <- condense_spaces(s)

  # "16mo in 8's."
  inds <- grep("[0-9]+.o in [0-9]+.o", s)  
  s[inds] <- gsub(" in [0-9]+.o", "", s[inds])

  # "12 mo
  inds <- grep("[0-9]+ .o", s)  
  for (id in c("mo", "to", "vo", "fo")) {
    s[inds] <- gsub(paste(" ", id, sep = ""), id, s[inds])
  }

  s <- harmonize_dimension(s, synonyms) 
  s <- map(s, synonyms, mode = "recursive")  

  # Make it unique here: after the initial harmonization
  # This helps to further reduce the number of unique cases 
  # Speed up by only handling unique cases
  # Temporarily map to original indices to keep it clear
  s <- s[match(sorig, suniq)]  
  sorig <- s
  s <- suniq <- unique(sorig)

  if (verbose) {
    message(paste("Estimating dimensions:", length(suniq), "unique cases"))    
  }

  # --------------------------------------

  tab <- t(sapply(s, function (x) {a <- try(polish_dimension(x, synonyms)); if (class(a) == "try-error") {a <- rep(NA, 5)}; return(a)
    }))
  rownames(tab) <- NULL

  tab <- data.frame(tab)

  if (verbose) {
    message("Convert to desired format")    
  }
  tab$original <- as.character(tab$original)
  tab$gatherings <- order_gatherings(unlist(tab$gatherings))
  tab$width <- suppressWarnings(as.numeric(as.character(tab$width)))
  tab$height <- suppressWarnings(as.numeric(as.character(tab$height)))
  tab$gatherings <- order_gatherings(tab$gatherings)
  tab$obl <- unlist(tab$obl, use.names = FALSE)
  tab.original <- tab  

  tab.final <- tab.original
  colnames(tab.final) <- paste0(colnames(tab.original), ".original")

  if (fill) {
    if (verbose) {
      message("Estimating missing entries")
    }

    tab.estimated <- augment_dimension_table(tab.original, dim.info = dimtab, sheet.dim.tab = sheet.dimension.table, verbose = verbose)

    tab.final <- cbind(tab.final, tab.estimated)

  }

  tab.final$original.original <- NULL  

  tab.final <- tab.final[match(sorig, suniq),]

  tab.final

}




#' @title Get Country
#' @description Map geographic places to country names.
#' @param x A vector of region names (cities or municipalities etc.)
#' @param map data.frame with region to country mappings (fields 'region' and 'country')
#' @return Country vector
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("comhis")
#' @examples x2 <- get_country("Berlin")
#' @keywords utilities
get_country <- function (x, map = NULL) {

  # TODO could add here some more countries from geonames
  # We could standardize country names but problem is that e.g.
  # England, Scotland
  # etc are not mapped (as UK). But is potentially useful later.
  # devtools::install_github("dsself/standardizecountries")
  # library(standard)
  # df.preprocessed$publication_country2 <- country_name(df.preprocessed$publication_country)
  # df.preprocessed$publication_country.code <- country_code(df.preprocessed$publication_country, "country", "iso3c")

  # Speed up by handling unique cases only
  xorig <- as.character(x)
  xorig.unique <- unique(xorig)  
  x <- xorig.unique

  if (is.null(map)) {
    f <- "reg2country.csv"
    message(paste("Reading region-country mappings from file ", f))
    map <- read_mapping(f, mode = "table", sep = ";", sort = TRUE, self.match = FALSE, include.lowercase = FALSE, ignore.empty = FALSE, remove.ambiguous = TRUE, lowercase.only = FALSE, from = "region", to = "country") 
  }
  
  message("Map each region in x to a country")
  # use lowercase
  # country <- map$country[match(tolower(x), tolower(map$region))]
  spl <- split(tolower(map$country), tolower(map$region)) 
  spl <- spl[tolower(x)]
  
  # If mapping is ambiguous, then name the country as ambiguous
  spl <- lapply(spl, unique)
  spl[which(sapply(spl, function (x) {length(unique(x)) > 1}, USE.NAMES = FALSE))] <- "ambiguous"
  spl[which(sapply(spl, function (x) {length(x) == 0}, USE.NAMES = FALSE))] <- NA  
  spl <- unlist(as.vector(spl))
  country <- spl

  # If multiple possible countries listed and separated by |;
  # use the first one (most likely)
  country <- str_trim(sapply(strsplit(as.character(country), "\\|"), function (x) {ifelse(length(x) > 0, x[[1]], NA)}, USE.NAMES = FALSE))

  # Use the final country names
  country <- map$country[match(tolower(country), tolower(map$country))]

  # The function was sped up by operating with unique terms
  country[match(xorig, xorig.unique)]

}




#' @title Enrich Data
#' @description Enrich data. 
#' @param data.validated Validated data.frame
#' @param df.orig Original data.frame
#' @return Augmented data.frame
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{df2 <- enrich_preprocessed_data(df)}
#' @keywords utilities
enrich_preprocessed_data <- function(df.preprocessed, df.orig) {

  # NOT processed:
  # - title
  pagecount <- width <- height <- NULL

  # This could be improved - varies in time !
  printrun <- 1000
  update.fields   <- names(df.preprocessed)

  # Note the source of page counts. Original MARC data by default.
  df.preprocessed$pagecount_from <- rep("original", nrow(df.preprocessed))

  # Always do. New field "author" needed for first edition recognition.
  # This is fast.
  if (any(c("author_name", "author_date") %in% update.fields)) {
    # this seems to take long even with only
    # 100 entries in df.preprocessed? -vv 
    df.preprocessed <- enrich_author(df.preprocessed)
  }

  if ("publisher" %in% update.fields) {

    message("Self-published docs where author is known but publisher not")
    # Note: also unknown authors are considered as self-publishers
    message("Add a separate self-published field")
    tmp <- self_published(df.preprocessed)
    df.preprocessed$self_published <- tmp$self_published
    df.preprocessed$publisher <- tmp$publisher

  }

  # -------------------------------------------------------------------

  if (any(c("physical_extent", "physical_dimension") %in% update.fields)) {

    # Enrich dimensions before pagecount (some dimensions reclassified)
    df.preprocessed <- enrich_dimensions(df.preprocessed)

    # Enrich pagecount after dimensions
    df.preprocessed <- enrich_pagecount(df.preprocessed)

    message("Add estimated paper consumption")
    # Estimated print run size for paper consumption estimates    
    # Paper consumption in sheets
    # (divide document area by standard sheet area
    sheet.area <- subset(sheet_sizes(), format == "sheet")$area
    df.preprocessed <- mutate(df.preprocessed,
            paper = printrun * (pagecount/2) * (width * height)/sheet.area)

    message("Add estimated print area")
    df.preprocessed <- mutate(df.preprocessed,
            print_area = (pagecount/2) * (width * height)/sheet.area)

  }

  message("Identify issues")
  df.preprocessed$issue <- is.issue(df.preprocessed)

  message("Custom gender information for Fennica")
  # For author names, use primarily the Finnish names database
  # hence use it to replace the genders assigned earlier 
  library(fennica)
  firstname <- pick_firstname(df.preprocessed$author_name, format = "last, first")

  # Let us Finnish gender mappings override others
  gender.fi <- get_gender_fi()[, c("name", "gender")] # Finnish
  genderfi  <- get_gender(firstname, gender.fi)
  inds <- which(!is.na(genderfi))
  df.preprocessed$author_gender[inds] <- genderfi[inds]

  # Let us Fennica custom gender mappings override others
  gender.custom <- read_mapping("custom_gender_fennica.csv", sep = "\t",
               from = "name", to = "gender", mode = "table")
  gendercustom <- get_gender(firstname, gender.custom)
  inds <- which(!is.na(gendercustom))
  df.preprocessed$author_gender[inds] <- gendercustom[inds]

  message("-- Fennica publishers")
  df.preprocessed$publisher <- polish_publisher_fennica(df.preprocessed)

  message("Enrichment OK")
  return(df.preprocessed)


}


#' @title Validate Preprocessed Data
#' @description Preprocessing validators and some adjustments.
#' @param data.preprocessed Preprocessed data.
#' @param max.pagecount Upper gap for the pagecount for ocs that exceed this limit.
#' @return Modified data.
#' @export
#' @author Ville Vaara and Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples # \dontrun{validate_preprocessed_data(data.preprocessed)}
#' @keywords utilities
validate_preprocessed_data <- function(df, max.pagecount = 5000) {

  # NOT processed:
  # - title

  # TODO perhaps separate validators for different fields
  df.preprocessed <- df

  data.to.analysis.fennica <- data.validated.fennica <- df.preprocessed
  df <- data.to.analysis.fennica

  # Consider all fields if update.fields is not specifically defined
  update.fields <- names(df)



  # Some documents have extremely high pagecounts
  # (up to hundreds of thousands of pages)
  # MT + LL selected 5000 pages as the default threshold.
  # If the document has more pages than this, the pagecount
  # info will be removed as unreliable
  # The ESTC seemed to have 4 documents (out of ~5e5) affected
  # with estimated pagecount over 5000
  # Also remove negative and zero pagecounts; should not be possible
  if ("physical_extent" %in% update.fields) {

    # Apply gap on the highest pagecounts
    df$pagecount[df$pagecount > max.pagecount] <- max.pagecount
    df$pagecount[df$pagecount <= 0] <- NA
    # Round page counts to the closest integer if they are not already integers
    df$pagecount <- round(df$pagecount)

  }


  if ("author_date" %in% update.fields) {

    # Author life years cannot exceed the present year
    # If they do, set to NA
    inds <- which(df$author_birth > max.year)
    if (length(inds) > 0) {
      df[inds, "author_birth"] <- NA
    }
    inds <- which(df$author_death > max.year)
    if (length(inds) > 0) {
       df[inds, "author_death"] <- NA
    }
    
    # Death must be after birth
    # If this is not the case, set the life years to NA
    inds <- which(df$author_death < df$author_birth)
    if (length(inds) > 0) {
      df[inds, "author_birth"] <- NA
      df[inds, "author_death"] <- NA
    }

    # Author life - make sure this is in numeric format
    df$author_birth <- as.numeric(as.character(df$author_birth))
    df$author_death <- as.numeric(as.character(df$author_death))  

    # Publication year must be after birth
    # FIXME: should we let these through to the final summaries
    # - this could help to spot problems ?
    inds <- which(df$author_birth > df$publication_year_from)
    if (length(inds) > 0) {
      df[inds, "author_birth"] <- NA
      df[inds, "author_death"] <- NA
      df[inds, "publication_year_from"] <- NA
      df[inds, "publication_year_till"] <- NA      
    }

  }

  if ("author_name" %in% update.fields) {
    df <- validate_names(df)
  }


  return (df)
}

#' @title Annual Publication Frequency to Text
#' @description Convert annual publication frequencies to text format.
#' @param x Original publication frequency text
#' @param peryear Estimated annual publication frequency
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{df <- publication_frequency_text("Twice per year" 2)}
#' @keywords utilities
publication_frequency_text <- function (x, peryear) {

  peryear <- as.numeric(peryear)
  peryear.text <- as.character(x)
  peryear.text[!is.na(peryear)] <- as.character(peryear[!is.na(peryear)])

  # TODO move to inst/extdata conversion table
  f <- system.file("extdata/frequency_conversions.csv", package = "comhis")
  freqs <- read_mapping(f, sep = ",", mode = "vector", include.lowercase = FALSE, from = "name", to = "annual")
  freqs <- sapply(freqs, function (s) {eval(parse(text=s))})

  # Match numeric frequencies to the closest option
  inds <- which(!is.na(peryear) & is.numeric(peryear))
  if (length(inds) > 0){
    nams <- sapply(peryear[inds], function (y) {names(which.min(abs(freqs - y)))})
    peryear.text[inds] <- nams
  }
  peryear.text[which(peryear < 0.1)] <- "Less than every ten Years"

  peryear.text <- condense_spaces(peryear.text)

  # Order the levels by frequency
  peryear.text <- factor(peryear.text, levels = unique(peryear.text[order(peryear)]))

  peryear.text
}




#' @title Polish Publication Frequency
#' @description Harmonize publication frequencies.
#' @param x publication frequency field (a vector) 
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{df <- polish_publication_frequency("Kerran vuodessa")}
#' @keywords utilities
polish_publication_frequency <- function(x) {

  # Remove periods  
  x <- condense_spaces(tolower(gsub("\\.$", "", x)))
  x <- gsub("^ca ", "", x)
  x <- gsub("\\?", " ", x)
  x <- gsub("'", " ", x)    
  x <- gsub(" */ *", "/", x)
  x <- gsub("^[0-9]+ s$", "", x)
  x <- condense_spaces(x)

  f <- system.file("extdata/replace_special_chars.csv", package = "fennica")
  spechars <- suppressWarnings(read_mapping(f, sep = ";", mode = "table", include.lowercase = TRUE))
  x <- as.character(map(x, spechars, mode = "match"))

  xorig <- x
  x <- xuniq <- unique(xorig)
  df <- do.call("rbind", lapply(x, polish_publication_frequencies))
  
  # Match to original inds and return
  df[match(xorig, xuniq),]

}



polish_publication_frequencies <- function (x) {

  # Convert with different languages. Use the one with least NAs
  # not an optimal hack but works for the time being..
  tmps <- list()
  # tmps[["English"]] <- suppressWarnings(polish_publication_frequency_english(x))
  tmps[["Swedish"]] <- suppressWarnings(polish_publication_frequency_swedish(x))  
  tmps[["Finnish"]] <- suppressWarnings(polish_publication_frequency_finnish(x))
  lang <- names(which.min(sapply(tmps, function (tmp) {sum(is.na(tmp))})))
  tmp <- tmps[[lang]]

  # Convert all units to years
  unityears <- tmp$unit
  unityears <- gsub("year", "1", unityears)  
  unityears <- gsub("month", as.character(1/12), unityears)  
  unityears <- gsub("week", as.character(1/52), unityears)  
  unityears <- gsub("day", as.character(1/365), unityears)  
  unityears <- gsub("Irregular", NA, unityears)
  unityears <- gsub("Single", NA, unityears)    

  suppressWarnings(
    annual <- as.numeric(as.character(tmp$freq)) / as.numeric(unityears)
  )

  # Provide harmonized textual explanations for each frequency
  annual2text <- publication_frequency_text(tmp$unit, annual)

  data.frame(freq = annual2text, annual = annual)

}





#' @title Polish Publication Frequency English
#' @description Harmonize publication frequencies for English data.
#' @param x publication frequency field (a vector) 
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{df <- polish_publication_frequency_english("weekly")}
#' @keywords utilities
polish_publication_frequency_english <- function(x) {

  # TODO add to CSV list rather than mixed in the code here				     
  x <- gsub("issued several times a week, frequency of issue varies", "3 per week", x)
  x <- gsub("during the law terms", NA, x)  
  x <- gsub("suday", "sunday", x)
  x <- gsub("colleced", "collected", x)
  x <- gsub(" and index$", "", x)    
  x <- gsub(", when parliament is in session", "", x)
  x <- gsub("\\(when parliament is in session\\)", "", x)
  x <- gsub("\\(when parliament is sitting\\)", "", x)
  x <- gsub("\\(while parliament is sitting\\)", "", x)  
  x <- gsub("\\(published according to sitting dates of parliament\\)", "", x)
  x <- gsub("\\(during the sitting dates of parliament\\)", "", x)
  x <- gsub("\\(during the sitting of parliament\\)", "", x)      
  x <- gsub(", with irregular special issues", "", x)  
  x <- gsub(" \\(collected [a-z]+\\)", "", x)
  x <- gsub(" \\(during the racing season\\)", "", x)
  x <- gsub(" \\(collected issues for [0-9]+\\)", "", x)
  x <- gsub(" \\(collected annually, [0-9]+-[0-9]+\\)", "", x)  
  x <- gsub(" \\(collected [0-9]+ times a [a-z]+\\)", "", x)
  x <- gsub(" \\(collected [a-z]+ [a-z]+\\)", "", x)
  x <- gsub(" \\(collected [a-z]+ [0-9]+ issues\\)", "", x)
  x <- gsub(" \\(compiled issues\\)", "", x)
  x <- gsub(" \\(compilation\\)", "", x)      
  x <- gsub(" \\(collected [a-z]+\\)", "", x)    
  x <- gsub(" \\(cumulati*ve\\)", "", x)
  x <- gsub(" \\(cumulated\\)", "", x)
  x <- gsub(" \\(with general title page\\)", "", x)  
  x <- gsub(" \\(cumulates monthly issues\\)", "", x)
  x <- gsub(" \\(cumulated every [a-z]+ numbers\\)", "", x)  
  x <- gsub(" \\(with [a-z]+ cumulation\\)", "", x)
  x <- gsub(", with annual or semiannual cumulation", "", x)
  x <- gsub(", with annual cumulation and indexes", "", x)  
  x <- gsub(", with [0-9]+-* *[a-z]+ cumulations*", "", x)
  x <- gsub(", with [a-z]+ cumulations*", "", x)  
  x <- gsub(", with cumulation in [0-9]+ volumes*", "", x)  
  x <- gsub(", with [a-z]+ [a-z]+ cumulations*", "", x)  
  x <- gsub(" \\(with [a-z]+ cumulations*\\)", "", x)  
  x <- gsub(" \\(cumulation\\)", "", x)
  x <- gsub(" \\(on mondays\\)", "", x)
  x <- gsub(" \\(on tuesdays\\)", "", x)    
  x <- gsub(" \\(on wednesdays\\)", "", x)
  x <- gsub(" \\(on thursdays\\)", "", x)
  x <- gsub(" \\(on fridays\\)", "", x)
  x <- gsub(" \\(on saturdays\\)", "", x)          
  x <- gsub(" \\(on sundays\\)", "", x)
  x <- gsub(" \\(mondays\\)", "", x)
  x <- gsub(" \\(tuesdays\\)", "", x)
  x <- gsub(" \\(tues\\)", "", x)      
  x <- gsub(" \\(wednesdays\\)", "", x)
  x <- gsub(" \\(thursdays\\)", "", x)
  x <- gsub(" \\(thurs\\.*\\)", "", x)  
  x <- gsub(" \\(fridays\\)", "", x)
  x <- gsub(" \\(saturdays\\)", "", x)          
  x <- gsub(" \\(sundays\\)", "", x)
  x <- gsub(" \\(w?th some variation\\)", "", x)
  x <- gsub(", with occasional supplements", "", x)
  x <- gsub("bi-", "bi", x)
  x <- gsub("semi-", "semi", x)
  x <- gsub("annually", "annual", x)
  x <- gsub(" \\[[0-9]+\\]", "", x)
  x <- condense_spaces(x)
  
  freq <- rep(NA, length = length(x))
  unit <- rep(NA, length = length(x))  

  # English
  f <- system.file("extdata/numbers_english.csv", package = "comhis")
  char2num <- read_mapping(f, sep = ",", mode = "table", from = "character", to = "numeric")
  x <- map(x, synonymes = char2num, from = "character", to = "numeric", mode = "match")

  # every ten issues/numbers
  inds <- c(grep("^every [0-9]+ issues", x), grep("^every [0-9]+ numbers", x))
  if (length(inds)>0) {
    x[inds] <- NA
  }

  # 18 issues per year
  inds <- grep("^[0-9]+ issues ", x)
  if (length(inds)>0) {
    x[inds] <- gsub(" issues", "", x[inds])
  }

  # 3 times weekly/daily/yearly/monthly -> 3 per week
  inds <- grep("^[0-9]+ times [a-z]+ly$", x)
  if (length(inds)>0) {
    x[inds] <- gsub("ly$", "", x[inds])
    x[inds] <- gsub(" times ", " per ", x[inds])
    x[inds] <- gsub(" dai$", " day", x[inds])    
  }

  # daily, except sunday -> 6/week
  inds <- grep("^daily,* except sunday$", x)
  if (length(inds)>0) {
    freq[inds] <- 6
    unit[inds] <- "week"
    x[inds] <- NA # handled    
  }

  # daily (except weekends)
  inds <- grep("^daily,* \\(*except [a-z]+\\. & [a-z]+\\.\\)*$", x)
  if (length(inds)>0) {
    freq[inds] <- 5
    unit[inds] <- "week"
    x[inds] <- NA # handled    
  }

  # daily except sunday
  inds <- grep("^daily,* \\(*except sundays*\\)*$", x)
  if (length(inds)>0) {
    freq[inds] <- 6
    unit[inds] <- "week"
    x[inds] <- NA # handled    
  }

  # daily (except sun.)
  inds <- grep("^daily \\(except [a-z]+\\.\\)$", x)
  if (length(inds)>0) {
    freq[inds] <- 6
    unit[inds] <- "week"
    x[inds] <- NA # handled    
  }

  # daily except weekends
  inds <- grep("^daily,* \\(*except weekends\\)*$", x)
  if (length(inds)>0) {
    freq[inds] <- 5
    unit[inds] <- "week"
    x[inds] <- NA # handled    
  }

  # daily
  inds <- grep("^daily", x)
  if (length(inds)>0) {
    freq[inds] <- 1
    unit[inds] <- "day"
    x[inds] <- NA # handled
  }

  # 2 daily
  inds <- grep("^[0-9]+ daily$", x)
  if (length(inds)>0) {
    freq[inds] <- unlist(strsplit(x[inds], " "), use.names = F)[[1]]
    unit[inds] <- "day"
    x[inds] <- NA # handled    
  }

  # every other day
  inds <- grep("^every other day$", x)
  if (length(inds)>0) {
    freq[inds] <- 1/2
    unit[inds] <- "day"
    x[inds] <- NA # handled    
  }

  # weekly
  inds <- grep("^weekly", x)
  if (length(inds)>0) {
    freq[inds] <- 1
    unit[inds] <- "week"
    x[inds] <- NA # handled    
  }

  # semiweekly
  inds <- grep("^semiweekly$", x)
  if (length(inds)>0) {
    freq[inds] <- 2
    unit[inds] <- "week"
    x[inds] <- NA # handled    
  }

  # semiweekly (tuesday and friday) 
  inds <- grep("^semiweekly \\([a-z]+ and [a-z]+\\)$", x)
  if (length(inds)>0) {
    freq[inds] <- 2
    unit[inds] <- "week"
    x[inds] <- NA # handled    
  }

  # biweekly
  inds <- grep("^biweekly", x)
  if (length(inds)>0) {
    freq[inds] <- 2
    unit[inds] <- "week"
    x[inds] <- NA # handled    
  }

  # triweekly
  inds <- grep("^triweekly$", x)
  if (length(inds)>0) {
    freq[inds] <- 3
    unit[inds] <- "week"
    x[inds] <- NA # handled    
  }

  # monthly
  inds <- grep("^monthly", x)
  if (length(inds)>0) {
    freq[inds] <- 1
    unit[inds] <- "month"
    x[inds] <- NA # handled    
  }

  # bimonthly
  inds <- grep("^bimonthly", x)
  if (length(inds)>0) {
    freq[inds] <- 1/2
    unit[inds] <- "month"
    x[inds] <- NA # handled    
  }

  # semimonthly
  inds <- grep("^semimonthly", x)
  if (length(inds)>0) {
    freq[inds] <- 1/2
    unit[inds] <- "month"
    x[inds] <- NA # handled    
  }

  # quarterly
  inds <- grep("^quarterly", x)
  if (length(inds)>0) {
    freq[inds] <- 4
    unit[inds] <- "year"
    x[inds] <- NA # handled    
  }

  # annual
  inds <- grep("^annual *\\(*", x)
  if (length(inds)>0) {
    freq[inds] <- 1
    unit[inds] <- "year"
    x[inds] <- NA # handled    
  }

  # semiannual
  inds <- grep("^semiannual", x)
  if (length(inds)>0) {
    freq[inds] <- 2
    unit[inds] <- "year"
    x[inds] <- NA # handled    
  }

  # biennial
  inds <- grep("^biennial$", x)
  if (length(inds)>0) {
    freq[inds] <- 1/2
    unit[inds] <- "year"
    x[inds] <- NA # handled    
  }

  # two or three times a year
  inds <- grep("^[0-9]+ or [0-9]+ times a [a-z]+$", x)
  if (length(inds)>0) {
    spl <- strsplit(x[inds], " ")
    freq[inds] <- mean(as.numeric(sapply(spl, function (xi) {xi[[1]]})), as.numeric(sapply(spl, function (xi) {xi[[3]]})))
    unit[inds] <- sapply(spl, function (xi) {xi[[6]]})
    x[inds] <- NA # handled    
  }

  # two or three times a year
  inds <- grep("^[0-9]+ to [0-9]+ times a [a-z]+$", x)
  if (length(inds)>0) {
    spl <- strsplit(x[inds], " ")
    freq[inds] <- mean(as.numeric(sapply(spl, function (xi) {xi[[1]]})), as.numeric(sapply(spl, function (xi) {xi[[3]]})))
    unit[inds] <- sapply(spl, function (xi) {xi[[6]]})
    x[inds] <- NA # handled    
  }

  # three times a year
  inds <- grep("^[0-9]+ times a [a-z]+", x)
  if (length(inds)>0) {
    x[inds] <- gsub(" times a ", " ", x[inds])
    spl <- strsplit(x[inds], " ")
    freq[inds] <- as.numeric(sapply(spl, function (xi) {xi[[1]]}))
    unit[inds] <- sapply(spl, function (xi) {xi[[2]]})
    x[inds] <- NA # handled    
  }

  # three times weekly
  inds <- grep("^[0-9]+ times [a-z]+$", x)
  if (length(inds)>0) {
    spl <- strsplit(x[inds], " ")
    freq[inds] <- as.numeric(sapply(spl, function (xi) {xi[[1]]}))
    unit[inds] <- sapply(spl, function (xi) {xi[[3]]})
    x[inds] <- NA # handled    
  }

  # three per year
  inds <- grep("^[0-9]+ per [a-z]+$", x)
  if (length(inds)>0) {
    spl <- strsplit(x[inds], " ")
    freq[inds] <- as.numeric(sapply(spl, function (xi) {xi[[1]]}))
    unit[inds] <- sapply(spl, function (xi) {xi[[3]]})
    x[inds] <- NA # handled    
  }

  # three times per year
  inds <- grep("^[0-9]+ times per [a-z]+$", x)
  if (length(inds)>0) {
    x[inds] <- gsub(" times per ", " ", x[inds])
    spl <- strsplit(x[inds], " ")
    freq[inds] <- as.numeric(sapply(spl, function (xi) {xi[[1]]}))
    unit[inds] <- sapply(spl, function (xi) {xi[[2]]})
    x[inds] <- NA # handled    
  }

  # 4 issues in 6 months
  inds <- grep("^[0-9]+ issues in [0-9]+ [a-z]+$", x)
  if (length(inds)>0) {
    spl <- strsplit(x[inds], " ")
    n1 <- as.numeric(sapply(spl, function (xi) {xi[[1]]}))
    n2 <- as.numeric(sapply(spl, function (xi) {xi[[4]]}))
    u <- sapply(spl, function (xi) {xi[[5]]})
    freq[inds] <- n1/n2
    unit[inds] <- u
    x[inds] <- NA # handled    
  }

  # 4 in 6 months
  inds <- grep("^[0-9]+ in [0-9]+ [a-z]+$", x)
  if (length(inds)>0) {
    spl <- strsplit(x[inds], " ")
    n1 <- as.numeric(sapply(spl, function (xi) {xi[[1]]}))
    n2 <- as.numeric(sapply(spl, function (xi) {xi[[3]]}))
    u <- sapply(spl, function (xi) {xi[[4]]})
    freq[inds] <- n1/n2
    unit[inds] <- u
    x[inds] <- NA # handled    
  }

  # 1 during a 6teen-month period
  inds <- grep("^[0-9]+ during a [0-9]+-[a-z]+ period", x)
  if (length(inds)>0) {
    x[inds] <- gsub("-", " ", x[inds])
    spl <- strsplit(x[inds], " ")
    n1 <- as.numeric(sapply(spl, function (xi) {xi[[1]]}))
    n2 <- as.numeric(sapply(spl, function (xi) {xi[[4]]}))
    u <- sapply(spl, function (xi) {xi[[5]]})
    freq[inds] <- n1/n2
    unit[inds] <- u
    x[inds] <- NA # handled    
  }

  # every five days
  inds <- grep("^every [0-9]+ [a-z]+$", x)
  if (length(inds)>0) {
    x[inds] <- gsub("^every ", "", x[inds])
    spl <- strsplit(x[inds], " ")
    freq[inds] <- 1/as.numeric(sapply(spl, function (xi) {xi[[1]]}))
    unit[inds] <- sapply(spl, function (xi) {xi[[2]]})
    x[inds] <- NA # handled    
  }

  # twice every three weeks
  inds <- grep("^[0-9]+ every [0-9]+ [a-z]+$", x)
  if (length(inds)>0) {
    spl <- strsplit(x[inds], " ")

    freq[inds] <- as.numeric(sapply(spl, function (xi) {xi[[1]]}))/as.numeric(sapply(spl, function (xi) {xi[[3]]}))
    unit[inds] <- sapply(spl, function (xi) {xi[[4]]})
    x[inds] <- NA # handled    
  }

  # semiannual
  inds <- grep("^semiannual$", x)
  if (length(inds)>0) {
    freq[inds] <- 2
    unit[inds] <- "year"
    x[inds] <- NA # handled    
  }

  # irregular
  inds <- c(
    which(x == "irregular"),
    which(x == "unknown"),
    which(x == "frequency unknown"),        
    which(x == "frequency irregular"),
    which(x == "no determinable frequency")
  )
  if (length(inds)>0) {
    freq[inds] <- NA
    unit[inds] <- "Irregular"
    x[inds] <- NA # handled        
  }

  x <- condense_spaces(x)
  if (is.null(x) || is.na(x) || x == "") {
    # skip
  }

  # Translate units (weeks -> week; years -> year etc)
  unit <- gsub("s$", "", unit)

  # orig = x, 
  data.frame(unit = unit, freq = as.numeric(as.character(freq)))

}



#' @title Polish Publication Frequency Swedish
#' @description Harmonize publication frequencies for Swedish data.
#' @param x publication frequency field (a vector) 
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("fennica")
#' @examples \dontrun{df <- polish_publication_frequency_swedish("1 nr/ar")}
#' @keywords utilities
polish_publication_frequency_swedish <- function(x) {

  x <- gsub(" h\\.*/", " nr/", x)
  x <- gsub(" hft\\.*/", " nr/", x)
  x <- gsub(" pl\\.*/", " nr/", x)
  x <- gsub(" s. l.nge kryssningarna varar", " ", x)
  x <- condense_spaces(x)
  
  freq <- rep(NA, length = length(x))
  unit <- rep(NA, length = length(x))  

  # Swedish
  f <- system.file("extdata/numbers_swedish.csv", package = "fennica")
  char2num <- read_mapping(f, sep = ",", mode = "table", from = "character", to = "numeric")
  x <- map(x, synonymes = char2num, from = "character", to = "numeric", mode = "match")
  
  # 6 nr/ar / 6-8 nr/ar
  inds <- grep("^[0-9]+-*[0-9]* nr/ar$", x)
  if (length(inds) > 0) {
    s <- condense_spaces(gsub("/", "", gsub("[[:lower:]]", "", x[inds])))
    freq[inds] <- sapply(strsplit(s, "-"), function (xi) {mean(as.numeric(xi))})
    unit[inds] <- "year"
  }

  # 6-8 nr/manad OR 6-8 nr/manaden OR 6-8 nr/man
  inds <- c(
          grep("^[0-9]+-*[0-9]* nr/man *[:lower:| ]*", x),
          grep("^[0-9]+-*[0-9]* nr/manad *[:lower:| ]*", x),	  
          grep("^[0-9]+-*[0-9]* nr/manaden *[:lower:| ]*", x))
  if (length(inds) > 0) {
    s <- gsub("[[:lower:]]", "", x[inds])
    s <- condense_spaces(gsub("/", "", s))
    freq[inds] <- sapply(strsplit(s, "-"), function (xi) {mean(as.numeric(xi))})
    unit[inds] <- "month"
  }

  # 6-8 nr/vecka
  inds <- grep("^[0-9]+-*[0-9]* nr/vecka", x)
  if (length(inds) > 0) {
    s <- condense_spaces(gsub("/", "", gsub("[[:lower:]]", "", x[inds])))
    freq[inds] <- sapply(strsplit(s, "-"), function (xi) {mean(as.numeric(xi))})
    unit[inds] <- "week"
  }

  # 6-8 nr/termin
  inds <- grep("^[0-9]+-*[0-9]* nr/termin", x)
  if (length(inds) > 0) {
    s <- condense_spaces(gsub("/", "", gsub("[[:lower:]]", "", x[inds])))
    # Termin is 1/2 years, hence multiplying the frequency by 2 to get annual estimate
    freq[inds] <- 2 * sapply(strsplit(s, "-"), function (xi) {mean(as.numeric(xi))})
    unit[inds] <- "year"
  }

  # 6-8 nr/kvartal
  inds <- grep("^[0-9]+-*[0-9]* nr/kvartal", x)
  if (length(inds) > 0) {
    s <- condense_spaces(gsub("/", "", gsub("[[:lower:]]", "", x)))
    freq[inds] <- 4 * sapply(strsplit(s, "-"), function (xi) {mean(as.numeric(xi))}) # kvartal is 1/4 year
    unit[inds] <- "year"
  }

  # daglig
  inds <- grep("^daglig$", x)
  if (length(inds)>0) {
    freq[inds] <- 1
    unit[inds] <- "day"
  }

  # arligen
  inds <- c(grep("^.rlig$", x), grep("^.rligen$", x))
  if (length(inds)>0) {
    freq[inds] <- 1
    unit[inds] <- "year"
  }

  # 1 nr/varannan manad	
  inds <- c(grep("^[0-9]+ nr/vartannat [[:lower:]]+$", x), grep("^[0-9]+ nr/varannan [[:lower:]]+$", x))
  if (length(inds)>0) {
    spl <- strsplit(x[inds], " ")
    freq[inds] <- as.numeric(sapply(spl, function (xi) {xi[[1]]}))/2
    unit[inds] <- sapply(strsplit(x[inds], " "), function (xi) {xi[[length(xi)]]})
  }
  
  # varannan/vartannat ar/manad/vecka
  inds <- c(grep("^vartannat [[:lower:]]+$", x), grep("^varannan [[:lower:]]+$", x))
  if (length(inds)>0) {
    freq[inds] <- .5
    unit[inds] <- sapply(strsplit(x[inds], " "), function (xi) {xi[[2]]})
  }

  # Vartannat eller vart trejde ar
  # Vartannat till vart tredje ar 
  inds <- c(grep("^vartannat [[:lower:]]+ vart 3 [[:lower:]]+$", x),
            grep("^varannan [[:lower:]]+ vart 3 [[:lower:]]+$", x)
       )
  if (length(inds)>0) {
    freq[inds] <- 2.5
    unit[inds] <- sapply(strsplit(x[inds], " "), function (xi) {xi[[length(xi)]]})
  }


  # vart x ar
  inds <- grep("^vart [0-9]+ [[:lower:]]+$", x)
  if (length(inds)>0) {
    x[inds] <- gsub("^vart ", "", x[inds])
    freq[inds] <- 1/as.numeric(sapply(strsplit(x[inds], " "), function (xi) {xi[[1]]}))
    unit[inds] <- sapply(strsplit(x[inds], " "), function (xi) {xi[[2]]})
  }

  # Varje vecka
  inds <- grep("^varje [[:lower:]]+$", x)
  if (length(inds)>0) {
    x[inds] <- gsub("^varje ", "", x[inds])
    freq[inds] <- 1
    unit[inds] <- x[inds]
  }

  # irregular
  inds <- grep("^irregular$", x)
  if (length(inds)>0) {
    freq[inds] <- NA
    unit[inds] <- "Irregular"
  }

  # Misc
  inds <- unique(c(
       	    grep("^oregelbunden$", x),
       	    grep("^sporadisk$", x)
	  ))
  if (length(inds) > 0) {
    freq[inds] <- NA
    unit[inds] <- "Irregular"
  }

  # TODO add these to separate table
  # Special cases
  inds <- which(x == "vart 3 ar-1 nr/ar") # Every second year
  if (length(inds) > 0) {
    freq[inds] <- 1/2
    unit[inds] <- "year"
  }

  if (is.null(x) || is.na(x)) {
    # skip
  } else if (x == "vart 3 till vart 4 ar") {
    freq <- 1/3.5    
    unit <- "year"
  } else if (x == "1 nr/vecka med sommaruppehall, dvs ca 42 nr/ar") {
    freq <- 42
    unit <- "year"
  } else if (x == "1 nr/vecka (april-sept.), 2 nr/m.nad (okt.-mars)") {
    freq <- 26 + 12 
    unit <- "year"
  } else if (x == "1 nr/vecka (april-sept.)") {
    freq <- 26
    unit <- "year"
  } else if (x == "2 nr/m.nad (1 och 4 kvartalet), 1 nr/kvartal (2 och 3 kvartalet)") {
    freq <- 12 + 2
    unit <- "year"
  } else if (x == "11 nr/ar + arsvol") {
    freq <- 12
    unit <- "year"
  } else if (x == "tidigare 1 nr vart 3 ar, nu 1 nr/ar")  {
    freq <- NA
    unit <- "Irregular"
  } else if (x == "2 nr/m.nad ([0-9]+-[0-9]+). 1 nr/m.nad ([0-9]+-[0-9+]?)")  {
    freq <- NA
    unit <- "Irregular"
  } else if (x == "var 3 dag s. l.nge kryssningarna varar")  {
    freq <- 1/3
    unit <- "day"
  }

  # Translate units in English
  unit <- gsub("^ar$", "year", unit)
  unit <- gsub("manaden", "month", unit)
  unit <- gsub("manad", "month", unit)  
  unit <- gsub("man", "month", unit)  
  unit <- gsub("veckor", "week", unit)
  unit <- gsub("vecka", "week", unit)  
  unit <- gsub("dagar", "day", unit)
  unit <- gsub("dag", "day", unit)    

  data.frame(unit = unit, freq = freq)

}







#' @title Polish Publication Frequency Finnish
#' @description Harmonize publication frequencies for Finnish data.
#' @param x publication frequency field (a vector) 1
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{df <- polish_publication_frequency_finnish("Kerran vuodessa")}
#' @keywords utilities
polish_publication_frequency_finnish <- function(x) {

  freq <- rep(NA, length = length(x))
  unit <- rep(NA, length = length(x))  

  # Finnish
  f <- system.file("extdata/numbers_finnish.csv", package = "fennica")
  char2num <- read_mapping(f, sep = ",", mode = "table", from = "character", to = "numeric")
  x <- map(x, synonymes = char2num, from = "character", to = "numeric", mode = "match")

  # yksi-kaksi kertaa/numeroa vuodessa
  inds <- unique(c(
            grep("^[[:lower:]&-]+ kerta+ [[:lower:]]+$", x),
            grep("^[0-9]+-[0-9]+ kerta+ [[:lower:]]+$", x)))
  if (length(inds)>0) {
    x[inds] <- condense_spaces(gsub("kerta+", "", x[inds]))
  }

  # yhdesta kahteen kertaa vuodessa
  inds <- c(grep("^[[:lower:]]+ [[:lower:]]+ kertaa [[:lower:]]+$", x),
            grep("^[0-9]+ *[0-9]* kertaa [[:lower:]]+$", x))
  if (length(inds)>0) {
    x[inds] <- condense_spaces(gsub("kerta+", "", x[inds]))
    n <- sapply(strsplit(x[inds], " "), function (x) {x[-length(x)]})
    freq[inds] <- mean(na.omit(as.numeric(n)))
    unit[inds] <- sapply(strsplit(x[inds], " "), function (xi) {xi[[length(xi)]]})
  }

  # kaksi kertaa vuodessa
  inds <- unique(c(
            grep("^[[:lower:]]+ kerta+ [[:lower:]]+$", x),
            grep("^[0-9]+ kerta+ [[:lower:]]+$", x)	    
	    ))
  if (length(inds)>0) {
    x[inds] <- condense_spaces(gsub("kerta+", "", x[inds]))
  }

  # yksi-kaksi numeroa
  # setting to NA as the interval not given
  # TODO: can be combined with interval or years to calculate frequency
  inds <- unique(c(
            grep("^[[:lower:]&-]+ numero[a]*$", x),
            grep("^[0-9]+-*[0-9]* numero[a]*$", x)))
  if (length(inds)>0) {
    x[inds] <- NA
    freq[inds] <- NA
    unit[inds] <- "Irregular"
  }

  # yksi-kaksi numeroa/numeroa vuodessa
  inds <- unique(c(
            grep("^[[:lower:]&-]+ numero[a]* [[:lower:]]+$", x),
            grep("^[0-9]+-[0-9]+ numero[a]* [[:lower:]]+$", x)))
  if (length(inds)>0) {
    x[inds] <- condense_spaces(gsub("numero[a]*", "", x[inds]))
  }

  # kaksi numeroa/numeroa vuodessa
  inds <- unique(c(
            grep("^[[:lower:]]+ numero[a]* [[:lower:]]+$", x),
            grep("^[0-9]+ numero[a]* [[:lower:]]+$", x)	    
	    ))
  if (length(inds)>0) {
    x[inds] <- condense_spaces(gsub("numero[a]*", "", x[inds]))
  }

  # yksi-kaksi vuodessa
  inds <- unique(c(
            grep("^[[:lower:]&-]+ [[:lower:]]+$", x),
            grep("^[0-9]+-[0-9]+ [[:lower:]]+$", x)))

  if (length(inds)>0) {
    n <- sapply(strsplit(x[inds], " "), function (x) {x[[1]]})
    n <- as.character(n)
    freq[inds] <- sapply(strsplit(n, "-"), function (x) {mean(as.numeric(x))})
    unit[inds] <- sapply(strsplit(x[inds], " "), function (x) {x[[2]]})
  }

  # kaksi vuodessa
  inds <- unique(c(
            grep("^[[:lower:]]+ [[:lower:]]+$", x),
            grep("^[0-9]+ [[:lower:]]+$", x)	    
	    ))
  if (length(inds)>0) {
    n <- sapply(strsplit(x[inds], " "), function (x) {x[[1]]})
    n <- as.character(n)
    freq[inds] <- as.numeric(n)
    unit[inds] <- sapply(strsplit(x[inds], " "), function (x) {x[[2]]})
  }

  # kerran kuussa
  inds <- grep("^kerran [[:lower:]]+$", x)
  if (length(inds)>0) {
    freq[inds] <- 1
    unit[inds] <- gsub("kerran ", "", x[inds])
  }

  # paivittain
  inds <- grep("^p.ivitt.in$", x)
  if (length(inds)>0) {
    freq[inds] <- 1
    unit[inds] <- "day"
  }

  # kuukausittain
  inds <- grep("^kuukausittain$", x)
  if (length(inds)>0) {
    freq[inds] <- 1
    unit[inds] <- "month"
  }

  # viikottain
  inds <- grep("^viiko[i]*ttain$", x)
  if (length(inds)>0) {
    freq[inds] <- 1
    unit[inds] <- "week"
  }

  # vuosittain
  inds <- grep("^vuosittain$", x)
  if (length(inds)>0) {
    freq[inds] <- 1
    unit[inds] <- "year"
  }

  # joka x vuosi
  inds <- grep("^joka [0-9]+ [[:lower:]]+$", x)  
  if (length(inds)>0) {
    x <- gsub("^joka ", "", x)
    n <- sapply(strsplit(x[inds], " "), function (x) {x[[1]]})
    n <- as.character(n)
    freq[inds] <- 1/as.numeric(n)
    unit[inds] <- sapply(strsplit(x[inds], " "), function (x) {x[[2]]})
  }

  # kerran x vuodessa
  inds <- grep("^kerran [0-9]+ [[:lower:]]+$", x)
  if (length(inds)>0) {
    x <- gsub("^kerran ", "", x)
    n <- sapply(strsplit(x[inds], " "), function (x) {x[[1]]})
    freq[inds] <- 1/as.numeric(n)
    unit[inds] <- sapply(strsplit(x[inds], " "), function (x) {x[[2]]}) 
  }

  # Single publication
  inds <- unique(c(
       	    grep("^ilmestynyt vain", x),
       	    grep("^ilmestynyt kerran$", x),
       	    grep("^ilmestynyt 1$", x),	    
       	    grep("^kertajulkaisu$", x)	    	    	    
	  ))
  if (length(inds)>0) {
    freq[inds] <- 1
    unit[inds] <- "Single"
    #x[inds] <- "Single"        
  }

  # Misc
  inds <- unique(c(
       	    grep("^ep.s..nn.llinen$", x),
       	    grep("^ep.s..nn.llisesti$", x),	    
       	    grep("^ilmestymistiheys vaihtelee$", x),
       	    grep("^vaihtelee$", x),
       	    grep("^vaihdellut$", x),
	    # This could be combined with interval to
	    # calculated frequency
       	    grep("^[[:lower:]]+ numeroa$", x)	    
	  ))
  if (length(inds) > 0) {
    freq[inds] <- NA
    unit[inds] <- "Irregular"
    #x[inds] <- "Irregular"    
  }
  
  # Translate units in English
  unit <- gsub("vuodessa", "year", unit)
  unit <- gsub("vuosi", "year", unit)
  unit <- gsub("kuukaudessa", "month", unit)
  unit <- gsub("kuussa", "month", unit)  
  unit <- gsub("kuukausi", "month", unit)
  unit <- gsub("viikossa", "week", unit)
  unit <- gsub("viikko", "week", unit)
  unit <- gsub("paivittain", "day", unit)  
  unit <- gsub("paivassa", "day", unit)
  unit <- gsub("paiva", "day", unit)

  data.frame(unit = unit, freq = freq)

}







geobox <- function (region) {

  if (length(region) == 1 && region == "Europe.main") {
    bbox <- c(-12, 35, 25, 60) # Main Europe with UK
  } else if (length(region) == 1 && region == "Europe.north") {
    bbox <- c(-1, 1, 38, 125) # Northern Europe    
  } else if (length(region) == 1 && region == "Europe") {
    bbox <- c(-15, 35, 30.5, 70) # Europe
  } else if (length(region) == 1 && region == "UK") {
    #bbox <- c(-10.5, 49.5, 2.5, 59) # UK
    bbox <- c(-10.7, 49.7, 2.3, 59) # UK      
  } else if (length(region) == 1 && region == "West") {
    bbox <- c(-120, 25, 30.5, 70) # West  
  } else if (length(region) == 1 && region == "World") {
    bbox <- c(-150, -70, 150, 70) # World
  } else {
    bbox <- region
  }
  names(bbox) <- c("left", "bottom", "right", "top")
  bbox
}


#' @title Read Bibliographic Metadata
#' @description Read metadata parsed from XML.
#' @param file Parsed raw data file/s
#' @param verbose verbose
#' @param sep separator
#' @return data.frame with raw data fields
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{df.raw <- read_bibliographic_metadata(file)}
#' @keywords utilities
read_bibliographic_metadata <- function (file, verbose = FALSE, sep = "|") {

  if (length(file) == 0) {stop("File is empty - halting !")}

  # If there are multiple files, read in a list and combine
  # in the end
  if (length(file) > 1) {

    dfs <- list()
    for (f in file) {
      if (verbose) {message(f)}
      dfs[[f]] <- read_bibliographic_metadata(f)
    }
    if (verbose) {message("Combining the batches..")}    
    df.all <- bind_rows(dfs)
    if (verbose) {message("OK")}    

    # Replace individual identifier columns
    df.all$original_row <- 1:nrow(df.all)

    return(df.all)

  } else {
  
    # Read data
    tab <- read.csv(file, sep = sep, strip.white = TRUE,
    	   		  stringsAsFactors = FALSE, encoding = "UTF-8")

    # Removes additional whitespace and some special characters from
    # beginning and end of strings
    tab <- apply(tab,1:2,function(x){
      x <- gsub("^[[:space:],:;]+","",gsub("[[:space:],:;]+$","",x)) 
    })

    # Convert empty cells to NAs
    tab <- apply(tab, 2, function (x) {y <- x; y[x %in% c(" ", "")] <- NA; y})
  
    # Form data frame
    df <- as.data.frame(tab, stringsAsFactors = FALSE)

    # Pick field clear names
    names.orig <- names(df)
    names(df) <- harmonize_field_names(gsub("^X", "", names(df)))

    if (any(is.na(names(df)))) {
      warnings(paste("Fields", paste(names.orig[which(is.na(names(df)))], collapse = ";"), "not recognized"))
    }

    df <- tibble::as_tibble(df)

    # Add identifier column
    df$original_row <- 1:nrow(df)

    return(df)

  }

}


#' @title Pick multivolume
#' @description Pick volume information for multi-volume documents.
#' @param x Page number field. Vector or factor of strings.
#' @return Volume information
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{pick_multivolume("v.1-3, 293")}
#' @keywords utilities
pick_multivolume <- function (x) {
  
  vols <- NA
  
  if (!is.na(x) && grepl("^[0-9]+ pts in [0-9]+v\\.", x)) {
    x <- gsub("^[0-9]+ pts in ", "", x)
  }
  
  if (!is.na(x) && grepl("^[0-9]+ pts \\([0-9]+ *v\\.*\\)", x)) {
    x <- gsub("^[0-9]+ pts \\(", "", x)
    x <- gsub("\\)", "", x)  
  }
  
  if (!is.na(x) && x == "v.") {
    vols <- 1  
  } else if (!is.na(x) && grepl("^[0-9]* {0,1}v\\.{0,1}$", x)) { 
    vols <- as.numeric(str_trim(gsub("v\\.{0,1}", "", x)))
  } else if (!is.na(x) && grepl("^v\\.", x)) {
    vols <- check_volumes(x)$n  
  } else if (!is.na(x) && grepl("v\\.", x)) {
    vols <- sapply(x, function (xx) {
      s2 <- gsub("v\\.", "SPLITMEHERE", xx)
      s2 <- unlist(strsplit(s2, "SPLITMEHERE"))
      s2 <- s2[s2 != ""]
      as.numeric(s2)
    })
    if (grepl(";", x)) {
      vols <- length(strsplit(x, ";")[[1]])
    }
  }
  
  if (length(vols) == 0) {vols <- NA}
  
  vols
  
}



#' @title Pick Parts
#' @description Pick parts information.
#' @param x physical_extent field. Vector or factor of strings.
#' @return Volume information
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{pick_parts("2 parts")}
#' @keywords utilities
pick_parts <- function (x) {

  parts <- NA

  if (length(grep("^[0-9]* pts", x))>0) {
    # 73 parts -> 73
    parts <- as.numeric(unlist(strsplit(x, " "))[[1]])
  }
  
  if (length(parts) == 0) {parts <- NA}

  parts
  
}




#' @title Pick volume
#' @description Pick volume
#' @param s Page number field. Vector or factor of strings.
#' @return Volume
#' @details A single document, but check which volume 
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{pick_volume("v.4")}
#' @keywords utilities
pick_volume <- function (s) {

  # Pick cases v.1 but not v.1-3
  voln <- NA

  if (length(grep("^v\\.[0-9]+$", s))>0) {
    voln <- gsub("^v\\.", "", s)
  } else if (length(grep("^v\\.[0-9]+-[0-9]+", s)) > 0) {
    # ignore v.7-9
    voln <- NA
  } else if (length(grep("^v\\.[0-9]+", s))>0) {
    voln <- gsub("^v\\.", "", s)
    spl <- as.numeric(unlist(strsplit(voln, ""), use.names = FALSE))
    voln <- substr(voln, 1, min(which(is.na(spl)))-1)
  }
  as.numeric(voln)

}




#' @title Remove Persons
#' @description Remove persons.
#' @param x A vector
#' @param who names to be removed
#' @return Polished vector
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{x2 <- remove_persons(x)}
#' @keywords utilities
remove_persons <- function (x, who = NULL) {

  # Get printing terms from a table
  # TODO later add names from the complete name list as well ?
  if (is.null(who)) {
    f <- system.file("extdata/persons.csv", package = "fennica") 
    terms <- as.character(read.csv(f)[,1])
  }

  x <- remove_terms(x, terms, include.lowercase = TRUE)

  x

}


#' @title Remove Trailing Periods
#' @description Remove trailing periods.
#' @param x A vector
#' @return A polished vector
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{x2 <- remove_trailing_periods(x)}
#' @keywords utilities
remove_trailing_periods <- function (x){ 

  if (all(is.na(x))) {return(x)}
  x <- gsub("\\.+$", "", x)
  x <- gsub("^\\.+", "", x)
    
  x
}




#' @title Remove Terms
#' @description Remove the given terms from the strings.
#' @param x A vector
#' @param terms Terms to be removed
#' @param where Locations to be removed ("all" / "begin" / "middle" / "end")
#' @param include.lowercase Include also lowercase versions of the terms
#' @param polish polish the entries after removing the terms (remove trailing spaces and periods)
#' @param recursive Apply the changes recursively along the list ?
#' @return Vector with terms removed
#' @details After removing the numerics, beginning, double and ending 
#'          spaces are also removed from the strings.
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples x2 <- remove_terms("test this", c("this", "works"), where = "all")
#' @keywords utilities
remove_terms <- function (x, terms, where = "all", include.lowercase = FALSE, polish = TRUE, recursive = FALSE) {

  # If removal is recursive, then go through the list as is in the given order
  # otherwise, optionally include lowercase, remove unique terms and sort by length 
  if (!recursive) {

    # Add lowercase versions
    if (include.lowercase) {
      terms <- c(terms, tolower(terms))
    }

    # List all unique terms
    terms <- sort(unique(terms))

    # Go from longest to shortest term to avoid nested effects
    terms <- terms[rev(order(sapply(terms, nchar, USE.NAMES = FALSE)))]
    
  }
  
  tmp <- matrix(sapply(terms, function (term) grepl(term, x), USE.NAMES = FALSE),
                  ncol = length(terms))

  for (i in 1:length(terms)) {
    if (any(tmp[, i])) {
      x[tmp[, i]] <- remove_terms_help(x[tmp[, i]], terms[[i]], where)
    }
  }
  
  if (polish) {
    x <- condense_spaces(x)
    x <- remove_trailing_periods(x)
  }
  
  x 

}



remove_terms_help <- function (x, term, where) {

    # remove elements that are identical with the term		   
    x[x == term] = ""

    # Speedup: return if all handled already
    if (all(x == "")) {return(x)}
    
    # Here no spaces around the term needed, elsewhere yes
    if ("all" %in% where) {

      # begin
      rms <- paste("^", term, "[ |\\.|\\,]", sep = "")
      x <- gsub(rms, " ", x)

      # middle
      x <- gsub(paste(" ", term, "[ |\\.|\\,]", sep = ""), " ", x)

      # end
      rms <- paste(" ", term, "$", sep = "")
      x <- gsub(rms, " ", x)
    }

    if ("full" %in% where) {
    
      x <- gsub(term, " ", x)

    }

    if ("begin" %in% where) {
    
      rms <- paste("^", term, "[ |\\.|\\,]", sep = "")
      x <- gsub(rms, " ", x)

    }

    if ("middle" %in% where) {
    
      x <- gsub(paste(" ", term, "[ |\\.|\\,]", sep = ""), " ", x)

    }

    if ("end" %in% where) {

      rms <- paste(" ", term, "$", sep = "")
      x <- gsub(rms, " ", x)

    }
    
    x
    
}







#' @title Condense Spaces
#' @description Trim and remove double spaces from the input strings.
#' @param x A vector
#' @importFrom stringr str_trim
#' @return A vector with extra spaces removed
#' @details Beginning, double and ending spaces are also removed from the strings.
#' @export 
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples x2 <- condense_spaces(" a  b cd ") # "a b cd"
#' @keywords utilities
condense_spaces <- function (x) {

  x <- str_trim(x, "both")
  x <- gsub(" +", " ", x)
  x[x == ""] <- NA
   
  x

}



#' @title Remove Brackets from Letters
#' @description Remove brackets surrounding letters.
#' @param x A vector
#' @param myletters Letters to remove
#' @return A polished vector 
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples x2 <- remove_brackets_from_letters("[p]")
#' @keywords utilities
remove_brackets_from_letters <- function (x, myletters = NULL) {

  if (is.null(myletters)) {myletters <- c(letters, LETTERS)}

  # [P] -> P
  for (l in myletters) {
    x <- gsub(paste("\\[", l, "\\]", sep = ""), l, x)
    x <- gsub(paste("\\(", l, "\\)", sep = ""), l, x)
  }   
  x

}

#' @title Harmonize ie
#' @description Harmonize ie statements.
#' @param x A vector
#' @param separator The separator string (i.e by default)
#' @return A vector polished
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{x2 <- harmonize_ie("i.e.")}
#' @keywords utilities
harmonize_ie <- function (x, separator = "i.e") {

  # Harmonized form
  h <- " i.e "

  x <- tolower(as.character(x))
  x <- condense_spaces(x)
  x <- gsub("-+", "-", x)

  x <- gsub("\\[oik[\\.]*", "[i.e ", x)
  x <- gsub("p\\.o\\.", " i.e ", x) # Finnish: pitaisi olla
  x <- gsub("p\\.o ", " i.e ", x) # Finnish: pitaisi olla  
  x <- gsub("\\[po[\\.]*", " i.e ", x) # Finnish: pitaisi olla  
  
  x <- gsub(" ie ", " i.e ", x)  
  x <- gsub("\\[ie ", "[i.e ", x)
  x <- gsub("\\[i\\. *e\\.* ", "[i.e ", x)
  x <- gsub("\\[i *e\\.* ", "[i.e ", x)
  x <- gsub("\\[i\\.e\\.* ", "[i.e ", x)      
  x <- gsub("^ie ", "i.e ", x)
  x <- gsub("i\\.e\\.*, ", "i.e ", x)      

  x <- gsub("\\,* +i\\.* *e+ *[\\.|\\,]*", h, x)

  x <- gsub("\\[* +i\\.* *e+ *[\\.|\\,]*", h, x)

  x <- gsub("^\\,* *i\\.* *e+ *[\\.|\\,]*", h, x)

  x <- gsub(" +i\\.* *e+ *[\\.|\\,]*", h, x)

  x <- gsub("p\\. i\\.* *e+ *[\\.|\\,]*", h, x) 
  x <- gsub("^p\\. i\\.* *e+ *[\\.|\\,]*", h, x)
  x <- gsub("\\[ *", "\\[", x)
  x <- gsub("^\\. *", "", x)

  x <- condense_spaces(x)

  x

}




#' @title Pick Last Name
#' @description Pick last name from full name, assuming the format is known 
#' @param x a vector of full names
#' @param format name format
#' @param keep.single If the name is without comma ('Shakespeare,
#'  William' versus 'William'), interpret the name as first name.
#'  Note that in this case also 'Shakespeare' will be interpreted as first name.
#'  In the current implementation keep.single is always TRUE.
#' @return a vector of last names
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples pick_lastname("Hobbes, Thomas")
#' @keywords utilities
pick_lastname <- function (x, format = "last, first", keep.single = TRUE) {

  x <- as.character(x)

  if (format == "last, first") {
    last <- sapply(x, function (x) {y <- unlist(strsplit(x, ", "), use.names = FALSE); if (length(y)>=1) y[[1]] else NA}, USE.NAMES = FALSE) 
  } else if (format == "first last") {
    last <- sapply(x, function (x) {y <- unlist(strsplit(x, " "), use.names = FALSE); y[[length(y)]]}, USE.NAMES = FALSE)
  } else {
    stop("Correct the unknown format in pick_lastname function.")
  }

  # Remove possible life year info
  last <- gsub(" \\([0-9|N|A]+-[0-9|N|A]+\\)", "", last)

  last

}

#' @title Remove Time Info
#' @description Remove time information.
#' @param x Vector (time field)
#' @param verbose verbose
#' @param months months to remove
#' @return Polished vector
#' @export
#' @details Remove months, year terms and numerics
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{x2 <- remove_time_info(x)}
#' @keywords utilities
remove_time_info <- function (x, verbose = FALSE, months = NULL) {

  if (is.null(months)) {
    f <- "months.csv"
    months <- as.character(read.csv(f, header = TRUE)[,1])
    months <- unique(c(months, tolower(months)))

    # Handle from longest to shortest to avoid problems
    months <- months[rev(order(nchar(months)))]
  }

  # 17th century 
  x <- condense_spaces(gsub("[0-9]*th century", " ", x))

  # July 8
  for (month in months) {

    # "march-1777"
    s <- paste0(month, "-")
    if (verbose) { message(paste("Removing", s)) }
    x <- gsub(s, " ", x)    

    # "17 or 18 February"
    s <- paste("[0-9]{1,2} or [0-9]{1,2} ", month, sep = "")
    if (verbose) {message(paste("Removing", s))}    
    x <- gsub(s, " ", x)    

    # " 17 February"
    s <- paste(" [0-9]{1,2} ", month, sep = "")
    if (verbose) {message(paste("Removing", s))}    
    x <- gsub(s, " ", x)

    # "[17 February"
    s <- paste("\\[[0-9]{1,2} ", month, sep = "")
    if (verbose) {message(paste("Removing", s))}    
    x <- gsub(s, " ", x)

    # "^17 February"
    s <- paste("^[0-9]{1,2} ", month, sep = "")
    if (verbose) {message(paste("Removing", s))}    
    x <- gsub(s, " ", x)

    s <- paste(month, " [0-9]{1,2} ", sep = "")
    s2 <- paste(month, " [0-9]{1,2}\\]", sep = "")    
    s3 <- paste(month, " [0-9]{1,2}$", sep = "")
    s4 <- paste(month, " [0-9]{1,2}\\,", sep = "")
    s5 <- paste(month, "\\, [0-9]{1,2}", sep = "")            
    if (verbose) {message(paste("Removing", s))}
    x <- gsub(s, " ", x)
    if (verbose) {message(paste("Removing", s2))}    
    x <- gsub(s2, " ", x)
    if (verbose) {message(paste("Removing", s3))}    
    x <- gsub(s3, " ", x)
    if (verbose) {message(paste("Removing", s4))}    
    x <- gsub(s4, " ", x)
    if (verbose) {message(paste("Removing", s5))}    
    x <- gsub(s5, " ", x)                

  }

  # other time information
  terms <- c("Anno\\.", "An\\. Do\\.", "year", "anno dom", "anno")
  toremove <- c(months, terms)

  x <- remove_terms(x, toremove)

  x

}






#' @title Remove Dimension Data
#' @description Remove dimension data.
#' @param x A character vector that may contain dimension information
#' @return The character vector with dimension information removed
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples # remove_dimension("4to 40cm", sheet_sizes())
#' @keywords internal
remove_dimension <- function (x, terms) {

  # Go from longest to shortest term to avoid nested effects
  terms <- terms[rev(order(sapply(unique(terms), nchar, USE.NAMES = FALSE)))]

  x[x %in% terms] <- " "

  for (term in terms) {

    inds <- grep(term, x)

    if (length(inds) > 0) {

      # begin
      rms <- paste("^", term, "[ |\\.|\\,]", sep = "")
      x[inds] <- gsub(rms, " ", x[inds])

      # middle
      x[inds] <- gsub(paste(" ", term, "[ |\\.|\\,]", sep = ""), " ", x[inds])

      # all
      rms <- paste(" ", term, "$", sep = "")
      x[inds] <- gsub(rms, " ", x[inds])

    }
    
  }

  x <- condense_spaces(x)
  inds <- which(!x == "v.") # Exclude ^v.$ as a special case
  if (length(inds) > 0) { 
    x[inds] <- remove_trailing_periods(x[inds])
  }

  x[x == ""] <- NA
  
  x

}


read_sysfile <- function (f0, pkg) {

  f <- system.file(f0, package = pkg)
  if (f == "") {
    f <- system.file(paste0("inst/", f0), package = pkg)
  }
  print(f)

  f
}


harmonize_volume <- function (x, verbose = FALSE, vol.synonyms = NULL) {

  if (is.null(vol.synonyms)) {
    f <- system.file("extdata/harmonize_volume.csv", package = "fennica")
    if (f == "") {
      f <- system.file("inst/extdata/harmonize_volume.csv", package = "fennica")
    }
    vol.synonyms <- read_mapping(f, sep = ";", mode = "table")  
  }

  if (verbose) {message("Initial harmonization")}
  s <- condense_spaces(x)
  s[grep("^v {0,1}[:|;]$", s)] <- "v"  
  s[s %in% c("v\\. ;", "v\\.:bill\\. ;")] <- NA  

  # FIXME can we put this in synonymes
  s <- gsub("vols*\\.", "v.", s)

  # FIXME list in separate file
  if (verbose) {message("Synonymous terms")}
  s <- map(s, vol.synonyms, mode = "match")
  s <- condense_spaces(s)

  # FIXME these should be done via synonyme list ?
  if (verbose) {message("Volume terms")}

  s <- gsub("\\(\\?\\) v\\.", "v.", s)
  s <- gsub("^vol\\.", "v. ", s)
  s <- gsub("\ *vol\\.{0,1} {0,1}$", " v. ", s)
  s <- gsub("\ *vol\\.", "v. ", s)
  s <- gsub(" vol\\.* *;*", "v. ", s)
  s <- gsub(" vol;", "v. ", s)      
  s <- gsub("^v\\.\\(", "(", s)
  s <- gsub(" v {0,1}$", "v. ", s)
  s <- condense_spaces(s)

  # "65,2v " -> "67v"
  inds <- grep("^[0-9]+,[0-9] *v", s)
  if (length(inds) > 0) {
    s[inds] <- sapply(s[inds], function (x) {vol_helper4(x)})
  }

  # "2 v " -> "2v"
  inds <- grep("^[0-9]+ v", s)
  if (length(inds) > 0) {
    s[inds] <- sapply(s[inds], function (x) {vol_helper3(x)})
  }

  # "2v " -> "2v."
  inds <- grep("^[0-9]+v[ |,]+", s)
  if (length(inds) > 0) {
    s[inds] <- sapply(s[inds], function (x) {vol_helper(x)})
  }

  inds <- grep("^[0-9]v\\(", s)
  if (length(inds) > 0) {
    s[inds] <- gsub("v\\(", "v.(", s[inds])
  }

  s <- sapply(s, function (si) {gsub("^[0-9]+ *v$", paste0(gsub("v$", "", si), "v."), si)}, USE.NAMES = FALSE)

  s <- gsub(" v\\. ", "v\\.", s)

  inds <- grep("^v.[0-9]+,[0-9]+", s)
  if (length(inds) > 0) {
    s[inds] <- sapply(s[inds], function (x) {vol_helper2(x)})
  }

  s

}


vol_helper <- function (s) {

     s <- gsub("v,", "v ,", s)

     spl <- unlist(strsplit(s, " "), use.names = FALSE)

     spl[[1]] <- gsub("v", "v.", spl[[1]])

     s <- spl
     
     if (length(spl) > 1) {     
       s <- paste(spl[1:2], collapse = "")   
     }

     if (length(spl) > 2) {
       s <- paste(s, paste(spl[3:length(spl)], collapse = " "), collapse = "")
     }

  s
}



vol_helper3 <- function (s) {

  # TODO could be combined with vol_helper to speed up	    

     spl <- unlist(strsplit(s, " "), use.names = FALSE)

     s <- spl
     
     if (length(spl) > 1) {     
       s <- paste(spl[1:2], collapse = "")   
     }

     if (length(spl) > 2) {
       s <- paste(s, paste(spl[3:length(spl)], collapse = " "), collapse = "")
     }

  s
}


vol_helper2 <- function (s) {
    spl <- unlist(strsplit(s, ","), use.names = FALSE)
    s <- paste(spl[[1]], "-", spl[-1], sep = "")
    s
}

vol_helper4 <- function (s) {
    spl <- unlist(strsplit(s, ","), use.names = FALSE)
    n1 <- as.numeric(spl[[1]])
    n2 <- as.numeric(pick_starting_numeric(spl[[2]]))
    spl[[2]] <- gsub("^[0-9]*", "", spl[[2]])
    rest <- spl[[2]]
    if (length(spl)>2) {
      rest <- paste(rest, spl[3:length(spl)], sep = ",")
    }
    s <- paste(n1+n2, "", rest, sep = "")
    s
}

#' @title Polish signature statements
#' @description Internal
#' @param s input char
#' @return vector
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See explanations of signature statements in \url{https://collation.folger.edu/2016/05/signature-statements/} and \url{https://manual.stcv.be/p/Inputting_Collation_Data_in_Brocade}.
#' @keywords internal
polish_signature_statements <- function (x) {

    require(stringr)

    x <- str_trim(x)
    
    x <- str_trim(gsub("\\([a-z|0-9|,| |\\?]*\\)", "", x))

    x <- unlist(stringr::str_split(x, " "))

    # Pages for all items
    pages <- unlist(sapply(x, function (xx) {polish_signature_statement(xx)}))

    pages

}


polish_signature_statement <- function (s) {

    require(stringr)

    hit <- any(grepl("[a-z]*?sup?[0-9]*?[a-z]*?", s))
    pages <- NA

    if (hit) {
      item <- str_extract(s, "^[a-z|0-9|-]*")     
      pages <- str_extract(s, "[0-9]+")
      pages <- as.numeric(pages)
      names(pages) <- item

      if (str_detect(item, "-")) {
        items <- unlist(stringr::str_split(item, "-"))

	ind1 <- match(items[[1]], letters)
	ind2 <- match(items[[2]], letters)
	if (!is.na(ind1) & !is.na(ind2)) {
          items <- letters[ind1:ind2]
          pages <- rep(pages, length(items))
          names(pages) <- items
	} else {
	  pages <- NA
	}
      }
    }
    
    pages

}






harmonize_christian <- function (x) {

  x <- str_trim(as.character(x))
  
  x <- gsub("anno dom\\.", " ", x)
  x <- gsub("an\\. dom\\.", " ", x)  
  x <- gsub("anno domini", " ", x)    
  x <- gsub("a\\.d\\.", " ", x)
  x <- gsub("ad", " ", x)  
  x <- gsub("A\\.D", " ", x) # redundant
  x <- gsub("anno d⁻ni", " ", x)
  x <- gsub("anno dñi", " ", x)
  x <- gsub("domini", " ", x)   

  x <- gsub("bc", "B.C", x)
  x <- gsub("b\\.c\\.", "B.C", x)  
  x <- gsub("b\\.c\\.", "before christian era", x)  
  x <- gsub("before christian era", "B.C", x)

  # Remove space
  x <- gsub(" B\\.C", "B.C", x)
  x <- condense_spaces(x)

  x
}

#' @title Handle ie
#' @description Handle ie statements.
#' @param x Character vector
#' @param harmonize Logical. Harmonize ie statements efore interpretation?
#' @param separator The separator string (i.e by default)
#' @return A vector polished
#' @importFrom stringr str_sub
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{x2 <- handle_ie("i.e.")}
#' @export
#' @keywords utilities
handle_ie <- function (x, harmonize = TRUE, separator = "i.e") {

  # 183 i.e 297 -> 297	  
  # 183-285 i.e 297 -> 183-297	  
  # 183-285 [i.e 297] -> 183-297
  # 183-285 i.e 297-299 -> 297-299

  y <- x

  if (harmonize) {
    y <- x <- harmonize_ie(y, separator = separator)
  }
  x <- condense_spaces(x)

  if (length(x) == 1 && (is.na(x) || x == separator)) {return(x)}

  # z [i.e y] -> y
  if (length(grep("[0-9|a-z]*\\.* \\[i\\.e [0-9|a-z]*\\]", x))>0) {

    # This is for "1905 [ie. 15]" -> 1915
    spl <- strsplit(x, " \\[i\\.e ")
    x1 <- sapply(spl, function (x) {x[[1]]})
    x2 <- gsub("\\]", "", sapply(spl, function (x) {x[[2]]}))
    inds <- which(nchar(x1) == 4 & nchar(x2) == 2)
    x[inds] <- sapply(inds, function (ind) {paste(substr(x1[[ind]], 1, 2), x2[[ind]], sep = "")})

    x <- gsub("^[0-9|a-z]*\\.* \\[i\\.e", "", x)

    x <- gsub("\\]$", "", x)
    
  }


  # "[1-3] 4-43 [44-45] 45-51 [i.e 46-52]"
  # keep the first part and just remove "45-51 ie"
  if (length(grep("[0-9]+-[0-9]+ i\\.e [0-9]+-[0-9]+", x)) == 1) {
    spl <- unlist(strsplit(x, " "), use.names = FALSE)    
    rmind <- which(spl == "i.e")
    rmind <- (rmind-1):rmind
    x <- paste(spl[-rmind], collapse = " ")
  }

  # " p 113-111 i.e 128] " -> 113-128
  if (length(grep("-[0-9]+ i\\.e [0-9]+", x)) == 1) {
    spl <- unlist(strsplit(x, "-"), use.names = FALSE)
    spl <- sapply(spl, function (spli) {handle_ie(spli)})
    x <- paste(spl, collapse = "-")
  }

  if (length(grep("-", x)) > 0 && length(grep("i\\.e", x)) > 0) {

    spl <- unlist(strsplit(x, "i\\.e"), use.names = FALSE)

    if (length(grep("-", spl)) == 2) {
      # 1-3 ie 2-4 -> 2-4
      x <- spl[[2]]
    } else {
    
      # [1658]-1659 [i.e. 1660] -> 1658-1660
      spl <- unlist(strsplit(x, "-"), use.names = FALSE)
      u <- sapply(spl, function (s) {handle_ie(s)}, USE.NAMES = FALSE)
      x <- paste(u, collapse = "-")
    }
    
  } else if (length(grep("\\[[0-9|a-z]* *i\\.e [0-9|a-z]*\\]", x))>0) {
  
    # z [x i.e y] -> z [y]  
    x <- unlist(strsplit(x, "\\["), use.names = FALSE)
    inds <- grep("i\\.e", x)
    u <- unlist(strsplit(x[inds], "i\\.e"), use.names = FALSE)
    x[inds] <- u[[min(2, length(u))]]
    x <- paste(x, collapse = "[")
    
  } else if (length(grep(" i\\.e ", x))>0) {
  
    # x i.e y -> y
    x <- unlist(strsplit(x, "i\\.e"), use.names = FALSE)
    x <- x[[min(2, length(x))]]
    
  } else if (length(grep("\\[i\\.e", x))>0) {
  
    # x [i.e y] -> y
    x <- unlist(strsplit(x, "\\[i\\.e"), use.names = FALSE)
    x <- x[[min(2, length(x))]]
    x <- gsub("\\]*$", "", x)
    
  } else if (length(grep("\\[[0-9|a-z]* i\\.e [0-9|a-z]*\\]", x))>0) {
    # "mdcxli [1641 i.e 1642]" -> mdcxli [1642]
    x <- unlist(strsplit(x, "\\["), use.names = FALSE)
    inds <- grep("i\\.e", x)    
    x[inds] <- handle_ie(x[inds])
    x <- paste(x, collapse = "[")
    
  }

  x <- gsub("\\[ ", "[", x)
  x <- gsub("^\\.*", "", x)  
  x <- str_trim(x)

  x
}


christian2numeric <- function (x) {
  
  inds <- grep("a.d", x)
  if (length(inds) > 0) {
    x[inds] <- as.numeric(str_trim(gsub("a.d", "", x[inds])))
  }
  
  inds <- grep("b.c", x)
  if (length(inds) > 0) {
    x[inds] <- -as.numeric(str_trim(gsub("b.c", "", x[inds])))
  }
  
  return(x)
}




#' @title Pick First Name
#' @description Pick first name from full name, assuming the format is known 
#' @param x a vector of full names
#' @param format name format
#' @param keep.single If the name is without comma ('Shakespeare,
#'  William' versus 'William'), interpret the name as first name.
#'  Note that in this case also 'Shakespeare' will be interpreted as first name.
#' @return a vector of first names
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples pick_firstname("Hobbes, Thomas")
#' @keywords utilities
pick_firstname <- function (x, format = "last, first", keep.single = FALSE) {

  xorig <- as.character(x)
  xuniq <- unique(xorig)
  x <- xuniq

  if (format == "last, first") {
    first <- sapply(x, function (x) {y <- unlist(strsplit(x, ", "), use.names = FALSE); if (length(y)>1) y[[2]] else if (keep.single) {y[[1]]} else {NA} }, USE.NAMES = FALSE)
  } else if (format == "first last") {
    first <- sapply(x, function (x) {unlist(strsplit(x, " "), use.names = FALSE)[[1]]}, USE.NAMES = FALSE)
  } else {
    stop("Correct the unknown format in pick_firstname function.")
  }

  # Remove possible life year info
  first <- gsub(" \\([0-9|N|A]+-[0-9|N|A]+\\)", "", first)
  first <- condense_spaces(first)

  first[match(xorig, xuniq)]

}






is.roman <- function (x) {

  x <- gsub("\\.", NA, x)

  check.roman <- function (x) {

    if (x == "" || is.na(x)) {return(FALSE)}

    xs <- unlist(strsplit(x, "-"), use.names = FALSE)
    isr <- c()

    for (i in 1:length(xs)) {  
      x <- xs[[i]]
      tmp <- suppressWarnings(as.numeric(x))
      tmp2 <- suppressWarnings(as.numeric(as.roman(x)))
      not.numeric <- length(na.omit(tmp)) > 0
      roman.numeric <- is.numeric(tmp2)

      isr[[i]] <- !(not.numeric && roman.numeric) && !is.na(tmp2) 
    }
    # iii-7 TRUE; iii-iv TRUE; 4-7 FALSE
    any(isr)
  }

  sapply(x, check.roman, USE.NAMES = FALSE)

}




roman2arabic <- function (x) {

  if (length(grep("vj", x)) == 1) {
    x <- gsub("j", "i", x)
  }

  helpf <- function(xi) {

    # Return numeric hits immediately (such as "4387")
    if (grepl("^[0-9]+$", xi)) {
      xr <- xi
    } else if (length(grep("-", xi)) > 0) {
      x2 <- str_trim(unlist(strsplit(xi, "-"), use.names = FALSE))
      n <- suppressWarnings(as.numeric(as.roman(x2)))
      n[is.na(n)] <- x2[is.na(n)] # vii-160
      xr <- paste(n, collapse = "-")
    } else {
      xr <- suppressWarnings(as.numeric(as.roman(xi)))
    }
    xr
  }

  sapply(x, function (xi) {helpf(xi)}, USE.NAMES = FALSE)

}




#' @title Pick Substring Indicated by Separator
#' @description Split the string by separator and pick the former or latter part.
#' @param x Input string
#' @param sep Separator string
#' @param which Indicate which part to pick
#' @return Polished string
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples x2 <- splitpick("London re Edinburgh", " re ", 1)
#' @keywords utilities
splitpick <- function (x, sep, which) {
  # london re edinburgh -> london
  inds <- grep(sep, x)
  if (length(inds) > 0) {
    spl <- unlist(strsplit(x[inds], sep), use.names = FALSE)
    x[inds] <- spl[[which]]
  }

  x
  
}


#' @title Remove Print Statements
#' @description Remove print statements.
#' @param x a vector
#' @return Polished vector
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples x2 <- remove_print_statements("Printed in London")
#' @keywords utilities
remove_print_statements <- function (x) {

  x0 = xorig <- tolower(as.character(x))
  xuniq <- unique(xorig)
  x <- xuniq

  terms.single = c()
  terms.multi = c()  

  ### Get printing terms from tables in various languages
  for (lang in c("finnish", "french", "german", "swedish", "english")) {

    f <- system.file(paste0("extdata/printstop_", lang, ".csv"), package = "fennica")
    terms <- unique(str_trim(tolower(read.csv(f, stringsAsFactors = FALSE)[,1])))

    # Harmonize the terms 
    terms.multi <- c(terms.multi, terms[nchar(terms) > 1])
    terms.single <- c(terms.single, terms[nchar(terms) == 1])

  }

  terms.multi = unique(terms.multi)
  terms.single = unique(terms.single)  

  x <- remove_terms(x, terms.multi, where = "all", polish = FALSE, include.lowercase = FALSE)
  x <- condense_spaces(x)

  # Back to original indices, then unique again; reduces
  # number of unique cases further
  xorig <- x[match(xorig, xuniq)]
  x <- xuniq <- unique(xorig)

  # Individual characters not removed from the end
  x <- remove_terms(x, terms.single, where = "begin", polish = FALSE, include.lowercase = FALSE)

  # Back to original indices, then unique again; reduces
  # number of unique cases further
  xorig <- x[match(xorig, xuniq)]
  x <- xuniq <- unique(xorig)

  x <- remove_terms(x, terms.single, where = "middle", polish = FALSE, include.lowercase = FALSE)
  x <- condense_spaces(x)
  x <- remove_trailing_periods(x)

  # Back to original indices, then unique again; reduces
  # number of unique cases further
  xorig <- x[match(xorig, xuniq)]
  x <- xuniq <- unique(xorig)

  # remove sine loco
  f <- system.file("extdata/sl.csv", package = "fennica") 
  sineloco <- as.character(read.csv(f)[,1])
  x <- remove_terms(x, sineloco, include.lowercase = TRUE)

  # Back to original indices, then unique again; reduces
  # number of unique cases further
  xorig <- x[match(xorig, xuniq)]
  x <- xuniq <- unique(xorig)

  # handle some odd cases manually
  # FIXME: estc-specific, move there
  # "122 s"; "2 p"
  x[grep("^[0-9]* [s|p]$", x)] <- NA
  x <- gsub("[0-9]\\. p\\.;","",x)
  x <- gsub("^(.*?);.*$","\\1",x) # nb. non-greedy match
  x[x==""] <- NA

  x = x[match(xorig, xuniq)]
  
  x
}




harmonize_sheets <- function (s, harm) {
  
  if (length(grep("[0-9]leaf", s))>0) {
    s <- gsub("leaf", " leaf", s)
  }

  # Harmonize
  s <- as.character(map(s, harm, mode = "recursive"))

  # Harmonize '* sheets'
  sheet.inds <- grep("sheet", s)
  s[sheet.inds] <- sapply(s[sheet.inds], function (si) {harmonize_sheets_help(si)})

  # Move into sheet synonyme table (had some problems hence here for now) ?
  s <- gsub("leaf", "sheet", s)
  s <- gsub("leave", "sheet", s)     
  s <- gsub("^1 sheets$", "1 sheet", s)
  s <- gsub("^sheet$", "1 sheet", s)
  s <- gsub("^sheets$", "2 sheets", s)
  s <- gsub("1 leaf \\(\\[2\\]p\\.\\)", "1 sheet", s)

  s <- condense_spaces(s)

  s 

}



harmonize_sheets_help <- function (s) {

  spl <- unlist(strsplit(s, ","))

  for (i in 1:length(spl)) {

    #if (length(grep("^[0-9] sheet", spl[[i]])) > 0) {
    #  xxx <- unlist(strsplit(spl[[i]], "sheet"), use.names = FALSE)
    #  n <- as.numeric(str_trim(xxx[[1]]))
    #  spl[[i]] <- paste(n, "sheets", sep = " ")
    #}

    if (length(grep("\\[^[0-9]|[a-z]\\] sheets", spl[[i]])) > 0) {
      xxx <- unlist(strsplit(spl[[i]], "sheet"), use.names = FALSE)
      n <- as.numeric(as.roman(str_trim(gsub("\\[", "", gsub("\\]", "", xxx[[1]])))))
      spl[[i]] <- paste(n, "sheets", sep = " ")
    }

  }

  # Combine again
  s <- paste(spl, collapse = ",")

  s
}

#' @title Remove s.l etc. clauses
#' @description Remove s.l etc. clauses 
#' @param x A character vector
#' @param terms Terms to be removed (a character vector). Optional
#' @return Polished vector
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples x2 <- remove_sl(c("s.l.", "London"))
#' @keywords utilities
remove_sl <- function (x, terms = NULL) {

  # Will requires serious rethinking with these stupid hacks.

  # Get printing terms from a table
  if (is.null(terms)) {
    f <- system.file("extdata/sl.csv", package = "fennica") 
    terms <- as.character(read.csv(f)[,1])
  }

  x <- remove_terms(x, terms, include.lowercase = FALSE)

  x <- gsub("\\[s.n.\\?\\]", NA, x)
  x <- gsub("\\[s.n.\\]", NA, x)
  x <- gsub("\\[s. n.\\]", NA, x)    
  x <- gsub("s. a", NA, x)
  x <- gsub("s i", NA, x)    

  x

}

#' @title Validate Names
#' @description Validation for names.
#' @param df.preprocessed Preprocessed data.frame.
#' @return Modified data.frame
#' @export
#' @author Ville Vaara and Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples # \dontrun{validate_names(df.preprocessed)}
#' @keywords utilities
validate_names <- function(df.preprocessed) {

  message("Validate author names. Set non-valid names to NA")

  # Some basic validation
  # "V. P" -> NA
  df.preprocessed$author_name[grep("^[A-Z|a-z][\\.|\\,]+ *[A-Z|a-z]$", df.preprocessed$author_name)] <- NA

  # "V. P. H" -> NA
  df.preprocessed$author_name[grep("^[A-Z|a-z][\\.|\\,]+ *[A-Z|a-z][\\.|\\,]+ *[A-Z|a-z][\\.|\\,]*$", df.preprocessed$author_name)] <- NA

  # "V P" -> NA
  df.preprocessed$author_name[grep("^[A-Z|a-z] +[A-Z|a-z]$", df.preprocessed$author_name)] <- NA

  # "V P H" -> NA
  df.preprocessed$author_name[grep("^[A-Z|a-z] +[A-Z|a-z] +[A-Z|a-z]$", df.preprocessed$author_name)] <- NA

  return (df.preprocessed)
}

# -----------------------------------------------------------------

# Author name validation with ready made lists is rather time-consuming
# Hence skip

#v <- validate_names(df.preprocessed$author_name, "full")
#discard.inds <- !v$valid
  
## Save discarded names for later analysis
#discarded.author.table <- rev(sort(table(as.character(df.preprocessed$author[discard.inds]))))
#discarded.author.firstnames <- v$invalid.first
#discarded.author.lastnames <- v$invalid.last  

## Remove discarded names from the list
# df.preprocessed$author_name[discard.inds] <- NA

# -----------------------------------------------------------------


#' @title Enrich Author Field
#' @description Enrich author field.
#' @param df Preprocessed data.frame
#' @return Augmented data.frame
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{df2 <- enrich_authoragecount(df)}
#' @keywords utilities
enrich_author <- function(df) {

  message("Enriching author fields..")

    # Custom table toaAugmen missing life years
    life.info <- read.csv(system.file("extdata/author_info.csv", package = "fennica"), stringsAsFactors = FALSE, sep = "\t")

    # Custom table to harmonize multiple author name variants
    f <- system.file("extdata/ambiguous-authors.csv", package = "fennica")
    ambiguous.authors <- read_mapping(f, mode = "list", sep = ";", self.match = FALSE, include.lowercase = FALSE, fast = TRUE)
    
    # Combine synonymous authors; augment author life years where missing etc.
    aa <- augment_author(df, life.info, ambiguous.authors)

    df <- aa
    rm(aa)

  # -------------------------------------------------------------------

  # TODO improve: many names are missing gender;
  # and time variation in name-gender mappings not counted
  message("Add estimated author genders")
  # Filter out names that are not in our input data
  # (this may speed up a bit)
  first.names <- pick_firstname(df$author_name, format = "last, first", keep.single = TRUE)

  # First use gender mappings from the ready-made table
  if (!exists("gendermap.file") || is.null(gendermap.file)) {
    gendermap.file = system.file("extdata/gendermap.csv", package = "fennica")
  }
  gendermap <- read_mapping(gendermap.file, sep = "\t", from = "name", to = "gender")
  df$author_gender <- get_gender(first.names, gendermap)

  message("Custom name-gender mappings to resolve ambiguous cases")
  # Consider the custom table as primary  
  # ie override other matchings with it
  custom <- gender_custom()
  g <- get_gender(first.names, custom)
  inds <- which(!is.na(g))
  df$author_gender[inds] <- g[inds]

  message("Add genders from the generic author info custom table")
  tab <- read.csv(system.file("extdata/author_info.csv", package = "fennica"), sep = "\t")
  g <- map(df$author_name, tab, from = "author_name", to = "author_gender", remove.unknown = TRUE)
  inds <- which(!is.na(g))
  df$author_gender[inds] <- g[inds]

  # Author life - make sure this is in numeric format
  df$author_birth <- as.numeric(as.character(df$author_birth))
  df$author_death <- as.numeric(as.character(df$author_death))  

  message("Author age on the publication year, when both info are available")
  inds <- which(df$publication_year_from < df$author_death & !is.na(df$author_birth))
  df$author_age <- rep(NA, nrow(df))
  df$author_age[inds] <- df$publication_year_from[inds] - df$author_birth[inds]
  # Remove negative author ages
  # FIXME: taking these to the final summaries could help to spot errors
  # df$author_age[df$author_age < 0] <- NA

  return (df)

}

#' @title Augment Author Info
#' @description Estimate missing entries in author info.
#' @param df data.frame with author_birth, author_death and author_name
#' @param life_info Additional author life years info table
#' @param ambiguous_authors Author synonyme table
#' @return Augmented data.frame
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @export
#' @examples # augment_author_life(df)
#' @details Augments author life years (author_birth and author_death) based on information from other entries of the same author where the info is available. Also supports manually provided information tables. Adds author_unique field which combines full author name and life years to provide a unique author identifier. Finally harmonizes ambiguous author names based on synonyme table.
#' @keywords utilities
augment_author <- function (df, life_info = NULL, ambiguous_authors = NULL) {

  author <- starts_with <- NULL
  
  # Consider only unique entries to speed up
  dfa <- df %>% select(starts_with("author"))
  dfa.uniq <- unique(as_data_frame(dfa))
  dfa.uniq$author_name <- as.character(dfa.uniq$author_name)

  message("..entry IDs for unique entries")
  dfa$id <- apply(dfa, 1, function (x) {paste(as.character(x), collapse = "")})
  dfa.uniq$id <- apply(dfa.uniq, 1, function (x) {paste(as.character(x), collapse = "")})  
  # Form match indices and remove unnecessary vars to speed up
  match.inds <- match(dfa$id, dfa.uniq$id)
  rm(dfa); dfa.uniq$id <- NULL

  message("Augment author life years")	       
  # For authors with a unique birth, use this birth year also when
  # birth year not given in the raw data
  dfa.uniq$author_birth <- guess_missing_entries(id = dfa.uniq$author_name, values = dfa.uniq$author_birth)$values
  dfa.uniq$author_death <- guess_missing_entries(id = dfa.uniq$author_name, values = dfa.uniq$author_death)$values

  # print("Add missing author life years from the predefined table")
  if (!is.null(life_info)) {  
    dfa.uniq$author_birth <- add_missing_entries(dfa.uniq, life_info, id = "author_name", field = "author_birth")
    dfa.uniq$author_death <- add_missing_entries(dfa.uniq, life_info, id = "author_name", field = "author_death") 
  }

  message("Add pseudonyme field")
  pseudo <- get_pseudonymes()
  dfa.uniq$author_pseudonyme <- tolower(dfa.uniq$author_name) %in% pseudo
  # Polish pseudonymes
  pse <- dfa.uniq$author_name[dfa.uniq$author_pseudonyme]
  pse <- gsub("\\,+", " ", pse)
  pse <- gsub("\\.+", "", pse)
  pse <- gsub("\\-+", " ", pse)    
  pse <- condense_spaces(pse)
  dfa.uniq$author_name[dfa.uniq$author_pseudonyme] <- pse

  message("Unique author identifier by combining name, birth and death years")
  author <- dfa.uniq$author_name
  # Add years only for real persons, not for pseudonymes
  author[which(!dfa.uniq$author_pseudonyme)] <- author_unique(dfa.uniq[which(!dfa.uniq$author_pseudonyme),], initialize.first = FALSE)
  dfa.uniq$author <- author
  rm(author)
  
  message("Harmonize ambiguous authors, including pseudonymes")
  if (!is.null(ambiguous_authors)) {	  	    
    dfa.uniq$author <- map(dfa.uniq$author, ambiguous_authors)
  }
  dfa.uniq$author[grep("^NA, NA", dfa.uniq$author)] <- NA  

  message("Fix author life years using the ones from the final harmonized version")
  message(".. retrieving the years ..")
  a <- dfa.uniq$author
  a <- strsplit(a, "\\(")
  len <- sapply(a, length, USE.NAMES = FALSE)
  a[len < 2] <- NA
  a[which(len == 2)] <- sapply(a[which(len == 2)], function (x) {x[[2]]}, USE.NAMES = FALSE)
  years <- gsub("\\)", "", a)
  rm(len);rm(a)
  
  message(".. splitting the years ..")
  years2 <- polish_years(years)
  spl <- strsplit(years, "-")
  len <- sapply(spl, length, USE.NAMES = FALSE)
  inds <- which(len >= 3)
  # 1300-1400-1500 case separately
  # take the range
  years2[inds,] <-  matrix(sapply(spl[inds], function (x) {range(na.omit(as.numeric(x)))}, USE.NAMES = FALSE), ncol = 2)
  # Then if birth = death, remove death
  years2[which(years2$from == years2$till), "till"] <- NA

  dfa.uniq$author_birth <- years2$from
  dfa.uniq$author_death <- years2$till

  # Replace the original entries with the updated ones
  df[, colnames(dfa.uniq)] <- dfa.uniq[match.inds,]

  df

}



#' @title Guess Missing Entries
#' @description Fill in missing values. This function assumes that
# 'each unique id has a unique value which can be missing for some
#' entries of the id but available in others. The missing data will be
#' filled based on the available values. Ambiguous cases (same id but
#' multiple values) are ignored.
#' @param id identifier vector
#' @param values corresponding values with potentially missing information (NAs)
#' @return A vector with augmented values
#' @examples \dontrun{guess_missing_entries(
#'   id = c("Tom", "Tom", "Pete", "Pete", "Pete"),
#'   	                 values = c(1, NA, 2, 3, NA))}
#' @export
#' @details For instance, we may have authors and author life
#' years (birth and death). The life years may be available for
#' a given author in some entries and missing in others.
#' When the information is unique, this function fills the missing
#' entries where possible. The function checks that the available
#' life years for the given id (author in this example) are unique
#' (ie. to avoid ambiguous mappings, for instance distinct authors
#' with identical name but different birth year). For unique id-value
#' relation, use the unique value to fill in the missing entries for
#' the same id)
#' @keywords utils
guess_missing_entries <- function (id, values) {

  id <- as.character(id)
  values <- as.character(values)		        
  tab <- cbind(id = id, values = values)

  # Unique entries
  spl <- split(tab[, "values"], tab[, "id"])
  spl <- lapply(spl, function (x) {unique(na.omit(x))})
  uniq <- names(which(sapply(spl, function (x) {length(x)}) == 1))
  spl <- spl[uniq]

  naind <- is.na(values) & (id %in% uniq)

  if (length(naind)>0) {
    values[naind] <- unlist(spl[id[naind]], use.names = FALSE)
  }

  quickdf(list(id = id, values = values))
  
}


#' @title Quick Data Frame
#' @description Speedups in data.frame creation.
#' @param x named list of equal length vectors
#' @return data.frame
#' @details This is 20x faster than as.data.frame. 
#' @export 
#' @references Idea borrowed from \url{http://adv-r.had.co.nz/Profiling.html}. 
#' @author HW/LL
#' @examples  \dontrun{quickdf(x)}
#' @keywords utilities
quickdf <- function(x) {
  class(x) <- "data.frame"
  attr(x, "row.names") <- .set_row_names(length(x[[1]]))
  x
}

#' @title Add missing entries
#' @description Fill in missing entries in the data based on supplied information table
#' @param df data.frame with the fields given in the 'id' and 'field' arguments
#' @param info Information table including the 'id' and 'field' fields
#' @param id Field that is used to match 'df' and 'info' data.frames given as input
#' @param field Field that will be filled in 'df' based on the information in 'info' data.frame
#' @return Character vector of unique author IDs
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @export
#' @examples \dontrun{a <- add_missing_entries(...)}
#' @keywords utilities
add_missing_entries <- function (df, info, id, field) {
  v <- df[[field]]
  inds <- which(is.na(v) & (df[[id]] %in% info[[id]]))
  v[inds] <- info[match(df[[id]][inds], info[[id]]), field]
  v
}

#' @title Create unique author ID
#' @description Form unique author identifiers by combining name and life years
#' @param df data.frame with fields "author_name", "author_birth", "author_death"
#' @param format name format ("last, first" or "first last")
#' @param initialize.first Convert first names into initials. Useful for removing duplicates when the name list contains different versions with both full name and the initials. Use of the life year fields helps to avoid mixing identical abbreviated names.
#' @return Character vector of unique author IDs
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{a <- author_unique(df)}
#' @export
#' @keywords utilities
author_unique <- function (df, format = "last, first", initialize.first = FALSE) {

  author_name <- author_birth <- author_death <- NULL

  dfa <- df[, c("author_name", "author_birth", "author_death")]
  dfa.orig <- dfa
  dfa.uniq <- unique(dfa.orig)
  # Entry IDs
  id.orig <- apply(dfa.orig, 1, function (x) {paste(as.character(x), collapse = "")})
  id.uniq <- apply(dfa.uniq, 1, function (x) {paste(as.character(x), collapse = "")})
  match.inds <- match(id.orig, id.uniq)
  rm(id.orig)  

  author_unique <- rep(NA, nrow(dfa.uniq))
  first <- pick_firstname(dfa.uniq$author_name, format = format, keep.single = FALSE)
  first[is.na(first) | first == "NA"] <- ""

  last  <- pick_lastname(dfa.uniq$author_name, format = format, keep.single = TRUE)

  author_unique <- apply(cbind(last, first, dfa.uniq$author_birth, dfa.uniq$author_death), 1, function (x) {paste(x[[1]], ", ", x[[2]], " (", x[[3]], "-", x[[4]], ")", sep = "")})  
  author_unique[is.na(dfa.uniq$author_name)] <- NA
  author_unique <- gsub(" \\(NA-NA\\)", "", author_unique)
  author_unique <- gsub("NA \\(NA-NA\\)", NA, author_unique)
  author_unique <- gsub("\\, NA$", "", author_unique)

  as.character(unname(author_unique))[match.inds]

}

#' @title Get Gender
#' @description Pick gender based on first names.
#' @param x Vector of first names
#' @param gendermap Table with name-gender mappings
#' @return Author gender information
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples
#'   \dontrun{
#'     gendermap <- read_mapping(system.file("extdata/gendermap.csv",
#'       package = "fennica"), sep = "\t", from = "name", to = "gender")
#'     get_gender(c("armi", "julius"), gendermap)
#' }
#' @keywords utilities
#' @importFrom gender gender
#' @import genderdata
get_gender <- function (x, gendermap) {

  # polish up
  x <- tolower(condense_spaces(gsub("\\.", " ", as.character(x))))

  first.names.orig <- x
  first.names.uniq <- unique(na.omit(first.names.orig))
  first.names <- first.names.uniq
  gendermap$name <- tolower(gendermap$name)  

  # Only keep the names that are in our present data. Speeding up
  mynames <- unique(c(first.names, unlist(strsplit(first.names, " "))))
  gendermap <- gendermap[gendermap$name %in% mynames,]
  map <- gendermap

  # None of our names are in the gender map
  # return NA for all
  if (nrow(map) == 0) {
    return(rep(NA, length(x)))
  }

  # Split by space
  spl <- strsplit(first.names, " ")
  len <- sapply(spl, length, USE.NAMES = FALSE)

  # Match unique names to genders
  gender <- rep(NA, length(first.names))

  # First check cases with a unique name
  inds <- which(len == 1)
  gender[inds] <- map(first.names[inds], map, from = "name", to = "gender", remove.unknown = TRUE)

  # Then cases with multiple names split by spaces
  # if different names give different genders, then set to NA
  inds <- which(len > 1)

  gtmp <- lapply(spl[inds], function (x) {unique(na.omit(map(x, map, from = "name", to = "gender", remove.unknown = TRUE)))})
  # Handle ambiguous cases
  len <- sapply(gtmp, length, USE.NAMES = FALSE)
  gtmp[len == 0] <- NA
  gtmp[len > 1] <- "ambiguous"
  # Set the identified genders
  gender[inds] <- sapply(gtmp, identity, USE.NAMES = FALSE)
  gender <- unname(sapply(gender, identity, USE.NAMES = FALSE))

  # Project unique names back to the original domain
  gender[match(first.names.orig, first.names.uniq)]
  
}



#' @title Custom Name-Gender Mappings
#' @description Custom first name table, including gender info.
#' @param ... Arguments to be passed
#' @return Table with first name and gender info.
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @export
#' @examples \dontrun{x <- gender_custom()}
#' @keywords utilities
gender_custom <- function (...) {

  # Read custom table
  first <- read_mapping(system.file("extdata/names/firstnames/custom_gender.csv", package = "fennica"), sep = "\t", from = "name", to = "gender", mode = "table")
  dic <- "custom_firstnames"
  first$dictionary <- dic

  # Set NA gender for individual letters
  first <- rbind(first, cbind(name = letters, gender = NA, dictionary = dic))

  first <- unique(first)

  first

}





#' @title First Edition Identification
#' @description Identify potential first editions
#' @details Identifies unique title-author combinations and marks the earliest occurrence as first edition.
#' @param df data.frame with the fields: author, title, publication_year
#' @return Logical vector indicating the potential first editions
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @export
#' @examples \dontrun{fed <- is_first_edition(df)}
#' @keywords utilities
is_first_edition <- function (df) {

  # Author-title combo		 
  id <- apply(df[, c("author", "title")], 1, function (x) {paste(x, collapse = "|")});

  # Split years and indices
  spl1 <- split(df$publication_year, id)
  spl2 <- split(df$original_row, id)

  # Cases with multiple years
  inds <- which(sapply(spl1, function (x) {sum(!is.na(x))}) > 1)

  # Identify row indices that correspond to minimum publication years
  # in unique author-title combos
  first <- c()
  later <- c()  
  for (ind in inds) {
    i <- !is.na(spl1[[ind]])
    mininds <- which(spl1[[ind]][i] == min(spl1[[ind]][i]))
    first <- c(first, spl2[[ind]][i][mininds])
    later <- c(later, spl2[[ind]][i][-mininds])
  }

  # Cases with a single occurrence are listed as NA
  # (as it is not sure if there are multiple editions)
  fed <- rep(NA, nrow(df))
  fed[df$original_row %in% unlist(first, use.names = FALSE)] <- TRUE
  fed[df$original_row %in% unlist(later, use.names = FALSE)] <- FALSE
  
  fed

}


#' @title Identify Self Published Documents
#' @description Identify Self published documents.
#' @param df data.frame that includes the given field
#' @return Output of the polished field
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @details The function considers self published documents those that have 'author' (or similar) in the publisher field, and those where the publisher is unknown.
#' @export
#' @keywords utilities
self_published <- function (df) {

  publisher <- as.character(df$publisher)
  author <- as.character(df$author)
  author[author == "NA"] <- NA

  inds <- which(grepl("^<*author>*$", tolower(publisher)) & !is.na(author))
  if (length(inds)>0) {
    publisher[inds] <- author[inds]
  }
  inds2 <- which(grepl("^<*author>*$", tolower(publisher)) & is.na(author))
  if (length(inds2)>0) {
    publisher[inds2] <- NA # "Self-published (unknown author)"
  }
  selfpub <- as.logical((publisher %in% "Self-published (unknown author)") |
  	                (author == publisher)
			)

  inds3 <- which(publisher %in% c("tuntematon", "unknown", "anonymous", "NA"))
  publisher[inds3] <- NA

  # Enrich NA self-published cases from the known ones
  nainds <- which(is.na(selfpub))
  if (length(nainds) > 0 & length(selfpub) > 0) {
    nots <- nainds[df[nainds, "publisher"] %in% df[which(!selfpub), "publisher"]]
    selfpub[nots] <- FALSE
    yess <- nainds[df[nainds, "publisher"] %in% df[which(selfpub), "publisher"]]
    selfpub[yess] <- TRUE
  }
  
  # Mark remaining self-published NAs to FALSE by default
  # selfpub[is.na(selfpub)] <- FALSE

  data.frame(publisher = publisher,
             self_published = selfpub)

}



#' @title Issue Identification
#' @description Identify documents that can be considered issues; based on other document info.
#' @details This function is used only to estimate pagecounts for documents with missing page count information.
#' Therefore no page count is considered in assessing the issue status.
#' @param df data.frame of documents x variables
#' @return Logical vector indicating the issues
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @export
#' @examples \dontrun{issue <- is.issue(df)}
#' @keywords utilities
is.issue <- function (df) {

  # Gatherings 1to-4to (any number of vols) 
  # selected.gatherings <- c("1to", "bs", "2small", "2fo", "2long", "4small", "4to", "4long")
  # inds1 <- (df$gatherings %in% selected.gatherings) 
  
  # All docs with >30 vols
  if ("volcount" %in% names(df)) {
    inds2 <- df$volcount > 30 
  } else {
    inds2 <- rep(FALSE, nrow(df))
  }

  # All documents that have (non-NA) publication frequency
  inds3 <- rep(FALSE, nrow(df))  
  if ("publication_frequency" %in% names(df)) {    
    inds3 <- !is.na(df$publication_frequency)
  }

  # TODO: how to consider publication_interval which is sometimes available?
  
  # The use of till - from did not work - 90% of these were multivolumes in ESTC
  # and not issues
  # All multivols (>=2) that have publication period of >= 3 years
  #inds4 <- (df$publication_year_till - df$publication_year_from) >= 3  
  #if ("volcount" %in% names(df)) {
  #  inds4 <- inds4 & (df$volcount >= 2) 
  #}

  # Large gatherings and docs with many volumes are considered issues
  inds <- inds2 | inds3

  inds[is.na(inds)] <- FALSE

  inds
  
}


#' @title Summary Tables
#' @description Generate summary tables from the preprocessed data frame.
#' @param df.preprocessed Preprocessed data.frame to be summarized
#' @param df.orig Original data.frame for comparisons
#' @param output.folder Output folder path
#' @return NULL
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @export
#' @examples # generate_summary_tables(df)
#' @keywords utilities
generate_summary_tables <- function (df.preprocessed, df.orig, output.folder = "output.tables") {

  # Circumvent build warnings			
  df <- author <- author_name <- author_birth <- author_death <- author_pseudonyme <- author_gender <- name <- NULL
  mean_pagecounts_multivol <- mean_pagecounts_singlevol <- mean_pagecounts_issue <- NULL
  obl <- NULL
  tally <- NULL
  desc <- NULL
  original_name <- NULL
  original_date <- NULL
  final_author_id <- NULL
  final_author_birth <- NULL
  final_author_death <- NULL
  publisher <- NULL
  gatherings <- NULL
  original_extent <- NULL
  final_pagecount <- NULL
  physical_extent <- NULL
  estimated_pagecount <- NULL
  publication_year <- NULL
  publication_interval <- NULL
  publication_interval_from <- NULL
  publication_interval_till <- NULL
  width <- NULL
  height <- NULL

  # Ensure compatibility			
  df.orig <- df.orig[match(df.preprocessed$original_row, df.orig$original_row),]

  message("Write summaries of field entries and count stats for all fields")
  for (field in setdiff(names(df.preprocessed),
    c(names(df.preprocessed)[grep("language", names(df.preprocessed))] , 
    "row.index", "paper", "publication_decade",
    "publication_year", "publication_year_from", "publication_year_till",
    "publication_interval",
    "publication_interval_from",
    "publication_interval_till",        
    "subject_topic", 
    "pagecount", "obl", "obl.original", "original_row", "dissertation",
    "synodal", "language", "original", "unity", "author_birth", "author_death",
    "gatherings.original", "width.original", "height.original",
    "longitude", "latitude", "page", "item", "publisher.printedfor",
    "publisher", "author_pseudonyme", 
    "control_number", "system_control_number",
    "author_name", "author", "area", "width", "height", "gender"))) {

   message(field)

   message("Accepted entries in the preprocessed data")
    s <- write_xtable(df.preprocessed[[field]], paste(output.folder, field, "_accepted.csv", sep = ""), count = TRUE)

    message("Discarded entries")
    if ((field %in% names(df.preprocessed)) && (field %in% names(df.orig))) {
      inds <- which(is.na(df.preprocessed[[field]]))
      original <- as.vector(na.omit(as.character(df.orig[[field]][inds])))
      tmp <- write_xtable(original, paste(output.folder, field, "_discarded.csv", sep = ""), count = TRUE)
    }

    message("Nontrivial conversions")
    if (field %in% names(df.preprocessed) && (field %in% names(df.orig)) && !field %in% c("dimension", "title")) {
      message(field)
      inds <- which(!is.na(df.preprocessed[[field]]))
      original <- as.character(df.orig[[field]][inds])
      polished <- as.character(df.preprocessed[[field]][inds])
      tab <- cbind(original = original, polished = polished)

      # Exclude trivial cases (original == polished exluding cases)
      tab <- tab[!tolower(tab[, "original"]) == tolower(tab[, "polished"]), ]
      tab <- as.data.frame(tab)
      x <- tab %>% group_by(original, polished) %>%
                   tally() %>%
		   arrange(desc(n))
      
      tmp <- write.table(x, file = paste(output.folder, field, "_conversion_nontrivial.csv", sep = ""),
                            quote = FALSE,
			    row.names = FALSE
      	     		    	 )

    }
  }

  # --------------------------------------------------------------

  message("..author conversion")
  o <- gsub("\\]", "", gsub("\\[", "", gsub("\\.+$", "", as.character(df.orig$author_name))))
  x <- as.character(df.orig$author_date)
  inds <- which(!is.na(x) & !(tolower(o) == tolower(x)))

  x1 <- as.character(df.preprocessed[inds, "author"])
  x2 <- as.character(df.preprocessed[inds, "author_birth"])
  x3 <- as.character(df.preprocessed[inds, "author_death"])

  li <- list(
         original_name = o[inds],
         original_date = x[inds],
       final_author_id = x1,
    final_author_birth = x2,
    final_author_death = x3
			  )

  df <- as.data.frame(li)

  x <- df %>%
         group_by(original_name, original_date, final_author_id, final_author_birth, final_author_death) %>%
         tally() %>%
	 arrange(desc(n))

  write.table(x, 
      file = paste(output.folder, paste("author_conversion_nontrivial.csv", sep = "_"), sep = ""),
      quote = FALSE,
      row.names = FALSE
  )

  # -----------------------------------------------------

   message("subject_topic")
   field <- "subject_topic"
   entries <- unlist(strsplit(as.character(df.preprocessed[[field]]), ";"), use.names = FALSE)
   s <- write_xtable(entries, paste(output.folder, field, "_accepted.csv", sep = ""), count = TRUE)

   message("Discarded entries")
   if ((field %in% names(df.preprocessed)) && (field %in% names(df.orig))) {
     inds <- which(is.na(df.preprocessed[[field]]))
     original <- as.vector(na.omit(as.character(df.orig[[field]][inds])))
     tmp <- write_xtable(original, paste(output.folder, field, "_discarded.csv", sep = ""), count = TRUE)
   }

   message("Nontrivial conversions")
   if (field %in% names(df.preprocessed) && (field %in% names(df.orig)) && !field %in% c("dimension", "title")) {
     message(field)
     inds <- which(!is.na(df.preprocessed[[field]]))
     original <- as.character(df.orig[[field]][inds])
     polished <- as.character(df.preprocessed[[field]][inds])
     tab <- cbind(original = original, polished = polished)
     # Exclude trivial cases (original == polished exluding cases)
     tab <- tab[!tolower(tab[, "original"]) == tolower(tab[, "polished"]), ] 
     tmp <- write_xtable(tab, paste(output.folder, field, "_conversion_nontrivial.csv", sep = ""), count = TRUE)
   }
  
  # -----------------------------------------------------

  message("Author")
  # Separate tables for real names and pseudonymes
  tab <- df.preprocessed %>% filter(!author_pseudonyme) %>%
      	 		     select(author, author_gender)
			     
  tmp <- write_xtable(tab,
      paste(output.folder, paste("author_accepted.csv", sep = "_"), sep = ""),
      count = FALSE, sort.by = "author")

  # -------------------------------------------------      

  message("Pseudonyme")
  tab <- df.preprocessed %>% filter(author_pseudonyme) %>% select(author)
  tmp <- write_xtable(tab, paste(output.folder, "pseudonyme_accepted.csv", sep = ""),
      	 		   count = TRUE, sort.by = "author")

  # ----------------------------------------------------

  message("..author")
  o <- as.character(df.orig[["author_name"]])
  x <- as.character(df.preprocessed[["author"]])
  inds <- which(is.na(x))
  tmp <- write_xtable(o[inds],
      paste(output.folder, paste("author_discarded.csv", sep = "_"), sep = ""),
      count = TRUE)
  # --------------------------------------------

  # Author gender
  message("Accepted entries in the preprocessed data")
  s <- write_xtable(df.preprocessed[["author_gender"]],
         paste(output.folder, "author_gender_accepted.csv", sep = ""),
	 count = TRUE)

  message("Discarded gender")
  inds <- which(is.na(df.preprocessed[["author_gender"]]))
  dg <- condense_spaces(gsub("\\.", " ", tolower(as.vector(na.omit(as.character(df.preprocessed$author[inds]))))))
  inds <- grep("^[a-z] [a-z]-[a-z]$", dg)  
  if (length(inds)>0) {
    dg <- dg[-inds]
  }
  tmp <- write_xtable(dg,
        paste(output.folder, "author_gender_discarded.csv", sep = ""),
	count = TRUE)
 
  message("Author gender tables realized in the final data")
  tab <- data.frame(list(name = pick_firstname(df.preprocessed$author_name),
                         gender = df.preprocessed$author_gender))
  tab <- tab[!is.na(tab$gender), ] # Remove NA gender

  write_xtable(subset(tab, gender == "male")[,-2],
                 paste(output.folder, "gender_male.csv", sep = ""))
  write_xtable(subset(tab, gender == "female")[,-2],
                 paste(output.folder, "gender_female.csv", sep = ""))

  # Unknown gender
  tmp <- unname(pick_firstname(df.preprocessed$author_name)[is.na(df.preprocessed$author_gender)])
  tmp <- condense_spaces(gsub("\\.", " ", tolower(tmp)))
  inds <- unique(
            c(which(nchar(tmp) == 1),
            grep("^[a-z] [a-z] von$", tmp),
            grep("^[a-z]{1,2} [a-z]{1,2}$", tmp),
       	    grep("^[a-z] [a-z] [a-z]$", tmp)))
  if (length(inds) > 0) { tmp <- tmp[-inds] }
  tmpg <- write_xtable(tmp, paste(output.folder, "gender_unknown.csv", sep = ""))

  # Unresolved (ambiguous) gender
  tmp <- unname(pick_firstname(df.preprocessed$author_name)[df.preprocessed$author_gender == "ambiguous"])
  tmp <- condense_spaces(gsub("\\.", " ", tolower(tmp)))
  inds <- c(which(nchar(tmp) == 1),
            grep("^[a-z]{1,2} [a-z]{1,2}$", tmp),
            grep("^[a-z]{1,2} [a-z]{1,2} von$", tmp),
	    grep("^von$", tmp),	    
            grep("^[a-z] von$", tmp),	    
       	    grep("^[a-z] [a-z] [a-z]$", tmp))
  if (length(inds) > 0) { tmp <- tmp[-inds] }
  tmpg <- write_xtable(tmp, paste(output.folder, "gender_ambiguous.csv", sep = ""))

  #-------------------------------------------------

  ## PUBLISHER
  # The result is visible at
  # https://github.com/COMHIS/fennica/blob/master/inst/examples/publisher.md
  # and that page is generated from
  # inst/extdata/publisher.Rmd

   message("Accepted publishers")
   x <- df.preprocessed[, c("publisher", "self_published")] %>%
          group_by(publisher, self_published) %>%
	  tally() %>%
	  arrange(desc(n))
   
   s <- write.table(x,
     	  file = paste(output.folder, field, "_accepted.csv", sep = ""),
	  quote = FALSE, row.names = FALSE
	  )

   message("Discarded publishers")
   if ((field %in% names(df.preprocessed)) && (field %in% names(df.orig))) {
      inds <- which(is.na(df.preprocessed[[field]]))
      original <- as.vector(na.omit(as.character(df.orig[[field]][inds])))
      # Remove trivial cases to simplify output
      inds <- c(grep("^\\[*s\\.*n\\.*\\]*[0-9]*\\.*$", tolower(original)),
      	        grep("^\\[*s\\.*n\\.*\\[*[0-9]*$", tolower(original)))
		
      if (length(inds) > 0) {		
        original <- original[-inds]
      }
      tmp <- write_xtable(original, paste(output.folder, field, "_discarded.csv", sep = ""), count = TRUE)
   }

  message("publisher conversions")
    o <- as.character(df.orig[[field]])
    x <- as.character(df.preprocessed[[field]])
    inds <- which(!is.na(x) & !(tolower(o) == tolower(x)))
    tmp <- write_xtable(cbind(original = o[inds],
      	 		      polished = x[inds]),
      paste(output.folder, paste(field, "conversion_nontrivial.csv", sep = "_"),
      sep = ""), count = TRUE)
    
  # --------------------------------------------


  ## CORPORATE
  # The result is visible at
  # https://github.com/COMHIS/fennica/blob/master/inst/examples/publisher.md
  # and that page is generated from
  # inst/extdata/publisher.Rmd

   message("Accepted corporates")
   field <- "corporate"

   s <- write_xtable(df.preprocessed[[field]],
     	  paste(output.folder, field, "_accepted.csv", sep = ""),
	  count = TRUE)

   message("Discarded corporates")
   if ((field %in% names(df.preprocessed)) && (field %in% names(df.orig))) {
      inds <- which(is.na(df.preprocessed[[field]]))
      original <- as.vector(na.omit(as.character(df.orig[[field]][inds])))
      # Remove trivial cases to simplify output
      inds <- c(grep("^\\[*s\\.*n\\.*\\]*[0-9]*\\.*$", tolower(original)),
      	        grep("^\\[*s\\.*n\\.*\\[*[0-9]*$", tolower(original)))
		
      if (length(inds) > 0) {		
        original <- original[-inds]
      }
      tmp <- write_xtable(original, paste(output.folder, field, "_discarded.csv", sep = ""), count = TRUE)
   }

  message("corporate conversions")
  nam <- "corporate"
    o <- as.character(df.orig[[nam]])
    x <- as.character(df.preprocessed[[nam]])
    inds <- which(!is.na(x) & !(tolower(o) == tolower(x)))
    tmp <- write_xtable(cbind(original = o[inds],
      	 		      polished = x[inds]),
      paste(output.folder, paste(nam, "conversion_nontrivial.csv", sep = "_"),
      sep = ""), count = TRUE)
      
  # ----------------------------

  message("Pagecount  conversions")
  o <- as.character(df.orig[["physical_extent"]])
  g <- as.character(df.preprocessed$gatherings)
  x <- as.character(df.preprocessed[["pagecount"]])

  # Do not show the estimated ones,
  # just the page counts that were originally available
  #x2 <- rep("", nrow(df.preprocessed));
  # x2[is.na(df.preprocessed[["pagecount.orig"]])] <- "estimate"
  inds <- which(!is.na(x) & !(tolower(o) == tolower(x)) &
                !is.na(df.preprocessed[["pagecount.orig"]]))
		
  tmp <- cbind(gatherings = g[inds],
      	                    original_extent = o[inds],  
      	 		    final_pagecount = x[inds]
			    )
  xx <- as.data.frame(tmp) %>% group_by(gatherings, original_extent, final_pagecount) %>%
                              tally() %>%
			      arrange(desc(n))

  write.table(xx, 
    file = paste(output.folder, "pagecount_conversions.csv", sep = ""),
       quote = FALSE,
       row.names = FALSE)

  # ----------------------------------------------

  message("Discard summaries")
  inds <- which(is.na(df.preprocessed$pagecount.orig))

  tmp <- cbind(
      	   gatherings = g[inds],	   
	   physical_extent = o[inds],
	   estimated_pagecount = x[inds]
	   )
  x <- as.data.frame(tmp) %>% group_by(gatherings, physical_extent, estimated_pagecount) %>%
                              tally() %>%
			      arrange(desc(n))

  write.table(x, file=paste(output.folder, "pagecount_discarded.csv", sep = ""), quote = FALSE, row.names = FALSE)

  # --------------------------------------------

  message("Conversion: publication year")
  # Publication year
  o <- gsub("\\.$", "", as.character(df.orig[["publication_time"]]))
  x <- df.preprocessed[, c("publication_year", "publication_year_from", "publication_year_till")]
  tab <- cbind(original = o, x)
  tab <- tab[!is.na(tab$publication_year),]
  xx <- as.data.frame(tab) %>% group_by(original, publication_year) %>% tally() %>% arrange(desc(n))
  
  tmp <- write.table(xx,
      file = paste(output.folder, "publication_year_conversion.csv",
      sep = ""), quote = FALSE, row.names = FALSE)
  
  message("Discarded publication year")
  o <- as.character(df.orig[["publication_time"]])
  x <- as.character(df.preprocessed[["publication_year"]])
  inds <- which(is.na(x))
  tmp <- write_xtable(o[inds],
      paste(output.folder, "publication_year_discarded.csv", sep = ""),
      count = TRUE)

  # --------------------------------------------

  message("Accepted publication frequency")
  if ("publication_frequency_text" %in% names(df.preprocessed)) {

     publication_frequency_annual <- NULL

     dfp <- df.preprocessed[, c("publication_frequency_text",
			        "publication_frequency_annual")]
     # Remove NA			 
     inds <- is.na(dfp$publication_frequency_text) &
     	     is.na(dfp$publication_frequency_annual)
     dfp <- dfp[!inds,]
     xx <- dfp %>% group_by(publication_frequency_text, publication_frequency_annual) %>%
                   tally() %>%
		   arrange(desc(publication_frequency_annual))
     
    tmp <- write.table(xx,
      file = paste(output.folder, "publication_frequency_accepted.csv", sep = ""),
      quote = FALSE, row.names = FALSE
      )
  
    message("Conversion: publication frequency")
    o <- cbind(original_frequency = condense_spaces(tolower(gsub("\\.$", "", as.character(df.orig[["publication_frequency"]])))),
               original_interval = condense_spaces(tolower(gsub("\\.$", "", as.character(df.orig[["publication_interval"]])))),
               original_time = condense_spaces(tolower(gsub("\\.$", "", as.character(df.orig[["publication_time"]]))))
       )
       
    x <- df.preprocessed[, c("publication_frequency_text", "publication_frequency_annual")]
    tab <- cbind(x, o)
    tab$publication_frequency_annual <- round(tab$publication_frequency_annual, 2)

    tab <- tab[which(!rowMeans(is.na(tab[, 1:3])) == 1),] # Remove NA cases
    xx <- tab %>% group_by(publication_frequency_text, publication_frequency_annual) %>%
                  tally() %>%
		  arrange(desc(n))

    tmp <- write.table(xx,
      file = paste(output.folder, "publication_frequency_conversion.csv",
      sep = ""), quote = FALSE, row.names = FALSE)
  
    message("Discarded publication frequency")
    o <- as.character(df.orig[["publication_frequency"]])
    x1 <- as.character(df.preprocessed[["publication_frequency_annual"]])
    x2 <- as.character(df.preprocessed[["publication_frequency_text"]])    
    inds <- which(is.na(x1) & is.na(x2))
    tmp <- write_xtable(o[inds],
      paste(output.folder, "publication_frequency_discarded.csv", sep = ""),
      count = TRUE)
      
  }

  # --------------------------------------------

  message("Conversion: publication interval")
  if ("publication_interval_from" %in% names(df.preprocessed)) {
  
    # Publication interval
    o <- tolower(gsub("\\.$", "", as.character(df.orig[["publication_interval"]])))
    x <- df.preprocessed[, c("publication_interval_from", "publication_interval_till")]
    tab <- cbind(original = o, x)
    tab <- tab[!is.na(tab$publication_interval_from) | !is.na(tab$publication_interval_till),]
    xx <- tab %>% group_by(original) %>% tally() %>% arrange(desc(n))
    tmp <- write.table(xx,
      paste(output.folder, "publication_interval_conversion_nontrivial.csv",
      sep = ""), quote = FALSE, row.names = FALSE)
  
    message("Discarded publication interval")
    o <- df.orig[, c("publication_interval", "publication_time", "publication_frequency")]
    o$publication_time <- gsub("^\\[", "", gsub("\\]$", "", gsub("\\.$", "", o$publication_time)))
    x <- df.preprocessed[,c("publication_interval_from", "publication_interval_till")]
    x2 <- df.preprocessed[, c("publication_frequency_annual", "publication_frequency_text")]
    inds <- which(rowSums(is.na(x)) == 2 & rowSums(is.na(x2)) == 2 )
    o <- o[inds,]
    inds <- is.na(unlist(o[,1])) & grepl("^[0-9]+$", unlist(o[, 2])) & is.na(unlist(o[,3]))
    xx <- o[!inds,] %>% group_by(publication_interval) %>% tally() %>% arrange(desc(n))
    tmp <- write.table(xx,
      file = paste(output.folder, "publication_interval_discarded.csv", sep = ""),
      quote = FALSE, row.names = FALSE
      )

    message("Accepted publication interval")
    o <- as.character(df.orig[["publication_interval"]])
    x <- df.preprocessed[c("publication_interval_from", "publication_interval_till")]
    inds <- which(rowSums(!is.na(x))>0)
    xx <- x[inds,] %>% group_by(publication_interval_from, publication_interval_till) %>% tally() %>% arrange(desc(n))
    tmp <- write.table(xx,
      file = paste(output.folder, "publication_interval_accepted.csv", sep = ""),
      quote = FALSE, row.names = FALSE      
      )

  }

  # --------------------------------------------

  message("Authors with missing life years")
  tab <- df.preprocessed %>% filter(!is.na(author_name) & (is.na(author_birth) | is.na(author_death))) %>% select(author_name, author_birth, author_death)
  tmp <- write.table(tab, file = paste(output.folder, "authors_missing_lifeyears.csv", sep = ""), quote = F, row.names = F)
 
  message("Ambiguous authors with many birth years")
  births <- split(df.preprocessed$author_birth, df.preprocessed$author_name)
  births <- births[sapply(births, length, USE.NAMES = FALSE) > 0]
  many.births <- lapply(births[names(which(sapply(births, function (x) {length(unique(na.omit(x)))}, USE.NAMES = FALSE) > 1))], function (x) {sort(unique(na.omit(x)))})
  dfs <- df.preprocessed[df.preprocessed$author_name %in% names(many.births),
      	 			c("author_name", "author_birth", "author_death")]
  dfs <- unique(dfs)
  dfs <- dfs %>% arrange(author_name, author_birth, author_death)
  write.table(dfs, paste(output.folder, "author_life_ambiguous.csv", sep = ""), quote = F, sep = "\t", row.names = FALSE)

  # -------------------------------------------------------

  message("Page counts")
  use.fields <- intersect(c("pagecount", "volnumber", "volcount"), names(df.preprocessed))
  tab <- cbind(original = df.orig$physical_extent, df.preprocessed[, use.fields])
  # For clarity: remove ECCO and Manually augmented pagecounts from ESTC data
  if ("pagecount_from" %in% names(df) & nrow(df.preprocessed) == nrow(df.orig)) {
    tab <- tab[df.preprocessed$pagecount_from %in% c("estc"),]
  }
  tmp <- write.table(tab, file = "output.tables/conversions_physical_extent.csv", quote = F, row.names = F)

  message("Physical dimension info")
  tab <- cbind(original = df.orig$physical_dimension,
               df.preprocessed[, c("gatherings.original", "width.original", "height.original", "obl.original", "gatherings", "width", "height", "obl", "area")])
  tmp <- write.table(tab, file = "output.tables/conversions_physical_dimension.csv", quote = F, row.names = F)

  message("Accepted / Discarded dimension info")
  inds <- which(is.na(df.preprocessed[["area"]]))
  xx <-
    data.frame(original = as.character(df.orig$physical_dimension)[inds],
          df.preprocessed[inds, c("gatherings", "width", "height", "obl")])
  xx <- xx %>% group_by(original, gatherings, width, height, obl) %>% tally() %>% arrange(desc(n))

  tmp <- write.table(xx,
    file = paste(output.folder, paste("physical_dimension_incomplete.csv", sep = "_"), sep = ""),
    quote = F, row.names = F)

  #-----------------------------------------------------------------------

  message("All summary tables generated.")
  gc()

  return(NULL)
}

#' @title Write Summary Table
#' @description Write xtable in a file
#' @param x a vector or matrix
#' @param filename output file
#' @param count Add total count of cases in the beginning
#' @param sort.by Column used for sorting. The Count is the default.
#' @param na.rm Remove NA entries
#' @param add.percentages Add percentage information to the table. This indicates the total fraction of the count, calculated from all input entries if na.rm is FALSE, and from non-NA entries if na.rm is TRUE.
#' @return Table indicating the count for each unique entry in the input  vector or matrix. The function writes the statistics in the file.
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{tab <- write_xtable(x, "tmp.tab")}
#' @keywords utilities
write_xtable <- function (x, filename = NULL, count = FALSE, sort.by = "Count", na.rm = TRUE, add.percentages = FALSE) {

  xorig <- x

  if (is.data.frame(x) && ncol(x) == 1) {
    x <- as.vector(x[,1])
  }

  if (is.factor(x)) {
    x <- as.character(x)
  }

  # Remove NAs
  if (na.rm) {
    if (is.null(dim(x))) {
      x <- x[!is.na(x)]
    } else {
      keep <- which(rowMeans(is.na(x)) < 1)
      if (length(keep) > 0) {
        x <- x[keep,]
      } else {
        x <- NULL
      }
    }
  }

  #if (length(x) == 0) {  
  #  message("The input to write_table is empty.")
  #  write("The input list is empty.", file = filename)    
  #  return(NULL)
  #}

  tab <- NULL
  if (is.vector(x)) {

    # Original number of entries (before removing NAs)
    ntotal <- length(x)

    if (length(x) == 0 && !is.null(filename)) {
      write("The input list is empty.", file = filename)
      return(NULL)
    }

    if (count) {
      counts <- rev(sort(table(x)))
      tab <- data.frame(list(Name = names(counts), Count = as.vector(counts)))
    }
    
    if (is.null(filename)) {return(tab)}

  } else if (is.matrix(x) || is.data.frame(x)) {

    # Original number of entries (before removing NAs)
    ntotal <- nrow(x)
    
    if (is.null(colnames(x))) {
      colnames(x) <- paste("X", 1:ncol(x), sep = "")
    }
    
    # Proceed
    id <- apply(x, 1, function (x) { paste(x, collapse = "-") })
    ido <- rev(sort(table(id)))
    
    tab <- as.data.frame(x)

    if (count) { 
      idn <- ido[match(id, names(ido))]
      tab[, "Count"] <- idn
    }
    
    tab <- tab[!duplicated(tab),]

    if (is.null(filename) & count) {
      tab <- tab[rev(order(tab[, "Count"])),]
      rownames(tab) <- NULL
      return(tab)
    }

    if (length(tab) > 0) {
      tab <- as.matrix(tab, nrow = nrow(x))
      if (ncol(tab) == 1) { tab <- t(tab) }
      # HR: Fixing a bug: "Count" had been tried to add twice as a column name
      if (count & !"Count" %in% colnames(tab)) {
        colnames(tab) <- c(colnames(tab), "Count")
      }
      rownames(tab) <- NULL
    } else {
      tab <- NULL
      
      
    }    
  }

  # Arrange
  if (!sort.by %in% c("Count", colnames(x))) {
    sort.by <- "Name"
  }

  s <- as.character(tab[, sort.by])
  n <- suppressWarnings(as.numeric(s))
  if (all(!is.na(n[!is.na(s)]))) {
    # If all !NAs are numeric
    o <- rev(order(n))
  } else {
    # Consider as char
    o <- order(s)
  }
  tab <- tab[o,]

  # Add fraction
  if (add.percentages & count) {
    tab <- cbind(tab,
      Percentage = round(100 * as.numeric(condense_spaces(tab[, "Count"]))/ntotal, 2))
  }

  if (count) {

    if (is.null(dim(tab)) && !is.null(tab)) {
      tab <- t(as.matrix(tab, nrow = 1))
    }
    
    if (!is.null(tab) && nrow(tab) > 1) {
      tab <- apply(tab, 2, as.character)
    }

    #n <- sum(as.numeric(tab[, "Count"]), na.rm = TRUE)
    #ntxt <- n    
    #if (is.matrix(tab)) {
    #  suppressWarnings(tab <- rbind(rep("", ncol(tab)), tab))
    #  tab[1, 1] <- paste("Total count (na.rm ", na.rm, "): ", sep = "")
    #  tab[1, 2] <- ntxt
    #  if (ncol(tab)>2) {
    #    tab[1, 3:ncol(tab)] <- rep("", ncol(tab) - 2)
    #  }
    #} else {
    #  tab <- c(paste("Total count:", ntxt), tab)
    #}
    
  }

  if (!is.null(filename)) {
    message(paste("Writing", filename))
    write.table(tab, file = filename, quote = FALSE, sep = "\t", row.names = FALSE)
  }

  if (!count && ("Count" %in% names(tab))) {
    tab <- tab[, -ncol(tab)]
  }

  tab

}



#' @title Remove Volume Info
#' @description Remove volume info from the string start.
#' @param x Page number field. Vector or factor of strings.
#' @return Page numbers without volume information
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{remove_volume_info("v.4, 293")}
#' @keywords utilities
remove_volume_info <- function (x) {

  x <- gsub("^[0-9]+ {0,1}v\\.", "", x)		   

  # Remove parts
  # "27 pts" -> " "
  s <- gsub("in [0-9]* {0,1}pts", " ", x)  
  s <- gsub("[0-9]* pts in", " ", s)
  s <- gsub("[0-9]* pts", " ", s)
  s <- condense_spaces(s)    
  s <- gsub("^\\(", "", s)
  s <- gsub("\\)$", "", s)  
  s <- gsub("^[0-9]+ {0,1}v\\.", "", s)

  # Cases 'v.1-3,7-8' etc
  s <- gsub("^v\\.[0-9]+-[0-9]+,[0-9]+-[0-9]+", "", s)

  # Cases 'v.1-3' etc
  s <- gsub("^v\\. ", "v\\.", s)
  inds <- intersect(grep("^v\\.", s), grep("-", s))

  s[inds] <- sapply(s[inds], function (si) {
    gsub(check_volumes(si)$text, "", si)
  })

  # special cases 
  s <- gsub("v\\.[0-9]-[0-9]\\, [0-9] ;", "", s)
  s <- gsub("v\\.[0-9]\\,[0-9]-[0-9] ;", "", s)
  s <- gsub("v\\.[0-9]-[0-9]\\,[0-9]-[0-9]*", "", s)
  s <- gsub("Vols\\.[0-9]-[0-9]\\,[0-9]-[0-9]*\\,plates :", "plates", s)

  # Remove the volume information 
  s <- gsub("^[0-9]{1,4}v\\.", "", s)

  # Cases 'v.1' etc.
  s <- gsub("v\\.[0-9]* {0,1}\\:{0,1}", "", s)

  # "v. (183,[2]) -> (183,[2])"
  s <- gsub("^v\\.", " ", s)

  # vol.synonymes <- c("vol", "part")
  s <- gsub(paste("^[0-9]{1,3} {0,1}vol[\\.| ]", sep = ""), " ", s)
  s <- gsub(paste("^[0-9]{1,3} {0,1}vol$", sep = ""), " ", s)

  # "8p. 21cm. (8vo)"
  s <- gsub("\\([0-9]{1,2}.o\\)" , "", s)
  s <- gsub("[0-9]*cm" , "", s)
  s <- gsub("^, *" , "", s)
  s <- gsub("^i [0-9]+ " , "", s)  # 6v i 2 (300; 200)

  s[s == ""] <- NA

  s

}


estimate_pages <- function (x) {

  # Initialize	       
  pagecount.info <- c(multiplier = 1, squarebracket = 0, plate = 0, arabic = 0, roman = 0, sheet = 0)
  library(stringr)
  # 
  # if (all(is.na(x))) {
  #   return(pagecount.info)
  # } else if (!is.na(suppressWarnings(as.numeric(x)))) {
  #   pagecount.info$sheet <- as.numeric(x)
  #   return(pagecount.info)           
  # } else if (str_detect(x, "^[IVXLCDM]+$")) {
  #   pagecount.info$roman <- suppressWarnings(as.numeric(as.roman(x)))
  #   return(pagecount.info)               
  # } else if (str_detect(x, "^\\[[0-9]+ {0,1}[p|s]{0,1}\\]$")) {
  #   pagecount.info$squarebracket <- suppressWarnings(as.numeric(str_trim(gsub("\\[", "", gsub("\\]", "", gsub(" [p|s]", "", x))))))
  #   return(pagecount.info)                  
  # } else if (str_detect(x, "^[0-9]+ sheets$")) {
  #   pagecount.info$sheet <- 2 * as.numeric(as.roman(str_trim(unlist(strsplit(x, "sheet"), use.names = FALSE)[[1]])))
  #   return(pagecount.info)                      
  # } else if (str_detect(x, "\\[{0,1}[0-9]* \\]{0,1} leaves")) {
  #   pagecount.info$squarebracket <- str_trim(gsub("\\[", "", gsub("\\]", "", x)))
  #   return(pagecount.info)                          
  # } else if (str_detect(x, "[0-9]+ \\+ [0-9]+")) {
  #   pagecount.info$sheet <- sum(as.numeric(str_trim(unlist(strsplit(x, "\\+"), use.names = FALSE))))
  #   return(pagecount.info)                              
  # } else if (!is.na(sum(as.numeric(roman2arabic(str_trim(unlist(strsplit(x, "\\+"), use.names = FALSE))))))) {
  #   x <- gsub("\\+", ",", x)
  # } else if (str_detect(x, "^p") && !str_detect(x, "-")) {
  #   if (is.numeric(str_trim(gsub("^p", "", x)))) {
  #     pagecount.info$sheet <- 1
  #     return(pagecount.info)                              
  #   } else if (str_detect(x, "^p") && str_detect(x, "-")) {
  #     x <- gsub("^p", "", x)
  #   }   
  # } else if (str_detect(x, "^1 sheet \\[*[0-9+]\\]*")) {
  #   x <- gsub("1 sheet", "", x)
  #   x <- gsub("\\[1\\]", "2", x)
  # } else if (str_detect(x, "^[0-9]+ sheets* [0-9]+ pages*$")) {
  #   x <- gsub("^s", "", unlist(strsplit(x, "sheet"), use.names = FALSE)[[2]])
  # }
  
  
  if (all(is.na(x))) {
    # "NA"
    return(pagecount.info)
  } else if (!is.na(suppressWarnings(as.numeric(x)))) {
    # "3"
    pagecount.info$sheet <- as.numeric(x)
    return(pagecount.info)            
  } else if ((is.roman(x) && length(unlist(strsplit(x, ","), use.names = FALSE)) == 1 && length(grep("-", x)) == 0)) {
    # "III" but not "ccclxxiii-ccclxxiv"
    pagecount.info$roman <- suppressWarnings(as.numeric(as.roman(x)))
    return(pagecount.info)                
  } else if (length(grep("^\\[[0-9]+ {0,1}[p|s]{0,1}\\]$", x)>0)) {
    # "[3]" or [3 p]
    pagecount.info$squarebracket <- suppressWarnings(as.numeric(str_trim(gsub("\\[", "", gsub("\\]", "", gsub(" [p|s]", "", x))))))
    return(pagecount.info)                    
  } else if (length(grep("^[0-9]+ sheets$", x)) == 1) {
    # "1 sheet is 2 pages"
    pagecount.info$sheet <- 2 * as.numeric(as.roman(str_trim(unlist(strsplit(x, "sheet"), use.names = FALSE)[[1]])))
    return(pagecount.info)                        
  } else if (length(grep("\\[{0,1}[0-9]* \\]{0,1} leaves", x)) > 0) {
    # "[50 ] leaves"    
    pagecount.info$squarebracket <- str_trim(gsub("\\[", "", gsub("\\]", "", x)))
    return(pagecount.info)                            
  } else if (length(grep("[0-9]+ \\+ [0-9]+", x))>0) {
    # 9 + 15
    pagecount.info$sheet <- sum(as.numeric(str_trim(unlist(strsplit(x, "\\+"), use.names = FALSE))))
    return(pagecount.info)                                
  } else if (!is.na(sum(as.numeric(roman2arabic(str_trim(unlist(strsplit(x, "\\+"), use.names = FALSE))))))) {
    # IX + 313
    x <- gsub("\\+", ",", x)
    #sum(as.numeric(roman2arabic(str_trim(unlist(strsplit(x, "\\+"), use.names = FALSE)))))
    #return(pagecount.info)                                    
  } else if (length(grep("^p", x)) > 0 && length(grep("-", x)) == 0) {
    # p66 -> 1
    if (is.numeric(str_trim(gsub("^p", "", x)))) {
      pagecount.info$sheet <- 1
      return(pagecount.info)                                
    } else if (length(grep("^p", x)) > 0 && length(grep("-", x)) > 0) {
      # p5-8 -> 5-8
      x <- gsub("^p", "", x)
    }    
  } else if (length(grep("^1 sheet \\[*[0-9+]\\]*", x))>0) {
    # "1 sheet [166]"
    x <- gsub("1 sheet", "", x)
    # 1 sheet ([1+] p.)
    x <- gsub("\\[1\\]", "2", x)
  } else if (length(grep("^[0-9]+ sheets* [0-9]+ pages*$", x))>0) {
    # 3 sheets 3 pages
    x <- gsub("^s", "", unlist(strsplit(x, "sheet"), use.names = FALSE)[[2]])
  }
  
  # --------------------------------------------
  
  # Then proceeding to the more complex cases...
  # Harmonize the items within commas

  # Remove plus now
  x <- gsub("\\+", "", x)
  x <- gsub("pages*$", "", x)  

  # "[52] plates between [58] blank sheets"
  x <- gsub("plates between ", "plates, ", x)
  # 6 sheets + 2 sheets
  x <- gsub("sheets", "sheets,", x)

  # Handle comma-separated elements separately
  spl <- condense_spaces(unlist(strsplit(x, ","), use.names = FALSE))

  # 13 [1] -> 13, [1]
  if (length(grep("^[0-9]+ \\[[0-9]+\\]$", spl))>0) {
    spl <- gsub(" ", ", ", spl)
  }  
  spl <- condense_spaces(unlist(strsplit(spl, ","), use.names = FALSE))

  # Harmonize pages within each comma
  x <- sapply(spl, function (x) { harmonize_pages_by_comma(x) }, USE.NAMES = FALSE)

  # Remove empty items
  x <- as.vector(na.omit(x))
  if (length(x) == 0) {x <- ""}

  if (length(grep("^ff", x[[1]]))==1) {
    # Document is folios - double the page count!
    pagecount.info$multiplier <- 2
  }

  # Fix romans
  x[x == "vj"] <- "vi"

  # Identify (potentially overlapping) attribute positions for
  # "arabic", "roman", "squarebracket", "dash", "sheet", "plate"
  # attributes x positions table 0/1
  # NOTE this has to come after harmonize_per_comma function ! 
  pagecount.attributes <- attribute_table(x)

  # If dashes are associated with square brackets, 
  # consider and convert them to arabic. Otherwise not.
  # ie. [3]-5 becomes 3-5 
  dash <- pagecount.attributes["dash", ]
  sqb  <- pagecount.attributes["squarebracket", ]
  inds <- which(dash & sqb)
  pagecount.attributes["arabic", inds] <- TRUE
  pagecount.attributes["squarebracket", inds] <- FALSE

  # Page count can't be roman and arabic at the same time.
  # or pages will double
  pagecount.attributes["roman", pagecount.attributes["arabic", ]] <- FALSE

  # Remove square brackets
  x <- gsub("\\[", "", x)
  x <- gsub("\\]", "", x)

  # Convert romans to arabics (entries separated by spaces possibly)
  # also 3-iv -> 3-4
  inds <- pagecount.attributes["roman", ] | pagecount.attributes["arabic", ]
  if (any(inds)) {
    x[inds] <- roman2arabic(x[inds])
  }

  # Convert plates to arabics
  inds <- pagecount.attributes["plate", ]
  if (any(inds)) {  
    x[inds] <- as.numeric(str_trim(gsub("pages calculated from plates", "", x[inds])))
  }

  # ----------------------------------------------

  # Start page counting

  # Sum square brackets: note the sum rule does not concern roman numerals
  inds <- pagecount.attributes["squarebracket",] & !pagecount.attributes["roman",]
  pagecount.info$squarebracket <- sumrule(x[inds])

  # Sum plates 
  # FIXME: at the moment these all go to sheets already
  inds <- pagecount.attributes["plate",]
  pagecount.info$plate <- sum(na.omit(suppressWarnings(as.numeric(x[inds]))))

  # Count pages according to the type
  for (type in c("arabic", "roman")) {
    pagecount.info[[type]] <- count_pages(x[pagecount.attributes[type,]])
  }

  # Sum sheets 
  inds <- pagecount.attributes["sheet",]
  xx <- NA
  xinds <- x[inds]
  xinds <- gsub("^sheets*$", "1 sheet", xinds)

  if (length(grep("sheet", xinds))>0) {
    # 1 sheet = 2 pages
    xinds <- sapply(xinds, function (xi) {str_trim(unlist(strsplit(xi, "sheet"), use.names = FALSE)[[1]])}, USE.NAMES = FALSE)
    xx <- suppressWarnings(2 * as.numeric(as.roman(xinds)))
  } 
  pagecount.info$sheet <- sumrule(xx) 

  # Return pagecount components
  pagecount.info

}



# A single instance of pages within commas
harmonize_pages_by_comma <- function (s) {

  # 30 [32]
  if (length(grep("[0-9]+ \\[[0-9]+\\]", s))>0) {
    s <- paste(unlist(strsplit(s, " "), use.names = FALSE)[-1], collapse = " ")
  }

  # Convert plates to pages
  s <- plates2pages(s)

  # 165-167 leaves -> 165-167
  if (length(grep("-", s))>0 && length(grep("leaves", s))>0) {
    s <- gsub("leaves", "", s)
  }

  # After plate operations handle p/s ("pages" / "sivua")
  s <- condense_spaces(s)

  if (length(grep("plates", s)) == 0 && !is.na(s) && length(s) > 0 && length(grep("^sheets*", s))==0) {
    s <- gsub("^[p|s]", "", s)    
    s <- gsub("^[p|s]\\.\\)", " ", s)
    s <- gsub("[p|s] *$", " ", s)
    s <- gsub("^[p|s] ", "", s)
    s <- gsub("[p|s]\\.]$", " ", s)
    s <- gsub(" [p|s]\\.{0,1} {0,1}\\]$", " ", s)
  }

  # Handle some odd cases
  s <- condense_spaces(s)
  s[s == ""] <- NA

  s

}


plates2pages <- function (s) {

  plate.multiplier <- 2	     

  # If not plate number given, consider it as a single plate
  # Convert plates to pages: 1 plate = 2 pages
  if (length(grep("plate", s)) > 0 || length(grep("lea", s)) > 0) {

    # Remove square brackets
    s <- condense_spaces(gsub("\\[", " ", gsub("\\]", " ", s)))

    if (s == "plate") {
      s <- 1
    } else if (length(grep("\\[*[0-9+]\\]* p of plates", s)) > 0) {
      # "[16] p of plates" -> [16]
      s <- gsub(" p of plates", "", s)
      plate.multiplier <- 1
    } else if (length(grep("plates*", s) > 0) && length(grep("lea", s)) == 0) {
      # "plates" instances without "leaf" or "leaves"
      xi <- str_trim(gsub("plates*", "", s))
      xi <- gsub("\\]", "", gsub("\\[", "", xi))
      # When no plate number is given, use plates = 2 plates
      xi[xi == ""] <- 2
      s <- suppressWarnings(as.numeric(as.roman(xi)))
    } else if (length(grep("plate", s) > 0) && length(grep("lea", s)) == 0) {
      # "plate" instances without "leaf" or "leaves"
      xi <- str_trim(gsub("plate", "", s))
      xi <- gsub("\\]", "", gsub("\\[", "", xi))
      # When no plate number is given, use 1 (plate = 1 page)
      xi[xi == ""] <- 1
      s <- as.numeric(xi)
    } else if (length(grep("leaf", s)) > 0) {
      # "leaf" instances 
      xi <- str_trim(gsub("leaf", "", s))
      xi <- gsub("\\]", "", gsub("\\[", "", xi))
      xi[xi == ""] <- 1
      # When no leaf number is given, use 1 (1 leaf)
      # and multiply the numbers by 2 (1 leaf = 2 pages)
      s <- 2 * as.numeric(xi)
    } else if (length(grep("leaves{0,1}", s)) > 0) {
      # "leaves" instances 
      xi <- str_trim(gsub("leaves{0,1}", "", s))   
      xi <- gsub("\\]", "", gsub("\\[", "", xi))
      # When no leaf number is given, use 2 (2 leaves)
      xi[xi == ""] <- 2
      s <- as.numeric(as.roman(xi))
    }

    # multiply the numbers xi by 2 (4 leaves = 8 pages)
    s <- plate.multiplier * as.numeric(s)
    s <- paste(s, "pages calculated from plates")

  }

  s

}


attribute_table <- function (x) {

  # Identify the different page count types and their positions
  # along the page count sequence, including
  # arabics (3), romans ("xiv"), squarebracketed ([3], [3]-5), dashed
  # (3-5, [3]-5), sheets ("2 sheets"), plates ("plates")
  # NOTE: we allow these types to be overlapping and they are later
  # used to identify the sequence type
  # Initialize attributes vs. positions table
  attributes <- c("arabic", "roman", "squarebracket", "dash", "sheet", "plate")
  pagecount.attributes <- matrix(FALSE, nrow = length(attributes), ncol = length(x))
  rownames(pagecount.attributes) <- attributes

  # ARABIC POSITIONS
  pagecount.attributes["arabic", ] <- position_arabics(x)

  # ROMAN POSITIONS
  pagecount.attributes["roman", ] <- position_romans(x)

  # SQUARE BRACKET POSITIONS
  pagecount.attributes["squarebracket", ] <- position_squarebrackets(x)

  # DASH POSITIONS
  pagecount.attributes["dash", grep("-", x)] <- TRUE

  # SHEET POSITIONS
  pagecount.attributes["sheet", ] <- position_sheets(x)

  # PLATE POSITIONS  
  # Estimate pages for plates 
  # and indicate their positions along the page count sequence
  # Example: "127,[1]p.,plates" 
  pagecount.attributes["plate", ] <- position_plates(x) 

  pagecount.attributes

}




position_arabics <- function (x) {

  positions <- rep(FALSE, length(x))

  for (i in 1:length(x)) {
    spl <- unlist(strsplit(x[[i]], "-"), use.names = FALSE)
    if (any(sapply(spl, function (x) {!is.na(suppressWarnings(as.numeric(x)))}, USE.NAMES = FALSE))) {
      positions[[i]] <- TRUE
    }
  }

  positions

}


position_squarebrackets <- function (x) {

  indsa <- sort(which(position_arabics(x))) # arabics
  indsb <- sort(unique(c(grep("\\[", x), grep("\\]", x)))) # square brackets
  inds <- sort(setdiff(indsb, indsa)) # square brackets that are not of form 91-[93]

  # Indicate positions in the page count sequence
  positions <- rep(FALSE, length(x))
  positions[inds] <- TRUE

  # Calculation of square bracket pages
  # depends on their position and dashes
  positions

}

position_sheets <- function (x) {

  grepl("sheet", x)

}


position_plates <- function (x) {

  # pages: pages calculated from plates separately for each position
  # positions: Positions for plate pages on the page count sequence
  # total: total pages calculated from plates
  grepl("pages calculated from plates", x)

}


position_romans <- function (x) {
  sapply(gsub("^\\[", "", gsub("\\]$", "", x)), function (xi) {any(is.roman(unlist(strsplit(xi, "-"), use.names = FALSE)))})
}


sumrule <- function (z) {
  sum(na.omit(suppressWarnings(as.numeric(z))))
}

count_pages <- function (z) {

  pp <- 0
  if (length(z) > 0) {
    if (seqtype(z) == "increasing.series") {
      pp <- intervalrule(z)
    } else if (seqtype(z) == "decreasing.series") {
      pp <- intervalrule(z, revert = TRUE)
    } else {
      pp <- maxrule(z)
    }
  }
  pp

}



seqtype <- function (z) {

  # series does not have any
  if (length(z)==0) {
    sequence.type <- "empty"
  } else {

    # Determine page count categories 
    # increasing / series / etc.
    sequence.type <- NA

    # Recognize increasing sequence
    increasing <- is.increasing(z)
    if (increasing) {
      # Use if to avoid unnecessary calculations.
      # Increasing series cannot be decreasing at the same time.
      decreasing <- FALSE
    } else {      
      decreasing <- is.decreasing(z)    
    }
    
    # Recognize series (ie. two-number sequences with dashes)
    series <- length(grep("^[0-9]+-[0-9]+$", z))>0 

    # Recognize single number
    single.number <- length(z) == 1 && is.numeric(suppressWarnings(as.numeric(z[[1]])) )

    # sequence has numbers without dashes
    if (!series && !increasing) { sequence.type <- "sequence" }
    if (!series && increasing)  { sequence.type <- "increasing.sequence" }
    if (!series && decreasing)  { sequence.type <- "decreasing.sequence" }    
    if (single.number) { sequence.type <- "sequence"}

    # series has dashes
    if (series && !increasing) { sequence.type <- "series" } 
    if (series && increasing) { sequence.type <- "increasing.series" }
    if (series && decreasing) { sequence.type <- "decreasing.series" }    

    # If there are several arabic elements and at least one dash among them, then use maximum
    multiple <- length(z) > 1
    if (series && multiple) { sequence.type <- "series" }

  }

  sequence.type
}


is.increasing <- function (x) {

  # Remove dashes
  x <- na.omit(suppressWarnings(as.numeric(unlist(strsplit(x, "-"), use.names = FALSE))))

  # Test if the numeric series is increasing
  incr <- FALSE
  if (!all(is.na(x))) {
    incr <- all(diff(x) >= 0)
  }

  incr
}



maxrule <- function (x) {

  xx <- as.numeric(x)
  if (any(is.na(xx))) {	
    xx <- na.omit(suppressWarnings(as.numeric(unlist(strsplit(unlist(strsplit(x, "-"), use.names = FALSE), " "), use.names = FALSE))))
  }

  max(xx)
  
}


intervalrule <- function (x, revert = FALSE) {

  xx <- na.omit(suppressWarnings(as.numeric(unlist(strsplit(x, "-"), use.names = FALSE))))

  # Revert the series around before calculation
  if (revert) {
    xx <- rev(xx)
  }
  
  max(xx) - min(xx) + 1

}



is.decreasing <- function (x) {

  # Remove dashes
  x <- na.omit(suppressWarnings(as.numeric(unlist(strsplit(x, "-"), use.names = FALSE))))

  # Test if the numeric series is decreasing
  decr <- FALSE
  if (!all(is.na(x))) {
    decr <- all(diff(x) <= 0)
  }

  decr
}



#' @title Harmonize dimension
#' @description Harmonize dimension information 
#' @param x A character vector that may contain dimension information
#' @param synonyms Synonyme table
#' @return The character vector with dimension information harmonized
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{harmonize_dimension("fol.")}
#' @keywords internal
harmonize_dimension <- function (x, synonyms = NULL) {

  s <- x
  s <- gsub("[ |\\.|\\,|\\;|\\:|\\?]+$", "", s)

  # 1915
  s[grep("^[0-9]{4,}$", s)] <- NA

  # "8" & "20"
  inds <- grep("^[0-9]*?$", s)
  s[inds] <- paste0(s[inds], "to")

  # "4; sm 2; 2" -> NA
  inds <- grep("[0-9]+.o; sm [0-9]+.o; [0-9]+.o", s)
  s[inds] <- gsub("[0-9]+.o; sm [0-9]+.o; [0-9]+.o", "", s[inds])

  # 2fo(7)
  inds <- c(grep("[0-9].o\\([0-9]\\)$", s),
          grep("[0-9].o\\([0-9]\\?\\)$", s))
  s[inds] <- substr(s[inds], 1, 3)

  # cm12mo cm.12mo
  inds <- grep("^cm\\.{0,1}[0-9]+.o$", s)
  s[inds] <- substr(s[inds], 3, 6)

  #"49 cm 2fo, 2fo"
  inds <- grep("^[0-9]* cm [0-9]+.o\\, [0-9]+.o$", s)
  s[inds] <- gsub("\\, ", "-", s[inds])

  #2; 1/2; 2
  inds <- grep("[0-9]+.o; [0-9]+.o; [0-9]+.o", s)
  s[inds] <- gsub(";", "-", s[inds])

  # 4to, 2fo and 1to
  inds <- grep("^[0-9]+.o, [0-9]+.o and [0-9]+.o$", s)
  s[inds] <- NA

  # 4to and 8vo -> 4to-8vo
  inds <- grep("[0-9]+.o and [0-9]+.o", s)
  s[inds] <- gsub(" and ", "-", s[inds])  

  #4to.;4to
  inds <- grep("^[0-9]+.o[\\.|\\,|;| ]+[0-9]+.o$", s)
  s[inds] <- gsub("[\\.|\\,|;| ]+", "-", s[inds])

  s <- gsub("- ", "-", s)

  s

}


#' @title Polish Dimension
#' @description Polish dimension field of a single document
#' @param x A dimension note (a single string of one document)
#' @param synonyms synonyms
#' @return Polished dimension information with the original string 
#' 	   and gatherings and cm information collected from it
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples # polish_dimension("4")
#' @keywords internal
polish_dimension <- function (x, synonyms) {

  # Harmonize terms
  s <- sorig <- x

  # "small"
  small <- FALSE
  if (length(grep("sm", s)) > 0) {
    s <- gsub("sm ", "", gsub("sm.", "", s))
    small <- TRUE
  }

  # Obl: height < width
  obl <- FALSE
  if (length(grep("obl", s))>0) {
    s <- gsub("obl", "", s)
    obl <- TRUE
  }

  # Handle long
  long <- FALSE
  if (length(grep("long", s)) > 0 || length(grep("\\+", s)) > 0) {
    long <- TRUE
    s <- gsub("long", "", s)
    s <- gsub("\\+", "", s)
  }

  # Pick all dimension info
  vol <- width <- height <- NA
  s <- condense_spaces(s)

  # No units given. Assume the number refers to the gatherings (not cm)
  x <- unique(str_trim(unlist(strsplit(s, " "), use.names = FALSE)))
  x[x == "NA"]   <- NA
  x[x == "NAto"] <- NA

  if (length(grep("cm", x)) == 0 && length(grep("[0-9]?o", x)) == 0) {
    if (length(x) == 1 && !is.na(x)) {
      x <- paste(as.numeric(x), "to", sep = "")
    }
  } else {
    # Pick gatherings measures separately
    x <- str_trim(unlist(strsplit(s, " "), use.names = FALSE))
  }

  hits <- unique(c(grep("[0-9]+[a-z]o", x), grep("bs", x)))

  gatherings <- NA
  if (length(hits) > 0) {
    x <- gsub(";;", "", x[hits])

    x <- unique(x)
    if (!length(x) == 1) {
      # Ambiguous gatherings info
      gatherings <- x
    } else {
      gatherings <- x
      if (long) {
        a <- unlist(strsplit(gatherings, ""), use.names = FALSE)
	ind <- min(which(is.na(as.numeric(a))))-1
	if (is.na(ind)) {ind <- length(a)}
	gatherings <- paste(paste(a[1:ind], collapse = ""), "long", sep = "")
      } else if (small) {
        a <- unlist(strsplit(gatherings, ""), use.names = FALSE)
	ind <- min(which(is.na(as.numeric(a))))-1
	if (is.na(ind)) {ind <- length(a)}
	gatherings <- paste(paste(a[1:ind], collapse = ""), "small", sep = "")
      }
    }
  }

  gatherings <- harmonize_dimension(gatherings, synonyms)

  if ( length(gatherings) == 0 ) { gatherings <- NA }
  if ( length(unique(gatherings)) > 1 ) { gatherings <- NA }

  # 4to-4to / 4to-2fo
  inds <- c(grep("^[0-9]+.o-[0-9]+.o$", gatherings), 
            grep("^[0-9]+.o-[0-9]+.o-[0-9]+.o$", gatherings))

  if (length(inds) > 0) {
    li <- lapply(gatherings[inds], function (x) {unique(unlist(strsplit(x, "-"), use.names = FALSE))})
    inds3 <- na.omit(inds[sapply(li, length) == 1])
    if (length(inds3) > 0) {
      gatherings[inds3] <- unlist(li[inds3], use.names = FALSE)
      gatherings[setdiff(inds, inds3)] <- NA
    } else {
      gatherings[inds] <- NA
    }
  }
  gatherings <- unlist(gatherings, use.names = FALSE)
  inds <- grep("^[0-9]+.o, [0-9]+.o$", gatherings)
  gatherings[inds] <- gsub("\\.;", "-", gatherings[inds])

  # Ambiguous CM information
  x <- unique(str_trim(unlist(strsplit(s, " "), use.names = FALSE)))
  if (length(grep("x", x)) > 1) {
    width <- height <- NA
  }

  # Pick CM x CM format separately when it is unambiguous
  if (length(grep("cm", x)) > 0 && length(grep("x", x)) == 1) {
      # Then pick the dimensions
      x <- unlist(strsplit(x, "cm"), use.names = FALSE)
      x <- str_trim(unlist(strsplit(x, " "), use.names = FALSE))
      i <- which(x == "x")
      if (is.numeric(str_trim(x[i+1])) && is.numeric(str_trim(x[i-1]))) {
        height <- as.numeric(str_trim(x[i+1]))
        width <- as.numeric(str_trim(x[i-1]))
      }
  } else if (length(grep("cm", x)) > 0 && length(grep("x", x)) == 0) {
      # Pick CM format (single value) separately when it is unambiguous
      # Then pick the dimensions
      x <- str_trim(unlist(strsplit(x, " "), use.names = FALSE))
      i <- which(x == "cm")
      height <- as.numeric(str_trim(x[i-1]))
      width <- NA
  } 

  # Obl: height < width
  if (!is.na(width) && !is.na(height)) {
    dims <- c(height, width)
    if (obl) {
      # NOTE: sort width and height and reverse their order if and only if
      # obl is stated; otherwise assume that the dimensions are given as height x width
      dims <- sort(dims)
      dims <- rev(dims)
    }
    width <- dims[[1]]
    height <- dims[[2]]
  }

  # If gatherings length > 1 then collapse
  gatherings <- paste(gatherings, collapse = ";")

  # Return
  list(original = sorig, gatherings = gatherings,
       width = width, height = height, obl = obl)

}



#' @title Augment Dimension Table
#' @description Estimate missing entries in dimension table where possible.
#' @param dim.tab Dimension table.
#' @param dim.info Mapping between document dimensions.
#' @param sheet.dim.tab Sheet dimension table.
#' @param verbose verbose
#' @return Augmented dimension table.
#' @seealso polish_dimensions
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("fennica")
#' @export
#' @examples # augment_dimension_table(dim.tab)
#' @keywords utilities
augment_dimension_table <- function (dim.tab, dim.info = NULL, sheet.dim.tab = NULL, verbose = FALSE) {

  width <- height <- gatherings <- NULL

  if (is.null(dim.info)) {
    if (verbose) {
      message("dim.info dimension mapping table not provided, using the default table dimension_table()")
    }
    dim.info <- dimension_table()
  }
  if (is.null(sheet.dim.tab)) {
    sheet.dim.tab <- sheet_area(verbose = verbose)
  }

  # Entry IDs
  if (verbose) {message("Unique dimension IDs.")}  
  id.orig <- apply(dim.tab, 1, function (x) {paste(as.character(x), collapse = "")})
  dim.tab.uniq <- unique(dim.tab)
  id.uniq <- apply(dim.tab.uniq, 1, function (x) {paste(as.character(x), collapse = "")})
  match.inds <- match(id.orig, id.uniq)
  rm(id.orig)

  if (verbose) {message(paste("Polishing dimension info:", nrow(dim.tab.uniq), "unique entries."))}

  # Only consider unique entries to speed up
  tmp <- NULL
  for (i in 1:nrow(dim.tab.uniq)) {
    if (verbose) {message(paste(i, "/", nrow(dim.tab.uniq)))}  
    tmp <- rbind(tmp, fill_dimensions(dim.tab.uniq[i, ], dim.info, sheet.dim.tab))
  }

  if (verbose) { message("Dimensions polished. Collecting the results.") }
  dim.tab.uniq <- as.data.frame(tmp)
  rm(tmp)
  rownames(dim.tab.uniq) <- NULL
  dim.tab.uniq$width <- as.numeric(as.character(dim.tab.uniq$width))
  dim.tab.uniq$height <- as.numeric(as.character(dim.tab.uniq$height))
  dim.tab.uniq$gatherings <- order_gatherings(dim.tab.uniq$gatherings)
  dim.tab.uniq$obl <- as.numeric(as.logical(dim.tab.uniq$obl))

  # print("Add area (width x height)")
  dim.tab.uniq <- mutate(dim.tab.uniq, area = width * height)

  # Map back to the original domain
  dim.tab.uniq[match.inds,]

}


#' @title Fill Missing Dimensions
#' @description Estimate missing entries in dimension vector where possible.
#' @param x dimension string 
#' @param dimension.table Given mappings between document dimensions
#' @param sheet.dimension.table Given mappings for sheet dimensions
#' @return Augmented dimension vector
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @export
#' @seealso augment_dimension_table
#' @examples \dontrun{
#'   dimension.table <- dimension_table(); 
#'   fill_dimensions(c(original = NA, gatherings = NA, width = 30, height = 48), dimension.table)
#' }
#' @keywords utilities
fill_dimensions <- function (x, dimension.table = NULL, sheet.dimension.table = NULL) {

    # Read dimension height/width/gatherings conversions
    if (is.null(dimension.table)) {
      dimension.table <- dimension_table()
    }
    if (is.null(sheet.dimension.table)) {
      sheet.dimension.table <- sheet_area(verbose = FALSE)
    }

    # Pick the available dimension information (some may be NAs)
    h <- as.numeric(as.character(x[["height"]]))
    w <- as.numeric(as.character(x[["width"]]))
    g <- as.character(x[["gatherings"]])
    o <- x[["original"]]

    if (!any("obl" == names(x))) {x[["obl"]] <- NA}
    obl <- x[["obl"]] 

    e <- estimate_document_dimensions(gatherings = g, height = h, width = w, obl = obl, dimension.table, sheet.dimension.table)

    w <- e$width
    h <- e$height
    g <- e$gatherings

    c(original = o, gatherings = g, width = w, height = h, obl = obl)

}



#' @title Estimate Missing Dimensions
#' @description Estimate missing dimension information.
#' @param gatherings Available gatherings information
#' @param height Available height information
#' @param width Available width information
#' @param obl Indicates height smaller than width 
#' @param dimension.table Document dimension table (from dimension_table())
#' @param sheet.dimension.table Table to estimate sheet area. 
#' 	  If not given, the table given by sheet_sizes() is used by default.
#' @return Augmented dimension information
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples # estimate_document_dimensions(gatherings = 2, height = 44)
#' @keywords utilities
estimate_document_dimensions <- function (gatherings = NA, height = NA, width = NA, obl = NULL, dimension.table = NULL, sheet.dimension.table = NULL) {

  if (is.null(gatherings) || length(gatherings) == 0) { gatherings <- NA }
  if (is.null(height) || length(height) == 0) { height <- NA }
  if (is.null(width) || length(width) == 0)  { width <- NA }

  # Ensure the inputs are of right format		     
  gatherings <- as.character(gatherings)
  width <- as.numeric(as.character(width))
  height <- as.numeric(as.character(height))

  if (length(grep("NA", gatherings)) > 0) { gatherings <- NA }
  if (length(grep("NA", width)) > 0)  { width <- NA }
  if (length(grep("NA", height)) > 0) { height <- NA }

  if (all(is.na(c(gatherings, height, width)))) {
    return(list(gatherings = gatherings, height = height, width = width))
  }

  # Height and gatherings given
  if (is.na(width) && !is.na(height) && !is.na(gatherings)) {

    if (any(gatherings == colnames(dimension.table))) {

      s <- dimension.table[dimension.table$height == round(height), gatherings]
      width <- as.numeric(as.character(s))

      if (length(width) == 0 || is.na(width)) {

        message(paste("Height (", height,") does not correspond to the gatherings (", gatherings, ") and width is not provided: trying to match width instead", sep = ""))
        width <- height
        height <- median(na.omit(as.numeric(as.character(dimension.table[which(as.character(dimension.table[, gatherings]) == round(width)), "height"]))))
       }

       if (is.na(height) || is.na(width)) {
         # warning("Height and width could not be estimated from the dimension table. Using the default gatherings size instead.")
    	 ind <- which(as.character(sheet.dimension.table$gatherings) == gatherings)
    	 width <- sheet.dimension.table[ind, "width"]
    	 height <- sheet.dimension.table[ind, "height"]
       }

    } else {
      # warning(paste("gatherings", gatherings, "not available in conversion table!"))
    }
  } else if (!is.na(width) && is.na(height) && !is.na(gatherings)) {
    # Else if width and gatherings given
    # warning("Only width and gatherings given, height is estimated from table !")
    g <- gatherings

    if (any(g == colnames(dimension.table))) {
      height <- median(na.omit(as.numeric(as.character(dimension.table[which(as.character(dimension.table[, g]) == round(width)), "height"]))))
    } else {
      # warning(paste("gatherings", g, "not available in conversion table!"))
    }

  } else if (is.na(width) && !is.na(height) && is.na(gatherings)) {

    # Only height given
    # pick the closest matches from the table
    hh <- abs(as.numeric(as.character(dimension.table$height)) - height)

    ind <- which(hh == min(hh, na.rm = TRUE))
    width <- as.numeric(as.character(dimension.table[ind, "NA"]))

    if (is.na(width)) {
      # warning(paste("No width found for height ", height, " and gatherings ", gatherings, sep = ""))
      return(
        list(gatherings = unname(gatherings),
       	     height = unname(height),
       	     width = unname(width),
       	     obl = unname(obl))
         )
    }

    # if multiple hits, pick the closest
    width <- mean(width, na.rm = TRUE)

    # Estimate gatherings
    gatherings <- estimate_document_dimensions(gatherings = NA, height = round(height), width = round(width), dimension.table = dimension.table, sheet.dimension.table = sheet.dimension.table)$gatherings    

  } else if (is.na(width) && is.na(height) && !is.na(gatherings)) {

    # Only gatherings given
    ind <- which(as.character(sheet.dimension.table$gatherings) == gatherings)
      
    width <- sheet.dimension.table[ind, "width"]
    height <- sheet.dimension.table[ind, "height"]

  } else if (!is.na(width) && !is.na(height) && is.na(gatherings)) {

    # width and height given; estimate gatherings
    # The closest matched for height
    hs <- as.numeric(as.character(dimension.table$height))

    hdif <- abs(hs - height)

    inds <- which(hdif == min(hdif, na.rm = TRUE))

    # corresponding widths
    ws <- dimension.table[inds, ]
    ginds <- c()

    for (wi in 1:nrow(ws)) {
      d <- abs(as.numeric(as.character(unlist(ws[wi,], use.names = FALSE))) - width)
      ginds <- c(ginds, setdiff(which(d == min(d, na.rm = TRUE)), 1:2))
    }
    gs <- unique(colnames(dimension.table)[unique(ginds)])

    # If gatherings is uniquely determined
    if (length(gs) == 1) {
      gatherings <- gs
    } else {
      # warning(paste("Ambiguous gatherings - not determined for width / height ", width, height, paste(gs, collapse = "/")))
    }
  } else if (!is.na(width) && is.na(height) && is.na(gatherings)) {
    # Only width given
    height <- as.numeric(dimension.table[which.min(abs(as.numeric(dimension.table[, "NA"]) - as.numeric(width))), "NA"])
    
    # If multiple heights match, then use average
    height <- mean(height, na.rm = TRUE)

    # Estimate gatherings
    gatherings <- estimate_document_dimensions(gatherings = NA, height = height, width = width, dimension.table = dimension.table)$gatherings
  }


  if (length(width) == 0) {width <- NA}
  if (length(height) == 0) {height <- NA}
  if (length(gatherings) == 0) {gatherings <- NA}

  if (is.na(width)) {width <- NA}
  if (is.na(height)) {height <- NA}
  if (is.na(gatherings)) {gatherings <- NA}

  height <- as.numeric(height)
  width <- as.numeric(width)

  # In obl width > height

  if (length(obl) > 0 && !is.na(obl) && any(obl)) {

    hw <- cbind(height = height, width = width)
    inds <- 1

    if (length(obl) > 1) {
      inds <- which(obl)
    }

    for (i in inds) {
      xx <- hw[i, ]
      if (sum(is.na(xx)) == 0) {
        hw[i, ] <- sort(xx)
      }
    }
    height <- hw[, "height"]
    width <- hw[, "width"]     
  }

  list(gatherings = unname(gatherings),
       height = unname(height),
       width = unname(width),
       obl = unname(obl))
}


#' @title Enrich Geodata
#' @description Enrich geodata.
#' @param x Publication place character vector
#' @return Augmented data.frame
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{df2 <- enrich_geo(df)}
#' @keywords utilities
enrich_geo <- function(x) {

  message("Enriching geo fields..")
  df <- data.frame(place = x)
  geonames <- places.geonames <- NULL

  message("Geocoordinates")
  # Use some manually fetched data
  load(system.file("extdata/geonames.RData", package = "fennica"))
  load(system.file("extdata/places.geonames.RData", package = "fennica"))
  
  geoc <- get_geocoordinates(df$place,
            geonames, places.geonames)

  geoc$place <- df$place

  message("Add publication country")
  df$country <- get_country(df$place)
  message(".. publication country added")  

  return (df)
  
}

#' @title Compare Title Count and Paper Consumption
#' @description Compare title count and paper consumption for selected field.
#' @param x data frame
#' @param field Field to analyze
#' @param selected Limit the analysis on selected entries
#' @param plot.mode "text" or "point"
#' @return List:
#' \itemize{
#'   \item{plot}{ggplot object}
#'   \item{table}{summary table}
#' }
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("bibliographica")
#' @examples \dontrun{compare_title_paper(df, "author")}
#' @keywords utilities
compare_title_paper <- function (x, field, selected = NULL, plot.mode = "text") {

  paper <- publication_decade <- titles <- paper <- NULL

  x$field <- x[[field]]

  # Nothing selected - take all
  if (is.null(selected)) {selected <- unique(x$field)}

  x <- x %>% filter(!is.na(field)) %>%
            filter(field %in% selected) %>%
	    group_by(field) %>%	    
            summarize(titles = n(),
                      paper = sum(paper, na.rm = T))


  # Prepare the plot
  p <- ggplot(x, aes(x = titles, y = paper)) +
    xlab("Title count") + ylab("Standard sheets") + 
    ggtitle(paste("Title count versus paper (", field, ")")) +
    scale_x_log10() + scale_y_log10() 

  if (plot.mode == "text") {
    p <- p + geom_text(aes(label = field), size = 5) 
  } else if (plot.mode == "point") {
    p <- p + geom_point(size = 2)
  }

  colnames(x)[[1]] <- field

  list(plot = p, table = x)

}



#' @title Get Geocoordinates
#' @description Map geographic places to geocoordinates.
#' @param x A vector of publication place names
#' @param geonames geonames
#' @param places.geonames places.geonames
#' @return data.frame with latitude and longitude
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{x2 <- get_geocoordinates("Berlin")}
#' @details Experimental.
#' @keywords utilities
get_geocoordinates <- function (x, geonames, places.geonames) {

  places <- asciiname <- country.code <- admin1 <- NULL

  pubplace.orig <- as.character(x)
  pubplace <- pubplace.uniq <- unique(pubplace.orig)

  # print("Match to geonames")
  geocoordinates <- geonames[match(places.geonames, geonames$asciiname), ]
  geocoordinates$latitude <- as.numeric(as.character(geocoordinates$latitude))
  geocoordinates$longitude <- as.numeric(as.character(geocoordinates$longitude))
  rownames(geocoordinates) <- places

  # TODO investigate opportunities to have identifiers for all major cities
  # Fill in manually the largest publication places that could not be uniquely matched to a location
  # and are hence still missing the coordinates
  #top <- rev(sort(table(subset(df, publication_place %in% names(which(is.na(places.geonames)))$publication_place)))

  message("Manual matching")
  place <- "London"
  f <- filter(geonames, asciiname == place & country.code == "GB")
  geocoordinates[place,] <- f

  place <- "Edinburgh"
  f <- geonames[intersect(grep("Edinburgh", geonames$alternatenames), which(geonames$country.code == "GB")),]
  geocoordinates[place,] <- f

  place <- "Dublin"
  f <- filter(geonames, asciiname == place & country.code == "IE")	
  geocoordinates[place,] <- f

  place <- "Philadelphia Pa"
  f <- filter(geonames, asciiname == "Philadelphia" & admin1 == "PA")
  geocoordinates[place,] <- f

  place <- "Boston"
  f <- filter(geonames, asciiname == place & country.code == "GB")
  geocoordinates[place,] <- f

  # TODO geonames matching might be improved if country code would be included
  # in the matching in the first place and not afterwards manually - to be implemented?
  place <- "Boston Ma"
  f <- filter(geonames, asciiname == "Boston" & country.code == "US")
  geocoordinates[place,] <- f

  # TODO Many options - in general check all with Mikko
  place <- "Oxford"
  f <- filter(geonames, asciiname == place & admin1 == "NY")
  geocoordinates[place,] <- f

  place <- "New York N.Y"
  f <- geonames[intersect(grep("New York", geonames$alternatenames), which(geonames$feature.code == "PPL")),]
  geocoordinates[place,] <- f

  place <- "York"
  f <- geonames[intersect(grep("York", geonames$alternatenames), which(geonames$country.code == "GB" & geonames$admin2 == "H3")),]
  geocoordinates[place, ] <- f

  place <- "Glasgow"
  f <- geonames[intersect(grep("Glasgow", geonames$alternatenames), which(geonames$country.code == "GB" & geonames$admin1 == "ENG")),]
  geocoordinates[place,] <- f

  place <- "York"
  f <- geonames[intersect(grep("York", geonames$alternatenames), which(geonames$country.code == "GB" & geonames$admin2 == "H3")),]
  geocoordinates[place,] <- f

  place <- "Cambridge"
  f <- filter(geonames, asciiname == place & country.code == "GB")
  geocoordinates[place,] <- f

  # Checked manually
  place <- "Providence R.I"
  geocoordinates[place, ] <- rep(NA, ncol(geocoordinates))
  geocoordinates[place, c("latitude", "longitude")] <- c(41.8384163, -71.4256989)

  place <- "Hartford Ct"
  f <- geonames[intersect(grep("Hartford", geonames$alternatenames), which(geonames$admin1 == "MA")),]
  geocoordinates[place,] <- f

  place <- "Amsterdam"
  f <- filter(geonames, asciiname == place & country.code == "NL")
  geocoordinates[place,] <- f

  place <- "Bristol"
  f <- filter(geonames, asciiname == place & country.code == "GB")
  geocoordinates[place,] <- f

  place <- "Norwich"
  f <- filter(geonames, asciiname == place & country.code == "GB")
  geocoordinates[place,] <- f

  place <- "Newcastle"
  f <- filter(geonames, asciiname == place & country.code == "GB")
  geocoordinates[place,] <- f

  place <- "Aberdeen"
  f <- filter(geonames, asciiname == place & country.code == "GB")
  geocoordinates[place,] <- f

  place <- "Watertown Ma"
  f <- filter(geonames, asciiname == "Watertown" & admin1 == "MA")
  geocoordinates[place,] <- f

  place <- "Paris"	 
  f <- filter(geonames, asciiname == place & country.code == "FR")
  geocoordinates[place,] <- f

  place <- "Baltimore Md" 
  f <- filter(geonames, asciiname == "Baltimore")
  geocoordinates[place,] <- f

  message("Read custom mappings from file")
  # FIXME integrate all into a single place - country - geocoordinates file
  # that will be used in place - country and place - coordinate mappings
  # systematically
  f <- system.file("extdata/geocoordinates.csv", package = "fennica")
  geotab <- read.csv(f, sep = "\t")
  rownames(geotab) <- geotab$place
  coms <- intersect(geotab$place, rownames(geocoordinates))
  geocoordinates[coms, c("latitude", "longitude")] <- geotab[coms, c("latitude", "longitude")]

  latitude <- as.numeric(as.character(geocoordinates[as.character(pubplace), "latitude"]))
  longitude <- as.numeric(as.character(geocoordinates[as.character(pubplace), "longitude"]))

  skip <- T
  if (!skip) {

  # Places with missing geocoordinates
  absent <- rownames(geocoordinates[is.na(geocoordinates$latitude), ])
  missing <- sort(unique(rownames(geocoordinates[is.na(geocoordinates$latitude), ])))

  # print("List all potential hits in geonames")
  hits <- list()
  if (length(missing) > 0) {
    for (place in missing) {
      # print(place)
      inds <- unique(c(grep(place, geonames$name), grep(place, geonames$asiiname), grep(place, geonames$alternatenames)))

      # Cambridge Ma -> Cambridge
      spl <- unlist(strsplit(place, " "))
      spl <- spl[-length(spl)]
      place2 <- paste(spl, collapse = " ")
      inds2 <- unique(c(grep(place2, geonames$name), grep(place2, geonames$asiiname), grep(place2, geonames$alternatenames)))
      inds <- unique(c(inds, inds2))

      hits[[place]] <- geonames[inds,]
    }
  }

  message("Places with no hit whatsoever in geonames")
  absent <- NULL 
  if (length(hits) > 0) {
    absent <- names(which(sapply(hits, function (x) {nrow(x) == 0})))
  }

  }

  tmpdf <- quickdf(list(latitude = latitude, longitude = longitude))

  # Now for missing geocoordinates try further custom data
  nainds <- is.na(tmpdf$latitude) | is.na(tmpdf$longitude)
  missing.geoc <- pubplace.uniq[nainds]

  f2 <- system.file("extdata/geoc_Kungliga.Rds", package = "fennica")
  f3 <- system.file("extdata/geoc_Finland.Rds", package = "fennica")    
  f2r <- readRDS(f2)
  f3r <- readRDS(f2)
  gctmp <- unique(bind_rows(f2r, f3r))
  tmpdf$latitude[nainds]  <- gctmp$lat[match(missing.geoc, gctmp$publication_place)]
  tmpdf$longitude[nainds] <- gctmp$lon[match(missing.geoc, gctmp$publication_place)]

  # Map back to the original domain
  return(tmpdf[match(pubplace.orig, pubplace.uniq),])

}

#' @title Dimension Table
#' @description Document dimension mapping table.
#' @param ... Arguments to be passed
#' @return Document dimension table
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("bibliographica")
#' @examples dimension_table()
#' @keywords utilities
dimension_table <- function (...) {
  
  f <- system.file("extdata/documentdimensions.csv", package = "bibliographica")
  dd <- read.csv(f, header = TRUE, sep = ",")# [-1,]
  colnames(dd) <- gsub("^X", "", colnames(dd))
  colnames(dd)[[1]] <- "height"
  colnames(dd) <- gsub("NA.", "NA", colnames(dd))
  dd <- dd[-1,]
  
  dd <- apply(dd, 2, as.character)
  
  # Add 1to
  ss <- sheet_sizes()
  
  dd <- cbind(dd, "1to" = rep("x", nrow(dd)))
  row1 <- rep("x", ncol(dd))
  dd <- rbind(row1, dd)  
  dd[, "height"] <- as.character(dd[, "height"])
  dd[,"NA"] <- as.character(dd[,"NA"])
  dd[,"1to"] <- as.character(dd[,"1to"])
  inds <- ss$gatherings == "1to"
  dd[1, "height"] <- ss[inds, "height"]
  dd[1, "NA"] <- ss[inds, "width"]
  dd[1, "1to"] <- ss[inds, "width"]
  
  # Reorder columns
  rownames(dd) <- NULL
  
  dd <- as.data.frame(dd, stringsAsFactors = FALSE)
  
  dd
  
}


#' @title Dimension Table
#' @description Document dimension mapping table.
#' @param ... Arguments to be passed
#' @return Document dimension table
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("bibliographica")
#' @examples dimension_table()
#' @keywords utilities
dimension_table <- function (...) {
  
  #f <- system.file("extdata/documentdimensions.csv", package = "bibliographica")
  dd <- read.csv("documentdimensions.csv", header = TRUE, sep = ",")# [-1,]
  colnames(dd) <- gsub("^X", "", colnames(dd))
  colnames(dd)[[1]] <- "height"
  colnames(dd) <- gsub("NA.", "NA", colnames(dd))
  dd <- dd[-1,]
  
  dd <- apply(dd, 2, as.character)
  
  # Add 1to
  ss <- sheet_sizes()
  
  dd <- cbind(dd, "1to" = rep("x", nrow(dd)))
  row1 <- rep("x", ncol(dd))
  dd <- rbind(row1, dd)  
  dd[, "height"] <- as.character(dd[, "height"])
  dd[,"NA"] <- as.character(dd[,"NA"])
  dd[,"1to"] <- as.character(dd[,"1to"])
  inds <- ss$gatherings == "1to"
  dd[1, "height"] <- ss[inds, "height"]
  dd[1, "NA"] <- ss[inds, "width"]
  dd[1, "1to"] <- ss[inds, "width"]
  
  # Reorder columns
  rownames(dd) <- NULL
  
  dd <- as.data.frame(dd, stringsAsFactors = FALSE)
  
  dd
  
}


#' @title Sheet Area
#' @description Sheet area in cm2.
#' @param x Sheet size 
#' @param sheet.dimension.table Table to estimate sheet area. 
#' 	  If not given, the table given by sheet_sizes() is used by default.
#' @param verbose Verbose
#' @return Sheet area (cm2)
#' @export
#' @details Sheet size is calculated according to the table given as output 
#'          from call sheet_area()
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("bibliographica")
#' @examples sheet_area("2to")
#' @keywords utilities
sheet_area <- function (x = NULL, sheet.dimension.table = NULL, verbose = FALSE) {
  
  if (is.null(sheet.dimension.table)) {
    
    if (verbose) {message("sheet.dimension.table not given, using sheet_sizes() mapping table by default")}
    tab <- sheet_sizes()
  } else {
    tab <- sheet.dimension.table
  }
  
  # Ensure correct formatting
  tab$format <- str_trim(as.character(tab$format))
  tab$gatherings <- str_trim(as.character(tab$gatherings))
  for (i in c("width", "height", "area")) {
    tab[,i] <- as.numeric(str_trim(as.character(tab[,i])))
  }
  
  if (!is.null(x)) {
    x <- as.character(x)
    ind <- which((tab$format %in% x) | (tab$gatherings %in% x))
    
    if (length(ind) > 0) {
      area <- tab[ind, "area"]
      
      if (verbose) {
        message(paste("The input", x, "corresponds to", tab[ind, "sheet"], "paper with", tab[ind, "width"], "cm width and", tab[ind, "height"], "cm height and an area of", tab[ind, "area"], "cm2"))
      }
    } else {
      # warning(paste(x, "not found from the sheet size conversion table"))
      return(NA)
    }
  } else {
    return(tab)
  }
  
  area
  
}


#' @title Sheet Sizes
#' @description Read sheet size table.
#' @param ... Arguments to be passed
#' @return Sheet size table
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("bibliographica")
#' @examples sheetsizes <- sheet_sizes()
#' @keywords utilities
sheet_sizes <- function (...) {  
  
  # Read the mapping table
  #f <- system.file("extdata/sheetsizes.csv", package = "bibliographica")
  tab <- as.data.frame(read.csv("sheetsizes.csv", sep = ","))
  tab$format <- str_trim(as.character(tab$format))
  tab$gatherings <- str_trim(as.character(tab$gatherings)) 
  tab$gatherings <- order_gatherings(tab$gatherings)
  
  tab  
}

#' @title order_gatherings
#' @description Sort gatherings levels 
#' @param x A vector or factor of gathering data
#' @return A factor with ordered gatherings levels
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("bibliographica")
#' @examples order_gatherings(factor(c("2fo", "1to", "8vo")))
#' @export
#' @keywords utilities
order_gatherings <- function (x) {
  
  # Remove unrecognized formats
  x <- polish_gatherings(x)
  
  # Recognize gatherings format (2fo or folio)
  format <- gatherings_format(x)
  
  # Denote the ordering directly in the table		 
  glevels <- tolower(unique(gatherings_table()[[format]]))
  
  # Capitalize
  x <- str_to_title(x)
  glevels <- str_to_title(glevels)
  
  # Exception
  x <- gsub("Bs", "bs", x)
  glevels <- gsub("Bs", "bs", glevels)  
  
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  fails <- unlist(setdiff(unique(x), glevels), use.names = FALSE)
  x[x %in% fails] <- "NA"
  inds <- which(glevels %in% x)
  glevels <- glevels[inds]
  
  # Order the levels
  factor(x, levels = glevels)
}


#' @title polish_gatherings
#' @description Polish gatherings
#' @param x A vector or factor of gathering data
#' @return A factor with polished gatherings levels
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("bibliographica")
#' @examples polish_gatherings(factor(c("2fo", "1tolded", "8vo")))
#' @export
#' @keywords utilities
polish_gatherings <- function (x) {
  
  gtab <- gatherings_table()
  
  # Denote the polishing directly in the table		 
  glevels <- unique(c(gtab$Standard,
                      gtab$Name,
                      gtab$Alternate,
                      gtab$Symbol))
  
  glevels <- unique(c(glevels, tolower(glevels)))
  
  # Remove unrecognized formats
  inds <- which(!tolower(x) %in% glevels)
  if (length(inds) > 0) {
    warning(paste("Removing the following unrecognized gatherings:", paste(sort(unique(x[inds])), collapse = ", ")))
    x[inds] <- NA
  }
  
  tolower(x)
  
}

#' @title Gatherings Table
#' @description Document gatherings names mapping table.
#' @param ... Arguments to be passed
#' @return Document gatherings table
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("bibliographica")
#' @examples gatherings_table()
#' @keywords utilities
gatherings_table <- function (...) {
  
  #f <- system.file("extdata/document_size_abbreviations.csv", package = "bibliographica")
  dd <- read.csv("document_size_abbreviations.csv", header = TRUE, sep = ";")
  dd <- apply(dd, 2, as.character)
  dd[dd == ""] <- NA
  dd <- as.data.frame(dd, stringsAsFactors = FALSE)
  
  dd
  
}

# Recognize gatherings format
gatherings_format <- function (x) {
  
  gtab <- gatherings_table()
  
  # Majority vote
  names(which.max(apply(gtab, 2, function (i) {sum(x %in% i)})))
  
}




#' @title Polish physical_extent Help Field
#' @description Internal
#' @param s input char
#' @return vector
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("bibliographica")
#' @keywords internal
polish_physext_help <- function (s, page.harmonize) {
  
  # Return NA if conversion fails
  if (length(s) == 1 && is.na(s)) {
    #return(rep(NA, 11))
    s <- ""
  } 
  
  # 141-174. [2] -> "141-174, [2]"
  if (grepl("[0-9]+\\.", s)) {
    s <- gsub("\\.", ",", s)
  }
  
  # Shortcut for easy cases: "24p."
  if (length(grep("^[0-9]+ *p\\.*$",s))>0) {
    #return(c(as.numeric(str_trim(gsub(" {0,1}p\\.{0,1}$", "", s))), rep(NA, 9)))
    s <- as.numeric(str_trim(gsub(" {0,1}p\\.{0,1}$", "", s)))
  }
  
  # Pick volume number
  voln <- pick_volume(s) 
  
  # Volume count
  vols <- unname(pick_multivolume(s))
  
  # Parts count
  parts <- pick_parts(s)
  
  # "2 pts (96, 110 s.)" = 96 + 110s
  if (length(grep("[0-9]+ pts (*)", s)) > 0 && length(grep(";", s)) == 0) {
    s <- gsub(",", ";", s)
  }
  
  # Now remove volume info
  s <- suppressWarnings(remove_volume_info(s))
  
  # Cleanup
  s <- gsub("^;*\\(", "", s)
  s <- gsub(" s\\.*$", "", s)
  s <- condense_spaces(s)
  
  # If number of volumes is the same than number of comma-separated units
  # and there are no semicolons, then consider the comma-separated units as
  # individual volumes and mark this by replacing commas by semicolons
  # ie. 2v(130, 115) -> 130;115
  if (!is.na(s) && !is.na(vols) && length(unlist(strsplit(s, ","), use.names = FALSE)) == vols && !grepl(";", s)) {
    s <- gsub(",", ";", s)  
  }
  
  # Estimate pages for each document separately via a for loop
  # Vectorization would be faster but we prefer simplicity and modularity here
  
  if (length(grep(";", s)) > 0) {
    spl <- unlist(strsplit(s, ";"), use.names = FALSE)
    page.info <- sapply(spl, function (x) {polish_physext_help2(x, page.harmonize)})
    page.info <- apply(page.info, 1, function (x) {sum(as.numeric(x), na.rm = TRUE)})
    page.info[[1]] <- 1 # Not used anymore after summing up  
  } else {
    page.info <- polish_physext_help2(s, page.harmonize)
  }
  
  s <- page.info[["pagecount"]]
  page.info <- page.info[-7]
  s[s == ""] <- NA
  s[s == "NA"] <- NA  
  s <- as.numeric(s)
  s[is.infinite(s)] = NA
  
  # Return
  names(page.info) <- paste0("pagecount.", names(page.info))
  # Add fields to page.info  		   
  page.info[["pagecount"]] <- as.vector(s)
  page.info[["volnumber"]] <- as.vector(voln)
  page.info[["volcount"]] <- as.vector(vols)
  page.info[["parts"]] <- as.vector(parts)
  page.info <- unlist(page.info)
  
  page.info
  
}


#' @title Polish physical_extent help field 2
#' @description Internal
#' @param x Input char
#' @return Internal
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("bibliographica")
#' @examples # TBA
#' @keywords internal

# Extract similar operations into separate functions
replace_pattern <- function(x, pattern, replacement) {
  gsub(pattern, replacement, x)
}

# Use `case_when` to replace multiple `if` conditions
polish_physext_help2 <- function (x, page.harmonize) {
  
  x <- as.character(map(x, page.harmonize, mode = "recursive"))
  
  x <- case_when(
    any(grepl("i\\.e", x)) ~ replace_pattern(x, ",", " "),
    any(grepl("\\[[0-9]+\\] p \\(p \\[[0-9]+\\] blank\\)", x)) ~ replace_pattern(x, " \\(p \\[[0-9]+\\] blank\\)", ""),
    any(grepl("^1 score \\([0-9]+ p\\)", x)) ~ replace_pattern(x, "1 score", ""),
    any(grepl("^[0-9]+ p \\[[0-9]+\\]$", x)) ~ replace_pattern(x, "\\[", ",["),
    any(grepl("^\\[[0-9]+\\] p \\[[0-9]+\\]$", x)) ~ {
      split_result <- strsplit(x, "p")
      if (length(split_result[[1]]) > 0) {
        unlist(split_result)[[1]]
      } else {
        x
      }
    },
    any(grepl("\\[[0-9]+\\] [0-9]+", x)) ~ replace_pattern(x, " ", ","),
    any(grepl("^[0-9]+ \\[[0-9]+\\]", x)) ~ replace_pattern(x, "\\[", ",["),
    any(grepl("[0-9]+p",x)) ~ replace_pattern(x, "p", " p"),
    TRUE ~ x
  )
  
  # Continue with the rest of your function...
  
  # Remove endings
  x <- gsub("[ |\\.|\\,|\\;|\\:]+$", "", x)
  
  # Remove spaces around dashes
  x <- gsub(" {0,1}- {0,1}", "-", x)
  x <- condense_spaces(x) 
  
  # Remove parentheses
  x <- gsub("\\(", " ", x)
  x <- gsub("\\)", " ", x)
  x <- condense_spaces(x) 
  x <- condense_spaces(gsub(" p p ", " p ", x))
  
  # 2 p [1] = 2, [1]
  if (any(grepl("^[0-9]+ p \\[[0-9]+\\]$", x))) {
    x <- condense_spaces(gsub("\\[", ",[", gsub("p", "", x)))
  }
  
  # [4] p [4] = [4], [4]
  if (any(grepl("^\\[[0-9]+\\] p \\[[0-9]+\\]$", x))) {
    split_result <- strsplit(x, "p")
    if (length(split_result[[1]]) > 0) {
      unlist(split_result)[[1]]
    } else {
      x
    }
  }
  
  # "[2] 4" -> "[2], 4"
  if (any(grepl("\\[[0-9]+\\] [0-9]+", x))) {
    x <- gsub(" ", ",", x)
  }
  
  # "4 [2]" -> 4, [2]
  if (any(grepl("^[0-9]+ \\[[0-9]+\\]", x))) {
    x <- gsub("\\[", ",[", x)  
  }
  
  if (any(grepl("[0-9]+p",x))) {
    x <- condense_spaces(gsub("p", " p", x))
  }
  
  x <- gsub("p\\.*$", "", x)
  # [4] p 2:o -> 4
  x <- gsub("[0-9]:o$", "", x)
  x <- gsub("=$", "", x)
  x <- gsub("^[c|n]\\.", "", x)
  x <- gsub("p \\[", "p, [", x)
  x <- gsub(": b", ",", x) 
  x <- condense_spaces(x)
  x <- gsub(" ,", ",", x)
  x <- gsub("^,", "", x)  
  
  x <- condense_spaces(x)
  
  page.info <- estimate_pages(x)
  
  # Take into account multiplier
  # (for instance when page string starts with Ff the document is folios
  # and page count will be multiplied by two - in most cases multiplier is 1)
  # Total page count; assuming the multiplier is index 1
  s <- unlist(page.info[-1], use.names = FALSE)
  page.info[["pagecount"]] <- page.info[["multiplier"]] * sum(s, na.rm = TRUE)
  
  page.info
  
}



#' @title Polish signature statements
#' @description Internal
#' @param s input char
#' @return vector
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("bibliographica") and explanations of signature statements in \url{https://collation.folger.edu/2016/05/signature-statements/} and \url{https://manual.stcv.be/p/Inputting_Collation_Data_in_Brocade}.
#' @keywords internal
polish_signature_statement_pagecount <- function (s) {
  
  inds <- which(grepl("sup", s))
  ss <- rep(NA, length(s))
  
  if (length(inds)>0) {
    pages <- sapply(s[inds], function (xx) {sum(polish_signature_statements(xx))})
    ss[inds] <- pages
    
  }
  
  names(ss) <- s
  
  ss
  
}

#' @title Polish signature statements
#' @description Internal
#' @param s input char
#' @return vector
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("bibliographica") and explanations of signature statements in \url{https://collation.folger.edu/2016/05/signature-statements/} and \url{https://manual.stcv.be/p/Inputting_Collation_Data_in_Brocade}.
#' @keywords internal
polish_signature_statements <- function (x) {
  
  x <- str_trim(x)
  
  x <- str_trim(gsub("\\([a-z|0-9|,| |\\?]*\\)", "", x))
  
  x <- unlist(str_split(x, " "))
  
  # Pages for all items
  pages <- unlist(sapply(x, function (xx) {polish_signature_statement(xx)}))
  
  pages
  
}


polish_signature_statement <- function (s) {
  
  hit <- any(grepl("[a-z]*?sup?[0-9]*?[a-z]*?", s))
  pages <- NA
  
  if (hit) {
    item <- str_extract(s, "^[a-z|0-9|-]*")     
    pages <- str_extract(s, "[0-9]+")
    pages <- as.numeric(pages)
    names(pages) <- item
    
    if (str_detect(item, "-")) {
      items <- unlist(str_split(item, "-"))
      
      ind1 <- match(items[[1]], letters)
      ind2 <- match(items[[2]], letters)
      if (!is.na(ind1) & !is.na(ind2)) {
        items <- letters[ind1:ind2]
        pages <- rep(pages, length(items))
        names(pages) <- items
      } else {
        pages <- NA
      }
    }
  }
  
  pages
  
}


#' @title Polish physical_extent Help Field
#' @description Internal
#' @param s input char
#' @return vector
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("bibliographica")
#' @keywords internal
polish_physext_help <- function (s, page.harmonize) {
  
  # Return NA if conversion fails
  if (length(s) == 1 && is.na(s)) {
    #return(rep(NA, 11))
    s <- ""
  } 
  
  # 141-174. [2] -> "141-174, [2]"
  if (grepl("[0-9]+\\.", s)) {
    s <- gsub("\\.", ",", s)
  }
  
  # Shortcut for easy cases: "24p."
  if (length(grep("^[0-9]+ *p\\.*$",s))>0) {
    #return(c(as.numeric(str_trim(gsub(" {0,1}p\\.{0,1}$", "", s))), rep(NA, 9)))
    s <- as.numeric(str_trim(gsub(" {0,1}p\\.{0,1}$", "", s)))
  }
  
  # Pick volume number
  voln <- pick_volume(s) 
  
  # Volume count FIX needed
  vols <- unname(pick_multivolume(s))
  
  # Parts count
  parts <- pick_parts(s)
  
  # "2 pts (96, 110 s.)" = 96 + 110s
  if (length(grep("[0-9]+ pts (*)", s)) > 0 && length(grep(";", s)) == 0) {
    s <- gsub(",", ";", s)
  }
  
  # Now remove volume info
  s <- suppressWarnings(remove_volume_info(s))
  
  # Cleanup
  s <- gsub("^;*\\(", "", s)
  s <- gsub(" s\\.*$", "", s)
  s <- condense_spaces(s)
  
  # If number of volumes is the same than number of comma-separated units
  # and there are no semicolons, then consider the comma-separated units as
  # individual volumes and mark this by replacing commas by semicolons
  # ie. 2v(130, 115) -> 130;115
  if (!is.na(s) && !is.na(vols) && length(unlist(strsplit(s, ","), use.names = FALSE)) == vols && !grepl(";", s)) {
    s <- gsub(",", ";", s)  
  }
  
  # Estimate pages for each document separately via a for loop
  # Vectorization would be faster but we prefer simplicity and modularity here
  
  if (length(grep(";", s)) > 0) {
    spl <- unlist(strsplit(s, ";"), use.names = FALSE)
    page.info <- sapply(spl, function (x) {polish_physext_help2(x, page.harmonize)})
    page.info <- apply(page.info, 1, function (x) {sum(as.numeric(x), na.rm = TRUE)})
    page.info[[1]] <- 1 # Not used anymore after summing up  
  } else {
    page.info <- polish_physext_help2(s, page.harmonize)
  }
  
  s <- page.info[["pagecount"]]
  page.info <- page.info[-7]
  s[s == ""] <- NA
  s[s == "NA"] <- NA  
  s <- as.numeric(s)
  s[is.infinite(s)] = NA
  
  # Return
  names(page.info) <- paste0("pagecount.", names(page.info))
  # Add fields to page.info
  vols <- vols[1:length(page.info[["volcount"]])]
  page.info[["pagecount"]] <- as.vector(s)
  page.info[["volnumber"]] <- as.vector(voln)
  #FIX below
  vols <- vols[1:length(page.info[["volcount"]])]
  page.info[["volcount"]] <- as.vector(vols)
  page.info[["parts"]] <- as.vector(parts)
  page.info <- unlist(page.info)
  
  page.info
  
}


#' @title Polish physical_extent Field
#' @description Pick page counts, volume counts and volume numbers.
#' @param x Page number field. Vector or factor of strings.
#' @param verbose Print progress info
#' @return Raw and estimated pages per document part
#' @details Document parts are separated by semicolons
#' @export
#' @details A summary of page counting rules that this function aims to (approximately) implement are provided in 
#' \url{https://www.libraries.psu.edu/psul/cataloging/training/bpcr/300.html}
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("bibliographica")
#' @examples tab <- polish_physical_extent("4p.", verbose = TRUE)
#' @keywords utilities
polish_physical_extent <- function (x, verbose = FALSE, rm.dim.file = NULL) {
  
  # Summary of abbreviations
  # http://ac.bslw.com/community/wiki/index.php5/RDA_4.5
  sorig <- tolower(as.character(x))
  suniq <- unique(sorig)
  
  if (verbose) {
    message(paste("Polishing physical extent field:",
                  length(suniq),
                  "unique cases"))
  }
  
  s <- suniq
  if (verbose) {message("Signature statements")}
  inds <- grep("sup", s)
  if (length(inds)>0) {
    pc <- polish_signature_statement_pagecount(s[inds])
    s[inds] <- unname(pc)
  }
  
  if (verbose) {message("Remove commonly used volume formats")}
  f <- read.csv("remove_dimension.csv", sep = ";", row.names=NULL)
  
  #if (verbose) {
    #message(paste("Reading", f, "in polish_physical_extent.R"))
  #}
  
  li <- f [,1]
  terms <- as.character(li)
  s <- remove_dimension(s, terms)
  s <- gsub("^na ", "", s)
  s <- gsub("\\.s$", " s", s)
  s <- gsub("\\. s", " s", s)    
  s <- gsub("&", ",", s)
  s <- gsub("\\*", " ", s)
  s <- gsub("\\{", "[", s)
  s <- gsub("\\}", "]", s)
  s[grep("^[ |;|:|!|?]*$", s)] <- NA 
  
  if (verbose) {
    message("Remove dimension info")
  }
  s <- gsub("^[0-9]+.o ", "", s) 
  
  if (verbose) {
    message("In Finnish texts s. is used instead of p.")
  }
  
  # Broken
  f <- read.csv("translation_fi_en_pages.csv", sep = ";", row.names=NULL)
  if (verbose) {
    message(paste("Reading", f))
  }
  
  #page.synonyms <- read_mapping(file = f, sep = ";", mode = "table", fast = TRUE)
  s <- map(s, f, mode="match")
  #rm(page.synonyms)
  
  if (verbose) {
    message("numbers_finnish")
  }
  
  f <- read.csv("numbers_finnish.csv", sep = ",")
  #char2num <- read_mapping(f, sep = ",", mode = "table", from = "character", to = "numeric")
  s <- map(s, synonymes = f, from = "character", to = "numeric", mode = "match")

  
  if (verbose) {message("Harmonize volume info")}
  inds <- setdiff(1:length(s), grep("^v\\.$", s))
  if (length(inds)>0) {
    s[inds] <- remove_trailing_periods(s[inds])
  }
  
  # Harmonize volume info
  s <- unname(harmonize_volume(s))
  
  # Back to original indices and new unique reduction 
  sorig <- s[match(sorig, suniq)]
  s <- suniq <- unique(sorig)
  
  if (verbose) {message("Harmonize ie")}
  s <- harmonize_ie(s)
  
  s[s == ""] <- NA
  
  if (verbose) {message("Read the mapping table for sheets")}  
  f <- read.csv("harmonize_sheets.csv", sep = ";")  
  
  #sheet.harmonize <- read_mapping(f, sep = ";", mode = "table", fast = TRUE)
  s <- harmonize_sheets(s, f)
  #rm(sheet.harmonize)
  
  # Just read page harmonization here to be used later
  if (verbose) {message("Read the mapping table for pages")}
  page.harmonize <- read.csv("harmonize_pages.csv", sep = "\t")    
  #page.harmonize <- read_mapping(f, sep = "\t", mode = "table", fast = FALSE)
  
  # Back to original indices and new unique reduction 
  s <- s[match(sorig, suniq)]
  sorig <- s
  suniq <- unique(sorig)
  s <- suniq
  
  if (verbose) {message("Read the mapping table for romans")}  
  f <- read.csv("harmonize_romans.csv", sep = "\t")    
  #romans.harm <- read_mapping(f, sep = "\t", mode = "table", fast = TRUE)
  s <- map(s, f, mode = "recursive")
  
  if (verbose) {message("Page harmonization part 2")}  
  f <- read.csv("harmonize_pages2.csv", sep = "|")      
  #harm2 <- read_mapping(f, sep = "|", mode = "table", fast = TRUE)
  s <- map(s, f, mode = "recursive")
  #rm(harm2)
  
  # Trimming
  # p3 -> p 3
  inds <- grep("p[0-9]+", s)
  if (length(inds)>0) {
    s[inds] <- gsub("p", "p ", s[inds])
  }  
  s <- condense_spaces(s)
  s[s == "s"] <- NA
  
  # 1 score (144 p.) -> 144 pages 
  if (length(grep("[0-9]* *scores* \\([0-9]+ p\\.*\\)", s))>0) {
    s <- gsub("[0-9]* *scores*", " ", s)
  }
  s <- condense_spaces(s)
  
  if (verbose) {message("Polish unique pages separately for each volume")}  
  
  # Back to original indices and new unique reduction 
  sorig <- s[match(sorig, suniq)]
  s <- suniq <- unique(sorig)
  
  # English
  f <- read.csv("numbers_english.csv", sep = ",")        
  #char2num <- read_mapping(f, sep = ",", mode = "table", from = "character", to = "numeric")
  s <- map(s, synonymes = f, from = "character", to = "numeric", mode = "match")
  
  if (verbose) {message(paste("Polishing physical extent field 3:", 
                               length(suniq), "unique cases"))}
  ret <- lapply(s, function (s) {
     a <- try(polish_physext_help(s, page.harmonize));
     if (class(a) == "try-error") {
       message(paste("Error in polish_physext_help:", s)); return(NA)} else {return(a)}
   })
   
  nainds <- which(is.na(ret))
   for (i in nainds) {
     message(paste("Before polish_physext_help:", i, s[[i]]))
     # NA vector of same length than the other entries
     ret[[i]] <- rep(NA, length(ret[[1]])) 
   }
   
   if (verbose) {message("Make data frame")}
   ret <- as.data.frame(t(sapply(ret, identity)))
   
   if (verbose) {message("Set zero page counts to NA")}
   ret$pagecount <- as.numeric(ret$pagecount)  
   ret$pagecount[ret$pagecount == 0] <- NA
   
   if (verbose) { message("Project to original list: indices") }
   inds <- match(sorig, suniq)
   
   if (verbose) { message("Project to original list: mapping") }  
   ret[inds, ]
  
}

#' @title Sheet Area
#' @description Sheet area in cm2.
#' @param x Sheet size 
#' @param sheet.dimension.table Table to estimate sheet area. 
#' 	  If not given, the table given by sheet_sizes() is used by default.
#' @param verbose Verbose
#' @return Sheet area (cm2)
#' @export
#' @details Sheet size is calculated according to the table given as output 
#'          from call sheet_area()
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("bibliographica")
#' @examples sheet_area("2to")
#' @keywords utilities
sheet_area <- function (x = NULL, sheet.dimension.table = NULL, verbose = FALSE) {
  
  if (is.null(sheet.dimension.table)) {
    
    if (verbose) {message("sheet.dimension.table not given, using sheet_sizes() mapping table by default")}
    tab <- sheet_sizes()
  } else {
    tab <- sheet.dimension.table
  }
  
  # Ensure correct formatting
  tab$format <- str_trim(as.character(tab$format))
  tab$gatherings <- str_trim(as.character(tab$gatherings))
  for (i in c("width", "height", "area")) {
    tab[,i] <- as.numeric(str_trim(as.character(tab[,i])))
  }
  
  if (!is.null(x)) {
    x <- as.character(x)
    ind <- which((tab$format %in% x) | (tab$gatherings %in% x))
    
    if (length(ind) > 0) {
      area <- tab[ind, "area"]
      
      if (verbose) {
        message(paste("The input", x, "corresponds to", tab[ind, "sheet"], "paper with", tab[ind, "width"], "cm width and", tab[ind, "height"], "cm height and an area of", tab[ind, "area"], "cm2"))
      }
    } else {
      # warning(paste(x, "not found from the sheet size conversion table"))
      return(NA)
    }
  } else {
    return(tab)
  }
  
  area
  
}

#' @title Polish Years
#' FIXME: UNIT TESTS MISSING NOW!
#' @description Pick and polish the year interval (start and end years) from a time field which is of the form 1800 or 1823-1845 etc.
#' @param x year field (a vector) 
#' @param start_synonyms Synonyme table for start year
#' @param end_synonyms Synonyme table for end year
#' @param verbose verbose
#' @param min.year Minimum year accepted
#' @param max.year Maximum year accepted
#' @param check If true, remove entries (replace by NA) where start > end
#' @return data.frame with the fields 'start' and 'end'
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @examples \dontrun{df <- polish_years(c("1746", "1745-1750"))}
#' @keywords utilities
polish_years <- function(x, start_synonyms=NULL, end_synonyms=NULL, verbose = TRUE, check = FALSE, min.year = -3000, max.year = as.numeric(format(Sys.time(), "%Y")) + 50) {

  
  # Delete suspiciously long strings
  inds <- which(nchar(x) > 200 & grepl("\t", x))
  if (length(inds) > 0) {
    x[inds] <- NA
    warning(paste("Removed ", length(inds), "publication year entries that are suspiciously long (over 200 characters) and include tabs"))
  }
  
  x <- gsub("\\.$", "", x)
  x <- gsub("\\[blank\\]", "?", x)
  x <- gsub("\\[sic\\.\\]", "", x)    
  x <- gsub("^&lt;", "", x)
  x <- gsub("&gt;$", "", x)
  x <- gsub("&gt;-$", "", x)
  x <- gsub(", *\\[*[0-9]\\]*$", "", x)
  x <- gsub("\\[\u0302", "[", x) # "[\u0302 = square bracket with circumflex
  x <- gsub("(^|[-[])[0-9]{3}[?]", "\\1", x)
  x <- gsub("(^|[-[])[0-9]{2}[?][?]", "\\1", x)
  x <- gsub("I([0-9]{3})([^0-9]|$)", "1\\1", x)
  # 1974 [p.o. 1976] -> 1976
  x <- gsub("[0-9]{4} ?[[]p[.]?o[.]? ?([0-9]{4})[]]", "\\1", x)
  x <- gsub("[\\^]", "", x)
  x <- gsub("[\\|]", "", x)
  x <- gsub("[u]", "", x)
  
  inds <- grep("\\[*[M,C,D,X,L,\\.]*\\]*", x)
  if (length(inds) > 0) {
    x[inds] <- sapply(x[inds], function (x) {gsub("\\.", "", x)})
  }
  
  inds <- intersect(grep("^--", x), grep("--$", x))
  x[inds] <- gsub("--$", "", gsub("^--", "", x[inds]))
  
  inds <- grep("^\\[*l[0-9]{3}\\.*\\]*$", x)
  if (length(inds) > 0) {
    x[inds] <- sapply(x[inds], function (x) {gsub("l", "1", x)})
  }
  
  f <- "months.csv"
  months <- as.character(read.csv(f, header = TRUE)[,1])
  months <- unique(c(months, tolower(months)))
  # Handle from longest to shortest to avoid problems
  months <- months[rev(order(nchar(months)))]
  
  # These seem unnecessary assignments.
  xorig <- tolower(as.character(x))
  xuniq <- unique(xorig)
  x <- xuniq
  
  if (verbose) {
    message(paste("Polishing years:", length(xuniq), "unique cases"))
  }
  
  # "[1.12.1584 jalkeen]" -> 1584 jalkeen
  inds <- grep("[0-9]{1,2}\\.[0-9]{1,2}\\.[0-9]{4}", x)
  x[inds] <- gsub("[0-9]{1,2}\\.[0-9]{1,2}\\.", "", x[inds])
  x <- gsub(",", ".", x)
  
  # 23.1967 -> 1967 excluding 1.5.6.7
  if (length(grep("[0-9]\\.[0-9]\\.[0-9]\\.[0-9]", x)) == 0) {
    x <- gsub(" [0-9]{1,2}\\.", "", x)
    x <- gsub("\\.[0-9]$", "", x)
  } else {
    x <- gsub("\\.", "", x)
  }
  
  # "Printed in the Yeare,;1648."
  inds <- grep(";", x)
  x[inds] <- unlist(sapply(x[inds], function (x) {x <- unlist(strsplit(x, ";")); paste(x[grep("[0-9]", x)], collapse = ", ")}), use.names = FALSE)
  x <- gsub("\\.", " ", x)
  x <- gsub(" or later", " ", x)  
  x <- gsub("0[0-9]*;m[a-z]*terio [a-z]*\\.* pauli", " ", x)
  
  # 18th century (remove separately before removing other letters)
  x <- gsub("[0-9]{1,4}th", "", x)  
  
  # Map back to original indices and make unique again. To speedup further.
  xorig <- x[match(xorig, xuniq)]
  
  x <- xuniq <- unique(xorig)
  x <- harmonize_ie(x)
  
  x <- gsub("-a", "- a", x) # -approximately
  x <- remove_print_statements(x)
  
  # Map back to original indices and make unique again. To speedup further.
  xorig <- x[match(xorig, xuniq)]
  x <- xuniq <- unique(xorig)
  
  x <- sapply(x, function (xi) {handle_ie(xi, harmonize = FALSE)}, USE.NAMES = FALSE)
  x <- condense_spaces(gsub("\\.", " ", x))
  
  x <- remove_time_info(x, verbose = F, months)
  
  # Map back to original indices and make unique again. To speedup further.
  xorig <- x[match(xorig, xuniq)]
  x <- xuniq <- unique(xorig)
  
  # 1642 [1643] -> 1643
  if (length(grep("^[0-9]* \\[[0-9]*\\]$", x)) > 0) {
    inds <- grep("^[0-9]* \\[[0-9]*\\]$", x)
    for (i in inds) {
      spl <- unlist(strsplit(x[[i]], " "))      
      if (length(spl) > 1) {
        x[[i]] <- spl[[2]]
      } else {
        x[[i]] <- spl[[1]]
      }
    }
  }
  
  
  
  # 1642[1643] -> 1643
  if (length(grep("^[0-9]{4}\\[[0-9]{4}\\]$", x)) > 0) {
    inds <- grep("^[0-9]{4}\\[[0-9]{4}\\]$", x)
    for (i in inds) {
      x[[i]] <- substr(x[[i]], 6, 9)
    }
  }
  
  # 1642[1643]-45 -> 1643-1645
  if (length(grep("^[0-9]{4}\\[[0-9]{4}\\]-[0-9]{2}$", x)) > 0) {
    inds <- grep("^[0-9]{4}\\[[0-9]{4}\\]-[0-9]{2}$", x)
    for (i in inds) {
      spl <- strsplit(x[[i]], "-")[[1]]
      start <- pick_year(spl[[1]])
      end <- paste0(substr(spl[[1]], 1, 2), spl[[2]])
      x[[i]] <- paste(start, end, sep = "-")
    }
  }
  
  # 1642[3] -> 1643
  inds <- grep("^[0-9]{4}\\[[0-9]{1}\\]$", x)
  if (length(inds) > 0) {
    for (i in inds) {
      x[[i]] <- paste0(substr(x[[i]], 1, 3), substr(x[[i]], 6, 6))
    }  
  }
  
  clean2 <- function (x) {
    
    x <- strsplit(x, "\\]-\\[")[[1]]
    
    start <- polish_year(x[[1]])[[1]]
    
    end <- NA
    if (length(x) > 1) {
      end <- polish_year(x[[2]])
      if (length(end) > 0) {end <- end[[1]]}
    }
    
    if (!is.na(start) & !is.na(end) & end < start) {
      end <- ""
    }
    
    x <- paste(start, end, "-")          
    
  } 
  
  
  # "[1900?]-[190-?]"
  inds <- grep("\\]-\\[", x)
  if (length(inds) > 0) {
    x[inds] <- sapply(x[inds], function (xx) {clean2(xx)})
  }
  
  # "[1900?]-190-?"
  clean1 <- function (x) {
    x <- strsplit(x, "\\]-")[[1]]
    
    start <- polish_year(x[[1]])
    
    end <- ""
    if (length(x) > 1) {
      end <- polish_year(x[[2]])
    }
    
    x <- paste(start, end, "-")    
  }
  
  inds <- grep("\\]-[?]*", x)
  if (length(inds) > 0) {
    x[inds] <- sapply(x[inds], function (xx) {clean1(xx)})
  }
  
  # 1966 [=1971]  -> 1971
  x <- gsub("[0-9]{4}  ?[[][=]([0-9]{4})[]]", "\\1", x)
  
  # Remove some other info
  x <- gsub("price [0-9] d", "", x)
  x <- gsub("-[0-9]{2,3}\\?{1,2}$", "", x)
  x <- gsub("\\?", "", x)
  x <- gsub("\\!", " ", x)  
  x <- gsub("^& ", "", x)
  
  x <- condense_spaces(gsub("\\[\\]", " ", x))
  x <- gsub(" -", "-", gsub("- ", "-", x))
  x <- gsub("-+", "-", x)
  x <- gsub("1\u0302", "1", x) #1\u0302 = 1 with circumflex
  
  x <- gsub("\\[[a-z| ]*\\]", "", x)
  
  x <- gsub("[[]", "", x)
  x <- gsub("[]]", "", x)
  x <- harmonize_christian(x)
  
  inds <- grep(" or ", x)
  if (length(inds)>0) {
    x[inds] <- sapply(x[inds], function (x) unlist(strsplit(x, " or "), use.names = FALSE)[[2]])
  }
  x[inds] <- str_trim(x[inds])
  
  # Convert romans
  x <- gsub("m\\.d", "md", x)
  x <- gsub("m\\.d\\.", "md", x)
  x <- gsub("m d", "md", x)
  x <- gsub("m d ", "md", x)  
  x <- gsub("m\\,d", "md", x)
  x <- gsub("m\\,d\\,", "md", x)
  x <- gsub("md x", "mdx", x)
  x <- gsub("md l", "mdl", x)  
  x <- gsub("ij$", "ii", x)
  
  num <- suppressWarnings(as.numeric(as.roman(gsub(" ", "", x))))
  inds <- which(!is.na(num))
  if (length(inds) > 0) {
    x[inds] <- num[inds]
  }
  
  # Map back to original indices and make unique again. To speedup further.
  xorig <- x[match(xorig, xuniq)]
  xuniq <- unique(xorig)
  x <- xuniq
  
  if (length(grep("[0-9]{4}\\[[0-9]", x))>1) {
    x <- substr(x, 1, 4)
  }
  
  res <- suppressWarnings(
    lapply(x,
           function (xi) {
             a <- try(polish_year(xi,
                                  start_synonyms = start_synonyms,
                                  end_synonyms = end_synonyms,
                                  months,
                                  verbose)
             )
             
             if (inherits(a, "try-error")) {
               return(c(NA, NA))
             } else {
               return(a)
             }
           }
    )
  )
  
  res <- do.call("rbind", res)
  start_year <- res[,1]
  end_year   <- res[,2]
  
  if (check) {
    inds <- which(start_year > end_year)
    if (length(inds) > 0) {
      start_year[inds] <- NA
      end_year[inds] <- NA      
    }
  }
  
  start_year[is.infinite(start_year)] <- NA
  end_year[is.infinite(end_year)] <- NA  
  
  # Do not accept years below and above these values
  print(min.year)
  print(max.year)
  
  start_year[start_year < min.year | start_year > max.year] <- NA
  end_year[end_year < min.year | end_year > max.year] <- NA  
  
  
  
  df <- data.frame(from = as.numeric(as.character(start_year)),
                   till = as.numeric(as.character(end_year)))
  
  message(paste("Checking that the years are within the accepted range:", min.year, "-", max.year))
  # Manually checked for Fennica - 3 publications before 1400;
  # FIXME make more explicit in the final reports; maybe with a separate enrich function as earlier
  # in all cases it seems that this is misspelling and the original year cant be inferred from the entry
  df$from[which(df$from > max.year)] <- NA
  df$from[which(df$from < min.year)] <- NA
  df$till[which(df$till > max.year)] <- NA
  df$till[which(df$year < min.year)] <- NA
  
  # Not yet incorporated in main function so that it would work
  # df<-polish_years_helper(df)
  # Match the unique cases to the original indices
  # before returning the df
  
  
  #print(max(match(xorig, xuniq))) 
  #print(nrow(df))
  return(df[match(xorig, xuniq), c("from", "till")])
  
}




#' @title Polish year
#' @description Pick and polish the year interval (start and end years) from a time field '
#' @param x year string
#' @param start_synonyms Synonyme table for start year
#' @param end_synonyms Synonyme table for end year
#' @param months months
#' @param verbose verbose
#' @param min.year Minimum year accepted
#' @param max.year Maximum year accepted
#' @return vector with the fields 'from' and 'till'
#' @author Leo Lahti and Niko Ilomaki \email{leo.lahti@@iki.fi}
#' @examples \dontrun{df <- polish_year(c("1746"))}
#' @keywords utilities
polish_year <- function(x, start_synonyms = NULL, end_synonyms = NULL, months, verbose = FALSE, min.year = -3000, max.year = 2100) {
  
  
  x <- gsub("^\\[", "", x)
  x <- gsub("\\]$", "", x)
  x <- gsub("\\?$", "", x)
  
  # x <- gsub("[0-9]{1,2} [a-z+]", "", x)
  if (length(grep("^[a-z|=]*-*[a-z|=]+[0-9]*", x)) > 0) {
    x <- gsub("^[a-z|-|=]*-*[a-z|-|=]+", "", x)
    x <- gsub("[a-z|=]+", "", x)
    x <- gsub("- +", "", x)     
  }
  
  # Some quick returns for simple cases to speed up
  if (length(grep("^[0-9]{4}$", x)) > 0) {
    
    # 1900
    start <- x # gsub("^([0-9]+)$", "\\1", x)
    end <- NA
    return (c(from=as.numeric(start), till=end))
  } else if (length(grep("^[0-9]{3}-$", x)) > 0) {
    
    # 190-
    start <- gsub("-", "0", x)
    end <- NA
    return (c(from=as.numeric(start), till=end))    
    
  } else if (length(grep("^[0-9]{4}\\?$", x)) > 0) {
    
    # 1900?
    start <- gsub("\\?", "", x)
    end <- NA
    return (c(from=as.numeric(start), till=end))
    
  } else if (length(grep("^[0-9]{3}-\\?$", x)) > 0) {
    
    # 190-?
    start <- gsub("-\\?", "0", x)
    
    end <- NA
    return (c(from=as.numeric(start), till=end))
    
  } else if (length(grep("^[0-9]{2}-$", x)) > 0) {
    
    # 19-
    start <- paste0(substr(x, 1, 2), "00")
    end <- NA
    return (c(from=as.numeric(start), till=end))
    
  } else if (is.na(x)) {
    return(c(NA, NA))
  } else if (length(grep("^[0-9]{1,3}[.]?$", x)) >  0) {
    return(c(NA, NA))
  } else if (length(grep("^[0-9]{5}[.]?$", x)) >  0) {
    return(c(NA, NA))
  } else if (length(grep("^[0-9]{4}[-]$", x)) > 0) {
    # 1994-
    start <- gsub("^([0-9]{4})-", "\\1", x)
    end <- NA
    return(c(start, end))
  } else if ((x == "-") | (x == "[-]")) {
    # - ; [-]
    return(c(NA, NA))
  } else if (length(grep("^[0-9]+[-|,]+[0-9]+[-|,]+[0-9]+[-|,][0-9]+", gsub(" ", "", x))) > 0) {
    # "1921-1922;1921-1922;1922"
    x <- condense_spaces(gsub(",", " ", gsub("-", " ", x)))
    x <- unlist(strsplit(x, " "), use.names = FALSE)
    x <- na.omit(as.numeric(x))
    start <- min(x)
    end <- max(x)
  } else if (x=="fin") {
    return(c(NA, NA))
  } else if (length(grep("^[0-9]+[-|,]+[0-9]+[-|,]+[0-9]", gsub(" ", "", x))) > 0) {
    # "1921-1922;1921
    x <- condense_spaces(gsub(",", " ", gsub("-", " ", x)))
    x <- unlist(strsplit(x, " "), use.names = FALSE)
    x <- na.omit(as.numeric(x))
    start <- min(x)
    end <- max(x)
  } else if (x=="NA-NA" | x=="NA-" | x=="-NA" | x=="-") {
    return(c(NA, NA))
  } else if (length(grep("^[0-9]{4}$", gsub("\\]", "", gsub("\\[", "", x)))) > 0) {
    # 190[1]] / 19[83]
    x <- gsub("\\[", "", x)
    x <- gsub("\\]", "", x)    
    start <- x
    end <- NA
    return (c(from=as.numeric(start), till=end))    
  } else if (length(grep("^\\[*[0-9]{4}\\]*[-]\\[*[0-9]{4}\\]*$", x)) > 0) {
    # 1900-1910 / [1929]-[1930]
    start <- gsub("^\\[*([0-9]{4}).*\\]*", "\\1", x)
    end <- gsub("\\[*.*([0-9]{4})\\]*$", "\\1", x)
    return (c(from=as.numeric(start), till=as.numeric(end)))
  } else if (length(grep("^\\[*[0-9]{4}\\]*[-]\\]* *\\[*[0-9]{4}\\]*$", x)) > 0) {
    # "[1904-] 1905"
    start <- gsub("^\\[*([0-9]{4}).*", "\\1", x)
    end <- gsub(".*([0-9]{4})$", "\\1", x)
    return (c(from=as.numeric(start), till=as.numeric(end)))
    
  } else if (length(grep("^[0-9]{4}-[0-9]{4}", gsub("\\]", "", gsub("\\[", "", x)))) > 0) {
    # "18[35-18]42"
    x <- gsub("\\]", "", gsub("\\[", "", x))
    spl <- unlist(strsplit(x, "-"), use.names = FALSE)
    start <- spl[[1]]
    end <- spl[[2]]
    
    return (c(from=as.numeric(start), till=as.numeric(end)))
  } else if (length(grep("^[0-9]{1,4}B\\.C-[0-9]{1,4}B\\.C$", x)) > 0) {
    # 30bc-26bc
    tmp <- as.numeric(gsub("B\\.C", "", unlist(strsplit(x, "-"))))
    start <- -tmp[[1]]
    end <- -tmp[[2]]
    return (c(from=as.numeric(start), till=as.numeric(end)))
  } else if (length(grep("^[0-9]{1,4}B\\.C-[0-9]{1,4}$", x)) > 0) {
    # 30bc-26
    tmp <- as.numeric(gsub("B\\.C", "", unlist(strsplit(x, "-"))))
    start <- -tmp[[1]]
    end <- tmp[[2]]
    return (c(from=as.numeric(start), till=as.numeric(end)))        
  } else if (length(grep("^[0-9]{1,4}B\\.C$", x)) > 0) {
    start <- -as.numeric(gsub("B\\.C", "", x))
    end <- NA
    return (c(from=as.numeric(start), till=as.numeric(end)))    
  } else if (length(grep("^[0-9| ]+$", x))>0) {
    n <- as.numeric(unlist(strsplit(condense_spaces(x), " ")))
    start <- min(n)
    end <- max(n)
    return (c(from=as.numeric(start), till=end))    
  } else if (length(grep("^(NA)?[-][0-9]{4}$", x)) > 0) {
    # NA-1910; -1910
    start <- NA
    end <- gsub("(NA)?[-](.*)", "\\2", x)
    return (c(from=as.numeric(start), till=as.numeric(end)))    
  }
  
  # More complex cases..
  # "mdccx-mdccxi [1710-1711]" -> [1710-1711]
  if (length(grep("[[:lower:]]*-[[:lower:]]* \\[[0-9]*-[0-9]*\\]", x))>0) {
    x <- remove_letters(x)
  } else if (length(grep("^[0-9]{4} *\\[[0-9]\\]$", x))>0) {
    # "1646[7]" -> 1647
    x <- gsub(" \\[", "\\[", x)
    x <- paste(substr(x, 1, 3), substr(x, 6, 6), sep = "")
  } else if (length(grep("^[0-9]{4}-\\[[0-9]*\\]", x))>0) {
    # "1646-[47]" -> 1646-47
    x <- gsub("\\[", "", gsub("\\]", "", x))
  } else if (length(grep("^[0-9]{4}\\[[0-9]{4}\\]-[0-9]{2}", x))>0) {
    # "1646[1647]-50" -> 1647-50
    x <- gsub("\\]", "", substr(x, 6, nchar(x)))
  } else if (length(grep("^[0-9]{4}, [0-9]\\:o$", x))>0) {
    # "1731, 4:o" -> 1731
    x <- substr(x, 1, 4)
  }  
  
  # Now Remove some special chars
  x <- gsub("\\(\\)", "", x)  
  x <- gsub("-+", "-", x)
  x <- gsub("^[<|>]*", "", x)
  x <- gsub("[<*|>]", "", x)  
  x <- condense_spaces(x)
  x <- gsub("[\\{|\\}]", " ", x)
  x <- gsub("\\\\>", " ", x)
  x <- gsub("\\[=", "[", x)
  x <- gsub("\\[\\]", "-", x)    
  x <- gsub("[[:lower:]]", "", x)
  x <- condense_spaces(x)
  
  if (length(grep("^[0-9]{2}\\[[0-9]{2}\\]$", x))>0) {
    # 19[99]
    x <- gsub("\\[", "", x)
    x <- gsub("\\]", "", x)    
  } else if (length(grep("^[0-9]{3}\\[[0-9]{1}\\]$", x))>0) {
    # 199[9]
    x <- gsub("\\[", "", x)
    x <- gsub("\\]", "", x)    
  } else if (length(grep("^[0-9]{4}/[0-9] \\[[0-9]{4}\\]$", x))>0) {
    # 1695/6 [1696]
    x <- gsub("\\]", "", unlist(strsplit(x, "\\["), use.names = FALSE)[[2]])
  } else if (length(grep("^[-][0-9]{4}$", x)) > 0) {
    x <- gsub("^-", "NA-", x)
  } else if (length(grep("^[0-9]{4} {0,1}\\[[0-9]*\\]$", x))>0) {
    # 1726[1727] -> 1727
    x <- gsub(" \\[", "[", x)
    x <- substr(x, 6, 9)
  } else if (all(!unlist(strsplit(x, "")) %in% letters) && length(grep("\\[[0-9]\\]", x))>0) {
    x <- gsub("\\[", " ", x)
    x <- gsub("\\]", " ", x)
    x <- gsub("\\(", " ", x)
    x <- gsub("\\)", " ", x)    
    x <- gsub("-", " ", x)
    x <- gsub(";", " ", x)
    x <- gsub(",", " ", x)
    x <- gsub("/", " ", x)
    x <- unlist(strsplit(x, " "), use.names = FALSE)
    x <- na.omit(as.numeric(x))
    x <- x[x >= 100] # ignore years below 100
    x <- paste(min(x), max(x), sep = "-")
  }
  
  x <- gsub("\\[[0-9]{2,3}-*\\]", "", x)  
  x <- gsub("-\\]-", "-", x)
  x <- gsub("\\[[0-9]{2}-\\]", "NA", x)
  x <- gsub("\\[[0-9]{2,3}-\\?", "NA", x)
  x <- gsub("\\[[0-9]{2}\\?+", "NA", x)
  x <- gsub("-[0-9]{2}-\\]", "-NA", x)
  x <- gsub("-[0-9]{2}-\\?", "-NA", x)
  x <- gsub("-[0-9]{2}\\?+", "-NA", x)
  x <- gsub("\\[", " ", x)
  x <- gsub("\\]", " ", x)      
  x <- gsub("^\\(", "", gsub("\\)$", "", x))
  x <- gsub(" -", "-", gsub("- ", "-", x))  
  x <- gsub("^-", "NA-", gsub("-$", "-NA", x))
  x <- gsub("[[:lower:]]", "", x)
  x <- condense_spaces(x)
  x <- gsub("^[\\:|\\=]", "", x)
  
  if (length(x) == 1 && (x == "" || is.na(x))) {
    x <- "NA"
  }
  if (length(x) > 1) {
    x <- na.omit(x)
  }
  
  x <- gsub(" *-+ *","-",x)
  
  if (length(grep("\\([0-9]+ */*[0-9]+\\)-[0-9]+ *\\([0-9]{4}/*[0-9]+", x))>0) {
    # "1(1861/1865)-8(1896/1900"
    x <- gsub("\\(", " ", x)
    x <- gsub("\\)", " ", x)
    x <- gsub("/", " ", x)
    x <- gsub("-", " ", x)            
    x <- unlist(strsplit(x, " "), use.names = FALSE)
    x <- na.omit(as.numeric(x))
    x <- x[x >= 100] # ignore years below 100
    x <- paste(min(x), max(x), sep = "-")  
  } else if (length(grep("^[0-9]{4}/[0-9]{4}-[0-9]{4}/[0-9]{4}$", x))>0) {
    # "1885/1886- 1894/1895"
    x <- na.omit(as.numeric(unlist(strsplit(unlist(strsplit(x, "-"), use.names = FALSE), "/"), use.names = FALSE)))
    x <- paste(min(x), max(x), sep = "-")
  } else if (length(grep("NA-[0-9]{4}-[0-9]{4}$", x))>0) {
    # NA-1524-1700
    x <- substr(x, 4, 13)
  } else if (length(grep("NA-[0-9]{4}-NA$", x))>0) {
    # 1736-49
    x <- substr(x, 4, 8)
  } else if (length(grep("[0-9]{4}-[0-9]{1,2}$", x))>0) {
    spl <- unlist(strsplit(x, "-"), use.names = FALSE)
    x <- paste(spl[[1]], paste(substr(spl[[1]], 1, 4-nchar(spl[[2]])), spl[[2]], sep = ""), sep = "-")
  } else if (length(grep("^[0-9]{4}/[0-9]*$", x))>0) {  
    x <- substr(x, 1, 4)
  } else if (length(grep("[0-9]{4} [0-9]*$", x))>0) {
    # 1780 1800 > 1780-1800
    x <- gsub(" ", "-", x)
  }
  
  #x <- unlist(strsplit("3: 1-26 ( 1904/1905 ) , 1: : 1-54 (1905/1906", ""))
  #x <- unlist(strsplit(x, ""))  
  #x <- as.numeric(x)
  #x[is.na(x)] <- "-"
  #x <- condense_spaces(paste(x, collapse = ""))
  #x <- unlist(strsplit(x, "-"), use.names = FALSE)
  #x <- na.omit(as.numeric(x))
  #x <- x[x >= 100] # ignore less than 100
  #x <- paste(min(x), max(x), sep = "-")
  
  # "( ) 25 1643"
  spl <- unlist(strsplit(x, " "), use.names = FALSE)
  spl <- unique(spl[grep("[0-9]{4}", spl)])
  
  if (length(spl) == 1) {
    x <- spl
  }
  
  # 1690, 1690 -> 1690
  if (length(grep("[0-9]{4}, [0-9]{4}$", x))>0) {  
    x <- as.character(min(as.numeric(unique(unlist(strsplit(x, ","), use.names = FALSE)))))
  }
  
  # "1885/1886--1889/1890-1885-1885-2"
  x <- gsub("'", " ", x)
  x <- gsub(",", " ", x)    
  x <- gsub("\\(", " ", x)
  x <- gsub("\\)", " ", x)
  x <- gsub(" -+", "-", x)
  x <- gsub("-+ ", "-", x)
  x <- gsub(":", " ", x)
  x <- gsub("\\.", " ", x)
  x <- condense_spaces(x)
  x <- gsub(" ", "-", x)
  x <- gsub("-+", "-", x)

  
  
  if (length(grep("^[0-9|/|-]+$", x))>0) {
    n <- unlist(strsplit(unlist(strsplit(x, "-"), use.names = F), "/"), use.names = F)
    n <- na.omit(as.numeric(n))
    n <- n[n>=500] # do not accept years below this one in this special case
    
    # there shouldn't be any of these as they've already been gsubbed to " " above
    # n <- unlist(strsplit(unlist(strsplit(as.character(n), "\\("), use.names = F), "\\)"), use.names = F)
    # n <- na.omit(as.numeric(n))
    
    start <- NA
    if (length(n) > 0) {
      start <- min(n)
    }
    end <- NA
    if (length(n) > 1) {
      end <- max(n)
    }
    return (c(from=as.numeric(start), till=as.numeric(end)))  
  }
  
  if (length(grep("^[0-9]{4}$", x)) > 0) {
    # 1900
    start <- gsub("^([0-9]+)$", "\\1", x)
    end <- NA
    return (c(from=as.numeric(start), till=end))
  } else if (length(grep("^[0-9]{4}[-][0-9]{4}$", x)) > 0) {
    # 1900-1910
    start <- gsub("^([0-9]{4}).*", "\\1", x)
    end <- gsub(".*([0-9]{4})$", "\\1", x)
    return (c(from=as.numeric(start), till=as.numeric(end)))
  }
  
  
  # Proceed to more complex cases
  if (!is.null(start_synonyms)) {
    start <- map(x, start_synonyms)
    start <- as.character(start)
  } else {
    start <- x
  }
  
  if (length(grep("-", x))>0) {
    spl <- unlist(strsplit(as.character(start), "-+"), use.names = FALSE)
    spl <- as.numeric(spl)
    
    # HR 20190225: Do not make this assumption. It's harmful.
    #if (sum(is.na(spl))>1) {
    #  # NA, 3, NA -> 3, NA (assume the year is start year if it is not clear)
    #  spl <- spl[min(which(!is.na(c(NA, 3, NA)))):length(spl)]
    #}
    #x <- spl
    start <- spl[[1]]
    #print(spl)
    if (length(spl) > 1) {
      end <- spl[[2]]
    } else {
      end <- NA
    }
    #x <- paste(x, collapse = "-")
  }
  
  if (length(grep("^(NA)?[-][0-9]{4}$", x)) > 0) {
    # NA-1910; -1910
    start <- NA
    end <- gsub("NA-", "", x)
    return (c(from=as.numeric(start), till=as.numeric(end)))    
    
  } else if (length(grep("^[0-9]{4}[-]NA$", x)) > 0) {
    # 1900-NA
    start <- gsub("-NA", "", x)
    end <- NA
    return (c(from=as.numeric(start), till=as.numeric(end)))        
  } else if (length(grep("\\[[0-9]*\\]", x)) > 0) {
    # MDCCLXVIII. [1768]  
    spl <- unlist(strsplit(x, " "), use.names = FALSE)
    if (length(spl) > 1) {
      spl <- spl[[2]]} else {spl <- spl[[1]]
      }
    start <- gsub("\\[", "", gsub("\\]", "", spl))
    end <- NA    
  } else if (length(grep("^[0-9]*\\.", x)) > 0) {
    # "1798. (price one dollar)"  
    start <- unlist(strsplit(x, "\\."), use.names = FALSE)[[1]]
    end <- NA
  } else if (length(grep("[0-9]+", x)) > 0) {
    # MDCCLXVIII. 1768
    spl <- unlist(strsplit(unlist(strsplit(x, " "), use.names = FALSE), "-"), use.names = FALSE)
    spl <- na.omit(as.numeric(spl))
    spl <- spl[spl > 100] # Do not accept years earlier than this
    #if (length(spl) > 1) {spl <- spl[[2]]} else {spl <- spl[[1]]}
    #start <- spl
    #end <- NA
    start <- min(spl)
    end <- NA
    if (length(spl) > 1) {
      end <- max(spl)
    }
  } else if (is.na(x)) {
    # somewhere along the way some NAs get in, possibly.
    # That produced a stream of error messages. -vv
    end <- NA
  } else if (x == "NA") {
    end <- NA
  }
  
  
  start[start == ""] <- NA
  start[start == " "] <- NA  
  
  start <- christian2numeric(start) 
  start_year <- as.numeric(start)
  
  # FIXME "cannot coerce type 'closure' to vector of type 'character'" error here.
  # There are cases where end has not yet been assigned at this point. Therefore
  # function below catches to a function base R called end() and hilarity ensues.
  # I'll implement a quick fix for now. -vv
  if (!(exists("end", mode = "character") || exists("end", mode = "numeric"))) {
    end <- NA
  }
  
  if (!is.null(end_synonyms)) {
    end <- map(end, end_synonyms)
    end <- as.character(end)
  }
  end <- christian2numeric(end)   
  end_year <- as.numeric(end)
  
  if (length(start_year) == 0) {start_year <- NA}
  if (length(end_year) == 0) {end_year <- NA}  
  if (length(start_year) > 1) {start_year <- NA}
  if (length(end_year) > 1) {end_year <- NA}
  
  return(c(start_year, end_year))
}


christian2numeric <- function (x) {
  
  inds <- grep("a.d", x)
  if (length(inds) > 0) {
    x[inds] <- as.numeric(str_trim(gsub("a.d", "", x[inds])))
  }
  
  inds <- grep("b.c", x)
  if (length(inds) > 0) {
    x[inds] <- -as.numeric(str_trim(gsub("b.c", "", x[inds])))
  }
  
  return(x)
}

#' @title Polish Languages
#' @description Construct binary matrix of languages for each entry
#' @param x language field (a vector)
#' @return data.frame with separate fields for different languages
#' @export
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("fennica")
#' @examples \dontrun{df <- mark_languages(c("fin;lat","eng"))}
#' @keywords utilities
polish_languages <- function(x) {
  #x <- gsub("\\|", ";", x)
  x0 <- x
  
  # Unique entries only to speed up
  xorig <- x
  xuniq <- unique(xorig)
  x <- xuniq
  
  # Convert to polished language names as in
  # http://www.loc.gov/marc/languages/language_code.html
  # TODO: XML version available, read directly in R:
  # see http://www.loc.gov/marc/languages/
  f <- system.file("extdata/language_abbreviations.csv", package = "fennica")
  abrv <- read.csv(f, sep = "\t", header = TRUE, encoding = "UTF-8")
  
  # Unrecognized languages?
  unrec <- as.vector(na.omit(setdiff(
    unique(unlist(strsplit(as.character(unique(x)), ";"))),
    abrv$synonyme
  )))
  
  if (length(unrec) > 0) {
    warning(paste("Unidentified languages: ", paste(unrec, collapse = ";")))
  }
  
  # TODO Vectorize to speed up ?
  for (i in 1:length(x)) {    
    lll <- sapply(unlist(strsplit(x[[i]], ";")), function (xx) {
      as.character(map(xx, abrv, remove.unknown = TRUE, mode = "exact.match"))
    })
    
    lll <- na.omit(as.character(unname(lll)))
    if (length(lll) == 0) {lll <- NA}
    
    # Just unique languages
    # "Undetermined;English;Latin;Undetermined"
    # -> "Undetermined;English;Latin"
    lll <- unique(lll)
    x[[i]] <- paste(lll, collapse = ";")
    
  }
  
  # List all unique languages in the data
  x[x %in% c("NA", "Undetermined", "und")] <- NA
  xu <- na.omit(unique(unname(unlist(strsplit(unique(x), ";")))))
  
  # Only accept the official / custom abbreviations
  # (more can be added on custom list if needed)
  xu <- intersect(xu, abrv$name)
  
  # Now check just the unique and accepted ones, and collapse
  # TODO: add ID for those that are not recognized
  # NOTE: the language count and multilingual fields should be fine however
  # as they are defined above already
  x <- sapply(strsplit(x, ";"), function (xi) {paste(unique(intersect(xi, xu)), collapse = ";")})
  
  # Multilinguality info
  len <- sapply(strsplit(x, ";"), length)
  dff <- data.frame(language_count = len)    
  multilingual <- len > 1
  dff$multilingual <- multilingual
  
  dff$languages <- x
  inds <- which(dff$languages == "")
  if (length(inds) > 0) {
    dff$languages[inds] <- "Undetermined"
  }
  
  # Add primary language
  if (length(grep(";", dff$languages)) > 0) {
    dff$language_primary <- sapply(strsplit(dff$languages, ";"),
                                   function (x) {x[[1]]})
  } else {
    dff$language_primary <- dff$languages
  }
  
  # Convert to factors
  dff$languages <- as.factor(str_trim(dff$languages))
  dff$language_primary <- as.factor(str_trim(dff$language_primary))
  
  list(harmonized_full = dff[match(xorig, xuniq),], unrecognized = unrec)
  
}

#' @title Polish Title
#' @description Polish the title field.
#' @param x Vector of titles
#' @return Vector of titles polished
#' @export
#' @details Remove ending commas, periods, spaces and parentheses, 
#' 	    starting prepositions etc.
#' @author Leo Lahti \email{leo.lahti@@iki.fi}
#' @references See citation("fennica")
#' @examples \dontrun{x2 <- polish_title(x)}
#' @keywords utilities
polish_title <- function (x) {
  
  x0 <- x
  x <- as.character(x)
  x <- unique(x)
  xinds <- match(x0, x)
  
  
  # Remove periods at the end
  x <- gsub("\\.$", "", as.character(x))
  x <- gsub("\\. $", "", as.character(x))
  
  x <- gsub("\\,$", "", x) # Remove commas at the end
  x <- gsub("[ ]+$", "", x) # Remove trailing spaces
  x <- gsub("\\]$", "", x) # Remove closing square brackets at the end
  x <- gsub("^\\[", "", x) # Remove opening square brackets at the start
  #x <- gsub("\\[|\\]", "",x) #remove brackets
  #x <- gsub("\\)$", "", x) # Remove closing parentheses at the end
  x <- gsub("^\\(", "", x) # Remove opening parentheses at the start
  x <- gsub("\\:$", "", x) # Remove colon at the end
  x <- gsub("^\\:", "", x) # Remove colon at the start
  x <- gsub("\\;$", "", x) # Remove semicolon at the end
  x <- gsub("/", "", x)
  x <- gsub("=", "", x)
  x <- str_replace_all(x, "\\|", "") # Remove pipe characters
  x <- str_replace_all(x, "\\/", "") # Remove slashes
  
  
  # Capitalize the first letter of words
  x <- gsub("^a", "A", x)
  x <- gsub("^the", "The", x)
  
  x[x == ""] <- NA
  
  
  
  # Map back to originals
  x <- x[xinds]
  
  x
}