#!/usr/bin/env Rscript
# ============================================================
# DESeq2 differential expression (a1 vs p1)
# Marianes Midgut dataset
# ============================================================

# ----------------------------
# 1. Load libraries
# ----------------------------
suppressPackageStartupMessages({
  library(DESeq2)
  library(MarianesMidgutData)
})

# ----------------------------
# 2. Load data
# ----------------------------
data("midgut", package = "MarianesMidgutData")

cat("Loaded object: midgut\n")
cat("Class:", class(midgut), "\n\n")

# ----------------------------
# 3. Run DESeq2 results
# ----------------------------
temp <- results(
  midgut,
  contrast = c("condition", "a1", "p1")
)

# ----------------------------
# 4. Helper function to format results
# ----------------------------
formatDESeq2Results <- function(x) {
  df <- as.data.frame(x)
  df <- data.frame(GeneID = rownames(df), df)
  rownames(df) <- NULL
  df
}

# ----------------------------
# 5. Format results
# ----------------------------
a1_vs_p1 <- formatDESeq2Results(temp)

# ----------------------------
# 6. Inspect output
# ----------------------------
cat("First 10 rows of a1_vs_p1:\n")
print(head(a1_vs_p1, 10))

cat("\nDimensions of result table:\n")
print(dim(a1_vs_p1))

# ----------------------------
# 7. (Optional) Save results
# ----------------------------
# write.csv(a1_vs_p1, "a1_vs_p1_DESeq2_results.csv", row.names = FALSE)
