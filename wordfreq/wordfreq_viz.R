library(readr)
library(dplyr)
library(ggplot2)

all_files_freq <- read.csv('all_files_freq.csv')

freq_viz <- function(words){
  # filter matched words' data
  matched <- all_files_freq %>%
    filter(word %in% words)
  
  # visualization
  p <- ggplot(data=matched) +
    geom_bar(mapping = aes(x = timestamp, y = freq, fill = src),
             stat = 'identity', position = "dodge") +
    scale_x_continuous(breaks = seq(from = min(matched$timestamp), to = max(matched$timestamp), by = 1)) +
    facet_wrap(vars(word))
  return(p)
}
