% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/polish_years.R
\name{polish_year}
\alias{polish_year}
\title{Polish year}
\usage{
polish_year(
  x,
  start_synonyms = NULL,
  end_synonyms = NULL,
  months,
  verbose = FALSE,
  min.year = -3000,
  max.year = 2100
)
}
\arguments{
\item{x}{year string}

\item{start_synonyms}{Synonyme table for start year}

\item{end_synonyms}{Synonyme table for end year}

\item{months}{months}

\item{verbose}{verbose}

\item{min.year}{Minimum year accepted}

\item{max.year}{Maximum year accepted}
}
\value{
vector with the fields 'from' and 'till'
}
\description{
Pick and polish the year interval (start and end years) from a time field '
}
\examples{
\dontrun{df <- polish_year(c("1746"))}
}
\author{
Leo Lahti and Niko Ilomaki \email{leo.lahti@iki.fi}
}
\keyword{utilities}
