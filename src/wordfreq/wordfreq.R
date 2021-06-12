library(readr)
library(stringr)
library(dplyr)

all_files <- list.files("time_sliced_collapsed", full.names = T)

count_freq <- function(article){
  # read file
  article_name <- gsub(".txt", "", basename(article), fixed = T)
  content <- readLines(article, encoding = 'UTF-8')
  words <- unlist(strsplit(content, '\u3000'))
  
  # word freq
  words_freq <- table(unlist(words))
  num_of_tokens <- length(words)
  
  # build word freq df
  words_freq_df <- tibble::as_tibble(cbind(names(words_freq),
                                       as.integer(words_freq),
                                       num_of_tokens)
                                 )
  colnames(words_freq_df) <- c('word', 'count', 'corp_size')
  words_freq_df$src <- strsplit(article_name, '_')[[1]][1]
  words_freq_df$timestep <- strsplit(article_name, '_')[[1]][2]
  return(words_freq_df)
}

all_files_freq <- lapply(all_files, function(x)(count_freq(x))) %>%
  bind_rows() %>%
  filter(grepl("[\u4E00-\u9FFF\u3400-\u4DBF]", word)) %>%
  mutate(count = as.integer(count),
         corp_size = as.integer(corp_size),
         timestep = as.integer(timestep)) %>%
  mutate(freq = round(count * 1000000 / corp_size, 4),
         timestep = factor(timestep, ordered = T)) %>%
  select(word, freq, src, timestep)

# export data
saveRDS(all_files_freq, 'word_freq.RDS')
#readr::write_csv(all_files_freq, 'all_files_freq.csv')
