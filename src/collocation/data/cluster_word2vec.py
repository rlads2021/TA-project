#%%
import pathlib
import numpy as np
from gensim.models import KeyedVectors

p = pathlib.Path("word2vec_model/")

m = str(p / "weibo_000.model")
wv = KeyedVectors.load(m, mmap='r')
# np.linalg.norm(wv["臺灣"])  # vector length

# %%
import csv

left_collo = set()
right_collo = set()
with open("country_collocates.csv", newline='') as csvfile:
    rows = csv.DictReader(csvfile)
    for row in rows:
        if row["collo_pos"] == "left":
            left_collo.add(row["collo"])
        else:
            right_collo.add(row["collo"])
        if row["collo"] == '️': print(row)

# %%
from tqdm import tqdm
from sklearn.cluster import KMeans

vocab = list(left_collo.union(right_collo).intersection(wv.vocab))
X = wv[vocab]

distortions = []
K = list(range(2,30))
for k in tqdm(K):
    kmeanModel = KMeans(n_clusters=k)
    kmeanModel.fit(X)
    distortions.append(kmeanModel.inertia_)

# %%
import matplotlib.pyplot as plt

plt.figure(figsize=(16,8))
plt.plot(K, distortions, 'bx-')
plt.xlabel('k')
plt.ylabel('Distortion')
plt.title('The Elbow Method showing the optimal k')
plt.show()


# %%
from collections import Counter

kmeanModel = KMeans(n_clusters=10)
kmeanModel.fit(X)
labels = kmeanModel.predict(X)
results = sorted( ((w, l) for w, l in zip(vocab, labels)), key=lambda x: x[1] )

Counter(labels)
# %%
