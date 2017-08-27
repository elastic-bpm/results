library(jsonlite)
library(ggplot2)

args = commandArgs(trailingOnly=TRUE)
setwd(args[1])
#setwd("C:/Users/Johannes/Projects/elastic/results/output/D/1")

saveMyPlot <- function(p, name) {
  png(paste(name,".png", sep=""), width=600, height=600)
  print(p)
  dev.off()
  Sys.sleep(0)
  
  win.metafile(paste(name,".emf", sep=""))
  print(p)
  dev.off()
  Sys.sleep(0)
}

logDF <- fromJSON("logstash.json", flatten = TRUE)
logDF$timeEpoch <- as.numeric( logDF$`fields.@timestamp`)
logDF$time <- as.POSIXct(logDF$timeEpoch/1000, origin="1970-01-01", tz="Europe/Amsterdam")

workerStart <- logDF[grep("worker:start", logDF$"_source.message", ignore.case=T),]
workerStart$start <- 1
firstStart <- min(workerStart$timeEpoch)

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

# p <- ggplot(schedulerInfo, aes(schedulerInfo$timeFromStart)) + 
#   xlab("Time (in seconds) since first Workflow started") + ylab("Active nodes") +
#   geom_area(aes(y = active_nodes)) +
#   scale_y_continuous(limits=c(0, 15), breaks=(breaks=seq(0,15,1))) +
#   scale_x_continuous(limits=c(0, 2540), breaks=(breaks=seq(0,2400,200)))
# print(p)

# waarde in aantal nodes veranderen als de waarde ervoor en erna hetzelfde zijn, maar anders dan deze waarde. 
active_nodes_adj <- active_nodes
for(i in 2: (length(active_nodes)-1))
{
  if(active_nodes[i-1] == active_nodes[i+1])
    active_nodes_adj[i] = active_nodes[i-1]
}

# aantal wijzigingen bekijken
sum(active_nodes != active_nodes_adj)

# plotten nieuwe active_nodes tegen tijd vanaf start workflow
p <- (ggplot(schedulerInfo, aes(schedulerInfo$timeFromStart, active_nodes_adj))+geom_bar(stat="identity", position="dodge") + scale_y_continuous(limits=c(0, 15), breaks=(breaks=seq(0,15,1))) 
  + scale_x_continuous(limits=c(0, 2540), breaks=(breaks=seq(0,2400,200)))
  + xlab("Time (in seconds) since first Workflow started") + ylab("Active nodes"))
saveMyPlot(p, "resources2")

# functie waarmee je kan berekenen hoeveel geld de hele workflow kost
# input: timeFromStart, active_nodes_adj en geld die het kost om 1 node 1 seconde te gebruiken
money <- function(timeFromStart, active_nodes_adj, moneynodesecond)
{
  # eerst alleen de timeFromStart >= 0 overhouden
  positive <- which(timeFromStart >= 0)
  timeFromStart <- timeFromStart[positive]
  active_nodes_adj <- active_nodes_adj[positive]
  
  # omdat de tijd terugloopt: tijd[i] - tijd[i+1] maal het aantal nodes op tijd[i+1]. 
  # aanname is dat van i tot i+1 het aantal nodes nodig is wat ook op tijd i+1 nodig was. 
  nodesseconds = 0
  for(i in 1:(length(active_nodes_adj)- 1))
  {
    nodesseconds <- nodesseconds + (timeFromStart[i]-timeFromStart[i+1])*active_nodes_adj[i+1] 
  }
  
  return (nodesseconds * moneynodesecond)
}

# input: timeFromStart, active_nodes_adj en geld die het kost om 1 node 1 seconde te gebruiken
money2 <- function(timeFromStart, active_nodes_adj, moneynodesecond)
{
  # eerst alleen de timeFromStart >= 0 overhouden
  positive <- which(timeFromStart >= 0)
  timeFromStart <- timeFromStart[positive]
  active_nodes_adj <- active_nodes_adj[positive]
  #zorgen dat tijd van klein naar groot loopt ipv andersom
  timeFromStart <- rev(timeFromStart)
  active_nodes_adj <- rev(active_nodes_adj)
  
  # omdat de tijd nu vooruit loopt: tijd[i+1] - tijd[i] maal het aantal nodes op tijd[i]. 
  # aanname is dat van i tot i+1 het aantal nodes nodig is wat ook op tijd i nodig was. 
  nodesseconds = 0
  for(i in 1:(length(active_nodes_adj)- 1))
  {
    nodesseconds <- nodesseconds + (timeFromStart[i+1]-timeFromStart[i])*active_nodes_adj[i] 
  }
  
  return (nodesseconds * moneynodesecond)
}


m <- money(schedulerInfo$timeFromStart, active_nodes_adj, 1)
md <- money(schedulerInfo$timeFromStart, active_nodes_adj, 0.0005)
m2 <- money2(schedulerInfo$timeFromStart, active_nodes_adj, 1)
m2d <- money2(schedulerInfo$timeFromStart, active_nodes_adj, 0.0005)

fileConn<-file("cost.txt")
writeLines(c(m,md," ",m2,m2d), fileConn)
close(fileConn)


