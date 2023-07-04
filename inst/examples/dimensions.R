
field <- "dimensions"
synonyms <- read.csv("../extdata/translation_fi_en_pages.csv", sep = ";") 
df.orig.full$dimensions <- comhis::map(df.orig.full$dimensions,
          synonyms, mode = "recursive")

# Fill in missing entries where estimates can be obtained:
# area, width, height, gatherings
# (also keep pure originals before fill in)
# devtools::load_all("~/comhis/rpkg/bibliographica")
df.tmp <- polish_dimensions(df.orig.full[[field]], fill = TRUE, verbose = TRUE)

