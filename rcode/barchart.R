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

dir = "C:\\Users\\Rosa\\Desktop\\output"

experiments <- c("A") # experiments <- c("A", "B", "C", "D", "E", "F", "G")
numruns <- c(8) # numruns <- c(8,12,2,8,8,2,10)

for(i in 1:length(experiments)) 
{
  exp <- experiments[i]
  numruns <- numruns[i]
  
  results <- NULL
  
  for(j in 1:numruns){
    setwd(paste0(dir, "\\", exp, "\\", j))
    load("wfDF.RData")
    results <- cbind(results,colSums(wfDF))
  }
  
  # nu hebben we een matrix met net zoveel kolommen als het aantal runs in dit experiment. 
  # geef de kolommen namen, nu even heel simpel gedaan
  colnames(results) <- 1:numruns
  
  # percentages 
  prop = prop.table(results,margin=2)
  par(mar=c(5.1, 4.1, 4.1, 7.1), xpd=TRUE)
  barplot(prop, col=heat.colors(length(rownames(prop))), width=2, beside=FALSE)
  legend("topright",inset=c(-0.25,0), fill=heat.colors(length(rownames(prop))), legend=rownames(results))
  
  # counts
  par(mar=c(5.1, 4.1, 4.1, 7.1), xpd=TRUE)
  barplot(results, col=heat.colors(length(rownames(results))), width=2)
  legend("topright",inset=c(-0.25,0), fill=heat.colors(length(rownames(results))), legend=rownames(results))

}