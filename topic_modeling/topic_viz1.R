library(ggplot2)
library(dplyr)
library(reshape2)

doc_dtm_group<-readRDS(file = "doc_dtm_group.rds")
top5termsPerTopic<-readRDS("top5termsPerTopic.rds")
topicNames<- readRDS("topicNames.rds")
theta<-readRDS("theta.rds")

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
  zerodf <- data.frame (time  = as.character (seq(1,9)), x=0)
  add_zero <- anti_join(zerodf, topic_proportion_per_time, by ="time")
  topic_proportion_per_time <- rbind(topic_proportion_per_time,add_zero)      
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
