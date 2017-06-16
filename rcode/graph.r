library(jsonlite)
library(ggplot2)
library( ReporteRs )
library(fBasics)
library(reshape)


args = commandArgs(trailingOnly=TRUE)
setwd(args[1])
#setwd("C:/Users/Johannes/Projects/elastic/results/output/D2/8")

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
  p <- boxplot(a, b)
  print(p)
  dev.off()
  Sys.sleep(0)
  
  win.metafile(paste(name,".metafile", sep=""))
  p <- boxplot(a, b)
  print(p)
  dev.off()
  Sys.sleep(0)
}

logDF <- fromJSON("logstash.json", flatten = TRUE)
logDF$timeEpoch <- as.numeric( logDF$`fields.@timestamp`)
logDF$time <- as.POSIXct(logDF$timeEpoch/1000, origin="1970-01-01", tz="Europe/Amsterdam")

workerStart <- logDF[grep("worker:start", logDF$"_source.message", ignore.case=T),]
workerDone <- logDF[grep("worker:done", logDF$"_source.message", ignore.case=T),]

workerStart$start <- 1
workerDone$start <- -1

firstStart <- min(workerStart$timeEpoch)

workflowUpdate <- logDF[grep("workflows:update", logDF$"_source.message", ignore.case=T),]
workflowUpdate$timeEpoch <- as.numeric( workflowUpdate$`fields.@timestamp`)
workflowUpdate$timeFromStart <- (workflowUpdate$timeEpoch - firstStart)/1000
workflowUpdate$json <- substring(workflowUpdate$`_source.message`, 18)

wf_count <- numeric(nrow(workflowUpdate))
todo_wf_count <- numeric(nrow(workflowUpdate))
busy_wf_count <- numeric(nrow(workflowUpdate))
done_wf_count <- numeric(nrow(workflowUpdate))
for (i in 1:nrow(workflowUpdate)){
  jsonStats = fromJSON(workflowUpdate[i,]$json)
  wf_count[i] <- jsonStats$workflow_count
  todo_wf_count[i] <- jsonStats$todo_workflow_count  
  busy_wf_count[i] <- jsonStats$busy_workflow_count  
  done_wf_count[i] <- jsonStats$done_workflow_count  
}
p <- ggplot(workflowUpdate, aes(workflowUpdate$timeFromStart)) + 
  geom_line(aes(y = wf_count, colour = "Total workflows")) + 
  geom_line(aes(y = todo_wf_count, colour = "Todo workflows")) + 
  geom_line(aes(y = busy_wf_count, colour = "Busy workflows")) + 
  geom_line(aes(y = done_wf_count, colour = "Done workflows")) +
  scale_x_continuous(limits=c(0, 2540), breaks=(breaks=seq(0,2400,200)))

saveMyPlot(p, "workflows")

taskUpdate <- logDF[grep("tasks:update", logDF$"_source.message", ignore.case=T),]
taskUpdate$timeEpoch <- as.numeric( taskUpdate$`fields.@timestamp`)
taskUpdate$timeFromStart <- (taskUpdate$timeEpoch - firstStart)/1000
taskUpdate$json <- substring(taskUpdate$`_source.message`, 14)

task_count <- numeric(nrow(taskUpdate))
todo_task_count <- numeric(nrow(taskUpdate))
busy_task_count <- numeric(nrow(taskUpdate))
done_task_count <- numeric(nrow(taskUpdate))
for (i in 1:nrow(taskUpdate)){
  jsonStats = fromJSON(taskUpdate[i,]$json)
  task_count[i] <- jsonStats$task_count
  todo_task_count[i] <- jsonStats$todo_task_count  
  busy_task_count[i] <- jsonStats$busy_task_count  
  done_task_count[i] <- jsonStats$done_task_count  
}
p <- ggplot(taskUpdate, aes(taskUpdate$timeFromStart)) + 
  geom_line(aes(y = task_count, colour = "Total tasks")) + 
  geom_line(aes(y = todo_task_count, colour = "Todo tasks")) + 
  geom_line(aes(y = busy_task_count, colour = "Busy tasks")) + 
  geom_line(aes(y = done_task_count, colour = "Done tasks")) +
  scale_x_continuous(limits=c(0, 2540), breaks=(breaks=seq(0,2400,200)))

