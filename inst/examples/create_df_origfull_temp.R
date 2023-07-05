#run this to create the main df with needed fields
#add more fields from the pick_fields

df.orig <- read.csv(file = "priority_fields_full_fennica.csv", skip = 1, head = TRUE, sep="\t")
colnames(df.orig)[1] ="melinda_id" #as index
colnames(df.orig)[2] ="language" #041a "author_name" #100a 

#change symbols or change | to ; in the combine_csv would be a better solution
#df.orig$language <- gsub("//|.*",";",df.orig$language)
#df.orig$language <- gsub(";"," ",df.orig$language)

colnames(df.orig)[3] ="language_original"  
colnames(df.orig)[4] ="author_name" #100a  # sign "|" has to be change to "," because some languages are written in more than one language use gsub
colnames(df.orig)[5] ="author_date" #100d 
colnames(df.orig)[6] ="title_uniform" #240a"
colnames(df.orig)[7] ="title" #245a
colnames(df.orig)[8] ="title_remainder" #245b #not included
colnames(df.orig)[9] ="publication_place"# 260a # sign "|" has to be dealt with
colnames(df.orig)[10] ="publisher_name" # 260b #same issues
colnames(df.orig)[11] ="publication_date" #260c #does it have multiple publication years
colnames(df.orig)[12] ="physical_extent" #300a
colnames(df.orig)[13] ="other_physical_details" #300b
colnames(df.orig)[14] ="physical_dimensions" #300c
colnames(df.orig)[15] ="accompanying_material" #300e
colnames(df.orig)[16] ="publication_frequency" #310a
colnames(df.orig)[17] ="publication_interval" #362a 
colnames(df.orig)[18] ="subject_geography" #651a
colnames(df.orig)[19] ="callnumbers" #callnumbers a


