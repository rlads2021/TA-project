library(readr)

setwd('../data/time_sliced_collapsed')
all_files <- list.files()

count_freq <- function(article){
  # read file
  article_name <- str_remove(article, '.txt')
  content <- readLines(article, encoding = 'UTF-8')
  words <- unlist(strsplit(content, '\u3000'))
  
  # word freq
  words_freq<-table(unlist(words))
  num_of_tokens <- length(unique(words))
  
  # build word freq df
  words_freq_df <- as.data.frame(cbind(names(words_freq),
                                       as.integer(words_freq)/num_of_tokens))
  colnames(words_freq_df) <- c('word', 'freq')
  words_freq_df$src <- strsplit(article_name, '_')[[1]][1]
  words_freq_df$timestamp <- strsplit(article_name, '_')[[1]][2]
  return(words_freq_df)
}

all_files_freq <- bind_rows(lapply(all_files, function(x)(count_freq(x))))

# export csv file
setwd('../../wordfreq')
write.csv(all_files_freq, 'all_files_freq.csv', row.names=FALSE)