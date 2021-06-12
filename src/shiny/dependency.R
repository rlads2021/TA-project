library(dplyr)
library(ggplot2)

#dependency_df <- readr::read_csv('data/dependency.csv') %>%
#   mutate(timestep = gsub("t", "", timestep) %>% as.integer)
#saveRDS(dependency_df, "data/dependency.rds")
dependency_df <- readRDS("data/dependency.rds")

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
    scale_fill_manual(values = c("#4B878BFF", "#D01C1FFF")) +
    facet_wrap(~timestep, scales = 'free') +
    coord_flip() +
    labs(x = 'Collacating Verbs',
         y = 'Frequency',
         title = paste0('Collacating Verbs of "', word, '"'))
}

# dependency_viz('臺灣', 1:9)
