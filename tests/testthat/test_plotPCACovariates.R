context("plotPCACovariates")

test_that("default", {
    p <- plotPCACovariates(bcb)
    expect_is(p, "list")
    expect_equal(
        names(p),
        c("significantCovars",
          "plot",
          "corMatrix",
          "pcsMatrix",
          "scatterPlot",
          "effectsSignificantCovars")
    )
    # Check significant covariates
    expect_equal(
        as.character(p[["significantCovars"]]),
        c("duplicationRateOfMapped",
          "exonicRate",
          "intergenicRate",
          "intronicRate",
          "rrna")
    )
    expect_equal(
        round(p[["effectsSignificantCovars"]], digits = 3),
        c(duplicationRateOfMapped = 0.610,
          exonicRate = 0.610,
          intergenicRate = 0.610,
          intronicRate = 0.610,
          rrna = 0.279,
          group = 0,
          mappedReads = 0,
          rrnaRate = 0,
          totalReads = 0,
          x53Bias = 0,
          # Fix GC name in YAML metadata?
          xGC = 0)
    )
})

test_that("defined metrics", {
    p <- plotPCACovariates(
        bcb,
        metrics = c("exonicRate", "intronicRate"))
    expect_equal(
        as.character(p[["significantCovars"]]),
        c("exonicRate", "intronicRate")
    )
    expect_equal(
        round(p[["effectsSignificantCovars"]], digits = 3),
        c(exonicRate = 0.610,
          intronicRate = 0.610)
    )
})

test_that("invalid parameters", {
    # Error on invalid column
    expect_error(
        plotPCACovariates(bcb, metrics = c("FOO", "BAR")),
        "Failed to select valid 'metrics' for plot"
    )
    # More than 1 metric is required
    expect_error(
        plotPCACovariates(bcb, metrics = "exonicRate"),
        "'degCovariates\\(\\)' requires at least 2 metadata columns"
    )
})
