library(reshape2)
library(ggplot2)
library(showtext)
library(tidytext)
library(dplyr)
library(tidyverse)
library(tidyr)
doc_dtm_group<-readRDS(file = "/doc_dtm_group.rds")
top5termsPerTopic<-readRDS("/top5termsPerTopic.rds")
topicNames<- readRDS("/topicNames.rds")
theta<-readRDS("/theta.rds")

topic_viz <- function(word,topicThreshold,sources){
  topicToFilter <- grep(word, topicNames)  
  topicThreshold <- 0.2
  selected <- list()
  for (i in seq(1, length(topicToFilter))){
    selected[[i]] <- which(theta[, topicToFilter[i]] >= topicThreshold)  
  }
  #get time label
  #exampleIds <- selectedDocumentIndexes
  exampleIds <- unique(unlist(selected))  
  K = length(topicNames [topicToFilter])  
  sources_filter <- doc_dtm_group[exampleIds,] %>% filter(group ==sources) 
  
  topic_proportion_per_time <- aggregate(theta[sources_filter$ID,topicToFilter], by = list(time = sources_filter$time), mean)
        
  # set topic names to aggregated columns
  colnames(topic_proportion_per_time)[2:(K+1)] <- topicNames [topicToFilter]  
  # reshape data frame
  vizDataFrame <- melt(topic_proportion_per_time, id.vars = "time")
  # plot topic proportions per decade as bar plot
  # Make plots wider 
  options(repr.plot.width=30, repr.plot.height=20)
  showtext_auto()
  p<- ggplot(vizDataFrame, aes(x=time, y=value, colour = variable, group = variable)) + 
    geom_point() + geom_line(size = 3) + 
    scale_fill_manual(values = paste0(alphabet(K), "FF"), name = "Topic") +  
    theme(text = element_text(size=25),axis.title=element_text(size=24,face="bold"),axis.text.x = element_text(angle = 90, hjust = 1))
  
  
  
  return(p)
}
