#!/usr/bin/env Rscript
# ============================================================
# Full Approach 2 Pipeline (C-MOOR)
# DESeq2 → clusterProfiler
# → manual pathways + best pathway
# → Expression plots (counts)
# → Differential expression plots (log2FC)
# Marianes Midgut dataset
# ============================================================

# ----------------------------
# 1. Load libraries
# ----------------------------
suppressPackageStartupMessages({
  library(DESeq2)
  library(MarianesMidgutData)
  library(clusterProfiler)
  library(enrichplot)
  library(org.Dm.eg.db)
  library(dplyr)
  library(ggplot2)
})

# ----------------------------
# 2. Load data
# ----------------------------
data("midgut", package = "MarianesMidgutData")

# ----------------------------
# 3. Output directory
# ----------------------------
outdir <- "plots/clusterProfiler"
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# ----------------------------
# 4. User-defined (hard-coded) pathways
# ----------------------------
manual_pathways <- c(
  "Neuroactive ligand-receptor interaction"
)

# ----------------------------
# 5. Helper functions
# ----------------------------

formatDESeq2Results <- function(x) {
  df <- as.data.frame(x)
  df <- data.frame(GeneID = rownames(df), df)
  rownames(df) <- NULL
  df
}

runClusterProfiler <- function(df) {

  ids <- bitr(
    df$GeneID,
    fromType = "ENSEMBL",
    toType   = "ENTREZID",
    OrgDb    = org.Dm.eg.db
  )
  if (nrow(ids) == 0) return(NULL)

  kegg <- enrichKEGG(
    gene      = ids$ENTREZID,
    organism = "dme",
    keyType  = "ncbi-geneid"
  )
  if (is.null(kegg) || nrow(kegg@result) == 0) return(NULL)

  kegg@result$Description <- sub(
    " - Drosophila melanogaster \\(fruit fly\\)",
    "",
    kegg@result$Description
  )
  kegg
}

selectBestPathway <- function(kegg) {

  df <- kegg@result %>%
    mutate(
      GeneRatio_num = sapply(GeneRatio, function(x) eval(parse(text = x))),
      score = -log10(p.adjust) * GeneRatio_num
    ) %>%
    arrange(desc(score))

  df[1, ]
}

getGenesFromPathway <- function(kegg, pathway_name) {

  genes <- kegg@result %>%
    filter(Description == pathway_name) %>%
    pull(geneID) %>%
    strsplit("/") %>%
    unlist()

  if (length(genes) == 0) return(NULL)

  bitr(
    genes,
    fromType = "ENTREZID",
    toType   = "ENSEMBL",
    OrgDb    = org.Dm.eg.db
  )$ENSEMBL
}

rankGenesInPathway <- function(res_df, genes, top_n = 10) {

  res_df %>%
    filter(GeneID %in% genes) %>%
    filter(!is.na(log2FoldChange)) %>%
    arrange(desc(abs(log2FoldChange))) %>%
    head(top_n)
}

# ============================================================
# Expression plot (counts) — md plotAcrossRegions meaning
# ============================================================

plotExpressionAcrossRegions <- function(gene_id, dds, outfile) {

  df <- data.frame(
    counts = counts(dds, normalized = TRUE)[gene_id, ],
    region = colData(dds)$condition
  )

  df$region <- factor(
    df$region,
    levels = c("a1","a2_3","Cu","LFCFe","Fe","p1","p2_4")
  )

  p <- ggplot(df, aes(region, counts)) +
    geom_bar(stat = "identity", fill = "steelblue") +
    theme_bw(base_size = 12) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    labs(
      title = paste("Expression of", gene_id),
      x = "Midgut sub-region",
      y = "Normalized counts"
    )

  ggsave(outfile, p, width = 6, height = 4, dpi = 300)
}


plotAcrossRegions_png <- function(gene_id, outfile) {

  df <- data.frame(
    counts = counts(midgut, normalized = TRUE)[gene_id, ],
    region = colData(midgut)$condition
  )

  df <- df[10:30, ]

  df$region <- factor(
    df$region,
    levels = c("a1", "a2_3", "Cu", "LFCFe", "Fe", "p1", "p2_4")
  )

  p <- ggplot(df) +
    geom_bar(aes(region, counts), stat = "identity") +
    ggtitle(gene_id) +
    theme_bw() +
    theme(
      axis.text.x = element_text(angle = 90, vjust = 0.5)
    )

  ggsave(
    filename = outfile,
    plot = p,
    width = 6,
    height = 4,
    dpi = 300
  )
}



# ============================================================
# Differential expression plot — DESeq2 log2FC
# ============================================================

