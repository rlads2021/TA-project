import pathlib
from gensim.models import Word2Vec

VEC_DIM = 100
WINDOW = 5
MIN_COUNT = 5
TRAIN = pathlib.Path("word2vec_train/")
MODEL = pathlib.Path("word2vec_model/")


def main():
    for fp in list(TRAIN.glob("*.txt")):
        output = MODEL / (fp.stem + ".model")
        train_text_file(fp, output)


def train_text_file(infile, output):
    # Train word2vec model
    model = Word2Vec(SentenceIterator(infile), size=VEC_DIM, window=WINDOW, min_count=MIN_COUNT, sg=1, workers=4)
    model.init_sims(replace=True)  # Use unit vector
    model.wv.save(str(output))


class SentenceIterator: 
    def __init__(self, filepath): 
        self.filepath = filepath 

    def __iter__(self): 
        for line in open(self.filepath): 
            yield line.strip().split('\u3000')


if __name__ == "__main__":
    main()
