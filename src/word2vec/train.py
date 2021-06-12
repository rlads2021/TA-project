import re
import csv
import pathlib
import numpy as np
from tqdm import tqdm
from gensim.models import Word2Vec, KeyedVectors

VEC_DIM = 50
WINDOW = 4
MIN_COUNT = 5
TRAIN = pathlib.Path("../data/time_sliced_collapsed/")
MODEL = pathlib.Path("model/")


def main():
    for fp in tqdm(list(TRAIN.glob("*.txt"))):
        output = MODEL / (fp.stem + ".model")
        train_text_file(fp, output)


def train_text_file(infile, output):
    # Train word2vec model
    model = Word2Vec(SentenceIterator(infile), size=VEC_DIM, window=WINDOW, min_count=MIN_COUNT, sg=1, workers=4)
    model.save(str(output))


class SentenceIterator: 
    def __init__(self, filepath): 
        self.filepath = filepath 

    def __iter__(self): 
        for line in open(self.filepath): 
            yield line.strip().split('\u3000')


if __name__ == "__main__":
    main()
