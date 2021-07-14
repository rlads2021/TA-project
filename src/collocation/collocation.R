library(readr)
library(stringr)
library(dplyr)
library(quanteda)
library(quanteda.textstats)
library(tibble)

#read files
all_files <- list.files("../data/time_sliced_collapsed", full.names = T)

collocate <- function(article) {
  
  # read data and merge all posts
  contents <- paste(readLines(article, encoding = "UTF-8"), collapse = " ")
  
  # tokenize
  tok_con <- tokenizers::tokenize_regex(contents, pattern = "\u3000") %>% 
    tokens(remove_punct = T, remove_symbols = T, remove_url = T) %>% 
    tokens_remove(pattern = stopwords("zh", "misc"))

  # computing collocations
  collo_df <- tok_con %>% 
    textstat_collocations(size = 2, min_count = 10) %>% 
    as_tibble() %>% 
    select(collocation, count) 
  
  # split collocation for further searching
  collo_df$collo_1 <- sapply(collo_df$collocation, function(x) strsplit(x, " ")[[1]][1], USE.NAMES = F)
  collo_df$collo_2 <- sapply(collo_df$collocation, function(x) strsplit(x, " ")[[1]][2], USE.NAMES = F)
  
  # remove redundant collocation pair
  collo_df <- collo_df %>% group_by(collo_1, collo_2) %>% 
    mutate(count = sum(count)) %>% 
    select(-collocation) %>% 
    distinct() %>% 
    ungroup()
  
  # toward MI score
  ## total 
  total <- length(as.character(tok_con))
  ## a 
  collo_df <- collo_df %>% rename(a = count)
  ## b = w1 & !w2
  leng <- nrow(collo_df)
  b <- vector("integer", leng)
  for (i in 1:leng) {
    w1 <- collo_df$collo_1[i]
    w2 <- collo_df$collo_2[i]
    count <- 0
    for (j in 1:leng) {
      if (collo_df$collo_1[j] == w1 && collo_df$collo_2[j] != w2) {
        count <- count + collo_df$a[j]
      }
    }
    b[i] <- count
  }
  ## c = !w1 & w2
  c <- vector("integer", leng)
  for (i in 1:leng) {
    ww1 <- collo_df$collo_1[i]
    w2 <- collo_df$collo_2[i]
    count <- 0
    for (j in 1:leng) {
      if (collo_df$collo_2[j] == w2 && collo_df$collo_1[j] != w1) {
        count <- count + collo_df$a[j]
      }
    }
    c[i] <- count
  }
  
  ## computing MI score
  collo_df <- collo_df %>% 
    mutate(b = b, 
           c = c,
           d = total - (a + b + c),
           r1 = a + b, 
           c1 = a + c, 
           e = r1 * c1 / total,
           # Attr = a / (a + c ),
           # Rel = a / (a + b ),
           MI = log2(a / e)) %>% 
    # extracting essential info 
    select(collo_1, collo_2, a, MI)
  
  # adding source and timestep info
  article_name <- gsub(".txt", "", basename(article), fixed = T)
  collo_df$src <- strsplit(article_name, '_')[[1]][1]
  collo_df$timestep <- strsplit(article_name, '_')[[1]][2]
  
  return(collo_df)
}

all_files_collocation <- lapply(all_files, function(x) (collocate(x))) %>%
  bind_rows() %>% 
  mutate(timestep = factor(timestep, ordered = T))

saveRDS(all_files_collocation, "./data/all_files_collocation.rds")
# write_csv(all_files_collocation, 'all_files_collocation_MI.csv')


####### Use merged data #########
fps <- list.files("../data/time_sliced_collapsed_merged", full.names = T)
d = lapply(fps, function(x) (collocate(x))) %>%
  bind_rows() %>% 
  mutate(timestep = factor(timestep, ordered = T))
saveRDS(d, "./data/collocation_merged.rds")