#' Top Tables of Differential Expression Results
#'
#' @rdname topTables
#' @name topTables
#' @author Michael Steinbaugh
#'
#' @param object DESeq2 results tables list generated by [resultsTables()].
#' @param n Number genes to report.
#' @param coding Whether to only return coding genes.
#'
#' @return Top table kables, for knit report.
#'
#' @examples
#' resTbl <- resultsTables(res, write = FALSE)
#' topTables(resTbl)
NULL



# Constructors ====
#' @importFrom basejump fixNA
#' @importFrom dplyr filter mutate rename
#' @importFrom S4Vectors head
#' @importFrom tibble remove_rownames
.subsetTop <- function(df, n, coding) {
    if (isTRUE(coding)) {
        df <- df %>%
            .[.[["broadClass"]] == "coding", , drop = FALSE]
    }
    df <- df %>%
        head(n = n) %>%
        rename(lfc = .data[["log2FoldChange"]]) %>%
        mutate(
            baseMean = round(.data[["baseMean"]]),
            lfc = format(.data[["lfc"]], digits = 3),
            padj = format(.data[["padj"]], digits = 3, scientific = TRUE),
            # Remove symbol information in description, if present
            description = gsub(
                x = .data[["description"]],
                pattern = " \\[.+\\]$",
                replacement = "")
        ) %>%
        .[, c("ensgene",
              "baseMean",
              "lfc",
              "padj",
              "symbol",
              "description")] %>%
        remove_rownames() %>%
        fixNA()
}



# Methods ====
#' @rdname topTables
#' @importFrom knitr kable
#' @export
setMethod(
    "topTables",
    signature("list"),
    function(
        object,
        n = 50,
        coding = FALSE) {
        up <- .subsetTop(object[["degLFCUp"]], n = n, coding = coding)
        down <- .subsetTop(object[["degLFCDown"]], n = n, coding = coding)
        contrastName <- object[["contrast"]]
        show(kable(
            up,
            caption = paste(contrastName, "(upregulated)")
        ))
        show(kable(
            down,
            caption = paste(contrastName, "(downregulated)")
        ))
    })
