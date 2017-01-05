library(jsonlite)
library(ggplot2)
setwd("C:/Users/Johannes/Projects/results/output/201701042235")

workflows <- fromJSON("120.json", flatten = TRUE)
workflows$minuten <- workflows$delay / 60000
workflows$amount <- seq.int(nrow(workflows))

plot<-ggplot(workflows,aes(x=workflows$minuten,y=workflows$amount, ymax))
plot<-plot + geom_point(aes(colour=factor(workflows$type), shape=factor(workflows$type)))
plot<-plot + scale_y_continuous(limits = c(0, 120))
plot<-plot + labs(x = "Delay in minutes", y = "Amount of workflows in the system", shape="Type of workflows", colour="Type of workflows")
plot<-plot + theme(legend.position = c(0.15,0.85))
plot
dev.copy(win.metafile, "120.metafile")
dev.off()
