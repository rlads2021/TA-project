#%%
import csv
import pathlib
from math import log2, log
from tqdm import tqdm

CUTOFF = 10
TOPN = 20
NODES = "臺灣".split("|")
# |中國|日本|美國|香港

def main():
    rows = []
    p = pathlib.Path("time_sliced_collapsed/")

    for fp in tqdm(list(p.glob("*.txt"))):
        src, ts = fp.stem.split("_")

        corpus = read_file(fp)
        left_collo = Collocation(corpus, left=1, right=0, cutoff=CUTOFF)
        right_collo = Collocation(corpus, left=0, right=1, cutoff=CUTOFF)

        for node in NODES:
            for collocate in left_collo.get_topn_collocates(node=node, n=TOPN, by="Gsq"):
                collo, stats = collocate
                rows.append({
                    'node': node,
                    'collo': collo,
                    'collo_pos': "left",
                    # 'MI': stats['MI'],
                    # 'Xsq': stats['Xsq'],
                    'association': stats['Gsq'],
                    'count': stats['count'],
                    'src': src,
                    'timestep': ts
                })

            for collocate in right_collo.get_topn_collocates(node=node, n=TOPN, by="Gsq"):
                collo, stats = collocate
                rows.append({
                    'node': node,
                    'collo': collo,
                    'collo_pos': "right",
                    # 'MI': stats['MI'],
                    # 'Xsq': stats['Xsq'],
                    'association': stats['Gsq'],
                    'count': stats['count'],
                    'src': src,
                    'timestep': ts
                })
    

    with open("country_collocates.csv", 'w', newline='') as csvfile:
        fieldnames = ["node", "collo", "collo_pos", "association", "count", "src", "timestep"]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


IGNORE_TERMS = "+ - $ ^ _ - ~ ～ ＄ ︿ ＊ ! \" # ## * , / : ? @ REMOVEDURL [ ] · “ ” ▓ ✨ 、 。 《 》 「 」 【 】 ！ （ ） ， ： ； ？ … < > ( ) . 『 』 ③ ⚠ ．".split()
IGNORE_TERMS = set(IGNORE_TERMS)
IGNORE_TERMS.add(chr(65039))
def read_file(fp):
    with open(fp, encoding="utf-8") as f:
        corpus = []
        for sent in f.read().split("\n"):
            if sent.strip() == "": continue
            sentence = []
            for tk in sent.split("\u3000"):
                if tk.strip() == "": continue
                if not has_zh(tk): continue
                #if tk in IGNORE_TERMS: continue
                sentence.append(tk)
            if len(sentence) > 0:
                corpus.append(sentence)
    return corpus



def has_zh(x: str):
    """Check whether a string contains Chinese characters

    Parameters
    ----------
    x : str
        String to check

    Returns
    -------
    bool
        True if the input contains Chinese character, else False
    """
    for char in x:
        if (char > u'\u4e00' and char < u'\u9fff') or (char > u'\u3400' and char < u'\u4DBF'):
            return True
    return False



class Collocation:
    def __init__(self, corpus, left=3, right=3, cutoff=3):
        # Collocation window definition
        self.left_window = left
        self.right_window = right
        self.cutoff = cutoff
        
        # Frequency info for calculating collocation indicies
        self.cooccur_freq = {}
        self.node_marginal_freq = {}
        self.collocate_marginal_freq = {}
        self.total = 0

        # Words in corpus
        self.words = set()

        # Collocation list
        self.collcations = {}

        # Count frequencies
        for sent in corpus:
            self.count_freq_sent(sent)
        self.total = sum(self.node_marginal_freq.values())


    def get_topn_collocates(self, node, n=10, by="Gsq"):
        subset = {}
        for collocate in self.words:
            stats = self.association(node, collocate, self.cutoff)
            if stats is not None:
                subset[collocate] = stats
        return sorted(subset.items(), key=lambda x: x[1][by], reverse=True)[:n]


    def association(self, node, collocate, cutoff):
        # Retrieve frequencies
        R1 = self.node_marginal_freq.get(node)
        C1 = self.collocate_marginal_freq.get(collocate)
        O11 = self.cooccur_freq.get((node, collocate))

        if O11 is None or R1 is None or C1 is None: 
            return None
        if O11 < cutoff: 
            return None
        
        # Cell expected values
        C2 = self.total - C1
        R2 = self.total - R1
        E11 = R1 * C1 / self.total
        E12 = R1 * C2 / self.total
        E21 = R2 * C1 / self.total
        E22 = R2 * C2 / self.total
        O12 = R1 - O11
        O21 = C1 - O11
        O22 = R2 - O21

        Obs = [O11, O12, O21, O22]
        Exp = [E11, E12, E21, E22]

        # Calculate stats
        ZERO = 1 / (self.total + 1)
        return {
            "MI": log2(O11 / E11), 
            "Xsq": self.Xsq(*Obs, *Exp),
            "Gsq": self.Gsq(*[ZERO if x == 0 else x for x in Obs], *[ZERO if x == 0 else x for x in Exp]),
            "count": O11,
        }
    

    def Gsq(self, O11, O12, O21, O22, E11, E12, E21, E22):
        val = 2 * (O11 * log(O11/E11) + O12 * log(O12/E12) + O21 * log(O21/E21) + O22 * log(O22/E22))
        if O11 < E11:
            val = -val
        return val       


    def Xsq(self, O11, O12, O21, O22, E11, E12, E21, E22):
        val = (O11 - E11)**2 / E11 + (O12 - E12)**2 / E12 + (O21 - E21)**2 / E21 + (O22 - E22)**2 / E22
        if O11 < E11:
            val = -val
        return val


    def count_freq_sent(self, sent):
        s_len = len(sent)
        for i, node in enumerate(sent):
            # Record word
            self.words.add(node)

            # Set window to scan through
            win_left = max(i - self.left_window, 0)
            win_right = min(i + self.right_window + 1, s_len)
            for collocate in sent[win_left:i] + sent[i+1:win_right]:
                # Count node marginal frequency
                if node not in self.node_marginal_freq:
                    self.node_marginal_freq[node] = 0
                self.node_marginal_freq[node] += 1

                # Count collocate marginal frequency
                if collocate not in self.collocate_marginal_freq:
                    self.collocate_marginal_freq[collocate] = 0
                self.collocate_marginal_freq[collocate] += 1

                # Count cooccurance frequency
                k = (node, collocate)
                if k not in self.cooccur_freq:
                    self.cooccur_freq[k] = 0
                self.cooccur_freq[k] += 1


if __name__ == '__main__':
    main()
    # pass
# %%
