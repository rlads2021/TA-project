library(dplyr)
library(ggplot2)

data_wv <- readr::read_csv("data/keyterms.pca.csv")
data_wv$anno <- with(data_wv, paste0(word, "_T", timestep))
data_wv <- mutate(data_wv, src2 = ifelse(src == "weibo", "微博", "PTT"))


#' words: multi-select
#' timesteps: multi-select
#' source: checkbox
embed_viz <- function(words, timesteps= 0:3, 
                      source = c("weibo", "ptt")) {
   
   data_wv %>%
      filter(word %in% words, 
             timestep %in% timesteps,
             src %in% source) %>%
   ggplot(aes(PC1, PC2)) + 
      geom_text(aes(label = anno, color = src2), size = 3.5) +
      scale_color_manual(values=c("#4B878BFF", "#D01C1FFF")) +
      theme(panel.grid.major = element_blank(),
            panel.grid.minor = element_blank(),
              legend.title = element_text(size = 10.5),
              legend.text = element_text(size = 10.5)
      ) +
      labs(color = "來源")
}


