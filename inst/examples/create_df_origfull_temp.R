#run this to create the main df with needed fields
#add more fields from the pick_fields

df.orig.full <- read.csv(file = "priority_fields_full_fennica.csv", skip = 1, head = TRUE, sep="\t")
colnames(df.orig.full)[1] ="melinda_id" #as index
colnames(df.orig.full)[2] ="author_name"
colnames(df.orig.full)[3] ="author_date"
colnames(df.orig.full)[4] ="language"
colnames(df.orig.full)[5] ="title_uniform"
colnames(df.orig.full)[6] ="title"
colnames(df.orig.full)[7] ="publication_place"
colnames(df.orig.full)[8] ="publisher"
colnames(df.orig.full)[9] ="publication_time"
colnames(df.orig.full)[10] ="current_publication_frequency"#?
colnames(df.orig.full)[11] ="dates of publicaton and/or sequence designation"#?
colnames(df.orig.full)[12] ="note_dissertation"
colnames(df.orig.full)[13] ="note_granter"
colnames(df.orig.full)[14] ="year_degree_granted"#?
colnames(df.orig.full)[15] ="note_source" 
colnames(df.orig.full)[16] ="topic" #?
colnames(df.orig.full)[17] ="geohraphic_name"#?
colnames(df.orig.full)[18] ="corporate"
colnames(df.orig.full)[19] ="uncontrolled"
colnames(df.orig.full)[20] = "successor"
colnames(df.orig.full)[21] = "holder"

