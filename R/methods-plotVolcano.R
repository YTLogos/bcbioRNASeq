#' Plot Volcano
#'
#' @rdname plotVolcano
#' @name plotVolcano
#' @family Differential Expression Plots
#' @author John Hutchinson, Michael Steinbaugh, Lorena Pantano
#'
#' @inheritParams AllGenerics
#'
#' @param alpha Alpha level cutoff used for coloring.
#' @param padj Use P values adjusted for multiple comparisions.
#' @param lfc Log fold change ratio (base 2) cutoff for coloring.
#' @param genes Character vector of gene symbols to label.
#' @param ntop Number of top genes to label.
#' @param direction Plot `up`, `down`, or `both` (**default**) directions.
#' @param shadeColor Shading color for bounding box.
#' @param shadeAlpha Shading transparency alpha.
#' @param pointColor Point color.
#' @param pointAlpha Point transparency alpha.
#' @param pointOutlineColor Point outline color.
#' @param histograms Show LFC and P value histograms.
#'
#' @seealso This function is an updated variant of
#'   `CHBUtils::volcano_density_plot()`.
#'
#' @return Volcano plot arranged as grid (`grid = TRUE`), or [show()]
#'   individual [ggplot] (`grid = FALSE`).
#'
#' @examples
#' # DESeqResults
#' plotVolcano(res, genes = "Sulf1")
#'
#' \dontrun{
#' # data.frame
#' plotVolcano(as.data.frame(res))
#' }
NULL



