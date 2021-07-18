read_collocation <- function(ts, min_freq) {
    if (ts == "all") {
        d = readRDS("data/collocation_merged.rds")
        d = d %>% 
           filter(!grepl("[a-zA-Z0-9_-]", collo_1),
                  !grepl("[a-zA-Z0-9_-]", collo_2),
                  a > min_freq) %>%
           select(-timestep)
    } else {
        d = readRDS("data/all_files_collocation.rds")
        d = d %>% 
           filter(!grepl("[a-zA-Z0-9_-]", collo_1),
                  !grepl("[a-zA-Z0-9_-]", collo_2),
                  a > min_freq,
                  timestep == ts) %>%
           select(-timestep)
    }
    return(d)
}



distr_summary <- function(term, topn) {
    dt = filter(d, term == collo_1 | term == collo_2) %>% 
       mutate(isFront = term == collo_2) %>%
       group_by(src) %>%
       top_n(topn, MI) %>%
       mutate(rank = rank(MI, ties.method = "average"))
    
    # front/back collocate 
    dt1 = filter(dt, src == "ptt")
    dt2 = filter(dt, src == "weibo")
    if (nrow(dt1) == 0 | nrow(dt2) == 0) return(NULL)
       
    NA_REPLACE = 0
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
}