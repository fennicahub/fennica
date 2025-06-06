% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/remove_time_info.R
\name{remove_time_info}
\alias{remove_time_info}
\title{Remove Time Info}
\usage{
remove_time_info(x, verbose = FALSE, months = NULL)
}
\arguments{
\item{x}{Vector (time field)}

\item{verbose}{verbose}

\item{months}{months to remove}
}
\value{
Polished vector
}
\description{
Remove time information.
}
\details{
Remove months, year terms and numerics
}
\examples{
\dontrun{x2 <- remove_time_info(x)}
}
\references{
See citation("fennica")
}
\author{
Leo Lahti \email{leo.lahti@iki.fi}
}
\keyword{utilities}
