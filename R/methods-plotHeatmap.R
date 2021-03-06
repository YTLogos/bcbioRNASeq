#' Heatmap
#'
#' These functions facilitate heatmap plotting of a specified set of genes. By
#' default, row- and column-wise hierarchical clustering is performed using the
#' Ward method, but this behavior can be overrided by setting `cluster_rows` or
#' `cluster_cols` to `FALSE`. When column clustering is disabled, the columns
#' are sorted by the interesting groups (`interestingGroups`) specified in the
#' [bcbioRNASeq] and then the sample names.
#'
#' @rdname plotHeatmap
#' @name plotHeatmap
#' @family Heatmaps
#' @author Michael Steinbaugh
#'
#' @inheritParams AllGenerics
#' @inheritParams basejump::gene2symbol
#'
#' @param genes Character vector of specific gene identifiers to plot.
#' @param annotationCol [data.frame] that specifies the annotations shown on the
#'   right side of the heatmap. Each row of this [data.frame] defines the
#'   features of the heatmap columns.
#' @param color Colors to use for plot. Defaults to [inferno()] palette.
#' @param legendColor Colors to use for legend labels. Defaults to [viridis()]
#'   palette.
#' @param title *Optional*. Plot title.
#' @param ... Passthrough arguments to [pheatmap::pheatmap()].
#'
#' @seealso [pheatmap::pheatmap()].
#'
#' @return Graphical output only.
#'
#' @examples
#' # Genes as Ensembl identifiers
#' genes <- counts(bcb)[1:20, ] %>% rownames()
#' plotHeatmap(bcb, genes = genes)
#'
#' # Flip the plot and legend palettes
#' plotHeatmap(
#'     bcb,
#'     genes = genes,
#'     color = viridis(256),
#'     legendColor = inferno)
#'
#' # Transcriptome heatmap
#' \dontrun{
#' plotHeatmap(bcb)
#' }
#'
#' # Use default pheatmap color palette
#' \dontrun{
#' plotHeatmap(
#'     bcb,
#'     color = NULL,
#'     legendColor = NULL)
#' }
#'
#' # DESeqDataSet
#' \dontrun{
#' plotHeatmap(dds)
#' }
#'
#' # DESeqTransform
#' \dontrun{
#' plotHeatmap(rld)
#' }
NULL



# Constructors ====
#' @importFrom dplyr mutate_all
#' @importFrom pheatmap pheatmap
#' @importFrom stats setNames
#' @importFrom tibble column_to_rownames rownames_to_column
#' @importFrom viridis inferno viridis
.plotHeatmap <- function(
    counts,
    genes = NULL,
    annotationCol = NULL,
    title = NULL,
    color = inferno(256),
    legendColor = viridis,
    quiet = FALSE,
    scale = "row",
    ...) {
    counts <- as.matrix(counts)

    # Check for identifier mismatch. Do this before zero count subsetting.
    if (!is.null(genes)) {
        if (!all(genes %in% rownames(counts))) {
            stop(paste(
                "Genes missing from counts matrix:",
                toString(setdiff(genes, rownames(counts)))),
                call. = FALSE)
        }
        counts <- counts %>%
            .[rownames(.) %in% genes, , drop = FALSE]
    }

    # Subset zero counts
    counts <- counts %>%
        .[rowSums(.) > 0, , drop = FALSE]
    if (!is.matrix(counts) |
        nrow(counts) < 2) {
        stop("Need at least 2 genes to cluster", call. = FALSE)
    }

    # Convert Ensembl gene identifiers to symbol names, if necessary
    if (nrow(counts) <= 100) {
        showRownames <- TRUE
    } else {
        showRownames <- FALSE
    }
    if (isTRUE(showRownames)) {
        counts <- gene2symbol(counts, quiet = quiet)
    }

    # Prepare the annotation columns
    if (!is.null(annotationCol)) {
        annotationCol <- annotationCol %>%
            as.data.frame() %>%
            # Coerce annotation columns to factors
            rownames_to_column() %>%
            mutate_all(factor) %>%
            column_to_rownames()
    }

    # Define colors for each annotation column, if desired
    if (!is.null(annotationCol) & !is.null(legendColor)) {
        annotationColors <- lapply(
            seq_along(colnames(annotationCol)), function(a) {
                col <- annotationCol[[a]] %>%
                    levels()
                colors <- annotationCol[[a]] %>%
                    levels() %>%
                    length() %>%
                    legendColor
                names(colors) <- col
                colors
            }) %>%
            setNames(colnames(annotationCol))
    } else {
        annotationColors <- NULL
    }

    # pheatmap will error if `NULL` title is passed as `main`
    if (is.null(title)) {
        title <- ""
    }

    # If `color = NULL`, use the pheatmap default
    if (is.null(color)) {
        color <- colorRampPalette(rev(brewer.pal(n = 7, name = "RdYlBu")))(100)
    }

    pheatmap(
        counts,
        annotation_col = annotationCol,
        annotation_colors = annotationColors,
        border_color = NA,
        color = color,
        main = title,
        scale = scale,
        show_rownames = showRownames,
        ...)
}



# Methods ====
#' @rdname plotHeatmap
#' @importFrom S4Vectors metadata
#' @export
setMethod(
    "plotHeatmap",
    signature("bcbioRNASeq"),
    function(
        object,
        genes = NULL,
        title = NULL,
        color = inferno(256),
        legendColor = viridis,
        quiet = FALSE,
        ...) {
        counts <- counts(object, normalized = "rlog")
        interestingGroups <- interestingGroups(object)
        annotationCol <- colData(object) %>%
            .[, interestingGroups, drop = FALSE]
        .plotHeatmap(
            counts = counts,
            annotationCol = annotationCol,
            # User-defined
            genes = genes,
            title = title,
            color = color,
            legendColor = legendColor,
            quiet = quiet,
            ...)
    })



#' @rdname plotHeatmap
#' @export
setMethod(
    "plotHeatmap",
    signature("DESeqDataSet"),
    function(
        object,
        genes = NULL,
        annotationCol = NULL,
        title = NULL,
        color = inferno(256),
        legendColor = viridis,
        quiet = FALSE,
        ...) {
        counts <- counts(object, normalized = TRUE)
        .plotHeatmap(
            counts = counts,
            # User-defined
            genes = genes,
            annotationCol = annotationCol,
            title = title,
            color = color,
            legendColor = legendColor,
            quiet = quiet,
            ...)
    })



#' @rdname plotHeatmap
#' @export
setMethod(
    "plotHeatmap",
    signature("DESeqTransform"),
    function(
        object,
        genes = NULL,
        annotationCol = NULL,
        title = NULL,
        color = inferno(256),
        legendColor = viridis,
        quiet = FALSE,
        ...) {
        counts <- assay(object)
        .plotHeatmap(
            counts = counts,
            # User-defined
            genes = genes,
            annotationCol = annotationCol,
            title = title,
            color = color,
            legendColor = legendColor,
            quiet = quiet,
            ...)
    })



#' @rdname plotHeatmap
#' @export
setMethod(
    "plotHeatmap",
    signature("matrix"),
    function(
        object,
        genes = NULL,
        annotationCol = NULL,
        title = NULL,
        color = inferno(256),
        legendColor = viridis,
        quiet = FALSE,
        ...) {
        .plotHeatmap(
            counts = object,
            # User-defined
            genes = genes,
            annotationCol = annotationCol,
            title = title,
            color = color,
            legendColor = legendColor,
            quiet = quiet,
            ...)
    })
