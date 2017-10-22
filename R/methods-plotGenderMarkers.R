#' Plot Sexually Dimorphic Gender Markers
#'
#' @rdname plotGenderMarkers
#' @name plotGenderMarkers
#' @family Quality Control Plots
#' @author Michael Steinbaugh
#'
#' @inheritParams AllGenerics
#' @param organism *Optional*. Organism name. Should be detected automatically,
#'   unless a spike-in FASTA sequence is provided containing a gene identifier
#'   that is first alphabetically in the count matrix rownames.
#' @param ylab Y-axis label.
#'
#' @return [ggplot].
#'
#' @examples
#' data(bcb)
#' plotGenderMarkers(bcb)
NULL



# Constructors ====
#' @importFrom dplyr left_join pull
#' @importFrom ggplot2 aes_string expand_limits geom_jitter ggplot labs
#' @importFrom stats setNames
#' @importFrom viridis scale_color_viridis
.plotGenderMarkers <- function(
    object,
    organism,
    ylab = "counts") {
    counts <- object

    # Load the relevant internal gender markers data
    envir <- loadNamespace("bcbioRNASeq")
    if (organism == "Mus musculus") {
        markers <- get("genderMarkersMmusculus", envir = envir)
    } else if (organism == "Homo sapiens") {
        stop("Human marker support coming in future update", call. = FALSE)
    } else {
        stop("Unsupported organism", call. = FALSE)
    }

    # Ensembl identifiers
    ensgene <- markers %>%
        .[.[["include"]] == TRUE, , drop = FALSE] %>%
        pull("ensgene") %>%
        sort() %>%
        unique()

    if (!all(ensgene %in% rownames(counts))) {
        warning("Missing gender markers in count matrix", call. = FALSE)
        return(NULL)
    }

    counts %>%
        .[ensgene, , drop = FALSE] %>%
        # This will coerce rownames to a column named `rowname`. We will rename
        # this to `ensgene` after melting the counts.
        as("tibble") %>%
        # For `melt()`, can also declare `measure.vars` here instead of using
        # `setNames()`. If you don't set `id`, function will output a message.
        melt(id = 1) %>%
        setNames(c("ensgene", "sampleName", "counts")) %>%
        left_join(markers, by = "ensgene") %>%
        ggplot(
            mapping = aes_string(
                x = "symbol",
                y = "counts",
                color = "sampleName",
                shape = "chromosome")
        ) +
        geom_jitter(size = 4) +
        expand_limits(y = 0) +
        labs(title = "gender markers",
             x = "gene",
             y = ylab) +
        scale_color_viridis(discrete = TRUE)
}



# Methods ====
#' @rdname plotGenderMarkers
#' @export
setMethod(
    "plotGenderMarkers",
    signature("bcbioRNASeqANY"),
    function(object) {
        counts <- tpm(object)
        organism <- metadata(object)[["organism"]]
        ylab <- "transcripts per million (tpm)"
        .plotGenderMarkers(counts, organism = organism, ylab = ylab)
    })



#' @rdname plotGenderMarkers
#' @export
setMethod(
    "plotGenderMarkers",
    signature("DESeqDataSet"),
    function(
        object,
        organism = NULL) {
        counts <- counts(object, normalized = TRUE)
        if (is.null(organism)) {
            organism <- rownames(counts) %>%
                .[[1]] %>%
                detectOrganism()
        }
        ylab <- "normalized counts"
        .plotGenderMarkers(counts, organism = organism, ylab = ylab)
    })



#' @rdname plotGenderMarkers
#' @export
setMethod(
    "plotGenderMarkers",
    signature("matrix"),
    .plotGenderMarkers)