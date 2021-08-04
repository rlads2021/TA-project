#' ---
#' title: "Topic Drift of 臺灣"
#' output: 
#'   html_document:
#'     toc: true
#'     toc_float: true
#'     number_sections: true
#' ---

#+ include=FALSE, fig.width=7
knitr::opts_chunk$set(
  echo = TRUE,
  message = FALSE,
  warning = FALSE,
  out.width = "100%",
  fig.dim = c(8, 6),
  dpi = 300
)


require(dplyr)
require(tidyr)
require(ggplot2)
ggplot2::theme_set(theme_bw())

source("functions.R")

collo <- readr::read_csv("country_collocates.csv")

#' # Left collocates topical drift
tp_left <- collo #%>% filter(collo_pos == "left") 

#' ## Topic contrast (PTT vs. Weibo)
#+ fig.dim=c(8, 3.5)
d <- tp_left %>% 
    group_by(src, collo) %>%
    summarise(count = sum(count)) %>%
    ungroup()

distr <- sapply(c("ptt", "weibo"), function(source) {
  d2 <- d %>% filter(src == source)
  terms <- d2$collo
  distr <- sapply(seq_along(terms), function(i) {
          d2$count[i] * beta_vec(terms[i])
      }) %>%
      apply(1, function(col) sum(col) / sum(d2$count))
  return(normalize(distr))
})

topic_labs <- rownames(distr)
distr %>% 
  as_tibble() %>% 
  mutate(topic = topic_labs) %>%
  gather(key = "src", value = "y", ptt, weibo) %>%
ggplot() +
  geom_bar(aes(topic, y, fill = src),
           stat = "identity", position = "dodge") +
  facet_wrap(vars(src), ncol = 2) +
  coord_flip() +
  scale_fill_manual(values = c("ptt" = "#00BFC4", "weibo" = "#F8766D")) +
  theme(legend.position = "none") +
  # axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Topic", y = "Percent")


#' ## Topic drift across time (PTT)
# scales::hue_pal()(4)
get_distr <- function(source, ts, pos = c("left", "right")) {
  d <- collo %>% 
    filter(collo_pos %in% pos, 
           timestep %in% ts,
           src == source) %>%
    group_by(collo) %>%
    summarise(count = sum(count)) %>%
    ungroup()
  
  terms <- d$collo
  distr <- sapply(seq_along(terms), function(i) {
          d$count[i] * beta_vec(terms[i])
      }) %>%
      apply(1, function(col) sum(col) / sum(d$count))
  return(normalize(distr))
}

ptt_ts_distr <- sapply(1:9, function(ts) 
  get_distr("ptt", ts))

ptt_ts_distr %>%
  as_tibble() %>%
  mutate(topic = topic_labs) %>%
  gather(key = "timestep", value = "y", -topic) %>%
  mutate(timestep = gsub("V", "", timestep, fixed = T)) %>%
  mutate(timestep = factor(as.integer(timestep, order = T))) %>%
  ggplot() +
  geom_bar(aes(topic, y), 
           stat = "identity",
           fill = "#00BFC4") +
  facet_wrap(vars(timestep), nrow = 2) +
  coord_flip() +
  theme(axis.text.x = element_text(angle = 90)) +
  scale_y_continuous(labels = scales::percent) +
  labs(y = "Percent", x = "")

#' ## Topic drift across time (Weibo)
wei_ts_distr <- sapply(1:9, function(ts) 
  get_distr("weibo", ts))

wei_ts_distr %>%
  as_tibble() %>%
  mutate(topic = topic_labs) %>%
  gather(key = "timestep", value = "y", -topic) %>%
  mutate(timestep = gsub("V", "", timestep, fixed = T)) %>%
  mutate(timestep = factor(as.integer(timestep, order = T))) %>%
  ggplot() +
  geom_bar(aes(topic, y), 
           stat = "identity",
           fill = "#F8766D") +
  facet_wrap(vars(timestep), nrow = 2) +
  coord_flip() +
  scale_y_continuous(labels = scales::percent) +
  theme(axis.text.x = element_text(angle = 90)) +
  labs(y = "Percent", x = "")


#' # Topic variation across time
euc_dist <- function(x, y) sqrt(sum((x - y)^2))
cos_dist <- function(x, y) 1 - (x %*% y) / sqrt(sum(x^2) * sum(y^2)) 
cos_sim <- function(x, y) (x %*% y) / sqrt(sum(x^2) * sum(y^2)) 

#' ## Within src
#+ fig.dim=c(8, 3)
topic_dist <- sapply(c("ptt", "weibo"), function(src) {
    topic_distr <- sapply(1:9, function(ts) get_distr(src, ts, "left"))
    #mean_distr <- rep(mean(topic_distr[, 1]), nrow(topic_distr))
    mean_distr <- apply(topic_distr, 1, mean)
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
  ptt <- get_distr("ptt", ts)
  wei <- get_distr("weibo", ts)
  cos_sim(ptt, wei)
})

data.frame(
  ts = factor(1:9, ordered = T),
  similarity = topic_distr_contrast) %>% 
  ggplot() +
  geom_line(aes(ts, similarity, group=1)) +
  labs(y = "Similarity",
       x = "Time")
