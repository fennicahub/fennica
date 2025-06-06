% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/remove_endings.R
\name{remove_endings}
\alias{remove_endings}
\title{Remove Endings}
\usage{
remove_endings(x, endings, random_order = FALSE)
}
\arguments{
\item{x}{vector}

\item{endings}{endings to remove}

\item{random_order}{Order the endings randomly before removal. TRUE/FALSE}
}
\value{
polished vector
}
\description{
Remove specified endings of strings.
}
\examples{
\dontrun{x2 <- remove_endings(x, endings)}
}
\references{
See citation("fennica")
}
\author{
Leo Lahti \email{leo.lahti@iki.fi}
}
\keyword{utilities}
