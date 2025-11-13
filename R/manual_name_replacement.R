#' @title Manual name replacements
#' @description Replace known pseudonyms or abbreviations in author names with full names.
#' @param s Character vector of author names
#' @param verbose Logical; if TRUE, print which replacements are made
#' @return Character vector with replacements applied
#' @examples
#' manual_name_replace(c("Isko", "A***,", "H-n,"), verbose = TRUE)
#' @export
manual_name_replace <- function(s, verbose = FALSE) {
  
  # --- Known manual replacements (regex patterns → full names) ---
  replacements <- list(
    "G\\. H\\. M-n" = "Mellin, Gustaf Henrik",
    "H-n" = "Hultin, Constance",
    "Ignatius, K\\. H\\. J\\." = "Ignatius, Carl Henrik Jakob",
    "Vendela" = "Randelin, Vendela",
    "En finne" = "Herman Avellan",
    "Räty, A" = "Räty, Anders",
    "-a-e-i" = "Galetski, Johan Fredrik",
    "-a -g" = "Runeberg, Fredrika",
    "A-ï-a" = "Ehrnrooth, Lovisa Adelaïda Ehrnrooth",
    "F\\. I\\." = "Ingberg, F.",
    "A\\*\\*\\*" = "Hongell, Alma",
    "Malle" = "Mallander, Malle",
    "Maria" = "Furuhjelm, Maria",
    "-ii-" = "Gerda von Mickwitz",
    "Aina" = "Forssman, Edith Theodora",
    "Nea" = "Huldi Torckell",
    "J\\. W\\." = "Wälmä, Juho",
    "A-nen" = "Anttonen, A. E.",
    "Isko" = "Kulovuori, Ida Sofia",
    "-ei-" = "Edelheim, Anna",
    "K\\. L\\." = "Lehmus, Kyösti",
    "Viva" = "Kronqvist, Olivia",
    "Aira" = "Koljonen, Maiju",
    "e-d" = "Melander, Elise",
    "-r-t" = "Enqvist, Walter",
    "Ura" = "Fredrik Wessman",
    "-lma" = "Holsti, Ilma",
    "Kynä" = "Saarinen, Toivo",
    "Setä" = "Kaarlo Luoto",
    "M\\. V\\." = "Virtanen, M.",
    "K-E\\." = "Oskari Korhonen",
    "Juuso" = "Kaksonen, Antti",
    "Niku" = "Kivinen, Niilo",
    "H\\." = "Hoving, Isaac Wilhelm",
    "L-n" = "Laurén, Ludvig Leonard",
    "-st-" = "Nordlund, Kustavi (Johan Gustaf)",
    "Oiva" = "Sahlman, Malviina"
  )
  
  # --- Apply replacements ---
  for (pattern in names(replacements)) {
    match_idx <- grepl(pattern, s, ignore.case = TRUE)
    if (any(match_idx)) {
      if (verbose) {
        message(sprintf("Replaced %d occurrence(s) of '%s' with '%s'",
                        sum(match_idx), pattern, replacements[[pattern]]))
      }
      s[match_idx] <- replacements[[pattern]]
    }
  }
  
  return(s)
}

