% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AllGenerics.R, R/methods-plotCountsPerGene.R
\docType{methods}
\name{plotCountsPerGene}
\alias{plotCountsPerGene}
\alias{plotCountsPerGene,bcbioRNASeq-method}
\alias{plotCountsPerGene,data.frame-method}
\title{Plot Counts Per Gene}
\usage{
plotCountsPerGene(object, ...)

\S4method{plotCountsPerGene}{bcbioRNASeq}(object, interestingGroups,
  normalized = "tmm", fill = scale_fill_viridis(discrete = TRUE),
  flip = TRUE)

\S4method{plotCountsPerGene}{data.frame}(object,
  interestingGroups = "sampleName", fill = scale_fill_viridis(discrete =
  TRUE), flip = TRUE)
}
\arguments{
\item{object}{Object.}

\item{...}{\emph{Additional arguments (for the S4 generic definition).}}

\item{interestingGroups}{Category to use to group samples. In the plotting
functions, this will define color and shape, where applicable. If unset,
this is automatically determined by the metadata set inside the
\link{bcbioRNASeq} object. When set to \code{NULL}, this will default to
\code{sampleName}.}

\item{normalized}{Count normalization method. See \code{\link[=counts]{counts()}} documentation
for more information.}

\item{fill}{Desired ggplot fill scale. Defaults to
\code{\link[viridis:scale_fill_viridis]{viridis::scale_fill_viridis()}}. Must supply discrete values. When set to
\code{NULL}, the default ggplot2 color palette will be used. If manual color
definitions are desired, we recommend using \code{\link[ggplot2:scale_fill_manual]{ggplot2::scale_fill_manual()}}.}

\item{flip}{Flip x and y axes.}
}
\value{
\link{ggplot}.
}
\description{
Plot Counts Per Gene
}
\examples{
plotCountsPerGene(bcb)

\dontrun{
plotCountsPerGene(
    bcb,
    interestingGroups = "group",
    fill = NULL)
}

# data.frame
\dontrun{
meltLog10(bcb, normalized = "tmm") \%>\% plotCountsPerGene()
}
}
\seealso{
Other Quality Control Plots: \code{\link{plot53Bias}},
  \code{\link{plotCountDensity}},
  \code{\link{plotExonicMappingRate}},
  \code{\link{plotGenderMarkers}},
  \code{\link{plotGeneSaturation}},
  \code{\link{plotGenesDetected}}, \code{\link{plotGene}},
  \code{\link{plotIntronicMappingRate}},
  \code{\link{plotMappedReads}},
  \code{\link{plotMappingRate}},
  \code{\link{plotRRNAMappingRate}},
  \code{\link{plotTotalReads}}
}
\author{
Michael Steinbaugh, Rory Kirchner, Victor Barrera
}
\concept{Quality Control Plots}