saveMyPlot(p, "tasks")


schedulerInfo <- logDF[grep("scheduler:info", logDF$"_source.message", ignore.case=T),]
schedulerInfo$timeEpoch <- as.numeric( schedulerInfo$`fields.@timestamp`)
schedulerInfo$timeFromStart <- (schedulerInfo$timeEpoch - firstStart)/1000
schedulerInfo$json <- substring(schedulerInfo$`_source.message`, 16)
active_machines <- numeric(nrow(schedulerInfo))
active_nodes <- numeric(nrow(schedulerInfo))
target_nodes <- numeric(nrow(schedulerInfo))
for (i in 1:nrow(schedulerInfo)) {
  jsonStats = fromJSON(schedulerInfo[i,]$json)
  active_machines[i] <- jsonStats$active_machines
  active_nodes[i] <- jsonStats$active_nodes
  target_nodes[i] <- jsonStats$target_nodes
}
p <- ggplot(schedulerInfo, aes(schedulerInfo$timeFromStart)) + 
  xlab("Time (in seconds) since first Workflow started") + ylab("Active nodes") +
  geom_area(aes(y = active_nodes)) +
  scale_y_continuous(limits=c(0, 15), breaks=(breaks=seq(0,15,1))) +
  scale_x_continuous(limits=c(0, 2540), breaks=(breaks=seq(0,2400,200)))
saveMyPlot(p, "resources")

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
  p <- p + scale_x_continuous(limits=c(0, 2540), breaks=(breaks=seq(0,2400,200)))
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
  p <- p + scale_x_continuous(limits=c(0, 2540), breaks=(breaks=seq(0,2400,200)))
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
  p <- p + scale_x_continuous(limits=c(0, 2540), breaks=(breaks=seq(0,2400,200)))
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
  p <- p + scale_x_continuous(limits=c(0, 2540), breaks=(breaks=seq(0,2400,200)))
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
  p <- p + scale_x_continuous(limits=c(0, 2540), breaks=(breaks=seq(0,2400,200)))
  p <- p + scale_colour_discrete(name="")
  p <- p + theme(legend.position="top")
  return (p)
}
saveMyPlot(plotNet(netDF), "net")


workflowStats <- logDF[grep("workflow:stats", logDF$"_source.message", ignore.case=T),]
workflowStats$timeEpoch <- as.numeric( workflowStats$`fields.@timestamp`)
workflowStats$timeFromStart <- (workflowStats$timeEpoch - firstStart)/1000
workflowStats$wfID <- substring(workflowStats$`_source.message`, 16, 51)
workflowStats$wfType <- substring(workflowStats$`_source.message`, 53, 53)
workflowStats$json <- substring(workflowStats$`_source.message`, 55)

type <- numeric(nrow(workflowStats))
makespan <- numeric(nrow(workflowStats))
wait_time <- numeric(nrow(workflowStats))
response_time <- numeric(nrow(workflowStats))
human_time <- numeric(nrow(workflowStats))
human_delay_time <- numeric(nrow(workflowStats))
system_time <- numeric(nrow(workflowStats))
system_delay_time <- numeric(nrow(workflowStats))
time <- numeric(nrow(workflowStats))
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
  time[i] <- workflowStats[i,]$timeFromStart
}

wfDF <- data.frame(time, type, makespan, wait_time, response_time, human_time, system_time)
basicStats(wfDF)
saveMyBoxplot(makespan ~ type, wfDF, "makespan")
saveMyBoxplot(response_time ~ type, wfDF, "response")
saveMyBoxplot(human_time ~ type, wfDF, "human")
saveMyBoxplot(system_time ~ type, wfDF, "system")
saveMyBoxplot(human_delay_time ~ type, wfDF, "human_delay")
saveMyBoxplot(system_delay_time ~ type, wfDF, "system_delay")

#nieuwe stukje, opslaan voor latere barcharts. 
wfDF <- data.frame(makespan, wait_time, human_delay_time, human_time, system_delay_time, system_time)
save(wfDF, file = "wfDF.Rdata")



