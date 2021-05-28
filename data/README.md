## Data

The real data are compressed in zip files with the same filenames as below. These zip files can be found on [Google Drive](https://drive.google.com/drive/folders/1UuDL7TtnBgseTyCcYNIWynkHvGyEv5l0). The data listed below are used for testing (quick prototyping programs).

- [`time_sliced_collapsed/*.txt`](time_sliced_collapsed/)
    - 用於 collcation / dependency parsing / word frequency analysis
    - 檔案格式
        - 檔名：`{來源}_{time_step}.txt`。目前總共有 12 個 time step (`0`-`11`)，是根據假日期計算出來的。
        
            ```
            ptt_0.txt
            ptt_1.txt
            ptt_2.txt
            ...
            weibo_0.txt
            weibo_1.txt
            weibo_2.txt
            ...
            ```

        - 內容：每個 row 為一篇文章，詞彙之間以 `\u3000` 分隔

- [`doc_annotated_lsa.csv`](doc_annotated_lsa.csv)
    - 用於 LSA document vector 提取 (時間資訊)
    - 檔案格式
        - 內容：兩個 column 的 csv 檔。每個 row 為一篇文章，內文儲存於 `text` 變項，內文的詞彙之間以 `\u3000` 分隔。變項 `docid` 為文本 id，以 `{來源}_{docnum}_T{time_step}` 標註 (e.g., `weibo_1_T2`)。

            ```csv
            docid,text
            weibo_1_T0,方豪　是　天主教　的　神父
            weibo_2_T4,【　北迴鐵路　是　日本　人蓋　的　？
            weibo_3_T0,#　黨史　微　課堂　#　【　“　如其　合格　，
            ...
            ```

- [`keyterm_annotated_lsa.csv`](keyterm_annotated_lsa.csv)
    - 用於 LSA word vector 提取 (時間資訊)
    - 檔案格式
        - 內容：兩個 column 的 csv 檔。每個 row 為一篇文章，內文儲存於 `text` 變項，內文的詞彙之間以 `\u3000` 分隔。keyterms 會以 `keyterm_{來源}_T{time_step}` 標註 (e.g., `國民黨_ptt_T2`)。關於目前所使用的 keyterms，請見 [`keyterms.txt`](keyterms.txt)。

            ```csv
            docid,text
            weibo_1,他　爲　國民黨_weibo_T0　辦　《　中央日報　》
            weibo_2,張亞中　炮火　全開　:　兩岸_weibo_T8　兵兇戰危
            ...
            ptt_1,國民黨_ptt_T2　的　亡臣　可　沒　那麼　老實
            ptt_2,臺灣_ptt_T2　是　日本　領土
            ...
            ```

- [`keyterm_annotated_wv_train.txt`](keyterm_annotated_wv_train.txt)  
    - Word Embedding 的訓練資料
    - 檔案格式：每個 row 為一篇斷好詞的文章，詞彙之間以 `\u3000` 分隔。內文的 keyterms 會以 `keyterm_{來源}_T{time_step}` 標註 (e.g., `國民黨_ptt_T2`)。關於目前所使用的 keyterms，請見 [`keyterms.txt`](keyterms.txt)。


### Other documentations

#### Full Data preperation

1. Raw
    - `raw/ptt_taiwan/*.json`: PTT posts containing keyword `台灣`
    - `raw/weibo/kmt.csv`: Weibo posts containing keyword `國民黨`
    - `raw/weibo/taiwan.csv`: Weibo posts containing keyword `台灣`
2. Segmented & converted to CSV
    - `raw/ptt_full.csv`
    - `raw/weibo_full.csv`
3. Explore corpus size across time (using `raw/ptt_full.csv` & `raw/weibo_full.csv`)
    - Goals: determine time step size, sample posts if corpus sizes are not balanced across PTT/Weibo
    - Documentation: <https://rlads2021.github.io/TA-project/post_freq>
    - Results:
        - `raw/ptt_sampled.csv`
        - `raw/weibo_sampled.csv`
        - `../timesteps.txt`
    - Reproduce:
        ```bash
        cd raw
        Rscript sample_posts.R
        ```