library(readr)
library(stringr)
library(dplyr)
library(ggplot2)

setwd("../data/time_sliced_collapsed")

freq_viz <- function(words){
  
  all_files <- list.files()
  
  count_freq <- function(article){
    # read file
    article_name <- str_remove(article, '.txt')
    content <- readLines(article, encoding = 'UTF-8')
    words <- unlist(strsplit(content, '\u3000'))
    
    # word freq
    words_freq<-table(unlist(words))
    num_of_tokens <- length(unique(words))
    
    # build word freq df
    words_freq_df <- as.data.frame(cbind(names(words_freq),
                                         as.integer(words_freq)/num_of_tokens))
    colnames(words_freq_df) <- c('word', 'freq')
    words_freq_df$src <- strsplit(article_name, '_')[[1]][1]
    words_freq_df$timestamp <- strsplit(article_name, '_')[[1]][2]
    return(words_freq_df)
  }
  
  all_files_freq <- bind_rows(lapply(all_files, function(x)(count_freq(x))))
  
  # filter matched words' data
  matched <- all_files_freq %>%
    filter(word %in% words)
  
  # visualization
  p <- ggplot(data=matched) +
    geom_bar(mapping = aes(x = timestamp, y = freq, fill = src),
             stat = 'identity', position = "dodge") +
    facet_wrap(vars(word))
  
  return(p)
}
