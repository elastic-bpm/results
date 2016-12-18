library(jsonlite)

setwd("C:/Users/Johannes/Projects/results/output/20161218")
logDF <- fromJSON("20161218-logstash.json", flatten = TRUE)

workerStart <- logDF[grep("worker:start", logDF$"_source.message", ignore.case=T),]
workerDone <- logDF[grep("worker:done", logDF$"_source.message", ignore.case=T),]

workerStart$start <- 1
workerStart$timeEpoch <- as.numeric( workerStart$`fields.@timestamp`)
workerStart$time <- as.POSIXct(workerStart$timeEpoch/1000, origin="1970-01-01", tz="Europe/Amsterdam")

workerDone$start <- -1
workerDone$timeEpoch <- as.numeric( workerDone$`fields.@timestamp`)
workerDone$time <- as.POSIXct(workerDone$timeEpoch/1000, origin="1970-01-01", tz="Europe/Amsterdam")

total <- rbind(workerStart, workerDone)

hist(workerStart$time, breaks="mins", freq=TRUE, format="%H:%M:%S")
hist(workerDone$time, breaks="mins", freq=TRUE, format="%H:%M:%S")

#save(workerStart, file = "workerStart.RData")
#save(workerDone, file = "workerDone.RData")
#save(logDF, file = "logDF.RData")

metricsDF <- fromJSON("20161218-metrics.json", flatten = TRUE)
colnames(metricsDF)
loadDF <- metricsDF[grep("load", metricsDF$"_source.metricset.name"),]
loadDF[,c("fields.@timestamp","_source.system.load.1")]
