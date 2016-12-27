library(jsonlite)
library(ggplot2)
library( ReporteRs )


#setwd("C:/Users/Johannes/Projects/results/output/20161218")
#setwd("C:/Users/Johannes/Projects/results/output/20161218.03")
setwd("C:/Users/Johannes/Projects/results/output/20161227")
#logDF <- fromJSON("20161227-logstash.json", flatten = TRUE)

#workerStart <- logDF[grep("worker:start", logDF$"_source.message", ignore.case=T),]
#workerDone <- logDF[grep("worker:done", logDF$"_source.message", ignore.case=T),]

#workerStart$start <- 1
#workerStart$timeEpoch <- as.numeric( workerStart$`fields.@timestamp`)
#workerStart$time <- as.POSIXct(workerStart$timeEpoch/1000, origin="1970-01-01", tz="Europe/Amsterdam")

#workerDone$start <- -1
#workerDone$timeEpoch <- as.numeric( workerDone$`fields.@timestamp`)
#workerDone$time <- as.POSIXct(workerDone$timeEpoch/1000, origin="1970-01-01", tz="Europe/Amsterdam")

#total <- rbind(workerStart, workerDone)

#hist(workerStart$time, breaks="mins", freq=TRUE, format="%H:%M:%S")
#hist(workerDone$time, breaks="mins", freq=TRUE, format="%H:%M:%S")

#save(workerStart, file = "workerStart.RData")
#save(workerDone, file = "workerDone.RData")
#save(logDF, file = "logDF.RData")

metricsDF <- fromJSON("20161227-metrics.json", flatten = TRUE)
metricsDF <- metricsDF[grep("^node", metricsDF$`_source.beat.hostname`),]
metricsDF$timeEpoch <- as.numeric( metricsDF$`fields.@timestamp`)
metricsDF$time <- as.POSIXct(metricsDF$timeEpoch/1000, origin="1970-01-01", tz="Europe/Amsterdam")
#summary(metricsDF)


loadDF <- metricsDF[grep("load", metricsDF$"_source.metricset.name"),]
#summary(loadDF)

p <- ggplot(loadDF, aes(loadDF$time, loadDF$`_source.system.load.5`))
p + geom_line(aes(colour = factor(loadDF$`_source.beat.hostname`)))
dev.copy(png, "load.png")
dev.off()

p <- ggplot(loadDF, aes(loadDF$time, loadDF$`_source.system.load.5`))
p + geom_line(aes(colour = factor(loadDF$`_source.beat.hostname`)))
dev.copy(win.metafile,"load.metafile")
dev.off()

writeDF <- metricsDF[complete.cases(metricsDF$`_source.system.diskio.write.bytes`),]
writeDF <- writeDF[grep("sda1", writeDF$`_source.system.diskio.name`),]
#summary(writeDF)
#writeDF

p <- ggplot(writeDF, aes(writeDF$time, writeDF$`_source.system.diskio.write.bytes`))
p + geom_line(aes(colour = factor(writeDF$`_source.beat.hostname`)))
dev.copy(png, "disk.png")
dev.off()

p <- ggplot(writeDF, aes(writeDF$time, writeDF$`_source.system.diskio.write.bytes`))
p + geom_line(aes(colour = factor(writeDF$`_source.beat.hostname`)))
dev.copy(win.metafile,"disk.metafile")
dev.off()


memDF <- metricsDF[complete.cases(metricsDF$`_source.system.memory.actual.used.pct`),]
#summary(memDF)
#memDF

p <- ggplot(memDF, aes(memDF$time, memDF$`_source.system.memory.actual.used.pct`))
p + geom_line(aes(colour = factor(memDF$`_source.beat.hostname`)))
dev.copy(png, "mem.png")
dev.off()

p <- ggplot(memDF, aes(memDF$time, memDF$`_source.system.memory.actual.used.pct`))
p + geom_line(aes(colour = factor(memDF$`_source.beat.hostname`)))
dev.copy(win.metafile, "mem.metafile")
dev.off()


cpuDF <- metricsDF[complete.cases(metricsDF$`_source.system.cpu.user.pct`),]
#summary(cpuDF)
#cpuDF

p <- ggplot(cpuDF, aes(cpuDF$time, cpuDF$`_source.system.cpu.user.pct`))
p + geom_line(aes(colour = factor(cpuDF$`_source.beat.hostname`)))
dev.copy(png, "cpu.png")
dev.off()

p <- ggplot(cpuDF, aes(cpuDF$time, cpuDF$`_source.system.cpu.user.pct`))
p + geom_line(aes(colour = factor(cpuDF$`_source.beat.hostname`)))
dev.copy(win.metafile, "cpu.metafile")
dev.off()

netDF <- metricsDF[complete.cases(metricsDF$`_source.system.network.in.bytes`),]
netDF <- netDF[grep("\\beth0\\b", netDF$`_source.system.network.name`),]
#summary(netDF)
#netDF

p <- ggplot(netDF, aes(netDF$time, netDF$`_source.system.network.in.bytes`))
p + geom_line(aes(colour = factor(netDF$`_source.beat.hostname`)))
dev.copy(png, "net.png")
dev.off()

p <- ggplot(netDF, aes(netDF$time, netDF$`_source.system.network.in.bytes`))
p + geom_line(aes(colour = factor(netDF$`_source.beat.hostname`)))
dev.copy(win.metafile, "net.metafile")
dev.off()
