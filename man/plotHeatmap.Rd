% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AllGenerics.R, R/methods-plotHeatmap.R
\docType{methods}
\name{plotHeatmap}
\alias{plotHeatmap}
\alias{plotHeatmap,bcbioRNASeq-method}
\alias{plotHeatmap,DESeqDataSet-method}
\alias{plotHeatmap,DESeqTransform-method}
\alias{plotHeatmap,matrix-method}
\title{Heatmap}
\usage{
plotHeatmap(object, ...)

\S4method{plotHeatmap}{bcbioRNASeq}(object, genes = NULL, title = NULL,
  color = inferno(256), legendColor = viridis, quiet = FALSE, ...)

\S4method{plotHeatmap}{DESeqDataSet}(object, genes = NULL,
  annotationCol = NULL, title = NULL, color = inferno(256),
  legendColor = viridis, quiet = FALSE, ...)

\S4method{plotHeatmap}{DESeqTransform}(object, genes = NULL,
  annotationCol = NULL, title = NULL, color = inferno(256),
  legendColor = viridis, quiet = FALSE, ...)

\S4method{plotHeatmap}{matrix}(object, genes = NULL, annotationCol = NULL,
  title = NULL, color = inferno(256), legendColor = viridis,
  quiet = FALSE, ...)
}
\arguments{
\item{object}{Object.}

\item{...}{Passthrough arguments to \code{\link[pheatmap:pheatmap]{pheatmap::pheatmap()}}.}

\item{genes}{Character vector of specific gene identifiers to plot.}

\item{title}{\emph{Optional}. Plot title.}

\item{color}{Colors to use for plot. Defaults to \code{\link[=inferno]{inferno()}} palette.}

\item{legendColor}{Colors to use for legend labels. Defaults to \code{\link[=viridis]{viridis()}}
palette.}

\item{quiet}{If \code{TRUE}, suppress any status messages and/or progress bars.}

\item{annotationCol}{\link{data.frame} that specifies the annotations shown on the
right side of the heatmap. Each row of this \link{data.frame} defines the
features of the heatmap columns.}
}
\value{
Graphical output only.
}
\description{
These functions facilitate heatmap plotting of a specified set of genes. By
default, row- and column-wise hierarchical clustering is performed using the
Ward method, but this behavior can be overrided by setting \code{cluster_rows} or
\code{cluster_cols} to \code{FALSE}. When column clustering is disabled, the columns
are sorted by the interesting groups (\code{interestingGroups}) specified in the
\link{bcbioRNASeq} and then the sample names.
}
\examples{
# Genes as Ensembl identifiers
genes <- counts(bcb)[1:20, ] \%>\% rownames()
plotHeatmap(bcb, genes = genes)

# Flip the plot and legend palettes
plotHeatmap(
    bcb,
    genes = genes,
    color = viridis(256),
    legendColor = inferno)

# Transcriptome heatmap
\dontrun{
plotHeatmap(bcb)
}

# Use default pheatmap color palette
\dontrun{
plotHeatmap(
    bcb,
    color = NULL,
    legendColor = NULL)
}

# DESeqDataSet
\dontrun{
plotHeatmap(dds)
}

# DESeqTransform
\dontrun{
plotHeatmap(rld)
}
}
\seealso{
\code{\link[pheatmap:pheatmap]{pheatmap::pheatmap()}}.

Other Heatmaps: \code{\link{plotCorrelationHeatmap}},
  \code{\link{plotDEGHeatmap}}
}
\author{
Michael Steinbaugh
}
\concept{Heatmaps}
