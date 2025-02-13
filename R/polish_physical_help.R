#author: Julia Matveeva yulmat@utu.fi,  Leo Lahti leo.lahti@utu
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
  vols <- vols[1:length(pagecount.info[["volcount"]])]
  page.info[["pagecount"]] <- as.vector(s)
  page.info[["volnumber"]] <- as.vector(voln)
  #FIX below
  vols <- vols[1:length(pagecount.info[["volcount"]])]
  page.info[["volcount"]] <- as.vector(vols)
  page.info[["parts"]] <- as.vector(parts)
  page.info <- unlist(page.info)
  
  page.info
  
}

