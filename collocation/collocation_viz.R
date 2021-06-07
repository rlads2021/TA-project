library(dplyr)
library(tibble)
library(ggplot2)
library(patchwork)
library(stringr)

all_colloc <- readRDS("./all_files_collocation_MI.RDS")

word <- "原則"

# filter for specific data and output a summary table
# can only search one word for a time
summary_tbl <- function(word, source = c("weibo", "ptt"), timesteps = c(1:3), count = 50) {
  # df for words at front
  front <- all_colloc %>% filter(collo_2 %in% word, src %in% source, timestep %in% timesteps, a > count) %>%
    select(-collo_2) %>% 
    rename(word = collo_1)
  # df for words at rear
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

colloc_to_plot <- summary_tbl(word = word, source = c("weibo", "ptt"), timesteps = c(1:5), count = 10)

# plot 
colloc_viz <- function(df) {
  # set group id to plot for every group 
  # (first by src, then by timestep)
  df <- df %>% bind_cols(gid = group_indices(df))
  
  # Add time step info
  timesteps <- gsub("_", " ~ ", readLines("./timesteps.txt"))
  timesteps <- gsub("-", "/", timesteps)
  timesteps <- gsub("2020", "20", timesteps)
  timesteps <- timesteps %>%
    str_replace_all("(\\d{2})/(\\d{2})/(\\d{2})", "\\2.\\3.\\1")
  # Replace facet label with timesteps
  ts <- rep(timesteps[unique(df$timestep)], n_distinct(df$src))
  names(ts) <- group_keys(df)$timestep

  N <-  n_groups(df)
  lst <- vector("list", N)
  # plot by (src, timestep) for every i, 
  for (i in 1:N) {
    p <- ggplot(data = filter(df, gid %in% i)) +
      geom_bar(aes(x = reorder(word, MI), y = MI, fill = frontness), stat = "identity") +
      facet_grid(src ~ timestep, labeller = labeller(timestep = ts[i])) + 
      theme(axis.title.x = element_blank(), 
            axis.title.y = element_blank()) +
      labs(fill = "located at") +
      coord_flip()
    # then save all plots in a list 
    lst[[i]] <- p
  }
  
  # assembling all plots on a graph
  patched <- wrap_plots(lst, nrow = 2, byrow = TRUE) + 
    plot_annotation(title = paste0("Collocation of \"", word, "\""),
                    subtitle = "Sort by Mutual Information (MI) Score") + 
    plot_layout(guides = "collect")

  return(patched)
}

colloc_viz(colloc_to_plot)