library(jsonlite)
library(ggplot2)
library( ReporteRs )
library(fBasics)
library(reshape)


#args = commandArgs(trailingOnly=TRUE)
#setwd(args[1])
setwd("C:/Users/Johannes/Projects/elastic/results/output/D")

logDF <- fromJSON("logstash.json", flatten = TRUE)
logDF$timeEpoch <- as.numeric( logDF$`fields.@timestamp`)
logDF$time <- as.POSIXct(logDF$timeEpoch/1000, origin="1970-01-01", tz="Europe/Amsterdam")

workerStart <- logDF[grep("worker:start", logDF$"_source.message", ignore.case=T),]
workerStart$start <- 1
firstStart <- min(workerStart$timeEpoch)


metricsDF <- fromJSON("metrics.json", flatten = TRUE)
metricsDF <- metricsDF[grep("^node", metricsDF$`_source.beat.hostname`),]
metricsDF$timeEpoch <- as.numeric( metricsDF$`fields.@timestamp`)
metricsDF$timeFromStart <- (metricsDF$timeEpoch - firstStart)/1000
metricsDF$time <- as.POSIXct(metricsDF$timeEpoch/1000, origin="1970-01-01", tz="Europe/Amsterdam")

loadDF <- metricsDF[grep("load", metricsDF$"_source.metricset.name"),]
save(loadDF, file = "loadDF.Rdata")

load("loadDF.Rdata")
load <- data.frame(loadDF$`_source.beat.name`, loadDF$timeFromStart, loadDF$`_source.system.load.5`)
colnames(load) <- c("name", "time", "load5")
load = load[load$time > 0,]

load$cut <- cut(x = load$time, breaks = seq(0, 2400, by = 10), labels = FALSE)
# AVG the values!!
for(i in 0:240) 
{
  bin = load[load$cut == i,]
  bin = bin[complete.cases(bin), ]
  #print(colAvgs(bin[, "load5"]))
  print(bin$load5)
}

p <- ggplot(loadDF, aes(loadDF$timeFromStart, loadDF$`_source.system.load.5`)) 
p <- p + geom_line(aes(colour = factor(loadDF$`_source.beat.hostname`)))
p <- p + xlab("Time (in seconds) since first Workflow started") + ylab("System load over 5 minutes")     
p <- p + scale_x_continuous(limits=c(0, 2540), breaks=(breaks=seq(0,2400,200)))
p <- p + scale_colour_discrete(name="")
p <- p + theme(legend.position="top")

p

