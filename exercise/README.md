## Test interactively,

First, you can test if all packages are well installed and can read data in the interactive mode R. Inside the docker image,

```
cd /home/rstudio
R
```

Once interactive R is lunched, load packages,
```
library(DESeq2)
library(MarianesMidgutData)
data("midgut", package = "MarianesMidgutData")
midgut
class(midgut)
temp <- results(midgut, contrast = c("condition", "a1", "p1"))
formatDESeq2Results <- function(x) {
  df <- as.data.frame(x)
  df <- data.frame(rownames(df), df)
  colnames(df) <- c("GeneID", colnames(df)[-1])
  rownames(df) <- NULL
  df
}
a1_vs_p1 <- formatDESeq2Results(temp)
head(a1_vs_p1, 10)
```

You'll be able to see first 10 lines of dataframe
```
  FBgn0000028 6.398922e+00    0.291792392 0.7817040  0.37327732 7.089421e-01
  10 FBgn0000032 8.832224e+02   -0.114117663 0.2055831 -0.55509249 5.788314e-01
             padj
	     1            NA
	     2  8.709166e-02
	     3  2.319873e-04
	     4  6.484972e-01
	     5  7.195408e-01
	     6  9.864439e-01
	     7            NA
	     8  6.155433e-07
	     9  8.450406e-01
	     10 7.596855e-01
```


Using R script, you can do the same thing,
```
Rscript ../exercise/run_deseq2_step1.R
```