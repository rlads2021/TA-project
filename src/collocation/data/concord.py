#%%
import json
from concordancer.concordancer import Concordancer
from concordancer import server

SRC = ["corpus_ptt.jsonl", "corpus_weibo.jsonl"][1]

print(f"Reading corpus file {SRC}...")
with open(SRC, encoding="utf-8") as f:
    corpus = [ json.loads(l) for l in f ]

print("Indexing corpus...")
C = Concordancer(corpus)
C.set_cql_parameters(default_attr="w", max_quant=3)
server.run(C)   
