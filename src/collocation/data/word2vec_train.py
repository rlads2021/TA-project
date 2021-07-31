import os
import pathlib
import gensim
import pickle
import numpy as np
from functools import reduce
from gensim.models import Word2Vec

VEC_DIM = 100
WINDOW = 5
MIN_COUNT = 5
TRAIN = pathlib.Path("word2vec_train/")
MODELS = pathlib.Path("word2vec_model/")
COMMON_VOCAB = MODELS / "common_vocab.pkl"

def main():
    # Train word2vec model
    for fp in TRAIN.glob("*.txt"):
        output = MODELS / (fp.stem + ".model")
        train_text_file(fp, output)

    # Align two model's vector space
    # Set base model to align with
    base_model = Word2Vec.load(str(MODELS / "ptt_000.model"))
    model = Word2Vec.load(str(MODELS / "weibo_000.model"))
    vocab = set(base_model.wv.vocab.keys()).intersection(model.wv.vocab)

    # Align model
    model = smart_procrustes_align_gensim(base_model, model)

    # Export model
    for m, src in [ (base_model, "ptt"), (model, "weibo") ]:
        m.init_sims(replace=True)    # Use unit vector
        m.wv.save( str(MODELS / f"{src}_aligned.model") )

    # Save common vocab
    with open(COMMON_VOCAB, "wb") as f:
        pickle.dump(vocab, f)



def train_text_file(infile, output):
    # Train word2vec model
    model = Word2Vec(SentenceIterator(infile), size=VEC_DIM, window=WINDOW, min_count=MIN_COUNT, sg=1, workers=4)
    #model.init_sims(replace=True)  # Use unit vector
    #model.wv.save(str(output))
    model.save(str(output))

def save_model(model, fp):
    model.init_sims(replace=True)  # Use unit vector
    model.wv.save(str(fp))

class SentenceIterator: 
    def __init__(self, filepath): 
        self.filepath = filepath 

    def __iter__(self): 
        for line in open(self.filepath): 
            yield line.strip().split('\u3000')


def smart_procrustes_align_gensim(base_embed, other_embed, words=None):
    """Procrustes align two gensim word2vec models (to allow for comparison between same word across models).
    Code ported from HistWords <https://github.com/williamleif/histwords> by William Hamilton <wleif@stanford.edu>.
        (With help from William. Thank you!)
    First, intersect the vocabularies (see `intersection_align_gensim` documentation).
    Then do the alignment on the other_embed model.
    Replace the other_embed model's syn0 and syn0norm numpy matrices with the aligned version.
    Return other_embed.
    If `words` is set, intersect the two models' vocabulary with the vocabulary in words (see `intersection_align_gensim` documentation).
    """

    # make sure vocabulary and indices are aligned
    base_embed.wv.init_sims()
    other_embed.wv.init_sims()
    in_base_embed, in_other_embed = align_gensim_models([base_embed, other_embed], words=words)

    # get the embedding matrices
    #base_vecs = in_base_embed.syn0norm
    #other_vecs = in_other_embed.syn0norm
    base_vecs = in_base_embed.wv.vectors_norm
    other_vecs = in_other_embed.wv.vectors_norm

    # just a matrix dot product with numpy
    m = other_vecs.T.dot(base_vecs) 
    # SVD method from numpy
    u, _, v = np.linalg.svd(m)
    # another matrix operation
    ortho = u.dot(v) 
    # Replace original array with modified one
    # i.e. multiplying the embedding matrix (syn0norm)by "ortho"
    #other_embed.syn0norm = other_embed.syn0 = (other_embed.syn0norm).dot(ortho)
    other_embed.vectors_norm = other_embed.wv.syn0 = (other_embed.wv.vectors_norm).dot(ortho)
    return other_embed



