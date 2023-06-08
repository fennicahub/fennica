---
title: "Document dimension preprocessing summary"
author: "Helsinki Computational History Group (COMHIS)"
date: "2021-01-15"
output: markdown_document
---



## Document size comparisons

  * Some dimension info is provided in the original raw data for altogether 0 documents (0%) but could not be interpreted for 0 documents (ie. dimension info was successfully estimated for NaN % of the documents where this field was not empty).

  * Document size (area) info was obtained in the final preprocessed data for altogether 479 documents (48%). For the remaining documents, critical dimension information was not available or could not be interpreted: [List of entries where document surface could not be estimated](physical_dimension_incomplete.csv)

  * Document gatherings info is originally available for NA documents (NA%), and further estimated up to NA documents (NA%) in the final preprocessed data.

  * Document height info is originally available for 39 documents (4%), and further estimated up to 479 documents (48%) in the final preprocessed data.

  * Document width info is originally available for 0 documents (0%), and further estimated up to 479 documents (48%) in the final preprocessed data.


These tables can be used to verify the accuracy of the conversions from the raw data to final estimates:

  * [Dimension conversions from raw data to final estimates](conversions_physical_dimension.csv)

  * [Automated tests for dimension conversions](https://github.com/COMHIS/fennica/blob/master/inst/extdata/tests_dimension_polish.csv)



The estimated dimensions are based on the following auxiliary information sheets:

  * [Document dimension abbreviations](https://github.com/COMHIS/fennica/blob/master/inst/extdata/document_size_abbreviations.csv)

  * [Standard sheet size estimates](https://github.com/COMHIS/fennica/blob/master/inst/extdata/sheetsizes.csv)

  * [Document dimension estimates](https://github.com/COMHIS/fennica/blob/master/inst/extdata/documentdimensions.csv) (used when information is partially missing)


  
<!--[Discarded dimension info](dimensions_discarded.csv)-->

Left: final gatherings vs. final document dimension (width x height). Right: original gatherings versus original heights where both are available. The point size indicates the number of documents for each case. The red dots indicate the estimated height that is used when only gathering information is available. 



```
## Error: Problem with `filter()` input `..1`.
## ✖ object 'paper' not found
## ℹ Input `..1` is `!is.na(paper) & !is.na(gatherings)`.
```

```
## Error in `[.data.frame`(dfs, , c("gatherings", "paper")): undefined columns selected
```

<img src="figure/dimension-summary-1.png" title="plot of chunk summary" alt="plot of chunk summary" width="280px" /><img src="figure/dimension-summary-2.png" title="plot of chunk summary" alt="plot of chunk summary" width="280px" /><img src="figure/dimension-summary-3.png" title="plot of chunk summary" alt="plot of chunk summary" width="280px" />


Left: Document dimension histogram (surface area);
Middle: Paper consumption histogram;
Right: title count per gatherings.


```
## Error in FUN(X[[i]], ...): object 'paper' not found
```

<img src="figure/dimension-sizes-1.png" title="plot of chunk sizes" alt="plot of chunk sizes" width="280px" /><img src="figure/dimension-sizes-2.png" title="plot of chunk sizes" alt="plot of chunk sizes" width="280px" />

### Gatherings timelines




Popularity of different document sizes over time. Left: absolute title counts. Right: relative title counts. Gatherings with less than 15 documents at every decade are excluded:



```
## Error in timeline(dfs, group = "gatherings", nmin = nmin, mode = "absolute"): could not find function "timeline"
```

```
## Error in print(res$plot): object 'res' not found
```

```
## Error in timeline(dfs, group = "gatherings", nmin = nmin, mode = "percentage"): could not find function "timeline"
```

```
## Error in print(res$plot): object 'res' not found
```


### Title count versus paper consumption




```
## Error: Problem with `summarise()` input `p`.
## ✖ object 'paper' not found
## ℹ Input `p` is `sum(paper, na.rm = TRUE)`.
## ℹ The error occurred in group 1: publication_year = 1575.
```

```
## Error in ggplot(d, aes(y = n, x = p)): object 'd' not found
```

![plot of chunk title_vs_paper](figure/dimension-title_vs_paper-1.png)

<!--


## Average document dimensions 

Here we use the original data only:

![plot of chunk avedimstime](figure/dimension-avedimstime-1.png)




Only the most frequently occurring gatherings are listed here:


Table: Average document dimensions

|gatherings.original | mean.width| median.width| mean.height| median.height|  n|
|:-------------------|----------:|------------:|-----------:|-------------:|--:|

-->
