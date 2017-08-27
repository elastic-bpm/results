# Stacked barchart maken met daarin een aantal tijdsvariabelen.
# per onderdeel (a tm g) een aantal runs naast elkaar plotten. 
# eerste dataframes wfDF inlezen. Per dataframe: som over de kolommen nemen. 
# eventueel een average? 
# dus 1 kolom per run. 
# die kolommen samen nemen in een nieuwe datframe met 1 kolom per run. 
# rownames aanpassen naar run1, run2, .... run8. 
# plotten

# per onderdeel ander aantal runs, zie onder: 
# a: 8
# b: 12
# c: 2
# d: 8
# e: 8
# f: 2
# g: 10
library(colorRamps)
library(fBasic)
dir = "C:\\Users\\Johannes\\Projects\\elastic\\results\\output"
options(scipen=999)
experiments <- c("A") # experiments <- c("A", "B", "C", "D", "E", "F", "G", "H")
numruns <- c(8) # numruns <- c(8,8,2,8,8,8,2,10)

for(i in 1:length(experiments)) 
{
  exp <- experiments[i]
  numruns <- numruns[i]
  
  results <- NULL
  
  for(j in 1:numruns){
    setwd(paste0(dir, "\\", exp, "\\", j))
    load("wfDF.RData")
    x <- data.matrix(colAvgs(wfDF))
    x <- sweep(x, 1, c(1000,1000,1000,1000,1000,1000), "/")
    results <- cbind(results, x)
  }
  
  # nu hebben we een matrix met net zoveel kolommen als het aantal runs in dit experiment. 
  # geef de kolommen namen, nu even heel simpel gedaan
  colnames(results) <- 1:numruns
  legend_texts = expression("T"["m"], "T"["w"], "T"["dh"], "T"["h"], "T"["ds"], "T"["s"])
  
  # percentages 
  prop = prop.table(results,margin=2)
  par(mar=c(5, 5, 5, 5), xpd=TRUE)
  barplot(prop, col=gray.colors(length(rownames(prop)), start = 0.3, end = 0.9, gamma = 2.2, alpha = NULL), width=2, beside=FALSE, xlab="# Threads/node", ylab="relative time spent")
  legend("topright",inset=c(0,-0.2), fill=gray.colors(length(rownames(prop)), start = 0.1, end = 0.9, gamma = 2.2, alpha = NULL), legend=legend_texts, ncol=6)
  
  # counts
  par(mar=c(5, 5, 5, 5), xpd=TRUE)
  barplot(results, col=gray.colors(length(rownames(results)), start = 0.3, end = 0.9, gamma = 2.2, alpha = NULL), width=2, beside=TRUE, xlab="# Threads/node", ylab="average runtime in minutes")
  legend("topright",inset=c(0,-0.2), fill=gray.colors(length(rownames(results)), start = 0.1, end = 0.9, gamma = 2.2, alpha = NULL), legend=legend_texts, ncol=6)
}
