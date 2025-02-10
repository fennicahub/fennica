estimate_pages <- function(x) {
  
  # Initialize as a list
  pagecount.info <- list(volcount = 0, multiplier = 1, squarebracket = 0, plate = 0, arabic = 0, roman = 0, sheet = 0)
  
  library(stringr)
  
  if (all(is.na(x))) {
    return(pagecount.info)
  } else if (!is.na(suppressWarnings(as.numeric(x)))) {
    pagecount.info$sheet <- as.numeric(x)
    return(pagecount.info)
  } else if (str_detect(x, "^[IVXLCDM]+$")) {
    pagecount.info$roman <- suppressWarnings(as.numeric(as.roman(x)))
    return(pagecount.info)
  } else if (str_detect(x, "^\\[[0-9]+ {0,1}[p|s]{0,1}\\]$")) {
    pagecount.info$squarebracket <- suppressWarnings(as.numeric(str_trim(gsub("\\[", "", gsub("\\]", "", gsub(" [p|s]", "", x))))))
    return(pagecount.info)
  } else if (str_detect(x, "^[0-9]+ sheets$")) {
    pagecount.info$sheet <- 2 * as.numeric(as.roman(str_trim(unlist(strsplit(x, "sheet"), use.names = FALSE)[[1]])))
    return(pagecount.info)
  } else if (str_detect(x, "\\[{0,1}[0-9]* \\]{0,1} leaves")) {
    pagecount.info$squarebracket <- str_trim(gsub("\\[", "", gsub("\\]", "", x)))
    return(pagecount.info)
  } else if (str_detect(x, "[0-9]+ \\+ [0-9]+")) {
    pagecount.info$sheet <- sum(as.numeric(str_trim(unlist(strsplit(x, "\\+"), use.names = FALSE))))
    return(pagecount.info)
  } else if (!is.na(sum(as.numeric(roman2arabic(str_trim(unlist(strsplit(x, "\\+"), use.names = FALSE))))))) {
    x <- gsub("\\+", ",", x)
  } else if (str_detect(x, "^p") && !str_detect(x, "-")) {
    if (is.numeric(str_trim(gsub("^p", "", x)))) {
      pagecount.info$sheet <- 1
      return(pagecount.info)
    } else if (str_detect(x, "^p") && str_detect(x, "-")) {
      x <- gsub("^p", "", x)
    }
  } else if (str_detect(x, "^1 sheet \\[*[0-9+]\\]*")) {
    x <- gsub("1 sheet", "", x)
    x <- gsub("\\[1\\]", "2", x)
  } else if (str_detect(x, "^[0-9]+ sheets* [0-9]+ pages*$")) {
    x <- gsub("^s", "", unlist(strsplit(x, "sheet"), use.names = FALSE)[[2]])
  }
  
  # --------------------------------------------
  
  # Harmonize the items within commas
  x <- gsub("\\+", "", x)
  x <- gsub("pages*$", "", x)  
  
  # "[52] plates between [58] blank sheets"
  x <- gsub("plates between ", "plates, ", x)
  # 6 sheets + 2 sheets
  x <- gsub("sheets", "sheets,", x)
  
  # Handle comma-separated elements separately
  spl <- condense_spaces(unlist(strsplit(x, ","), use.names = FALSE))
  
  # 13 [1] -> 13, [1]
  if (length(grep("^[0-9]+ \\[[0-9]+\\]$", spl)) > 0) {
    spl <- gsub(" ", ", ", spl)
  }  
  spl <- condense_spaces(unlist(strsplit(spl, ","), use.names = FALSE))
  
  # Harmonize pages within each comma
  x <- sapply(spl, function(x) { harmonize_pages_by_comma(x) }, USE.NAMES = FALSE)
  
  # Remove empty items
  x <- as.vector(na.omit(x))
  if (length(x) == 0) {x <- ""}
  
  if (length(grep("^ff", x[[1]])) == 1) {
    # Document is folios - double the page count!
    pagecount.info$multiplier <- 2
  }
  
  # Fix romans
  x[x == "vj"] <- "vi"
  
  # Identify (potentially overlapping) attribute positions for
  # "arabic", "roman", "squarebracket", "dash", "sheet", "plate"
  # attributes x positions table 0/1
  pagecount.attributes <- attribute_table(x)
  
  # If dashes are associated with square brackets, 
  # consider and convert them to arabic. Otherwise not.
  dash <- pagecount.attributes["dash", ]
  sqb  <- pagecount.attributes["squarebracket", ]
  inds <- which(dash & sqb)
  pagecount.attributes["arabic", inds] <- TRUE
  pagecount.attributes["squarebracket", inds] <- FALSE
  
  # Page count can't be roman and arabic at the same time.
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
  
  # Sum square brackets
  inds <- pagecount.attributes["squarebracket",] & !pagecount.attributes["roman",]
  pagecount.info$squarebracket <- sumrule(x[inds])
  
  # Sum plates 
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
  
  if (length(grep("sheet", xinds)) > 0) {
    # 1 sheet = 2 pages
    xinds <- sapply(xinds, function(xi) { str_trim(unlist(strsplit(xi, "sheet"), use.names = FALSE)[[1]]) }, USE.NAMES = FALSE)
    xx <- suppressWarnings(2 * as.numeric(as.roman(xinds)))
  }
  pagecount.info$sheet <- sumrule(xx) 
  
  # Return pagecount components
  pagecount.info
  
}
