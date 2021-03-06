#' Print Summary Statistics of Alpha Level Cutoffs
#'
#' @note [bcbioRNASeq] does not support contrast definitions, since the
#'   object contains an internal [DESeqDataSet] with an empty design formula.
#'
#' @rdname alphaSummary
#' @name alphaSummary
#' @family Differential Expression Utilities
#' @author Michael Steinbaugh, Lorena Patano
#'
#' @inheritParams AllGenerics
#' @inheritParams DESeq2::results
#'
#' @param alpha Numeric vector of desired alpha cutoffs.
#' @param caption *Optional*. Character vector to add as caption to the table.
#' @param ... *Optional*. Passthrough arguments to [DESeq2::results()]. Use
#'   either `contrast` or `name` arguments to define the desired contrast.
#'
#' @return [kable].
#'
#' @seealso [DESeq2::results()].
#'
#' @examples
#' # bcbioRNASeq
#' alphaSummary(bcb)
#'
#' # DESeqDataSet
#' alphaSummary(dds)
#' \dontrun{
#' alphaSummary(dds, contrast = c("group", "ko", "ctrl"))
#' alphaSummary(dds, name = "group_ko_vs_ctrl")
#' }
NULL



# Constructors ====
#' @importFrom DESeq2 results
#' @importFrom dplyr bind_cols
#' @importFrom knitr kable
#' @importFrom magrittr set_colnames set_rownames
#' @importFrom utils capture.output
.alphaSummary <- function(
    dds,
    alpha = c(0.1, 0.05, 0.01, 1e-3, 1e-6),
    caption = NULL,
    ...) {
    dots <- list(...)
    if (is.null(caption)) {
        if (!is.null(dots[["contrast"]])) {
            caption <- dots[["contrast"]] %>%
                paste(collapse = " ")
        } else if (!is.null(dots[["name"]])) {
            caption <- dots[["name"]]
        }
    }
    lapply(seq_along(alpha), function(a) {
        info <- capture.output(
            summary(results(dds, ..., alpha = alpha[a]))
        ) %>%
            # Get the lines of interest from summary
            .[4:8]
        parse <- info[1:5] %>%
            # Extract the values after the colon in summary
            vapply(function(a) {
                gsub("^.+\\:\\s(.+)\\s$", "\\1", a)
            }, FUN.VALUE = "character") %>%
            # Coerce to character here to remove names
            as.character()
        data.frame(alpha = parse)
    }) %>%
        bind_cols() %>%
        set_colnames(alpha) %>%
        set_rownames(c("LFC > 0 (up)",
                       "LFC < 0 (down)",
                       "outliers",
                       "low counts",
                       "cutoff")) %>%
        kable(caption = caption)
}



# Methods ====
#' @rdname alphaSummary
#' @importFrom BiocGenerics design
#' @importFrom stats formula
#' @export
setMethod(
    "alphaSummary",
    signature("bcbioRNASeq"),
    function(
        object,
        alpha = c(0.1, 0.05, 0.01, 1e-3, 1e-6),
        caption = NULL,
        ...) {
        dds <- bcbio(object, "DESeqDataSet")
        # Warn if empty design formula detected
        if (design(dds) == formula(~1)) {
            warning("Empty DESeqDataSet design formula detected",
                    call. = FALSE)
        }
        .alphaSummary(
            dds = dds,
            alpha = alpha,
            caption = caption,
            ...)
    })



#' @rdname alphaSummary
#' @export
setMethod(
    "alphaSummary",
    signature("DESeqDataSet"),
    function(
        object,
        alpha = c(0.1, 0.05, 0.01, 1e-3, 1e-6),
        caption = NULL,
        ...) {
        .alphaSummary(
            dds = object,
            alpha = alpha,
            caption = caption,
            ...)
    })
