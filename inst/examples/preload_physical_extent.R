# Load necessary CSV files beforehand
remove_dimension_data <- read.csv("remove_dimension.csv", sep = ";", row.names = NULL)
translation_fi_en_data <- read.csv("translation_fi_en_pages.csv", sep = ";", row.names = NULL)
numbers_finnish_data <- read.csv("numbers_finnish.csv", sep = ",")
harmonize_sheets_data <- read.csv("harmonize_sheets.csv", sep = ";")
harmonize_pages_data <- read.csv("harmonize_pages.csv", sep = "\t")
harmonize_pages2_data <- read.csv("harmonize_pages2.csv", sep = "|")
harmonize_romans_data <- read.csv("harmonize_romans.csv", sep = "\t")
numbers_english_data <- read.csv("numbers_english.csv", sep = ",")
