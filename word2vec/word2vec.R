library(dplyr)
library(ggplot2)
library(ggrepel)
library(plotly)
theme_set(theme_bw())

data_wv <- readr::read_csv("aligned_wv_pca.csv")
data_wv <- mutate(data_wv, src2 = ifelse(src == "weibo", "微博", "PTT"))

search_terms = strsplit("臺灣, 日本, 美國", ",")[[1]] %>% trimws()



#' words: free input
#' timesteps: multi-select
embed_viz <- function(search_terms, timesteps = 1:4) {
   data_wv %>% 
      filter(word %in% search_terms, timestep %in% timesteps) %>%
      group_by(word, src) %>%
      mutate(group = paste(word, src, sep="_")) %>%
      arrange(timestep) %>%
      ungroup() %>%
   ggplot(aes(PC1, PC2, color = src2, shape = word)) +
      geom_point() +
      geom_text_repel(aes(label = timestep)) +
      geom_path(arrow = arrow(angle = 20, type="closed", 
                              length = unit(0.1, "inches")), 
                alpha = 0.4) +
      scale_color_manual(values=c("#4B878BFF", "#D01C1FFF")) +
      theme(panel.grid.major = element_blank(),
            panel.grid.minor = element_blank(),
              legend.title = element_text(size = 10.5),
              legend.text = element_text(size = 10.5)
      ) +
      labs(color = "來源", shape = "詞彙")
}

