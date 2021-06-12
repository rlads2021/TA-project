fps <- c("../data/keyterms.txt",
         "../word2vec/keyterms.pca.csv")

for (fp in fps) file.copy(fp, "data/", overwrite = TRUE)
