library(reshape2)
library(ggplot2)
library(dplyr)

doc_dtm_group<-readRDS(file = "data/doc_dtm_group.rds")
searchterms<- readRDS("data/searchterms.rds")
#top5termsPerTopic <-readRDS("data/top5termsPerTopic.rds")
topicNames<- readRDS("data/topicNames.rds")
theta <- readRDS("data/theta.rds")


#本機上這樣跑比較好看
topic_viz <- function(word, sources){
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
  sources_filter <- doc_dtm_group[exampleIds,] %>% filter(group == sources) 
  
  topic_proportion_per_time <- aggregate(theta[sources_filter$ID,topicToFilter], by = list(time = sources_filter$time), mean)
        
  # set topic names to aggregated columns
  colnames(topic_proportion_per_time)[2:(K+1)] <- topicNames [topicToFilter]  
  # reshape data frame
  vizDataFrame <- melt(topic_proportion_per_time, id.vars = "time")
  # plot topic proportions per decade as bar plot
  # Make plots wider 
  options(repr.plot.width=30, repr.plot.height=20)
  #showtext_auto()
  p <- ggplot(vizDataFrame, aes(x=time, y=value, 
                                colour = variable, 
                                group = variable)) + 
    geom_point() + geom_line(size = 1, alpha = 0.55) +
    labs(colour = "主題",  y = "比例", x = "時間",
         title = paste0(
           ifelse(sources == "ptt", "PTT ", "微博"),
           "文章主題關鍵詞含有「", word , "」之文章主題比例分佈")
    )
    
  return(p)
}
#' Usage: 
#' topic_viz("臺灣", "ptt")
#' topic_viz("臺灣", "wei")


topic_viz2 <- function(word, sources){
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
  p<- ggplot(vizDataFrame, aes(x=time, y=value, colour = variable, group = variable)) + 
    geom_point() + geom_line(size = 1, alpha = 0.55) +
    labs(colour = "主題",  y = "比例", x = "時間",
         title = paste0(
           ifelse(sources == "ptt", "PTT ", "微博"),
           "內文含有「", word , "」之文章主題比例分佈")
    )
    
  return(p)
}
#' Usage: 
#' topic_viz2("臺灣", "ptt")
#' topic_viz2("臺灣", "wei")

