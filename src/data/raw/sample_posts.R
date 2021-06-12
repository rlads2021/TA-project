# For documentation, see post_freq.Rmd or https://rlads2021.github.io/TA-project/post_freq.html

START_DATE = "2020-05-01" 
END_DATE = "2020-10-01"
TS_NUM = 9  # Number of time steps

library(dplyr)
library(tidyr)
library(ggplot2)
theme_set(theme_bw())

ptt <- readr::read_csv("ptt_full.csv")
wei <- readr::read_csv("weibo_full.csv")

# Set time step splits
date_filter <- c(as.Date(START_DATE), as.Date(END_DATE))
start <- seq(date_filter[1], date_filter[2], length.out = TS_NUM + 1)
end <- (start - 1)
rng <- vector("list", length(start) - 1)
for (i in seq_along(start)) {
   if (i == length(start)) break
   rng[[i]] = c(start[i], end[i + 1])
}

get_ts <- function(dates) {
   sapply(dates, function(x) get_ts_atom(x))
}
get_ts_atom <- function(date) {
   for (ts in seq_along(rng)) {
      if (between(date, rng[[ts]][1], rng[[ts]][2]))
         return(ts)         
   }
   warning(date, " not in defined timesteps!")
   return(NULL)
}
count_tokens <- function(x) sapply(strsplit(x, '\u3000'), function(x) length(x))

# Sample PTT posts
set.seed(100)
ptt <- ptt %>% 
   filter(between(date, date_filter[1], date_filter[2] - 1)) %>%
   mutate(ts = get_ts(date)) %>%
   group_by(ts) %>%
   sample_n(size = 3500) %>%
   ungroup() %>%
   select(id, ts, text)
ptt$id <- seq_along(1:nrow(ptt))

# Filter weibo posts
wei <- wei %>% 
   filter(between(date, date_filter[1], date_filter[2] - 1)) %>%
   mutate(ts = get_ts(date)) %>%
   select(id, ts, text)
wei$id <- seq_along(1:nrow(wei))

# Export data
readr::write_csv(ptt, "ptt_sampled.csv")
readr::write_csv(wei, "weibo_sampled.csv")
writeLines(sapply(rng, function(x) paste0(x[1],"_",x[2])), "../timesteps.txt")
