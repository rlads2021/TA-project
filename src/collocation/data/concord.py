#%%
import json
from concordancer.concordancer import Concordancer
from concordancer import server

SRC = ["corpus_ptt.jsonl", "corpus_weibo.jsonl"][0]

print("Reading corpus from file...")
with open(SRC, encoding="utf-8") as f:
    corpus = [ json.loads(l) for l in f ]

C = Concordancer(corpus)
C.set_cql_parameters(default_attr="word", max_quant=3)
server.run(C)   
