library(tidyverse)

dependency_df <- read_csv('data/dependency.csv') 

# word: single-select from c('台灣', '美國', '中國')
# timesteps: multi-select
# sources: checkbox

dependency_viz <- function(word,
                           timesteps,
                           sources = c('weibo', 'ptt')) {
  matched <- dependency_df %>%
    filter(keyword == word,
           timestep %in% timesteps,
           src %in% sources) %>%
    arrange(-freq) %>%
    group_by(timestep, src) %>%
    slice(1:10)
  
  ggplot(matched, aes(reorder(verb, freq), freq)) +
    geom_col(aes(fill = src), position = 'dodge') +
    facet_wrap(~timestep, scales = 'free') +
    coord_flip() +
    labs(x = 'Collacating Verbs',
         y = 'Frequency',
         title = paste0('Collacating Verbs of "', word, '"'))
}


dependency_viz('臺灣', c('t1', 't2', 't3', 't4'))
