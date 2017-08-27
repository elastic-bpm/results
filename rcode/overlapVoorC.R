#install.packages("dplyr")
#install.packages("ggplot2")
library(ggplot2)
library(dplyr)

# elke x seconden 1 bin. 
# ook geprobeerd met 5 en 10. 5 ziet er niet goed uit. 10 is vrij aardig maar 1 gekke uitschieter.
average_time <- 20

####### EERSTE DATASET #######

setwd("C:\\Users\\Johannes\\Projects\\elastic\\results\\output\\C\\1")
load("loadDF.Rdata")
colnames(loadDF)
DF1 <- loadDF[,c("_source.system.load.15" , "timeFromStart", "_source.beat.name") ]
colnames(DF1)
colnames(DF1) <- c("load5", "time", "node")
# alleen data bewaren met starttijd >= 0
DF1 <- DF1[DF1$time >= 0,]
# alleen meenemen als het een actieve node is. 
# Voor de 1e set:  node01 node02 node03 node05 node06 node07 node10 node11 node13 node14
DF1$active <- DF1$node %in% c("node01", "node02", "node03", "node05", "node06", "node07", "node10", "node11", "node13", "node14")
sum(DF1$active)
DF1 <- DF1[DF1$active,]

# plotje met nog gewone tijd
ggplot(DF1, aes(DF1$time, DF1$load5,colour=DF1$node)) + 
  geom_line() + 
  geom_point()

min(DF1$time)
max(DF1$time)
hist(DF1$time, breaks=125)
# tijd opdelen in bins
DF1$timecat <- DF1$time %/% average_time

ggplot(DF1, aes(DF1$timecat, DF1$load5,colour=DF1$node)) + 
  geom_line() + 
  geom_point()

# per tijdsgroep het gemiddelde, de standaarddeviatie, en de standaarddeviatie van het gemiddelde bepalen.
DF1.summary <- DF1 %>% group_by(timecat) %>%
  summarize(loadmean = mean(load5),
            loadsd = sd(load5), 
            loadsd2 = sd(load5)/sqrt(length(load5)))

####### TWEEDE DATASET #######

setwd("C:\\Users\\Johannes\\Projects\\elastic\\results\\output\\C\\2")
load("loadDF.Rdata") #nb: ook weer een loadDF dataframe
colnames(loadDF)
DF2 <- loadDF[,c("_source.system.load.15" , "timeFromStart", "_source.beat.name") ]
colnames(DF2)
colnames(DF2) <- c("load5", "time", "node")
# alleen data bewaren met starttijd >= 0
DF2 <- DF2[DF2$time >= 0,]
# alleen meenemen als het een actieve node is. 
# Voor de 2e set:  node01 node02 node06 node07 node08 node10 node12 node13 node14 node15
DF2$active <- DF2$node %in% c("node01", "node02", "node06", "node07", "node08", "node10", "node12", "node13", "node14", "node15")
sum(DF2$active)
DF2 <- DF2[DF2$active,]


# plotje met nog gewone tijd
ggplot(DF2, aes(DF2$time, DF2$load5,colour=DF2$node)) + 
  geom_line() + 
  geom_point()

min(DF2$time)
max(DF2$time)
hist(DF2$time, breaks=125)

# tijd opdelen in bins
DF2$timecat <- DF2$time %/% average_time

ggplot(DF2, aes(DF2$timecat, DF2$load5,colour=DF2$node)) + 
  geom_line() + 
  geom_point()

# per tijdsstukje gemiddelde load, standaarddeviatie en standaarddeviate van het gemiddelde bepalen
DF2.summary <- DF2 %>% group_by(timecat) %>%
  summarize(loadmean = mean(load5),
            loadsd = sd(load5), 
            loadsd2 = sd(load5)/sqrt(length(load5)))


####### NIEUWE SAMENGEVOEGDE DATASET VAN DE GEMIDDELDES #######

# 1 dataset van maken. op tijdsgroep samengevoegd.
merged <- merge(DF1.summary, DF2.summary, by="timecat", all.x=TRUE, all.y=TRUE)
# timecat aanpassen om er eerst weer werkelijke seconden en dan maar direct minuten van te maken
merged$timecat <- merged$timecat * average_time/60

cols <- c("wl1" = "red", "wl2" = "blue")
shapes <- c("wl1" = 1, "wl2" = 2)
alpha <- c("wl1" = 0.5, "wl2" = 0.5)
# 2 eerdere grafieken in 1. 
ggplot(merged, aes(timecat)) +
  geom_point(aes(y= loadmean.x, shape="wl1")) + 
  geom_line(aes(y= loadmean.x, colour = "wl1")) +
  geom_errorbar(aes(ymin = (loadmean.x - loadsd2.x), ymax = (loadmean.x + loadsd2.x), colour="wl1", alpha="wl1")) +
  geom_point(aes(y= loadmean.y, shape="wl2")) + 
  geom_line(aes(y= loadmean.y, colour = "wl2")) +
  geom_errorbar(aes(ymin = (loadmean.y - loadsd2.y), ymax = (loadmean.y + loadsd2.y), colour="wl2", alpha="wl2")) + 
  xlab("minutes from start") + ylab("mean load") +
  scale_shape_manual(name = 'Workload', values = shapes) +
  scale_colour_manual(name = 'Workload', values = cols) +
  scale_alpha_manual(name = 'Workload', values = alpha)
