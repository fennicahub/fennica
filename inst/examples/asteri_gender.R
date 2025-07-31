# load csv 
asteri_genders <- read.csv("asteri_genders.csv", sep = ";", header = FALSE)
names <- c("id1", "name", "id2", "gender", "count")
colnames(asteri_genders) <- names
# Ensure both ID columns are character (important for matching!)
df.orig$author_id <- toupper(gsub(" ", "", as.character(df.orig$author_id)))
asteri_genders$id2 <- toupper(gsub(" ", "", as.character(asteri_genders$id2)))

# Safely map gender to df.orig
df.orig$gender <- asteri_genders$gender[match(df.orig$author_id, asteri_genders$id2)]

df.orig$author_id[trimws(df.orig$author_id) == ""] <- NA
df.orig$gender[trimws(df.orig$gender) == ""] <- NA
