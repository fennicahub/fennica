
library(rmarkdown)
rmarkdown::render("manuscript-krakow.Rmd")
#knitr::knit("manuscript-krakow.Rmd", encoding="UTF-8")

# Push changes to github
# https://github.com/ropensci/git2r
library(git2r)
repo <- repository("../../")
#config(repo, user.name="antagomir", user.email="leo.lahti@iki.fi")
add(repo, "figure/*.png", force = TRUE)
# commit(repo, "Rmd update")
# push(repo) # does not work ?
#system("git push")

# # system("git add -f figure/*.png")
# # system("git add output.tables/*.csv")
# system("git commit -a -m'Rmd update'")
# system("git push")
