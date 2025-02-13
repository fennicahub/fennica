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
  #FIXME: process 1,2M in chunks, some pages are not correctly estimated
  #somea dditional abbreviations needed "Kolme numeroimatonta sivua" etc. 
  
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

  li <- read.csv("remove_dimension.csv")[,1]
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

  if (verbose) {
   message("Reading translation_fi_en_pages.csv")
  }
  page.synonyms <- read_mapping("translation_fi_en_pages.csv", sep = ";", mode = "table", fast = TRUE)
  s <- map(s, page.synonyms, mode="match")
  rm(page.synonyms)

  if (verbose) {
    message("numbers_finnish")
  }
  
  char2num <- read_mapping("numbers_finnish.csv", sep = ",", mode = "table", from = "character", to = "numeric")
  s <- map(s, synonymes = char2num, from = "character", to = "numeric", mode = "match")
  rm(char2num)

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

  sheet.harmonize <- read_mapping("harmonize_sheets.csv", sep = ";", mode = "table", fast = TRUE)
  s <- harmonize_sheets(s, sheet.harmonize)
  rm(sheet.harmonize)

  # Just read page harmonization here to be used later
  if (verbose) {message("Read the mapping table for pages")}   
  page.harmonize <- read_mapping("harmonize_pages.csv", sep = "\t", mode = "table", fast = FALSE)

  # Back to original indices and new unique reduction 
  s <- s[match(sorig, suniq)]
  sorig <- s
  suniq <- unique(sorig)
  s <- suniq

  if (verbose) {message("Read the mapping table for romans")}  
 
  romans.harm <- read_mapping("harmonize_romans.csv", sep = "\t", mode = "table", fast = TRUE)
  s <- map(s, romans.harm, mode = "recursive")

  if (verbose) {message("Page harmonization part 2")}       
  harm2 <- read_mapping("harmonize_pages2.csv", sep = "|", mode = "table", fast = TRUE)
  s <- map(s, harm2, mode = "recursive")
  rm(harm2)

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
  char2num <- read_mapping("numbers_english.csv", sep = ",", mode = "table", from = "character", to = "numeric")
  s <- map(s, synonymes = char2num, from = "character", to = "numeric", mode = "match")
  
  if (verbose) {message(paste("Polishing physical extent field 3:", length(suniq), "unique cases"))}
  ret <- lapply(s, function (s) {
    a <- try(polish_physext_help(s, page.harmonize));
    if (class(a) == "try-error") {
      message(paste("Error in polish_physext_help:", s)); return(NA)} else {return(a)}
  })

  
  nainds <- which(is.na(ret))
  for (i in nainds) {
    message(paste("Before polish_physext_help:", i, s[[i]]))
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