plotGeneDEAcrossRegions <- function(
  gene_id,
  dds,
  baseline,
  padj_cutoff,
  outfile
) {

  regions <- setdiff(unique(colData(dds)$condition), baseline)

  df <- bind_rows(lapply(regions, function(r) {

    res <- tryCatch(
      results(dds, contrast = c("condition", r, baseline)),
      error = function(e) NULL
    )
    if (is.null(res)) return(NULL)

    res_df <- as.data.frame(res)
    res_df$GeneID <- rownames(res_df)

    g <- res_df[res_df$GeneID == gene_id, ]
    if (nrow(g) == 0) return(NULL)

    data.frame(
      comparison = paste(r, "vs", baseline),
      log2FoldChange = g$log2FoldChange,
      padj = g$padj
    )
  }))

  if (nrow(df) == 0) return(NULL)

  df$comparison <- factor(df$comparison, levels = df$comparison)
  df$significant <- df$padj < padj_cutoff

  p <- ggplot(df, aes(comparison, log2FoldChange, fill = significant)) +
    geom_bar(stat = "identity") +
    geom_hline(yintercept = 0, linetype = "dashed") +
    scale_fill_manual(
      values = c("TRUE" = "firebrick", "FALSE" = "grey70"),
      name = paste0("padj < ", padj_cutoff)
    ) +
    theme_bw(base_size = 12) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    labs(
      title = paste("Differential expression of", gene_id),
      x = "Region comparison",
      y = "log2 Fold Change"
    )

  ggsave(outfile, p, width = 7, height = 4, dpi = 300)
}

# ----------------------------
# 6. User parameters
# ----------------------------
padj_cutoff <- 0.01
top_n_genes <- 10

# ----------------------------
# 7. Regions
# ----------------------------
regions <- unique(colData(midgut)$condition)

# ----------------------------
# 8. Main loop
# ----------------------------
for (r1 in regions) {
  if (r1 != "p1_4") next
  for (r2 in regions) {

    if (r1 == r2) next
    cat("Processing:", r1, "vs", r2, "\n")

    res_raw <- tryCatch(
      results(midgut, contrast = c("condition", r1, r2)),
      error = function(e) NULL
    )
    if (is.null(res_raw)) next

    res <- formatDESeq2Results(res_raw)

    sig_genes <- res %>%
      filter(!is.na(padj), padj <= padj_cutoff)
    if (nrow(sig_genes) == 0) next

    clusters <- runClusterProfiler(sig_genes)
    if (is.null(clusters)) next

    # ---- Dotplot (PNG) ----
    dotplot_file <- file.path(
      outdir,
      paste0("clusterProfiler_", r1, "_vs_", r2, ".png")
    )

    png(dotplot_file, width = 3000, height = 2100, res = 300)
    print(dotplot(clusters, showCategory = nrow(clusters@result)))
    dev.off()

    # ---- Best pathway ----
    best_pathway <- selectBestPathway(clusters)
    best_pathway_name <- best_pathway$Description

    # ---- Combine manual + best ----
    all_pathways <- unique(c(manual_pathways, best_pathway_name))
    available <- clusters@result$Description
    #selected_pathways <- intersect(all_pathways, available)
    selected_pathways <- manual_pathways # FIXME
    print (manual_pathways)
    if (length(selected_pathways) == 0) next

    # ---- Loop over selected pathways ----
    for (pathway_name in selected_pathways) {
      genes <- getGenesFromPathway(clusters, pathway_name)
      if (is.null(genes)) next
 
      top_genes <- rankGenesInPathway(res, genes, top_n_genes)
      if (nrow(top_genes) == 0) next
      cat("Selected genes for pathway:", pathway_name, "\n")
      print(
        top_genes %>%
	select(GeneID, log2FoldChange, padj)
      )


      pathway_dir <- file.path(
        outdir,
        "genes",
        paste0(r1, "_vs_", r2),
        gsub(" ", "_", pathway_name)
      )
      dir.create(pathway_dir, recursive = TRUE, showWarnings = FALSE)

      for (g in top_genes$GeneID) {

        plotExpressionAcrossRegions(
          gene_id = g,
          dds = midgut,
          outfile = file.path(
            pathway_dir,
            paste0(g, "_expression_across_regions.png")
          )
        )

	plotAcrossRegions_png(
	  gene_id = g,
          outfile = file.path(
            pathway_dir,
            paste0(g, "_expression_across_regions_md.png")
          )
 	)


        plotGeneDEAcrossRegions(
          gene_id = g,
          dds = midgut,
          baseline = r1,
          padj_cutoff = padj_cutoff,
          outfile = file.path(
            pathway_dir,
            paste0(g, "_DE_across_regions.png")
          )
        )
      }
    }
  }
}

cat("\n✅ All analyses complete.\n")