# Constructors ====
#' @importFrom basejump annotable camel
#' @importFrom BiocGenerics density
#' @importFrom cowplot draw_plot ggdraw
#' @importFrom dplyr arrange desc left_join mutate
#' @importFrom ggrepel geom_text_repel
#' @importFrom grid arrow unit
#' @importFrom rlang !! sym
#' @importFrom S4Vectors na.omit
#' @importFrom tibble rownames_to_column
.plotVolcano <- function(
    object,
    alpha = 0.01,
    padj = TRUE,
    lfc = 1,
    genes = NULL,
    ntop = 0,
    direction = "both",
    shadeColor = "green",
    shadeAlpha = 0.25,
    pointColor = "gray",
    pointAlpha = 0.75,
    pointOutlineColor = "darkgray",
    histograms = TRUE) {
    if (!any(direction %in% c("both", "down", "up")) |
        length(direction) > 1) {
        stop("Direction must be both, up, or down")
    }

    # Generate stats tibble ====
    stats <- as.data.frame(object) %>%
        rownames_to_column("ensgene") %>%
        camel(strict = FALSE) %>%
        # Keep genes with non-zero counts
        .[.[["baseMean"]] > 0, , drop = FALSE] %>%
        # Keep genes with a fold change
        .[!is.na(.[["log2FoldChange"]]), , drop = FALSE] %>%
        # Keep genes with a P value
        .[!is.na(.[["pvalue"]]), , drop = FALSE] %>%
        # Select columns used for plots
        .[, c("ensgene", "log2FoldChange", "pvalue", "padj")]
    g2s <- detectOrganism(stats[["ensgene"]][[1]]) %>%
        annotable(format = "gene2symbol")
    stats <- left_join(stats, g2s, by = "ensgene")

    # Negative log10 transform the P values
    # Add `1e-10` here to prevent `Inf` values resulting from `log10()`
    if (isTRUE(padj)) {
        stats <- stats %>%
            # Keep genes with an adjusted P value
            .[!is.na(.[["padj"]]), , drop = FALSE] %>%
            # log10 transform
            mutate(negLog10Pvalue = -log10(.data[["padj"]] + 1e-10))
        pTitle <- "adj p value"
    } else {
        stats <- stats %>%
            mutate(negLog10Pvalue = -log10(.data[["pvalue"]] + 1e-10))
        pTitle <- "p value"
    }

    stats <- stats %>%
        # Calculate rank score
        mutate(rankScore = .data[["negLog10Pvalue"]] *
                   abs(.data[["log2FoldChange"]])) %>%
        arrange(desc(!!sym("rankScore")))


    # Text labels ====
    if (!is.null(genes)) {
        volcanoText <- stats %>%
            .[.[["symbol"]] %in% genes, , drop = FALSE]
    } else if (ntop > 0) {
        volcanoText <- stats[1:ntop, , drop = FALSE]
    } else {
        volcanoText <- NULL
    }


    # Plot ranges ====
    # Get range of LFC and P values to set up plot borders
    rangeLFC <-
        c(floor(min(na.omit(stats[["log2FoldChange"]]))),
          ceiling(max(na.omit(stats[["log2FoldChange"]]))))
    rangeNegLog10Pvalue <-
        c(floor(min(na.omit(stats[["negLog10Pvalue"]]))),
          ceiling(max(na.omit(stats[["negLog10Pvalue"]]))))


    # LFC density histogram ====
    lfcDensity <- stats[["log2FoldChange"]] %>%
        na.omit() %>%
        density()
    lfcDensityDf <- data.frame(
        x = lfcDensity[["x"]],
        y = lfcDensity[["y"]])
    lfcHist <- stats %>%
        ggplot(aes_(x = ~log2FoldChange)) +
        geom_density() +
        scale_x_continuous(limits = rangeLFC) +
        labs(x = "log2 fold change",
             y = "") +
        # Don't label density y-axis
        theme(axis.text.y = element_blank(),
              axis.ticks.y = element_blank())
    if (direction == "both" | direction == "up") {
        lfcHist <- lfcHist +
            geom_ribbon(
                data = lfcDensityDf %>%
                    .[.[["x"]] > lfc, ],
                aes_(x = ~x, ymax = ~y),
                ymin = 0,
                fill = shadeColor,
                alpha = shadeAlpha)
    }
    if (direction == "both" | direction == "down") {
        lfcHist <- lfcHist +
            geom_ribbon(
                data = lfcDensityDf %>%
                    .[.[["x"]] < -lfc, ],
                aes_(x = ~x, ymax = ~y),
                ymin = 0,
                fill = shadeColor,
                alpha = shadeAlpha)
    }


    # P value density plot ====
    pvalueDensity <- stats[["negLog10Pvalue"]] %>%
        na.omit() %>%
        density()
    pvalueDensityDf <-
        data.frame(x = pvalueDensity[["x"]],
                   y = pvalueDensity[["y"]])
    pvalueHist <- stats %>%
        ggplot(aes_(x = ~negLog10Pvalue)) +
        geom_density() +
        geom_ribbon(data = pvalueDensityDf %>%
                        .[.[["x"]] > -log10(alpha + 1e-10), ],
                    aes_(x = ~x, ymax = ~y),
                    ymin = 0,
                    fill = shadeColor,
                    alpha = shadeAlpha) +
        labs(x = paste("-log10", pTitle),
             y = "") +
        # Don't label density y-axis
        theme(axis.text.y = element_blank(),
              axis.ticks.y = element_blank())


    # Volcano plot ====
    volcano <- stats %>%
        ggplot(aes_(x = ~log2FoldChange,
                    y = ~negLog10Pvalue)) +
        labs(x = "log2 fold change",
             y = paste("-log10", pTitle)) +
        geom_point(
            alpha = pointAlpha,
            color = pointOutlineColor,
            fill = pointColor,
            pch = 21) +
        theme(legend.position = "none") +
        scale_x_continuous(limits = rangeLFC)
    if (!is.null(volcanoText)) {
        volcano <- volcano +
            geom_text_repel(
                data = volcanoText,
                aes_(x = ~log2FoldChange,
                     y = ~negLog10Pvalue,
                     label = ~symbol),
                arrow = arrow(length = unit(0.01, "npc")),
                box.padding = unit(0.5, "lines"),
                color = "black",
                fontface = "bold",
                force = 1,
                point.padding = unit(0.75, "lines"),
                segment.color = "gray",
                segment.size = 0.5,
                show.legend = FALSE,
                size = 4)
    }
    if (direction == "both" | direction == "up") {
        volcanoPolyUp <- with(stats, data.frame(
            x = as.numeric(c(
                lfc,
                lfc,
                max(rangeLFC),
                max(rangeLFC))),
            y = as.numeric(c(
                -log10(alpha + 1e-10),
                max(rangeNegLog10Pvalue),
                max(rangeNegLog10Pvalue),
                -log10(alpha + 1e-10)))))
        volcano <- volcano +
            geom_polygon(
                data = volcanoPolyUp,
                aes_(x = ~x, y = ~y),
                fill = shadeColor,
                alpha = shadeAlpha)
    }
    if (direction == "both" | direction == "down") {
        volcanoPolyDown <- with(stats, data.frame(
            x = as.numeric(c(
                -lfc,
                -lfc,
                min(rangeLFC),
                min(rangeLFC))),
            y = as.numeric(c(
                -log10(alpha + 1e-10),
                max(rangeNegLog10Pvalue),
                max(rangeNegLog10Pvalue),
                -log10(alpha + 1e-10)))))
        volcano <- volcano +
            geom_polygon(
                data = volcanoPolyDown,
                aes_(x = ~x, y = ~y),
                fill = shadeColor,
                alpha = shadeAlpha)
    }


    # Grid layout ====
    if (isTRUE(histograms)) {
        ggdraw() +
            # Coordinates are relative to lower left corner
            draw_plot(
                lfcHist,
                x = 0, y = 0.7, width = 0.5, height = 0.3) +
            draw_plot(
                pvalueHist,
                x = 0.5, y = 0.7, width = 0.5, height = 0.3) +
            draw_plot(
                volcano, x = 0, y = 0, width = 1, height = 0.7)
    } else {
        volcano +
            ggtitle("volcano")
    }
}



# Methods ====
#' @rdname plotVolcano
#' @importFrom S4Vectors metadata
#' @export
setMethod(
    "plotVolcano",
    signature("DESeqResults"),
    function(object, alpha = NULL, ...) {
        if (is.null(alpha)) {
            alpha <- metadata(object)[["alpha"]]
        }
        .plotVolcano(object, alpha = alpha, ...)
    })



#' @rdname plotVolcano
#' @export
setMethod(
    "plotVolcano",
    signature("data.frame"),
    .plotVolcano)
