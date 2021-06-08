library(dplyr)
library(tibble)
library(ggplot2)
library(patchwork)
library(stringr)

all_colloc <- readRDS("../data/all_files_collocation.rds")


summary_tbl <- function(word, source = c("weibo", "ptt"), timesteps = c(1:3), count = 50) {
  
  # tbl for words at front
  front <- all_colloc %>% filter(collo_2 %in% word, src %in% source, timestep %in% timesteps, a > count) %>%
    select(-collo_2) %>% 
    rename(word = collo_1)
  
  # tbl for words at rear
  back <- all_colloc %>% filter(collo_1 %in% word, src %in% source, timestep %in% timesteps, a > count) %>% 
    select(-collo_1) %>% 
    rename(word = collo_2)
  
  # summary table
  tbl <- bind_rows("front" = front, "back" = back, .id = "frontness") %>% 
    group_by(src, timestep) %>% 
    # select only top 10 MI score 
    slice_max(MI, n = 10) %>% 
    rename(count = a)
  
  return(tbl)
}

plot_single <- function(word, source, timestep, n = 10) {
    d <- summary_tbl(word, timesteps = timestep) %>%
        filter(src == source)
    # Create fake data if empty
    if (nrow(d) == 0)
        d <- data.frame(word = rep("", n),
                        MI = 0,
                        count = 0,
                        src = source,
                        timestep = timestep,
                        frontness = c("back", "front"),
                        stringsAsFactors = F)
    
    ggplot(d) +
        geom_bar(aes(reorder(word, MI), MI, 
                     fill = frontness), stat = "identity") +
        facet_grid(src ~ timestep) +
        coord_flip()
}


plot_src <- function(word = "新聞", source = "ptt", timesteps=1:5) {
    patched <- lapply(timesteps, function(ts) plot_single(word, source, ts))
    patched <- wrap_plots(patched, nrow = 1, byrow = TRUE)
    return(patched)
}


colloc_viz <- function(word, timesteps=1:5) {
  patched <- list(
      plot_src(word, "ptt", timesteps),
      plot_src(word, "weibo", timesteps)
  )
  
  # assembling all plots on a graph
  patched <- wrap_plots(patched, nrow = 2, byrow = TRUE) + 
    plot_annotation(title = paste0("Collocation of \"", word, "\""),
                   subtitle = "Sort by Mutual Information (MI) Score") +
    plot_layout(guides = "collect")

  return(patched)
}

#' Usage:
#' colloc_viz("新聞", 1:5)
