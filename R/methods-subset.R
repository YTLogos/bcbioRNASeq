#' Bracket-Based Subsetting
#'
#' Extract genes by row and samples by column from a [bcbioRNASeq] object. The
#' internal [DESeqDataSet] and count transformations are rescaled automatically.
#'
#' @rdname subset
#' @name subset
#'
#' @author Lorena Pantano, Michael Steinbaugh
#'
#' @inheritParams base::`[`
#' @param ... Additional arguments.
#'
#' @return [bcbioRNASeq].
#'
#' @seealso `help("[", "base")`.
#'
#' @examples
#' data(bcb)
#' genes <- 1:50
#' samples <- c("group1_1", "group1_2")
#'
#' # Subset by sample name
#' bcb[, samples]
#'
#' # Subset by gene list
#' bcb[genes, ]
#'
#' # Subset by both genes and samples
#' \dontrun{
#' bcb[genes, samples]
#' }
#'
#' # Skip normalization
#' \dontrun{
#' bcb[genes, samples, skipNorm = TRUE]
#' }
NULL



# Constructors ====
#' Create DDS
#'
#' This operation must be placed outside of the S4 method dispatch. Otherwise,
#' the resulting subset object will be ~2X the expected size on disk when
#' saving, for an unknown reason.
#'
#' @noRd
#'
#' @importFrom DESeq2 DESeqDataSetFromTximport
#' @importFrom stats formula
.createDDS <- function(txi, tmpData) {
    DESeqDataSetFromTximport(
        txi = txi,
        colData = tmpData,
        design = formula(~1))
}



#' @importFrom DESeq2 DESeqTransform
.countSubset <- function(x, tmpData) {
    DESeqTransform(
        SummarizedExperiment(
            assays = x,
            colData = tmpData))
}



#' @importFrom DESeq2 DESeq estimateSizeFactors rlog
#'   varianceStabilizingTransformation
#' @importFrom S4Vectors metadata SimpleList
.subset <- function(x, i, j, ..., drop = FALSE) {
    if (missing(i)) {
        i <- 1:nrow(x)
    }
    if (missing(j)) {
        j <- 1:ncol(x)
    }
    dots <- list(...)
    if (is.null(dots[["maxSamples"]])) {
        maxSamples <- 50
    } else {
        maxSamples <- dots[["maxSamples"]]
    }

    if (is.null(dots[["skipNorm"]])) {
        skipNorm <- FALSE
    } else {
        skipNorm <- dots[["skipNorm"]]
    }

    # Subset SE object ====
    se <- SummarizedExperiment(
        assays = SimpleList(counts(x)),
        rowData = rowData(x),
        colData = colData(x),
        metadata = metadata(x))

    tmp <- se[i, j, drop = drop]
    tmpGenes <- row.names(tmp)
    tmpRow <- rowData(tmp) %>%
        as.data.frame()
    tmpData <- colData(tmp) %>%
        as.data.frame()
    tmpTxi <- bcbio(x, "tximport")

    # Subset tximport data ====
    txi <- SimpleList(
        abundance = tmpTxi[["abundance"]] %>%
            .[tmpGenes, tmpData[["sampleID"]]],
        counts = tmpTxi[["counts"]] %>%
            .[tmpGenes, tmpData[["sampleID"]]],
        length = tmpTxi[["length"]] %>%
            .[tmpGenes, tmpData[["sampleID"]]],
        countsFromAbundance = tmpTxi[["countsFromAbundance"]]
    )
    rawCounts <- txi[["counts"]]
    tmm <- .tmm(rawCounts)
    tpm <- txi[["abundance"]]

    if (skipNorm) {
        message("Skip re-normalization, just selecting samples and genes")
        # To Fix if we find the solution.
        # Only way to avoid disk space issue.
        # Direct subset of dds create a huge file.
        dds <- .createDDS(txi, tmpData) %>%
            estimateSizeFactors()
        vst <- .countSubset(counts(x, "vst")[i, j], tmpData)
        rlog <- .countSubset(counts(x, "rlog")[i, j], tmpData)
        normalizedCounts <- counts(x, "normalized")[i, j]
    } else {
        # Fix for unexpected disk space issue (see constructor above)
        dds <- .createDDS(txi, tmpData)
        # DESeq2 will warn about empty design formula
        dds <- suppressWarnings(DESeq(dds))
        normalizedCounts <- counts(dds, normalized = TRUE)
    }

    # rlog & variance ====
    if (nrow(tmpData) > maxSamples & !skipNorm) {
        message("Many samples detected...skipping count transformations")
        rlog <- .countSubset(log2(tmm + 1), tmpData)
        vst <- .countSubset(log2(tmm + 1), tmpData)
    } else if (!skipNorm) {
        message("Performing rlog transformation")
        rlog <- rlog(dds)
        message("Performing variance stabilizing transformation")
        vst <- varianceStabilizingTransformation(dds)
    }

    if (is.matrix(bcbio(x, "featureCounts"))) {
        tmpFC <- bcbio(x, "featureCounts") %>%
            .[tmpGenes, tmpData[["sampleID"]], drop = FALSE]
    } else {
        tmpFC <- bcbio(x, "featureCounts")
    }

    # Subset Metrics ====
    tmpMetadata <- metadata(x)
    tmpMetrics <- tmpMetadata[["metrics"]] %>%
        .[.[["sampleID"]] %in% tmpData[["sampleID"]], , drop = FALSE]
    tmpMetadata[["metrics"]] <- tmpMetrics

    tmpAssays <- SimpleList(
        raw = rawCounts,
        normalized = normalizedCounts,
        tpm = tpm,
        tmm = tmm,
        rlog = rlog,
        vst = vst)

    # Slot additional data
    bcbio <- SimpleList(
        tximport = txi,
        DESeqDataSet = dds,
        featureCounts = tmpFC)

    # bcbioRNASeq ====
    new("bcbioRNASeq",
        SummarizedExperiment(
            assays = tmpAssays,
            colData = tmpData,
            rowData = tmpRow,
            metadata = tmpMetadata),
        bcbio = bcbio)
}



# Methods ====
#' @rdname subset
#' @export
setMethod(
    "[",
    signature(x = "bcbioRNASeq",
              i = "ANY",
              j = "ANY"),
    function(x, i, j, ..., drop = FALSE) {
        .subset(x, i, j, ..., drop)
    })
