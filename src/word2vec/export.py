#%%
import csv
import pickle
import pathlib
import numpy as np
from sklearn.decomposition import PCA
from gensim.models import Word2Vec

MODEL = pathlib.Path('model_aligned/')
MODEL_EXPORT = pathlib.Path('model_export/')
VOCAB = 'common_vocab.pkl'
OUTPUT_PCA = "aligned_wv_pca.csv"
with open(VOCAB, "rb") as f:
    VOCAB = pickle.load(f)
VOCAB.remove("")
VOCAB = list(VOCAB)

#%%
all_wv = []
all_words = []

for fp in MODEL.glob("*.model"):
    out_fp = MODEL_EXPORT / (fp.stem + ".txt")

    # Load aligned model
    model = Word2Vec.load(str(fp)).wv
    
    with open(out_fp, "w", encoding="utf-8") as f:
        # Select only words in common vocab
        for word in VOCAB:
            vec = model[word]
            # Write to plain text
            vec_str = '\t'.join(str(n) for n in vec)
            f.write(f"{word}\t{vec_str}\n")

            # Save to big matrix
            src, ts = fp.stem.split("_")
            all_wv.append(vec)
            all_words.append(f"{word}_{src}_{ts}")


#%%
# PCA reduce all words in corpus
all_wv = np.array(all_wv)
twodim = PCA().fit_transform(all_wv)[:, :2]

# Save PCA results
with open(OUTPUT_PCA, "w", encoding="utf-8", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["word", "src", "timestep", "PC1", "PC2"])

    for word, (pc1, pc2) in zip(all_words, twodim):
        word, src, ts = word.split("_")
        writer.writerow([word, src, ts, pc1, pc2])
