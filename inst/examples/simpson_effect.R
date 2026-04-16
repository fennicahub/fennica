# # Download the csv file
url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/harmonized_fennica.csv"
# 
# Read the CSV file, explicitly setting the first column to character
# Count the number of columns in the file
column_count <- ncol(read.csv(url, nrows = 1, sep = "\t"))
#Create colClasses with 'character' for the first column and 'default' for the rest
col_classes <- c("character", rep(NA, column_count - 1))

# Read the file with the specified colClasses
df  <- read.csv(url, header = TRUE, sep = "\t", quote = "", stringsAsFactors = FALSE, colClasses = col_classes)

df2 <- df

df1 <- df %>% filter(publication_year >= 1809 & publication_year <= 1917)
