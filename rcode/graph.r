library(jsonlite)
library(ggplot2)
library( ReporteRs )
library(fBasics)

args = commandArgs(trailingOnly=TRUE)
setwd(args[1])
#setwd("C:/Users/Johannes/Projects/elastic/results/output/201705291239.swarm1-master")

saveMyPlot <- function(p, name) {
  png(paste(name,".png", sep=""), width=600, height=600)
  print(p)
  dev.off()
  Sys.sleep(0)
  
  win.metafile(paste(name,".metafile", sep=""))
  print(p)
  dev.off()
  Sys.sleep(0)
}

saveMyBoxplot <- function(a, b, name) {
  png(paste(name,".png", sep=""), width=600, height=600)
  boxplot(a, b)
  dev.off()
  Sys.sleep(0)
  
  win.metafile(paste(name,".metafile", sep=""))
  boxplot(a, b)
  dev.off()
  Sys.sleep(0)
}

logDF <- fromJSON("logstash.json", flatten = TRUE)
logDF$timeEpoch <- as.numeric( logDF$`fields.@timestamp`)
logDF$time <- as.POSIXct(logDF$timeEpoch/1000, origin="1970-01-01", tz="Europe/Amsterdam")

workerStart <- logDF[grep("worker:start", logDF$"_source.message", ignore.case=T),]
workerDone <- logDF[grep("worker:done", logDF$"_source.message", ignore.case=T),]

workflowStats <- logDF[grep("workflow:stats", logDF$"_source.message", ignore.case=T),]
workflowStats$wfID <- substring(workflowStats$`_source.message`, 16, 51)
workflowStats$wfType <- substring(workflowStats$`_source.message`, 53, 53)
workflowStats$json <- substring(workflowStats$`_source.message`, 55)

#workflowStats$json

type <- numeric(nrow(workflowStats))
makespan <- numeric(nrow(workflowStats))
wait_time <- numeric(nrow(workflowStats))
response_time <- numeric(nrow(workflowStats))
human_time <- numeric(nrow(workflowStats))
human_delay_time <- numeric(nrow(workflowStats))
system_time <- numeric(nrow(workflowStats))
system_delay_time <- numeric(nrow(workflowStats))
for (i in 1:nrow(workflowStats)){
  jsonStats = fromJSON(workflowStats[i,]$json)
  type[i] <- strtoi(workflowStats[i,]$wfType)
  makespan[i] <- jsonStats$makespan
  wait_time[i] <- jsonStats$wait_time
  response_time[i] <- jsonStats$response_time
  human_time[i] <- jsonStats$human_time
  system_time[i] <- jsonStats$system_time
  human_delay_time[i] <- jsonStats$human_delay_time
  system_delay_time[i] <- jsonStats$system_delay_time
}

wfDF <- data.frame(type, makespan, wait_time, response_time, human_time, system_time)
basicStats(wfDF)
saveMyBoxplot(makespan ~ type, wfDF, "makespan")
saveMyBoxplot(response_time ~ type, wfDF, "response")
saveMyBoxplot(human_time ~ type, wfDF, "human")
saveMyBoxplot(system_time ~ type, wfDF, "system")
saveMyBoxplot(human_delay_time ~ type, wfDF, "human_delay")
saveMyBoxplot(system_delay_time ~ type, wfDF, "system_delay")
#boxplot(wfDF)

workerStart$start <- 1
workerDone$start <- -1

firstStart <- min(workerStart$timeEpoch)

metricsDF <- fromJSON("metrics.json", flatten = TRUE)
metricsDF <- metricsDF[grep("^node", metricsDF$`_source.beat.hostname`),]
metricsDF$timeEpoch <- as.numeric( metricsDF$`fields.@timestamp`)
metricsDF$timeFromStart <- (metricsDF$timeEpoch - firstStart)/1000
metricsDF$time <- as.POSIXct(metricsDF$timeEpoch/1000, origin="1970-01-01", tz="Europe/Amsterdam")
#summary(metricsDF)

loadDF <- metricsDF[grep("load", metricsDF$"_source.metricset.name"),]
#summary(loadDF)

plotLoad <- function(df) {
  p <- ggplot(df, aes(df$timeFromStart, df$`_source.system.load.5`))
  p <- p + geom_line(aes(colour = factor(df$`_source.beat.hostname`)))
  p <- p + xlab("Time (in seconds) since first Workflow started") + ylab("System load over 5 minutes")     
  p <- p + scale_colour_discrete(name="")
  p <- p + theme(legend.position="top")
  return (p)
}
saveMyPlot(plotLoad(loadDF), "load")


writeDF <- metricsDF[complete.cases(metricsDF$`_source.system.diskio.write.bytes`),]
writeDF <- writeDF[grep("sda1", writeDF$`_source.system.diskio.name`),]
#writeDF[writeDF$timeFromStart <= 10 & writeDF$timeFromStart > 0,]$`_source.beat.hostname`
plotDisk <- function(df) {
  p <- ggplot(df, aes(df$timeFromStart, df$`_source.system.diskio.write.bytes`))
  p <- p + geom_line(aes(colour = factor(df$`_source.beat.hostname`)))
  p <- p + xlab("Time (in seconds) since first Workflow started") + ylab("Bytes written to disk since start")     
  p <- p + scale_colour_discrete(name="")
  p <- p + theme(legend.position="top")
  return (p)
}
saveMyPlot(plotDisk(writeDF), "disk")

memDF <- metricsDF[complete.cases(metricsDF$`_source.system.memory.actual.used.pct`),]
plotMemory <- function(df) {
  p <- ggplot(df, aes(df$timeFromStart, df$`_source.system.memory.actual.used.pct`))
  p <- p + geom_line(aes(colour = factor(df$`_source.beat.hostname`)))
  p <- p + xlab("Time (in seconds) since first Workflow started") + ylab("Memory usage")     
  p <- p + scale_colour_discrete(name="")
  p <- p + theme(legend.position="top")
  return (p)
}
saveMyPlot(plotMemory(memDF), "mem")

cpuDF <- metricsDF[complete.cases(metricsDF$`_source.system.cpu.user.pct`),]
plotCPU <- function(df) {
  p <- ggplot(df, aes(df$timeFromStart, df$`_source.system.cpu.user.pct`))
  p <- p + geom_line(aes(colour = factor(df$`_source.beat.hostname`)))
  p <- p + xlab("Time (in seconds) since first Workflow started") + ylab("CPU usage")     
  p <- p + scale_colour_discrete(name="")
  p <- p + theme(legend.position="top")
  return (p)
}
saveMyPlot(plotCPU(cpuDF), "cpu")

netDF <- metricsDF[complete.cases(metricsDF$`_source.system.network.in.bytes`),]
netDF <- netDF[grep("\\beth0\\b", netDF$`_source.system.network.name`),]
netDF$MBs <- netDF$`_source.system.network.in.bytes` / 1024 / 1024 / 1024 #TO GB
plotNet <- function(df) {
  p <- ggplot(df, aes(df$timeFromStart, df$MBs))
  p <- p + geom_line(aes(colour = factor(df$`_source.beat.hostname`)))
  p <- p + xlab("Time (in seconds) since first Workflow started") + ylab("GBs received over eth0 since start")
  p <- p + scale_colour_discrete(name="")
  p <- p + theme(legend.position="top")
  return (p)
}
saveMyPlot(plotNet(netDF), "net")


