library(dplyr)
library(ggplot2)
library(stringr)


all_files_freq <- readRDS("data/word_freq.RDS")


freq_viz <- function(words){
  
  matched <-  all_files_freq[all_files_freq$word %in% words, ]
  p <- ggplot(matched) +
    geom_bar(mapping = aes(x = timestep, y = freq, fill = src),
             stat = 'identity', position = "dodge") +
    scale_fill_manual(values=c("#4B878BFF", "#D01C1FFF")) +
    scale_x_discrete(breaks = seq_along(timesteps)) +
    theme(
      text = element_text(size=14),
      axis.text.x = element_text(#angle = 50, 
                                 #vjust = 0.5, 
                                 #hjust = 1,
                                 size = 11.5)
    ) +
    labs(x = "時間", y = "頻率 (每百萬詞)")
  
  if (length(words) > 1) 
    p <- p + facet_wrap(vars(word), nrow = length(words), scales = "free_y")
  
  return(p)
}
