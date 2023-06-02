#execute in the fennica/inst/examples directory

library(quarto)
library(knitr)

#all the files in the _bookdown.yml without subject_geography.Rmd
rmd_files <- c(
  "index.Rmd", "author_date.Rmd", "author_name.Rmd",
  "corporate.Rmd", "language.Rmd", "holder.Rmd",
  "note_dissertation.Rmd", "note_granter.Rmd", "note_source.Rmd",
  "publisher.Rmd", "publication_interval.Rmd", "publication_place.Rmd",
  "publication_time.Rmd", "subject_topic.Rmd", "successor.Rmd",
  "title.Rmd", "title_uniform.Rmd", "uncontrolled.Rmd"
)


#lopp for files convertion
for (file in rmd_files) {
  # name for the qmd files : we just change the file's extension
  qmd_file <- gsub("\\.Rmd$", ".qmd", file) 

  tryCatch({
    # convert the .Rmd file into quarto format, the output is just the name of the new .qmd file created
    knitr::convert_chunk_header(file, output = qmd_file)
    cat("created:", qmd_file, "\n")
  }, error = function(e) {
    cat("Failed to convert:", file, "\n")
  })
}

# all the Rmd files int the current dir
qmd_files <- list.files(pattern = "\\.qmd$")

#loop for files treatment
for (file in qmd_files) {
  tryCatch({
    # put `source("init.R")` at the beginning od the document : source all the necessary dependencies
    # [TODO : find an other solution]
    quarto_code <- readLines(file)
    quarto_code <- c("```{r}", "#| include = FALSE", "source(\"init.R\")", "```", quarto_code)
    writeLines(quarto_code, file)

  }, error = function(e) {
    cat("Failed to render:", file, "\n")
  })
}

# render the document in the current directory
quarto::quarto_render() 