library(dplyr)
library(quanteda)
library(quanteda.textstats)
library(quanteda.textmodels)
library(quanteda.textplots)
library(tidyr)

lsa <- readRDS('data/lsa.rds')

lsa_df <- as_tibble(lsa, rownames = 'doc') %>%
  separate(doc, c('src', 'id', 'timestep')) %>%
  mutate(idx = row_number())

# <src>_<timestep>_<n>: single-select from 0-10
plot_network_shiny <- function(timesteps = 1:3, n = 10, src = c("weibo", "ptt")) {
   params <- rep(n, length(src) * length(timesteps))
   ts <- paste0("t", timesteps, "_n")
   ts <- paste(rep(src, each = length(timesteps)), ts, sep="_")
   names(params) <- ts
   params <- as.list(params)
   plt <- do.call(plot_network, params)
   print(plt)
}

plot_network <- function(weibo_t1_n = 0,
                         weibo_t2_n = 0,
                         weibo_t3_n = 0,
                         weibo_t4_n = 0,
                         weibo_t5_n = 0,
                         weibo_t6_n = 0,
                         weibo_t7_n = 0,
                         weibo_t8_n = 0,
                         weibo_t9_n = 0,
                         ptt_t1_n = 0,
                         ptt_t2_n = 0,
                         ptt_t3_n = 0,
                         ptt_t4_n = 0,
                         ptt_t5_n = 0,
                         ptt_t6_n = 0,
                         ptt_t7_n = 0,
                         ptt_t8_n = 0,
                         ptt_t9_n = 0) {
  idx <-
    c(
      sample(lsa_df[lsa_df$src == 'weibo' &
                      lsa_df$timestep == 'T1', ]$idx, weibo_t1_n),
      sample(lsa_df[lsa_df$src == 'weibo' &
                      lsa_df$timestep == 'T2', ]$idx, weibo_t2_n),
      sample(lsa_df[lsa_df$src == 'weibo' &
                      lsa_df$timestep == 'T3', ]$idx, weibo_t3_n),
      sample(lsa_df[lsa_df$src == 'weibo' &
                      lsa_df$timestep == 'T4', ]$idx, weibo_t4_n),
      sample(lsa_df[lsa_df$src == 'weibo' &
                      lsa_df$timestep == 'T5', ]$idx, weibo_t5_n),
      sample(lsa_df[lsa_df$src == 'weibo' &
                      lsa_df$timestep == 'T6', ]$idx, weibo_t6_n),
      sample(lsa_df[lsa_df$src == 'weibo' &
                      lsa_df$timestep == 'T7', ]$idx, weibo_t7_n),
      sample(lsa_df[lsa_df$src == 'weibo' &
                      lsa_df$timestep == 'T8', ]$idx, weibo_t8_n),
      sample(lsa_df[lsa_df$src == 'weibo' &
                      lsa_df$timestep == 'T9', ]$idx, weibo_t9_n),
      sample(lsa_df[lsa_df$src == 'ptt' &
                      lsa_df$timestep == 'T1', ]$idx, ptt_t1_n),
      sample(lsa_df[lsa_df$src == 'ptt' &
                      lsa_df$timestep == 'T2', ]$idx, ptt_t2_n),
      sample(lsa_df[lsa_df$src == 'ptt' &
                      lsa_df$timestep == 'T3', ]$idx, ptt_t3_n),
      sample(lsa_df[lsa_df$src == 'ptt' &
                      lsa_df$timestep == 'T4', ]$idx, ptt_t4_n),
      sample(lsa_df[lsa_df$src == 'ptt' &
                      lsa_df$timestep == 'T5', ]$idx, ptt_t5_n),
      sample(lsa_df[lsa_df$src == 'ptt' &
                      lsa_df$timestep == 'T6', ]$idx, ptt_t6_n),
      sample(lsa_df[lsa_df$src == 'ptt' &
                      lsa_df$timestep == 'T7', ]$idx, ptt_t7_n),
      sample(lsa_df[lsa_df$src == 'ptt' &
                      lsa_df$timestep == 'T8', ]$idx, ptt_t8_n),
      sample(lsa_df[lsa_df$src == 'ptt' &
                      lsa_df$timestep == 'T9', ]$idx, ptt_t9_n)
    )
  
  sum <- length(idx)
  
  sample_lsa <- lsa[idx,]
  doc_sim <-
    textstat_simil(as.dfm(sample_lsa), method = "cosine") %>% as.matrix()
  
  ## plotting
  textplot_network(as.dfm(doc_sim),
                   min_freq = 0.92,
                   edge_size = 0.6,
                   vertex_labelsize = 4.3)
}

#plot_network(10, 0, 10)

