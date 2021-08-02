topics <- readRDS("topic_beta.rds")
topics_terms <- unique(topics$term)
tp_num <- max(unique(topics$topic))

beta_vec <- function(word) {
    if (!word %in% topics_terms) return(normalize(rep(1, tp_num)))
    topics %>% 
        filter(term == word) %>% 
        arrange(topic) %>%
        .$beta %>% normalize()
}

normalize <- function(vec) {
    decimal <- as.character(min(vec)) %>% 
        strsplit("e-") %>% unlist()
    if (length(decimal) == 2) {
        decimal <- as.integer(decimal[2])
        vec <- vec * 10 ^ decimal
    }
    vec / sqrt(sum(vec^2))  
} 