selected.countries <- c("Suomi","Ruotsi","USA","Saksa","Tanska","UK","Viro","Venäjä")
dfx <- df.full %>% filter(publication_ctr %in% selected.countries) %>% filter(!is.na(publication_tia))
dfx$publication_dec <- as.numeric(paste0(substr(dfx$publication_tia,1,3),"0"))
dfz <- dfx %>% group_by(publication_ctr, publication_dec) %>% summarize(documents = n())

theme_set(theme_bw(20))
p <- ggplot(dfz, aes(x = publication_dec, y = documents, group = publication_ctr))
p <- p + geom_point(aes(col = publication_ctr))
p <- p + geom_line(aes(col = publication_ctr))
p <- p + xlab("Publication Decade")
p <- p + ylab("Documents (n)")
p
