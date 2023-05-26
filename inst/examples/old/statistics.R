---
title: "Historical Methods 1488-1828"
author: "Marjanen, Lahti, Roivainen, Tolonen"
date: "August 28, 2018"
output: word_document
---


```{r init, echo=FALSE, message=FALSE, warning=FALSE}
# To be run after all historical methods analyses
library(skimr)
d <- list()

fen <- subset(df0, catalog == "Fennica")
kun <- subset(df0, catalog == "Kungliga")
cats <- list(Fennica = fen, Kungliga = kun)

for (cat in unique(df0$catalog)) {

  dd <- subset(df0, catalog == cat)[, c("publication_year", "publication_place", "gatherings", "title", "pagecount", "publisher", "language", "subject_topic")]

  complete <- round(100 * colMeans(!is.na(dd)), 1)
  unique <- apply(dd, 2, function (x) {length(unique(x))})

  d[[cat]] <- data.frame(Field = colnames(dd), Complete = complete, Unique = unique)

}
```


### Total overview

Records in 1488-1828 after the duplicate removal:

 * Fennica: ```r nrow(subset(df0, catalog == "Fennica"))```
 * Kungliga: ```r nrow(subset(df0, catalog == "Kungliga"))```


### Field completeness

```{r complete, echo=FALSE, message=FALSE, warning=FALSE}
w <- data.frame(Field = map_fieldnames(colnames(dd)),
           Fennica = d$Fennica$Complete,
	   Kungliga = d$Kungliga$Complete) %>%
	     arrange(desc(Fennica))

kable(w)
```


### Unique entries in each field

```{r unique, echo=FALSE, message=FALSE, warning=FALSE}
w <- data.frame(Field = map_fieldnames(colnames(dd)),
           Fennica = d$Fennica$Unique,
	   Kungliga = d$Kungliga$Unique) %>%
	     arrange(desc(Fennica))

kable(w)
```




### Title


Number of unique and all non-empty titles per catalog.

```{r titles, echo=FALSE, message=FALSE, warning=FALSE}
df <- df0 %>% group_by(catalog) %>% summarise(Unique = length(unique(title)), All = sum(!is.na(title)))
kable(df)
```


Title length variation quantified in characters and in words.

```{r title_characters, echo=FALSE, message=FALSE, warning=FALSE}
library(ggplot2)
theme_set(theme_bw(20))
library(tidyverse)
df <- df0 %>% mutate(title_chars = nchar(title))
p <- ggplot(df) +
       geom_histogram(aes(x = title_chars)) + 
       labs(x = "Title length (characters)",
            y = "Frequency (n)") +
       #scale_x_log10(breaks = 10^(0:3)) +
       scale_x_log10(breaks = c(1, 10, 100, 1000)) +       
       facet_grid(. ~ catalog)
print(p)
```




```{r title_words, echo=FALSE, message=FALSE, warning=FALSE}
library(ggplot2)
library(stringi)
theme_set(theme_bw(20))
library(tidyverse)
df <- df0 %>% mutate(title_words = stri_count_words(title))
p <- ggplot(df) +
       geom_histogram(aes(x = title_words)) + 
       labs(x = "Title length (words)",
            y = "Frequency (n)") +
       #scale_x_log10(breaks = 10^(0:3)) +
       scale_x_log10(breaks = c(1, 10, 100)) +       
       facet_grid(. ~ catalog)
print(p)
```




### Genre

Number of unique and all genres per catalog.

```{r titles, echo=FALSE, message=FALSE, warning=FALSE}
df <- df0 %>% group_by(catalog) %>%
              summarise(Unique = length(unique(subject_topic)),
	                All = sum(!is.na(subject_topic)))
kable(df)
```


The most common genres in Fennica:

```{r genres_fen, echo=FALSE, message=FALSE, warning=FALSE}
kable(top(fen, "subject_topic", 10, "data.frame"))
```


The most common genres in Kungliga:

```{r genres_kun, echo=FALSE, message=FALSE, warning=FALSE}
kable(top(kun, "subject_topic", 10, "data.frame"))
```


### Publisher

Number of unique and all publishers per catalog.

```{r titles, echo=FALSE, message=FALSE, warning=FALSE}
field <- "publisher"
df$field <- df[[field]]

df <- df0 %>% group_by(catalog) %>%
              summarise(Unique = length(unique(field)),
	                All = sum(!is.na(field)))
kable(df)
```


The most common publishers in Fennica:

```{r publishers_fen, echo=FALSE, message=FALSE, warning=FALSE}
kable(top(fen, field, 10, "data.frame"))
```


The most common publishers in Kungliga:

```{r publishers_kun, echo=FALSE, message=FALSE, warning=FALSE}
kable(top(kun, field, 10, "data.frame"))
```



### Pages

Page count variation.

```{r pagecount, echo=FALSE, message=FALSE, warning=FALSE}
p <- ggplot(df0) +
       geom_histogram(aes(x = pagecount)) + 
       labs(x = "Page count (n)",
            y = "Frequency (n)") +
       scale_x_log10(breaks = c(1, 10, 100, 1000)) +       
       facet_grid(. ~ catalog)
print(p)
```


### Language


Number of unique and all languages per catalog.

```{r languages , echo=FALSE, message=FALSE, warning=FALSE}
field <- "language"
df$field <- df[[field]]

df <- df0 %>% group_by(catalog) %>%
              summarise(Unique = length(unique(field)),
	                All = sum(!is.na(field)))
kable(df)
```


The most common languages in Fennica:

```{r languages_fen, echo=FALSE, message=FALSE, warning=FALSE}
kable(top(fen, field, 10, "data.frame"))
```

The most common languages in Kungliga:

```{r languages_kun, echo=FALSE, message=FALSE, warning=FALSE}
kable(top(kun, field, 10, "data.frame"))
```


### Publication place

Number of unique and all publication places per catalog.

```{r places, echo=FALSE, message=FALSE, warning=FALSE}
field <- "publication_place"
df$field <- df[[field]]

df <- df0 %>% group_by(catalog) %>%
              summarise(Unique = length(unique(field)),
	                All = sum(!is.na(field)))
kable(df)
```


The most common publication places in Fennica:

```{r languages_fen, echo=FALSE, message=FALSE, warning=FALSE}
kable(top(fen, field, 10, "data.frame"))
```

The most common publication places in Kungliga:

```{r languages_kun, echo=FALSE, message=FALSE, warning=FALSE}
kable(top(kun, field, 10, "data.frame"))
```



### Format (Gatherings)

Number of unique and all gatherings per catalog.

```{r places, echo=FALSE, message=FALSE, warning=FALSE}
field <- "gatherings"
df$field <- df[[field]]

df <- df0 %>% group_by(catalog) %>%
              summarise(Unique = length(unique(field)),
	                All = sum(!is.na(field)))
kable(df)
```

