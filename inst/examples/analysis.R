# Combine Fennica + Kungliga and mark duplicates
source("analysis.combined.R")


# Duplicate analyses / HR
# may have to be updated after the latest code changes
# but very slow
# TODO develop cache system or similar
source("analysis.combined.run.R")
warning("Check analysis.combined.run.R")

# Custom analyses
knitr::knit("summary.Rmd", encoding="UTF-8")
knitr::knit("Helsinki.Rmd", encoding="UTF-8")
knitr::knit("Suomi.Rmd", encoding="UTF-8")
knitr::knit("Turku.Rmd", encoding="UTF-8")
knitr::knit("Vaasa.Rmd", encoding="UTF-8")
knitr::knit("suvut.Rmd", encoding="UTF-8")
knitr::knit("swedish_gap.Rmd", encoding="UTF-8")
# knitr::knit("20151209-HelsinkiDH.Rmd", encoding="UTF-8")
# knitr::knit("20160303-Krakow.Rmd", encoding="UTF-8")

# RM knitr::knit("20161117-manuscript.Rmd", encoding="UTF-8")
# RM knitr::knit("20170125-Manuscript-FK.Rmd", encoding="UTF-8")
# RMrmarkdown::render("manuscript-krakow.Rmd") # Manuscript draft
# knitr::knit("manuscript-krakow.Rmd", encoding="UTF-8")

# Gaudeamus
# knitr::knit("201705-Gaudeamus.Rmd", encoding="UTF-8")
#rmarkdown::render("201705-Gaudeamus.Rmd", output_format="pdf_document")
#rmarkdown::render("201705-Gaudeamus.Rmd") 
#source("Figure3.R")

# Manuscript 2/2017 Figures
# Historical Methods 2018 Marjanen et al.

#library(rmarkdown); library(knitr)
#knitr::knit("201808-HistoricalMethods-Figures.Rmd", encoding="UTF-8")
#rmarkdown::render("201808-HistoricalMethods-Supplement.Rmd", output_format = "pdf_document", encoding="UTF-8") 

# rmarkdown::render("20160715-Krakow-Fennica.Rmd") # Krakow 7/2016 slides frozen.
# library(rmarkdown)
# rmarkdown::render("slidetemplates.Rmd", params = list(min.year = 1488, max.year = 1828, data = "df.combined.Rds"))
# rmarkdown::render("slidetemplates.Rmd", params = "ask")
# rmarkdown::render("flexdashboard.Rmd")
# rmarkdown::render("slides.Rmd") # Another Slide draft, to bw combined
# rmarkdown::render("test.Rmd") # For interactive testing

# Push changes to github
# https://github.com/ropensci/git2r
# library(git2r)
# repo <- repository("../../")
#config(repo, user.name="antagomir", user.email="leo.lahti@iki.fi")
# add(repo, "figure/*.png", force = TRUE)
# commit(repo, "Rmd update")
# push(repo) # does not work ?
#system("git push")

# # system("git add -f figure/*.png")
# # system("git add output.tables/*.csv")
# system("git commit -a -m'Rmd update'")
# system("git push")



