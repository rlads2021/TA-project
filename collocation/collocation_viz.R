library(dplyr)
library(tibble)
# selecting 
keyword <- "總統"
source <- c("ptt", "weibo")
time <- c(1:9)
df_1 <- all_files_collocation %>% 
  filter(src %in% source, timestep %in% time, collo_1 %in% keyword) %>% 
  select(-c(collo_1)) %>% 
  mutate(frontness = "back") %>% 
  rename(word = collo_2)
df_2 <- all_files_collocation %>% 
  as_tibble() %>% 
  filter(src %in% source, timestep %in% time, collo_2 %in% keyword) %>% 
  select(-c(collo_2)) %>% 
  mutate(frontness = "front") %>% 
  rename(word = collo_1)
df <- bind_rows(df_1, df_2)
dft <- df %>% arrange(word, frontness, src, timestep, desc(MI)) %>% 
  group_by(timestep, src) %>% 
  slice_max(order_by = MI, n = 5) 

library(ggplot2)
p <- ggplot(data = dft) +
  geom_bar(aes(x = reorder(word, MI), y = MI, fill = frontness), stat = "identity") +
  facet_grid(vars(src), vars(timestep)) +
  labs(x = "搭配詞", title = "美國") +
  coord_flip()
p