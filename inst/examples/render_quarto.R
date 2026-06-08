library(quarto)

files <- c(
  "index.qmd",
  "author_info.qmd",
  "author_name.qmd",
  "author_date.qmd",
  "genre_655.qmd",
  "genre_008.qmd",
  "language.qmd",
  "physical_dimensions.qmd",
  "physical_extent.qmd",
  "publisher.qmd",
  "publication_place.qmd",
  "publication_time.qmd",
  "signum.qmd",
  "title.qmd",
  "title_remainder.qmd",
  "title2.qmd",
  "title_uniform.qmd",
  "udk.qmd",
  "content_type.qmd",
  "acknowledgments.qmd",
  "technical_information.qmd"
)

for (f in files) {
  message("Rendering: ", f)
  quarto_render(f)
}