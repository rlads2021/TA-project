##load package ####
library(tidyverse)
library(stringr)
library(tidytext)
library(lubridate)
options(stringsAsFactors = F)
library(dplyr)
library(tidyr)
library(ggplot2)
theme_set(theme_bw())
## Loading data#####
setwd("C:/Users/am/Desktop/109-2/LOPE/R/final project")
doc = readr::read_csv("doc_annotated_lsa.csv")
View(doc)
str(doc)
##stm####
install.packages("stm")
library(stm)
data(package = "stm")

#R fu dtm #####
library(dplyr)
library(quanteda)
library(quanteda.textstats)
d_tokens <- corpus(doc, docid_field = "docid", text_field = "text") %>%
  tokenizers::tokenize_regex(pattern = "\u3000") %>%
  tokens()
d_dfm <- dfm(d_tokens)
d_dfm
#Document-feature matrix of: 134,825 documents, 346,847 features (99.98% sparse) and 0 docvars.

d_dfm <- dfm(d_tokens) %>% 
  dfm_remove(pattern = readLines("stopwords.txt"), valuetype = "fixed") %>%
  dfm_select(pattern = "[\u4E00-\u9FFF]", valuetype = "regex") %>%
  dfm_trim(min_termfreq = 5) %>%
  #dfm_tfidf() #有了tfidf就會無法跑d_dtm_t <- convert(d_dfm, to = "topicmodels")
d_dfm

#沒跑td-idf可以跑以下 但是檔案太大 要稍微再處理過再來跑(或許就是後面那一步驟不要tfidf
library(topicmodels)
d_dtm_t <- convert(d_dfm, to = "topicmodels")
d_dtm_lda4 <- LDA(d_dtm_t, k = 4, control = list(seed = 1234))
#跑了tfidf後的dfm無法透過convert轉換成topic modeling 格式的原因(待讀)
#https://stackoverflow.com/questions/63632177/error-converting-to-stm-after-tf-idf-weighting

# 0.75 Document-feature matrix of: 134,825 documents, 291,936 features (99.98% sparse) and 0 docvars.
#Document-feature matrix of: 134,825 documents, 93,497 features (99.93% sparse) and 0 docvars.
# 1.0 Document-feature matrix of: 134,825 documents, 291,936 features (99.98% sparse) and 0 docvars.
library(tm)
#non count foc feature into tidy format
# we cannot feed non-count dfm into 
d_dfm.df <- broom::tidy(d_dfm)
View(d_dfm.df) #doc -term count
#The tidy method works on these document-feature matrices as well, turning them into a one-token-per-document-per-row table:

#Right now our data frame word_counts is in a tidy form, 
#with one-term-per-document-per-row, 
#but the topicmodels package requires a DocumentTermMatrix. 
#As described in Chapter 5.2, we can cast a one-token-per-row table 
#into a DocumentTermMatrix with tidytext’s cast_dtm().
d_dtm <- d_dfm.df %>%
  tidytext::cast_dtm(document,term, count)

d_dtm
#https://stackoverflow.com/questions/51886583/r-package-topicmodels-lda-error-invalid-argument
#無效果
toy_unique = unique(d_dtm$term)
for (i in 1:length(toy_unique)){
  A = as.integer(d_dtm$term == toy_unique[i])
  d_dtm[toy_unique[i]] = A
}

# <<DocumentTermMatrix (documents: 134815, terms: 93497)>>
#   Non-/sparse entries: 8571564/12596226491
# Sparsity           : 100%
# Maximal term length: 14
# Weighting          : term frequency (tf)
#寫得很好嗚嗚
#https://www.tidytextmining.com/dtm.html
#https://www.tidytextmining.com/topicmodeling.html#library-heist

#老師LDA:我用convert的方式可以將Quanteda的dtm餵入#####
library(topicmodels)
#d_dtm_t <- convert(d_dfm, to = "topicmodels")
# cannot convert a non-count dfm to a topic model format
#convert() only works on corpus, dfm objects.
#dfm2stm <- convert(d_dfm.df, to = "stm")
##convert() only works on corpus, dfm objects.
d_dtm_lda16 <- LDA(d_dtm, k = 16, control = list(seed = 1234))
d_dtm_lda4 <- LDA(d_dtm, k = 4, control = list(seed = 1234))

#topic modeling####
# install.packages("stm")
library(stm)
topic_model <- stm(d_dfm, K = 12, init.type = "Spectral", reportevery = 10)
# ## import jiebaR `cutter()`data已經萬好詞了似乎不用####
# library(jiebaR)
# cutter <- worker()
# readr::read_csv("jieba_large_dict.txt")
# segment_not <- c("韓國瑜")
# # source("../segment_not.R") 
# new_user_word(cutter, segment_not)
# stopWords <- readRDS("data/stopWords.rds")
# library(jiebaR) #load
# cutter <- worker(bylines = T,user = "./jieba_large_dict.txt",stop_word = "./stopwords_zh-tw.txt") #Create word splitter, whether bylines is divided by lines, user user dictionary, stop_word stop dictionary
# comments_seg <- cutter["./doc_annotated_lsa.csv"] #File segmentation, enter the file address directly, and automatically save it as a file after segmentation
# 
# doc.list <- strsplit(as.character(doc$text),split=" ")
# length(doc.list)
# doc.list[1]

doc_corpus <-quanteda::corpus(doc, text_field="text")
View(doc_corpus)
doc_corpus[["text6"]]
summary(doc_corpus,n=2)
# Corpus consisting of 134825 documents, showing 2 documents:
#   
#   Text Types Tokens Sentences      docid
# text1    92    126         1 weibo_1_T1
# text2    67     92         4 weibo_2_T1

doc[1,2]
doc[2,2]#2nd rwo 2nd col

#unnest_tokens:tokenize ####
stop_word =readr::read_csv("stopwords_zh-tw.txt")
stop_words = stop_word
doc_tidy <- as_tibble(doc) %>% 
  # tokenize the tweets
  tidytext::unnest_tokens(word, text) %>%
  # remove stop words
  anti_join(stop_words) #%>%
# and stem the words
#mutate(word=wordStem(word))不要stem的話

View(doc_tidy)
