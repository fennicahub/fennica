#' @import dplyr
#' @importFrom graphics plot
#' @importFrom grDevices dev.off
#' @importFrom grDevices png
#' @importFrom stats na.omit
#' @importFrom stringdist amatch
#' @importFrom stringr str_extract
#' @importFrom stringr str_replace
#' @importFrom stringr str_trim
#' @importFrom data.table fread
#' @importFrom utils adist
#' @importFrom utils read.csv
#' @importFrom utils tail
#' @importFrom utils as.roman
#' @importFrom stringr str_split
#' @importFrom stringr str_count
#' @importFrom stringr str_c
#' @importFrom tm stopwords

globalVariables(c("published_in","publication_place"))

.onAttach <- function(lib, pkg)
{

  # This may help with encodings in Mac/Linux
  # Sys.setlocale(locale = "UTF-8")
  # Sys.setlocale(locale = "WINDOWS-1252")

  packageStartupMessage("fennica - Algorithms for Finnish Library Data.\nCopyright (C) 2014-2021 Leo Lahti, Hege Roivainen, and Mikko Tolonen\n\nhttps://github.com/COMHIS/fennica \n\n Some scientists will seek and develop new collaborative arrangements; have members from all fields of science; and these new ways of working, effectively instrumented by huge computers, will contribute greatly to the advance in handling the complex, but essentially organic, problems of the biological and social sciences. - Weaver 1948 \n")

}
