library(dplyr)
library(tidyr)

topic_labels <- data.frame(
    topic = seq_along(readLines("topic_labels.txt")),
    label = readLines("topic_labels.txt")
)
topics <- readRDS("topic_beta.rds") %>%
    left_join(topic_labels, by = c("topic" = "topic"))
topics_terms <- unique(topics$term)
tp_num <- max(unique(topics$topic))

beta_vec <- function(word) {
    if (!word %in% topics_terms) return(normalize(rep(1, tp_num)))
    vec <- topics %>% 
        filter(term == word) %>% 
        arrange(topic)
    label <- vec$label
    vec <- normalize(vec$beta)
    names(vec) <- label
    return(vec)
}

normalize <- function(vec) {
    decimal <- as.character(min(vec)) %>%
        strsplit("e-") %>% unlist()
    if (length(decimal) == 2) {
        decimal <- as.integer(decimal[2])
        vec <- vec * 10 ^ decimal
    }
    # vec / sqrt(sum(vec^2))  
    vec / sum(vec)
} 