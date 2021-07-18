library(dplyr)
source("functions.R")

TOPN = 80
MIN_COLLO_FREQ = 10

for (ts in c(1:9, "all")) {
  cat("Processing timestep:", ts, "...\n")
  
  d = read_collocation(ts = ts, min_freq = MIN_COLLO_FREQ)
  terms = unique(c(d$collo_1, d$collo_2))
  term_dist = lapply(terms, distr_summary, TOPN)
  term_dist = bind_rows(term_dist)
  
  fn = paste0("topn_collo_distr_", ts, ".rds")
  saveRDS(term_dist, file = file.path("data", fn))
}


# Similar terms to taiwan
library(ggplot2)
library(ggrepel)

fps = list.files("data", pattern = "topn_collo*", full.names = T)
term_dist = lapply(fps, function(fp) {
  ts = gsub("topn_collo_distr_", "", basename(fp))
  ts = gsub(".rds", "", ts)
  if (ts == "all") return(NULL)
  d = readRDS(fp) %>% mutate(timestep = as.integer(ts))
  return(d)
})
term_dist = dplyr::bind_rows(term_dist)
term_dist$timestep = factor(term_dist$timestep, ordered = T)
term_dist = term_dist %>%
  filter(grepl("^(大陸|臺灣|中國|日本|韓國|美國)$", seed))

term_dist_all = readRDS("data/topn_collo_distr_all.rds")%>%
  filter(grepl("^(大陸|臺灣|中國|日本|韓國|美國)$", seed))

term_dist %>%
  mutate(lab = paste0(seed, "_", timestep)) %>%
ggplot(aes(medianRankFront.weibo - medianRankBack.weibo,
           medianRankFront.ptt - medianRankBack.ptt,
           color=seed))+
   geom_hline(yintercept = 0, color = alpha("grey", 0.85)) +
   geom_vline(xintercept = 0, color = alpha("grey", 0.85)) + 
   geom_abline(slope=1, intercept = 0, linetype = "dashed", color = alpha("grey", 0.8)) +
   # geom_text(data = term_dist_all, 
   #           aes(label = seed), size = 3, color="black") +
   geom_point() +
   geom_text_repel(aes(label = lab), size = 2.7) +
   theme_minimal() +
   labs(x = "Weibo Back Tendency", y = "PTT Back Tendency",
        color = "Node Word")

# rank_diff_thres = 1
# IQR_thres = 5
# term_dist %>% 
#    filter(
#       (propFront.weibo == 1 & propFront.ptt < 1) |
#       (medianRankFront.weibo - medianRankBack.weibo < rank_diff_thres & 
#           medianRankFront.ptt - medianRankBack.ptt > rank_diff_thres &
#           IQRrankFront.weibo < IQR_thres & IQRrankBack.weibo < IQR_thres)
#       ) %>% 
#    View
