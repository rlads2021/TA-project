library(dplyr)
library(ggplot2)
library(ggrepel)
library(plotly)
theme_set(theme_bw())

data_wv <- readr::read_csv("aligned_wv_pca.csv")
data_wv <- mutate(data_wv, src2 = ifelse(src == "weibo", "微博", "PTT"))

#' words: free input
#' timesteps: multi-select
embed_viz <- function(search_terms, timesteps = 1:4) {
   d <- data_wv %>% 
      filter(word %in% search_terms, timestep %in% timesteps) %>%
      group_by(word, src) %>%
      mutate(group = paste(word, src, sep="_")) %>%
      arrange(timestep) %>%
      ungroup()
   
   # Compute centroid for text
   centroid <- d %>% 
      group_by(word, src2) %>%
      summarise(PC1 = mean(PC1), PC2 = mean(PC2)) %>%
      ungroup()
   
   ggplot(d, aes(PC1, PC2, color = src2, linetype = word, shape = word)) +
      geom_point() +
      geom_text_repel(data = centroid, 
                aes(PC1, PC2, label = word), 
                alpha = 0.6, size = 3.5) +
      geom_text_repel(aes(label = timestep)) +
      geom_path(arrow = arrow(angle = 20, type="closed", 
                              length = unit(0.1, "inches")), 
                alpha = 0.5) +
      scale_color_manual(values=c("#4B878BFF", "#D01C1FFF")) +
      theme(panel.grid.major = element_blank(),
            panel.grid.minor = element_blank(),
              legend.title = element_text(size = 10.5),
              legend.text = element_text(size = 10.5)
      ) +
      labs(color = "來源", shape = "詞彙") +
      guides(linetype=FALSE) 
}
#' search_terms = strsplit("臺灣, 日本", ",")[[1]] %>% trimws()
#' embed_viz(search_terms)
 

# Query Most similar words
most_simil <- function(word, time, src, topn = 10) {
  wv <- read_wv(time, src)
  word <- wv[word, ]
  siml <- apply(wv, 1, function(row) cossim(row, word))
  return(sort(siml, decreasing = T)[2:(topn + 1)])
}

read_wv <- function(time = 1, src = "ptt", dir = "model_export_rds/") {
  readRDS(paste0(dir, src, "_", time, ".RDS"))  
}

cossim <- function(x1, x2)
  sum(x1 * x2) / sqrt( sum(x1^2) * sum(x2^2) )

