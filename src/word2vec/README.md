Component: word2vec visualization
=================================

## Generate data used in shiny app

```bash
python3 train.py
```

- inputs: `../data/keyterm_annotated_wv_train.txt`
- outputs
    - `wv.model.bin` (word2vec full model, cache only, no used directly)
    - `keyterms.pca.csv` (keyterms word vectors reduced to 2 dimensions, data used in `word2vec.R`)


## Shiny App plotting function

See `word2vec.R` for details.


### Usage

```r
embed_viz(words = c("國民黨", "民進黨"), 
          timesteps= 0:2, 
          source = c("weibo", "ptt"))
```
<img src="embed_viz.png" width="60%">
