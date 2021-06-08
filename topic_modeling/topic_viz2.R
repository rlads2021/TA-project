library(broom)
library(tm)
library(topicmodels)
library(reshape2)
library(ggplot2)
library(pals)
library(showtext)
library(tidytext)
library(stm)
library(dplyr)
library(quanteda.textstats)
library(tidyverse)
library(tidyr)
library(quanteda)
doc_dtm_group<-readRDS(file = "/doc_dtm_group.rds")
searchterms<- readRDS("/searchterms.rds")
top5termsPerTopic<-readRDS("/top5termsPerTopic.rds")
topicNames<- readRDS("/topicNames.rds")
theta<-readRDS("/theta.rds")

topic_viz_2 <- function(word,topicThreshold,sources){
  topicToFilter <- grep(word, searchterms) #search terms是所有文章資料有斷出的詞彙來找
  topicThreshold <- 0.2
  selected <- list()
  for (i in seq(1, length(topicToFilter))){
    selected[[i]] <- which(theta[, topicToFilter[i]] >= topicThreshold)  
  }
  #get time label
  #exampleIds <- selectedDocumentIndexes
  exampleIds <- unique(unlist(selected))  
  K = length(topicNames [topicToFilter])  
  #doc_dtm$time <- substr(doc_dtm$doc_id,nchar(doc_dtm$doc_id),nchar(doc_dtm$doc_id)) PTT這邊已經有惹 time 了不用再做 
  # get mean topic proportions per decade
  
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
    geom_point() + geom_line(size = 3) 
    
  
  
  
  return(p)
}

