#' ---
#' title: "Topic Drift of 臺灣"
#' output: 
#'   html_document:
#'     toc: true
#'     toc_float: true
#'     number_sections: true
#' ---

#+ include=FALSE
knitr::opts_chunk$set(
  echo = TRUE,
  message = FALSE,
  warning = FALSE,
  out.width = "100%",
  fig.dim = c(8, 4),
  dpi = 300
)


require(dplyr)
require(tidyr)
require(ggplot2)
ggplot2::theme_set(theme_bw())

cluster <- readr::read_csv("cluster_labels2.csv") %>%
  mutate(src = if_else(src == "wei", "weibo", src))
collo <- readr::read_csv("country_collocates.csv") %>%
  left_join(cluster, 
            by = c("collo" = "collocate", "src" = "src")) %>%
  mutate(cluster2 = factor(cluster),
         cluster = factor(labels))
  # mutate(cluster = if_else(is.na(cluster), 
  #                          if_else(src == "ptt", -1, -2), 
  #                          cluster),
  #        cluster = factor(as.integer(cluster)))


#' # Collocates topical drift (left + right)
tp_left <- collo %>%
  filter(!is.na(cluster)) %>%
  group_by(src, timestep, cluster) %>%
  summarise(count = n()) %>% ungroup() %>%
  arrange(timestep, src, cluster) %>% 
  group_by(src, timestep) %>%
  mutate(total_count = sum(count)) %>% ungroup()

#' ## Topic contrast (PTT vs. Weibo)
#+ fig.dim=c(8, 3.2)
tp_left %>%
  group_by(src, cluster) %>% 
  summarise(count = sum(count)) %>%
  ungroup() %>% group_by(src) %>%
  mutate(total_count = sum(count)) %>%
  ungroup() %>% 
  # filter(!cluster %in% c(-1, -2)) %>%
ggplot() +
  geom_bar(aes(cluster, count/total_count, fill = src),
           stat = "identity", position = "dodge") +
  scale_y_continuous(labels = scales::percent) +
  facet_wrap(vars(src), ncol = 2) +
  scale_fill_manual(values = c("ptt" = "#00BFC4", "weibo" = "#F8766D")) +
  theme(legend.position = "none") +
  coord_flip() +
  labs(x = "Cluster", y = "Percent")

#' ## Topic drift across time (PTT)
# scales::hue_pal()(4)
tp_left %>% 
  filter(src == "ptt") %>%
  ggplot() +
  geom_bar(aes(cluster, count/total_count), 
           stat = "identity",
           fill = "#00BFC4") +
  facet_wrap(vars(timestep), nrow = 2) +
  coord_flip() +
  scale_y_continuous(labels = scales::percent) +
  theme(axis.text.x = element_text(angle = 90)) +
  labs(y = "Percent", x ="")

#' ## Topic drift across time (Weibo)
tp_left %>% 
  filter(src == "weibo", !cluster %in% c(-1, -2)) %>%
  ggplot() +
  geom_bar(aes(cluster, count/total_count), 
           stat = "identity",
           fill = "#F8766D") +
  facet_wrap(vars(timestep), nrow = 2) +
  coord_flip() +
  theme(axis.text.x = element_text(angle = 90)) +
  scale_y_continuous(labels = scales::percent) +
  labs(y = "Percent", x ="")


#' # Topic variation across time
vectorize_topic_distr <- function(source, ts) {
  vec <- tp_left %>% 
    filter(timestep == ts, src == source) %>% 
    select(cluster, count)
  
  clusters <- as.character(tp_left$cluster)
  for (clust in clusters) {
    if (!clust %in% vec$cluster) vec <- rbind(vec, c(clust, 0))
  }
  
  vec <- vec %>% arrange(cluster)
  return(norm_dist(as.integer(vec$count)))
}
euc_dist <- function(x, y) sqrt(sum((x - y)^2))
cos_dist <- function(x, y) 1 - (x %*% y) / sqrt(sum(x^2) * sum(y^2)) 
cos_sim <- function(x, y) (x %*% y) / sqrt(sum(x^2) * sum(y^2)) 
norm_dist <- function(x) x / sum(x)

#' ## Within src
#+ fig.dim=c(8, 3)
topic_dist <- sapply(c("ptt", "weibo"), function(src) {
    topic_distr <- sapply(1:9, function(ts) vectorize_topic_distr(src, ts))
    #mean_distr <- rep(mean(topic_distr[, 1]), nrow(topic_distr))
    mean_distr <- norm_dist(apply(topic_distr, 1, sum))
    topic_dist <- apply(topic_distr, 2, function(col) {
      cos_dist(col, mean_distr)
    })
    return(topic_dist)
  }
)

data.frame(ts = factor(1:9, ordered = T)) %>% 
  cbind(topic_dist) %>%
  gather(key = "src", value = "distance", ptt, weibo) %>%
ggplot() +
  geom_line(aes(ts, distance, color = src, group = src, linetype=src)) +
  scale_color_manual(values = c("ptt" = "#00BFC4", "weibo" = "#F8766D")) +
  labs(y = "Distance to mean distribution",
       x = "Time")

#' ## Between src
topic_distr_contrast <- sapply(1:9, function(ts) {
  ptt <- vectorize_topic_distr("ptt", ts)
  wei <- vectorize_topic_distr("weibo", ts)
  cos_sim(ptt, wei)
})

data.frame(
  ts = factor(1:9, ordered = T),
  similarity = topic_distr_contrast) %>% 
  ggplot() +
  geom_line(aes(ts, similarity, group=1)) +
  labs(y = "Similarity", x = "Time")
