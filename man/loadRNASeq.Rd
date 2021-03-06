% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/loadRNASeq.R
\name{loadRNASeq}
\alias{loadRNASeq}
\title{Load bcbio RNA-Seq Data}
\usage{
loadRNASeq(uploadDir, interestingGroups = "sampleName",
  sampleMetadataFile = NULL, maxSamples = 50, annotable,
  ensemblVersion = NULL, ...)
}
\arguments{
\item{uploadDir}{Path to final upload directory. This path is set when
running \code{bcbio_nextgen -w template}.}

\item{interestingGroups}{Character vector of interesting groups. First entry
is used for plot colors during quality control (QC) analysis. Entire vector
is used for PCA and heatmap QC functions.}

\item{sampleMetadataFile}{\emph{Optional}. Custom metadata file containing
sample information. Otherwise defaults to sample metadata saved in the YAML
file.}

\item{maxSamples}{Maximum number of samples to calculate \code{\link[DESeq2:rlog]{DESeq2::rlog()}} and
\code{\link[DESeq2:varianceStabilizingTransformation]{DESeq2::varianceStabilizingTransformation()}} matrix. See Details.}

\item{annotable}{\emph{Optional}. User-defined gene annotations (a.k.a.
"annotable"), which will be slotted into \code{\link[=rowData]{rowData()}}. Typically this should
be left undefined. By default, the function will automatically generate an
annotable from the annotations available on Ensembl. If set \code{NULL}, then
\code{\link[=rowData]{rowData()}} inside the resulting \link{bcbioRNASeq} object will be left empty.
This is recommended for projects dealing with genes or transcripts that are
poorly annotated.}

\item{ensemblVersion}{\emph{Optional}. Ensembl release version. If \code{NULL},
defaults to current release, and does not typically need to be
user-defined. This parameter can be useful for matching Ensembl annotations
against an outdated bcbio annotation build.}

\item{...}{Additional arguments, slotted into the \code{\link[=metadata]{metadata()}} accessor.}
}
\value{
\link{bcbioRNASeq}.
}
\description{
Simply point to the final upload directory output by
\href{https://bcbio-nextgen.readthedocs.io/}{bcbio}, and this function will take
care of the rest. It automatically imports RNA-seq counts, metadata, and
program versions used.
}
\details{
When number of samples is bigger than \code{maxSamples}, \code{rlog} and \code{vst} slot
in \link[SummarizedExperiment:SummarizedExperiment]{SummarizedExperiment::SummarizedExperiment} will be the output of
\link{edgeR} normalization method.
}
\note{
When working in RStudio, we recommend connecting to the bcbio-nextgen
run directory as a remote connection over
\href{https://github.com/osxfuse/osxfuse/wiki/SSHFS}{sshfs}.
}
\examples{
uploadDir <- system.file("extdata/bcbio", package = "bcbioRNASeq")
bcb <- loadRNASeq(uploadDir, interestingGroups = "group")

# Load without gene annotations
bcb <- loadRNASeq(uploadDir, annotable = NULL)
}
\author{
Michael Steinbaugh, Lorena Pantano
}
