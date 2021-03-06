#' Aggregate Lane-Split Technical Replicates
#'
#' Frequently RNA-seq experiments are performed with technical replicates
#' split across flow cell lanes. This generic facilitates quick aggregation
#' of counts across the flow cells.
#'
#' @rdname aggregateReplicates
#' @name aggregateReplicates
#'
#' @importFrom basejump aggregateReplicates
#'
#' @inheritParams AllGenerics
#'
#' @param pattern Grep pattern to match lane identifiers in sample name.
#'
#' @return Object of same class, with pooled technical replicates.
#'
#' @examples
#' # matrix
#' \dontrun{
#' aggregateReplicates(assay(bcb))
#' }
#'
#' # DESeqDataSet
#' \dontrun{
#' aggregateReplicates(dds)
#' }
NULL



# Constructors ====
#' @importFrom stats setNames
.aggregateReplicatesMatrix <- function(
    object,
    pattern = "_L\\d+") {
    # Obtain the unique pooled sample names
    if (!all(grepl(pattern, colnames(object)))) {
        stop("Lane pattern didn't match all samples")
    }
    stem <- gsub(x = colnames(object),
                 pattern = pattern,
                 replacement = "") %>%
        unique() %>%
        sort()
    # Perform [rowSums()] on the matching columns per sample
    lapply(seq_along(stem), function(a) {
        object %>%
            .[, grepl(paste0("^", stem[a], pattern), colnames(.))] %>%
            rowSums()
    }) %>%
        setNames(stem) %>%
        do.call(cbind, .) %>%
        # [round()] here otherwise [DESeq()] will fail on this matrix
        round()
}



#' @importFrom BiocGenerics design
#' @importFrom DESeq2 DESeq DESeqDataSetFromMatrix
#' @importFrom dplyr distinct mutate
#' @importFrom magrittr set_rownames
.aggregateReplicatesDESeqDataSet <- function(
    object,
    pattern = "_L\\d+") {
    # Get the stored design formula
    design <- design(object)

    # Pool the lane split technical replicates
    message("Aggregating raw counts slotted in DESeqDataSet")
    countData <- counts(object, normalized = FALSE) %>%
        aggregateReplicates()

    # Mutate the colData metadata to pooled samples
    colData <- colData(object) %>%
        as.data.frame() %>%
        mutate(
            sampleID = gsub(
                x = .data[["sampleID"]],
                pattern = pattern,
                replacement = ""),
            sampleName = gsub(
                x = .data[["sampleName"]],
                pattern = pattern,
                replacement = ""),
            lane = NULL,
            sizeFactor = NULL
        ) %>%
        distinct() %>%
        set_rownames(.[["sampleID"]])

    # Check that the new colData matches the counts matrix
    if (!identical(colData[["sampleName"]], colnames(countData))) {
        stop("Sample name mismatch in colData and countData")
    }

    # Replace sample names in pooled count matrix with description
    colnames(countData) <- colData[["description"]]
    if (!identical(rownames(colData), colnames(countData))) {
        stop("Description mismatch in colData and countData")
    }

    message("Reloading DESeqDataSet using DESeqDataSetFromMatrix")
    DESeqDataSetFromMatrix(
        countData = countData,
        colData = colData,
        design = design) %>%
        DESeq()
}



# Methods ====
#' @rdname aggregateReplicates
#' @export
setMethod(
    "aggregateReplicates",
    signature("matrix"),
    .aggregateReplicatesMatrix)



#' @rdname aggregateReplicates
#' @note [DESeqDataSet] is returned using [DESeqDataSetFromMatrix()].
#' @export
setMethod(
    "aggregateReplicates",
    signature("DESeqDataSet"),
    .aggregateReplicatesDESeqDataSet)
