library(dplyr)

unique_count <- as.data.frame(df.orig %>%
  summarise(n_unique = n_distinct(type_of_record)))

unique_counts <- table(df.orig$type_of_record)

unique_counts_df$percentage <- unique_counts_df$n_unique / sum(unique_counts_df$n_unique) *  100




top_plot(df.orig, "type_of_record", ntop = 10, log10 = TRUE) + labs(y = "Entries (n)")


x <- top(df.orig, "type_of_record")
tab <- cbind(names(x), unname(x), round(100 * unname(x/nrow(df)), 1))
colnames(tab) <- c("Type of Record", "Documents (n)", "Fraction (%)")
kable(head(tab, 14))