def align_gensim_models(models, words=None):
    """
    Returns the aligned/intersected models from a list of gensim word2vec models.
    Generalized from original two-way intersection as seen above.
    
    Also updated to work with the most recent version of gensim
    Requires reduce from functools
    
    In order to run this, make sure you run 'model.init_sims()' for each model before you input them for alignment.
    
    ##############################################
    ORIGINAL DESCRIPTION
    ##############################################
    
    Only the shared vocabulary between them is kept.
    If 'words' is set (as list or set), then the vocabulary is intersected with this list as well.
    Indices are re-organized from 0..N in order of descending frequency (=sum of counts from both m1 and m2).
    These indices correspond to the new syn0 and syn0norm objects in both gensim models:
        -- so that Row 0 of m1.syn0 will be for the same word as Row 0 of m2.syn0
        -- you can find the index of any word on the .index2word list: model.index2word.index(word) => 2
    The .vocab dictionary is also updated for each model, preserving the count but updating the index.
    """

    # Get the vocab for each model
    vocabs = [set(m.wv.vocab.keys()) for m in models]

    # Find the common vocabulary
    common_vocab = reduce((lambda vocab1,vocab2: vocab1&vocab2), vocabs)
    if words: common_vocab&=set(words)

    # If no alignment necessary because vocab is identical...
    
    # This was generalized from:
    # if not vocab_m1-common_vocab and not vocab_m2-common_vocab and not vocab_m3-common_vocab:
    #   return (m1,m2,m3)
    if all(not vocab-common_vocab for vocab in vocabs):
        print("All identical!")
        return models
        
    # Otherwise sort by frequency (summed for both)
    common_vocab = list(common_vocab)
    common_vocab.sort(key=lambda w: sum([m.wv.vocab[w].count for m in models]),reverse=True)
    
    # Then for each model...
    for m in models:
        
        # Replace old vectors_norm array with new one (with common vocab)
        indices = [m.wv.vocab[w].index for w in common_vocab]
                
        old_arr = m.wv.vectors_norm
                
        new_arr = np.array([old_arr[index] for index in indices])
        m.wv.vectors_norm = m.wv.syn0 = new_arr

        # Replace old vocab dictionary with new one (with common vocab)
        # and old index2word with new one
        m.wv.index2word = common_vocab
        old_vocab = m.wv.vocab
        new_vocab = {}
        for new_index,word in enumerate(common_vocab):
            old_vocab_obj=old_vocab[word]
            new_vocab[word] = gensim.models.word2vec.Vocab(index=new_index, count=old_vocab_obj.count)
        m.wv.vocab = new_vocab

    return models


def intersection_align_gensim(m1,m2, words=None):
    """
    Intersect two gensim word2vec models, m1 and m2.
    Only the shared vocabulary between them is kept.
    If 'words' is set (as list or set), then the vocabulary is intersected with this list as well.
    Indices are re-organized from 0..N in order of descending frequency (=sum of counts from both m1 and m2).
    These indices correspond to the new syn0 and syn0norm objects in both gensim models:
        -- so that Row 0 of m1.syn0 will be for the same word as Row 0 of m2.syn0
        -- you can find the index of any word on the .index2word list: model.index2word.index(word) => 2
    The .vocab dictionary is also updated for each model, preserving the count but updating the index.
    """

    # Get the vocab for each model
    vocab_m1 = set(m1.vocab.keys())
    vocab_m2 = set(m2.vocab.keys())

    # Find the common vocabulary
    common_vocab = vocab_m1&vocab_m2
    if words: common_vocab&=set(words)

    # If no alignment necessary because vocab is identical...
    if not vocab_m1-common_vocab and not vocab_m2-common_vocab:
        return (m1,m2)

    # Otherwise sort by frequency (summed for both)
    common_vocab = list(common_vocab)
    common_vocab.sort(key=lambda w: m1.vocab[w].count + m2.vocab[w].count,reverse=True)

    # Then for each model...
    for m in [m1,m2]:
        # Replace old syn0norm array with new one (with common vocab)
        indices = [m.vocab[w].index for w in common_vocab]
        old_arr = m.syn0norm
        new_arr = np.array([old_arr[index] for index in indices])
        m.syn0norm = m.syn0 = new_arr

        # Replace old vocab dictionary with new one (with common vocab)
        # and old index2word with new one
        m.index2word = common_vocab
        old_vocab = m.vocab
        new_vocab = {}
        for new_index,word in enumerate(common_vocab):
            old_vocab_obj=old_vocab[word]
            new_vocab[word] = gensim.models.word2vec.Vocab(index=new_index, count=old_vocab_obj.count)
        m.vocab = new_vocab

    return (m1,m2)


if __name__ == "__main__":
    main()
