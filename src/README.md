# 原始碼說明文件

- `data/`: 原始資料以及資料前處理，詳見其內之 [README.md](data/README.md)
- `collocation/`: 搭配詞視覺化函數
- `dependency/`: 句法剖析以及視覺化函數
- `lsa/`: LSA 訓練及視覺化函數
- `topic_modeling/`: 主題模型訓練及視覺化函數
- `word2vec/`: 詞向量訓練及視覺化函數。相關說明，詳見其內之 [README.md](word2vec/README.md)
- `wordfreq/`: 詞頻計算及視覺化函數
- `shiny/`: 整合前面 6 個部份 (`collocation` ~ `wordfreq`) 視覺化函數，建置成 shiny app (動態視覺化)
- `report/`: 書面報告內容以及輸出程式碼，詳見其內之 [README.md](report/README.md)
