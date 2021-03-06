% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AllGenerics.R, R/methods-plotPCACovariates.R
\docType{methods}
\name{plotPCACovariates}
\alias{plotPCACovariates}
\alias{plotPCACovariates,bcbioRNASeq-method}
\title{Find Correlation Between Principal Components (PCs) and Covariates}
\usage{
plotPCACovariates(object, ...)

\S4method{plotPCACovariates}{bcbioRNASeq}(object, metrics = TRUE,
  transform = "rlog", ...)
}
\arguments{
\item{object}{Object.}

\item{...}{Additional arguments, passed to \code{\link[DEGreport:degCovariates]{DEGreport::degCovariates()}}.}

\item{metrics}{Include sample summary metrics as covariates. Defaults to
include all metrics columns (\code{TRUE}), but desired columns can be specified
here as a character vector.}

\item{transform}{String specifying \link{DESeqTransform} slotted inside the
\link{bcbioRNASeq} object:
\itemize{
\item \code{rlog} (\strong{recommended}).
\item \code{vst}: variance stabilizing transformation.
}}
}
\value{
\link{ggplot}.
}
\description{
\code{\link[DEGreport:degCovariates]{DEGreport::degCovariates()}} wrapper supporting a \link{bcbioRNASeq} object.
}
\examples{
plotPCACovariates(bcb, metrics = TRUE)
plotPCACovariates(bcb, metrics = c("exonicRate", "intronicRate"))
}
\seealso{
\itemize{
\item \code{\link[DEGreport:degCovariates]{DEGreport::degCovariates()}}.
\item \code{\link[DESeq2:rlog]{DESeq2::rlog()}}.
\item \code{\link[DESeq2:varianceStabilizingTransformation]{DESeq2::varianceStabilizingTransformation()}}.
}
}
\author{
Lorena Pantano, Michael Steinbaugh
}
