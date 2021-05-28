import re
import csv
import pathlib
import numpy as np
from sklearn.decomposition import PCA
from gensim.models import Word2Vec, KeyedVectors

TRAIN = pathlib.Path('../data/keyterm_annotated_wv_train.txt')
OUTPUT = pathlib.Path('wv.model.bin')
OUTPUT_PCA = 'keyterms.pca.csv'


def main():
    # Load word2vec model
    if OUTPUT.exists():
        wv = KeyedVectors.load(str(OUTPUT))
    else:
        # Train word2vec model
        model = Word2Vec(SentenceIterator(TRAIN), size=100, window=4, min_count=5, sg=1, workers=4)
        wv = model.wv
        wv.save(str(OUTPUT))

    # Extract keyterms' vectors
    pat_anno = re.compile(r"_(weibo|ptt)_T\d{1,2}")
    words = [ w for w in wv.vocab if pat_anno.search(w) ]
    keyterms_wv = np.array([wv[w] for w in words])

    # Perform PCA on keyterm vector space
    twodim = PCA().fit_transform(keyterms_wv)[:, :2]

    # Save PCA results
    with open(OUTPUT_PCA, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["word", "src", "timestep", "PC1", "PC2"])

        for word, (pc1, pc2) in zip(words, twodim):
            word, src, ts = word.split("_")
            writer.writerow([word, src, ts[1:], pc1, pc2])


class SentenceIterator: 
    def __init__(self, filepath): 
        self.filepath = filepath 

    def __iter__(self): 
        for line in open(self.filepath): 
            yield line.strip().split('\u3000')


if __name__ == "__main__":
    main()
