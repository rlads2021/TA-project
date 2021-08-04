library(tidyr)
library(dplyr)
library(stringr)

read_numpytxt <- function(fp) {
    readLines(fp) %>%
        sapply(function(row) strsplit(row, " ") %>% unlist %>% as.double) %>%
        t()
}
most_siml <- function(vec, mat, sim_func=euc_sim) {
    x <- apply(mat, 1, function(row) sim_func(vec, row))
    sort(x, decreasing = T)
}
cos_sim <- function(x, y) sum(x * y) / sqrt(sum(x^2) * sum(y^2))
euc_sim <- function(x, y) 1 / sqrt(sum((x - y)^2))
centroid_label <- function(cluster_label) {
    vec <- centroids[cluster_label + 1, ]
    d <- collo %>% filter(cluster == cluster_label)
    w <- paste0(d$collocate, "_", d$src)
    most_siml(vec, x_pca[w, ], euc_sim)[1:6] %>%
        names() %>% 
        str_remove("_wei") %>% 
        str_remove("_ptt") %>% 
        paste(collapse = " ")
}

# Read data
collo <- readr::read_csv("cluster_labels.csv") %>%
    mutate(cluster = factor(cluster, order = T))
words <- paste0(collo$collocate, "_", collo$src)
x_pca <- read_numpytxt("pca_collocates_vec.txt")
rownames(x_pca) <- words
centroids <- read_numpytxt("centroids_vec.txt")

center_labs <- sapply(0:9, function(lab) centroid_label(lab))
d <- data.frame(
    cluster = factor(0:9, order = T),
    labels = center_labs
)

collo %>%
    left_join(d, by = c("cluster" = "cluster")) %>%
    readr::write_csv("cluster_labels2.csv")