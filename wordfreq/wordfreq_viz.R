library(dplyr)
library(ggplot2)
theme_set(theme_bw())

all_files_freq <- readRDS("word_freq.RDS")

freq_viz <- function(words){
  
  matched <-  all_files_freq[all_files_freq$word %in% words, ]
  p <- ggplot(matched) +
    geom_bar(mapping = aes(x = timestep, y = freq, fill = src),
             stat = 'identity', position = "dodge") +
    scale_fill_manual(values=c("#4B878BFF", "#D01C1FFF")) +
    scale_x_discrete(breaks = seq(1, 9, by = 1))
  
  if (length(words) > 1) 
    p <- p + facet_wrap(vars(word), nrow = length(words))
  
  return(p)
}
