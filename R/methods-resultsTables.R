#' Differential Expression Results Tables
#'
#' @rdname resultsTables
#' @name resultsTables
#' @author Michael Steinbaugh
#'
#' @inheritParams AllGenerics
#' @inheritParams basejump::annotable
#'
#' @param lfc Log fold change ratio (base 2) cutoff. Does not apply to
#'   statistical hypothesis testing, only gene filtering in the results tables.
#'   See [results()] for additional information about using `lfcThreshold` and
#'   `altHypothesis` to set an alternative hypothesis based on expected fold
#'   changes.
#' @param summary Show summary statistics as a Markdown list.
#' @param headerLevel Markdown header level.
#' @param write Write CSV files to disk.
#' @param dir Directory path where to write files.
#' @param organism *Optional*. Override automatic genome detection. By
#'   default the function matches the genome annotations based on the first
#'   Ensembl gene identifier row in the object. If a custom FASTA spike-in
#'   is provided, then this may need to be manually set.
#'
#' @return Results list.
#'
#' @examples
#' data(res)
#' resTbl <- resultsTables(res, lfc = 0.25, write = FALSE)
#' class(resTbl)
#' names(resTbl)
NULL



# Constructors ====
#' Markdown List of Results Files
#'
#' Enables looping of results contrast file links for RMarkdown.
#'
#' @author Michael Steinbaugh
#' @keywords internal
#'
#' @param resTbl List of results tables generated by [resultsTables()].
#' @param dir Output directory.
#'
#' @return [writeLines()].
#' @noRd
.mdResultsTables <- function(resTbl, dir) {
    if (!dir.exists(dir)) {
        stop("DE results directory missing", call. = FALSE)
    }
    all <- resTbl[["allFile"]]
    deg <- resTbl[["degFile"]]
    degLFCUp <- resTbl[["degLFCUpFile"]]
    degLFCDown <- resTbl[["degLFCDownFile"]]
    mdList(c(
        paste0("[`", all, "`](", file.path(dir, all), "): ",
               "All genes, sorted by Ensembl identifier."),
        paste0("[`", deg, "`](", file.path(dir, deg), "): ",
               "Genes that pass the alpha (FDR) cutoff."),
        paste0("[`", degLFCUp, "`](", file.path(dir, degLFCUp), "): ",
               "Upregulated DEG; positive log2 fold change."),
        paste0("[`", degLFCDown, "`](", file.path(dir, degLFCDown), "): ",
               "Downregulated DEG; negative log2 fold change.")
    ))
}



#' @importFrom basejump annotable camel snake
#' @importFrom dplyr arrange desc left_join
#' @importFrom readr write_csv
#' @importFrom rlang !! sym
#' @importFrom S4Vectors metadata
#' @importFrom tibble rownames_to_column
.resultsTablesDESeqResults <- function(
    object,
    lfc = 0,
    write = TRUE,
    summary = TRUE,
    headerLevel = 3,
    dir = file.path("results", "differential_expression"),
    organism = NULL,
    quiet = FALSE) {
    contrast <- .resContrastName(object)
    fileStem <- snake(contrast)

    # Alpha level, from [DESeqResults]
    alpha <- metadata(object)[["alpha"]]

    # Match genome against the first gene identifier by default
    if (is.null(organism)) {
        organism <- rownames(object)[[1]] %>%
            detectOrganism()
    }
    anno <- annotable(organism, quiet = quiet)

    all <- object %>%
        as.data.frame() %>%
        rownames_to_column("ensgene") %>%
        as("tibble") %>%
        camel(strict = FALSE) %>%
        left_join(anno, by = "ensgene") %>%
        arrange(!!sym("ensgene"))

    # Check for overall gene expression with base mean
    baseMeanGt0 <- all %>%
        arrange(desc(!!sym("baseMean"))) %>%
        .[.[["baseMean"]] > 0, ]
    baseMeanGt1 <- baseMeanGt0 %>%
        .[.[["baseMean"]] > 1, ]

    # All DEG tables are sorted by BH adjusted P value
    deg <- all %>%
        .[!is.na(.[["padj"]]), ] %>%
        .[.[["padj"]] < alpha, ] %>%
        arrange(!!sym("padj"))
    degLFC <- deg %>%
        .[.[["log2FoldChange"]] > lfc |
              .[["log2FoldChange"]] < -lfc, ]
    degLFCUp <- degLFC %>%
        .[.[["log2FoldChange"]] > 0, ]
    degLFCDown <- degLFC %>%
        .[.[["log2FoldChange"]] < 0, ]

    # File paths
    allFile <- paste(fileStem, "all.csv.gz", sep = "_")
    degFile <- paste(fileStem, "deg.csv.gz", sep = "_")
    degLFCUpFile <- paste(fileStem, "deg_lfc_up.csv.gz", sep = "_")
    degLFCDownFile <- paste(fileStem, "deg_lfc_down.csv.gz", sep = "_")

    resTbl <- list(
        contrast = contrast,
        # Cutoffs
        alpha = alpha,
        lfc = lfc,
        # Tibbles
        all = all,
        deg = deg,
        degLFC = degLFC,
        degLFCUp = degLFCUp,
        degLFCDown = degLFCDown,
        # File paths
        allFile = allFile,
        degFile = degFile,
        degLFCUpFile = degLFCUpFile,
        degLFCDownFile = degLFCDownFile)

    if (isTRUE(write)) {
        # Write the CSV files
        dir.create(dir, recursive = TRUE, showWarnings = FALSE)

        write_csv(all, file.path(dir, allFile))
        write_csv(deg, file.path(dir, degFile))
        write_csv(degLFCUp, file.path(dir, degLFCUpFile))
        write_csv(degLFCDown, file.path(dir, degLFCDownFile))

        # Output file information in Markdown format
        .mdResultsTables(resTbl, dir)
    }

    if (isTRUE(summary)) {
        if (!is.null(headerLevel)) {
            mdHeader(
                "Summary statistics",
                level = headerLevel,
                asis = TRUE)
        }
        mdList(
            c(paste(nrow(all), "genes in count matrix"),
              paste("base mean > 0:", nrow(baseMeanGt0), "genes (non-zero)"),
              paste("base mean > 1:", nrow(baseMeanGt1), "genes"),
              paste("alpha cutoff:", alpha),
              paste("lfc cutoff:", lfc, "(applied in tables only)"),
              paste("deg pass alpha:", nrow(deg), "genes"),
              paste("deg lfc up:", nrow(degLFCUp), "genes"),
              paste("deg lfc down:", nrow(degLFCDown), "genes")),
            asis = TRUE)
    }

    resTbl
}



# Methods ====
#' @rdname resultsTables
#' @export
setMethod(
    "resultsTables",
    signature("DESeqResults"),
    .resultsTablesDESeqResults)
