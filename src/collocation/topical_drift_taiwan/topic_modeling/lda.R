library(dplyr)
library(tidytext)
library(quanteda)
library(topicmodels)

# q_dfm <- readLines("all_trim.txt") %>%
#     corpus() %>%
#     tokenizers::tokenize_regex("\u3000") %>%
#     tokens() %>%
#     dfm() %>%
#     dfm_select(pattern = "[\u4E00-\u9FFF]", valuetype = "regex") %>%
#     dfm_trim(min_termfreq = 5)
# 
# lda <- LDA(convert(q_dfm, to = "topicmodels"), k = 5, control = list(seed = 1234))
# topics <- tidy(lda, matrix = "beta")

topics <- readRDS("topic_beta.rds")

# Check collocate coverage
collo <- unique(readr::read_csv("country_collocates.csv")$collo)
mean(collo %in% topics$term)  # coverage


# Attach labels
normalize <- function(vec) {
    decimal <- as.character(min(vec)) %>% 
        strsplit("e-") %>% unlist()
    if (length(decimal) == 2) {
        decimal <- as.integer(decimal[2])
        vec <- vec * 10 ^ decimal
    }
    vec / sqrt(sum(vec^2))  
} 
beta_vec <- function(word) {
    topics %>% 
        filter(term == word) %>% 
        arrange(topic) %>%
        .$beta %>% normalize()
}
word = "水桶"
