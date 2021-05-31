library(readr)
library(stringr)

setwd("../data/time_sliced_collapsed")

## read files
all_files <- list.files()
all_files_content <- lapply(all_files, function(x)(readLines(x, encoding = 'UTF-8')))

count_freq <- function(article){
  # preprocessing
  words <- unlist(strsplit(article, '\u3000'))
  cleaned_words <- str_replace_all(words, '[^[:alnum:]]', '') # remove special characters
  cleaned_words <- str_replace_all(cleaned_words, '[A-Za-z0-9]', '') # remove eng and digits
  
  # word freq
  words_freq<-table(unlist(cleaned_words))
  num_of_tokens <- length(unique(cleaned_words))
  
  # build word freq df
  words_freq_df <- as.data.frame(cbind(names(words_freq),
                                       as.integer(words_freq)/num_of_tokens))
  colnames(words_freq_df) <- c('word', 'freq')
  return(words_freq_df)
}

## pass the function to all files content
all_files_content_freq <- lapply(all_files_content, function(x)(count_freq(x)))
