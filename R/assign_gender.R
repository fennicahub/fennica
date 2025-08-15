# sources: genderize.io (https://genderize.io/) and henko dataset (https://www.ldf.fi/dataset/henko) 
assign_gender <- local({
  .cache <- new.env(parent = emptyenv())
  
  function(x, current_gender = NULL, dict_path = "fennica_name_genders.csv") {
    # 0) Load + cache dictionary once per path
    if (!exists("dict", envir = .cache) ||
        !identical(get("dict_path", envir = .cache, inherits = FALSE), dict_path)) {
      
      dict <- fread(dict_path, colClasses = c(name = "character", gender = "character"))
      dict[, name_lower := tolower(trimws(name))]
      setorder(dict, name_lower)
      dict <- unique(dict, by = "name_lower")  # drop duplicate names
      setkey(dict, name_lower)
      
      assign("dict", dict, envir = .cache)
      assign("dict_path", dict_path, envir = .cache)
    } else {
      dict <- get("dict", envir = .cache)
    }
    
    n <- length(x)
    # 1) Start from current genders (if provided), else build empty
    out <- if (!is.null(current_gender)) as.character(current_gender) else rep(NA_character_, n)
    
    # 2) Only compute for rows we actually need to fill
    fill_idx <- is.na(out)
    if (!any(fill_idx)) return(out)
    
    need_raw <- x[fill_idx]
    need <- tolower(trimws(as.character(need_raw)))
    ok <- nzchar(need)
    if (!any(ok)) return(out)
    
    # 3) Unique strings to resolve
    u <- unique(need[ok])
    
    # 4) Tokenize once (split on ';' and whitespace), preserving order per string
    split_tokens <- function(v) {
      if (requireNamespace("stringi", quietly = TRUE)) {
        stringi::stri_split_regex(v, pattern = "[;\\s]+", omit_empty = TRUE, simplify = FALSE)
      } else {
        strsplit(v, "[;[:space:]]+", perl = TRUE)
      }
    }
    splits <- split_tokens(u)
    
    if (length(splits) == 0L) return(out)
    
    tok_dt <- data.table(
      id    = rep.int(seq_along(splits), lengths(splits)),
      token = tolower(trimws(unlist(splits, use.names = FALSE)))
    )
    tok_dt <- tok_dt[nzchar(token)]
    
    if (nrow(tok_dt)) {
      # 5) Join tokens to dict, then take the first matching token per unique string
      matched <- tok_dt[dict, on = .(token = name_lower), nomatch = 0L]
      if (nrow(matched)) {
        first <- matched[, .SD[1L], by = id]  # first token with a hit per string
        lut <- setNames(rep(NA_character_, length(u)), u)
        lut[first$id] <- first$gender
      } else {
        lut <- setNames(rep(NA_character_, length(u)), u)
      }
    } else {
      lut <- setNames(rep(NA_character_, length(u)), u)
    }
    
    # 6) Map back to all rows being filled
    map <- lut[ match(need, u) ]
    
    # careful: assign back using absolute positions
    idx <- which(fill_idx)
    out[idx[ok]] <- map
    
    out
  }
})
