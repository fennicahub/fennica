## Author productivity for 1809-1917

Title count in relation to the paper consumed in their books(all authors):
  
  ```{r}
#| label = "authortitlespapers",
#| fig.height = 8,
#| fig.width = 18,
#| echo = FALSE,
#| warning = FALSE
library(dplyr)
library(gridExtra)
library(grid)
library(ggplot2)
library(lattice)

theme_set(theme_bw(base_size = 12))
res1 <- compare_title_paper(df, "author_name", plot.mode = "text")
res2 <- compare_title_paper(df, "author_name", plot.mode = "point")
grid.arrange(res2$plot, res1$plot, nrow = 1)
#kable(res1$table)
```
