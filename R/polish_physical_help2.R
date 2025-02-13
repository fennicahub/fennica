polish_physical_help2 <- function (x, page.harmonize) {
  
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
