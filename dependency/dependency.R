library(tidyverse)

dependency_df <- read_csv('data/dependency.csv') 

# word: single-select from c('台灣', '美國', '中國')
# timesteps: multi-select
# sources: checkbox

plot <- function(word,
                 timesteps,
                 sources = c('weibo', 'ptt')) {
  matched <- dependency_df %>%
    filter(keyword == word,
           timestep %in% timesteps,
           src %in% sources) %>%
    group_by(src, timestep) %>%
    arrange(-freq) %>%
    top_n(10)
  
  ggplot(matched, aes(reorder(verb, freq), freq)) +
    geom_col(aes(fill = src), position = 'dodge') +
    facet_wrap(~timestep, scales = 'free') +
    coord_flip() +
    xlab('Dependency Verbs') +
    ylab('Frequency')
}


plot('臺灣', c('t1', 't2', 't3', 't4'))
