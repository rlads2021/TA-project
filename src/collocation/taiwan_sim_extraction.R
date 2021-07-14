TOPN = 50
MIN_COLLO_FREQ = 15

library(dplyr)
d = readRDS("data/collocation_merged.rds")

# Get unique terms
d = d %>% 
   filter(!grepl("[a-zA-Z0-9_-]", collo_1),
          !grepl("[a-zA-Z0-9_-]", collo_2),
          a > MIN_COLLO_FREQ) %>%
   select(-timestep)
terms = unique(c(d$collo_1, d$collo_2))

term_dist = lapply(terms, function(term) {
    dt = filter(d, term == collo_1 | term == collo_2) %>% 
       mutate(isFront = term == collo_2) %>%
       group_by(src) %>%
       top_n(TOPN, MI) %>%
       mutate(rank = rank(desc(MI), ties.method = "average"))
    
    # front/back collocate 
    dt1 = filter(dt, src == "ptt")
    dt2 = filter(dt, src == "weibo")
    if (nrow(dt1) == 0 | nrow(dt2) == 0) return(NULL)
       
    NA_REPLACE = nrow(dt1) + nrow(dt2)
    stats = vector("numeric", 13)
    idx = 1
    for (data in list(dt1, dt2)) {
      isF = data$isFront
      rank = data$rank
      
      stats[idx + 1] = mean(isF)
      stats[idx + 2] = 1 - mean(isF)
      
      if (sum(isF) != 0) {
         stats[idx + 3] = median(rank[isF])
         stats[idx + 5] = IQR(rank[isF])
      } else {
         stats[idx + 3] = NA_REPLACE
         stats[idx + 5] = NA_REPLACE
      }
      if (mean(isF) != 1) {
         stats[idx + 4] = median(rank[!isF])
         stats[idx + 6] = IQR(rank[!isF])
      } else {
         stats[idx + 4] = NA_REPLACE
         stats[idx + 6] = NA_REPLACE
      }
      
      idx = idx + 6
    }  
    nm = "seed propFront.ptt propBack.ptt medianRankFront.ptt 
    medianRankBack.ptt IQRrankFront.ptt IQRrankBack.ptt 
    propFront.weibo propBack.weibo medianRankFront.weibo 
    medianRankBack.weibo IQRrankFront.weibo IQRrankBack.weibo"
    names(stats) = strsplit(nm, "\\s+")[[1]]
    stats = as.list(stats)
    stats[["seed"]] = term
    return(stats)
})

term_dist = bind_rows(term_dist)
#head(term_dist, 100) %>% View


# Similar terms to taiwan
library(ggplot2)

ggplot(term_dist) +
   geom_hline(yintercept = 0, color = alpha("grey", 0.8)) +
   geom_vline(xintercept = 0, color = alpha("grey", 0.8)) + 
   geom_text(
      aes(x = medianRankFront.weibo - medianRankBack.weibo,
          y = medianRankFront.ptt - medianRankBack.ptt,
          label = seed), size = 2.5) +
   theme_minimal()

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
