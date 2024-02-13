library(dplyr)

#the file need to be zipped, otherwise it's too big to be put on github
unzip("aineistotyypit.zip",exdir=".")
# List the preprocessed data file and read the data
df_content <- read.csv(file = "aineistotyypit.csv", skip = 1, head = TRUE, sep="\t")
#rename column names
df_content <- df_content %>% 
  dplyr::rename("melinda_id" = 1, #("035","a")
                "leader" = 2, # ("leader","-")
                "008" = 3, # ("008","-")
                "336" = 4, #("336","a")
                "337" = 5, # ("337","a")
                "338" = 6, # ("338","a")
                "publication_time" = 7, #("260","c")
                "signum" = 8) #("callnumbers","a")

# Define the pattern to match from the  8th character to the first letter character
pattern <- "^(.{7})([^a-zA-Z]*)(.)(.*)"

# Use sub to replace the matched pattern with the part you want to keep
# In this case, we're keeping the part after the  8th character and before the first letter
df_content$`008_07/10` <- sub(pattern, "\\2\\4", df_content$`008`)

# Define the pattern to match the first letter character and everything after it
pattern <- "[a-zA-Z].*"

# Use sub to replace the matched pattern with an empty string
df_content$`008_07/10` <- sub(pattern, "", df_content$`008_07/10`)


# Function to remove non-numeric characters
remove_non_numeric <- function(x) {
  gsub("[^0-9]", "", x)
}

# Apply the function to each element of the column
df_content$`008_07/10`<- sapply(df_content$`008_07/10`, remove_non_numeric)

df_content$publication_time<- sapply(df_content$publication_time, remove_non_numeric)


# Count the number of rows where column1 and column2 match
matching_rows <- sum(df_content$publication_time == df_content$`008_07/10`)
print(matching_rows)

# Count the number of rows where column1 and column2 do not match
non_matching_rows <- sum(df_content$publication_time != df_content$`008_07/10`)
print(non_matching_rows)

# Create df for better visualisation of non_matching_rows
non_matching_rows2 <- as.data.frame(df_content[df_content$publication_time != df_content$`008_07/10`, ])



# Identify the rows where '008_07/10' is empty
empty_07_rows <- which(is.na(non_matching_rows2$`008_07/10`) |
                         non_matching_rows2$`008_07/10` == "" |
                         non_matching_rows2$`008_07/10` == " ")

# Print the rows with empty '008_07/10'
print(non_matching_rows2[empty_07_rows,  ])

# Count the number of empty cells in the 'publication_time' column
# Check for NA, empty strings, and spaces
empty_pubtime <- sum(is.na(non_matching_rows2$publication_time) |  
                       non_matching_rows2$publication_time == "" |  
                       non_matching_rows2$publication_time == " ")

# Print the count of empty cells
print(empty_pubtime)

# Remove rows where both 'publication_time' and '008_07/10' are empty
non_matching_rows2 <- non_matching_rows2[!(is.na(non_matching_rows2$publication_time) &  
                                             non_matching_rows2$publication_time == "" &  
                                             non_matching_rows2$publication_time == " " &  
                                             is.na(non_matching_rows2$`008_07/10`) &  
                                             non_matching_rows2$`008_07/10` == "" &  
                                             non_matching_rows2$`008_07/10` == " "), ]

# Print the cleaned data frame
print(non_matching_rows2)

# Count the number of values longer than  4 characters
longer_than_four <- sum(nchar(non_matching_rows2$publication_time) >  4)

# Count the number of empty cells
empty_cells <- sum(is.na(non_matching_rows2$publication_time) |
                     non_matching_rows2$publication_time == "" |
                     non_matching_rows2$publication_time == " ")

# Count the number of values exactly  8 characters long
exactly_eight <- sum(nchar(non_matching_rows2$publication_time) ==  8)

# Print the counts
print(paste("Longer than  4 characters: ", longer_than_four))
print(paste("Empty cells: ", empty_cells))
print(paste("Exactly  8 characters long: ", exactly_eight))

# Count the number of values between  4 and  8 characters long
count_between_4_and_8 <- sum(nchar(non_matching_rows2$publication_time) >  4 & nchar(non_matching_rows2$publication_time) <  8)

# Print the count
print(count_between_4_and_8)





