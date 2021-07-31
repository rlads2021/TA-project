import pathlib
from collo_extract import Collocation, read_file
from tqdm import tqdm

CUTOFF = 10
TOPN = 50
NODES = "臺灣|中國|日本|美國|香港".split("|")
# |中國|日本|美國|香港
p = pathlib.Path("time_sliced_collapsed/")



for fp in tqdm(sorted(p.glob("*.txt"))):
    src, ts = fp.stem.split("_")
    corpus = read_file(fp)

    left_collo = Collocation(corpus, left=1, right=0, cutoff=CUTOFF)
    right_collo = Collocation(corpus, left=0, right=1, cutoff=CUTOFF)
    for node in NODES:
        left_collocates = []
        for collocate in left_collo.get_topn_collocates(node, n=TOPN, by="Gsq"):
            left_collocates.append(collocate[0])
        
        right_collocates = []
        for collocate in right_collo.get_topn_collocates(node, n=TOPN, by="Gsq"):
            right_collocates.append(collocate[0])
        
        with open("compare.txt", "a") as f:
            f.write(f"Timestep: {ts}\tsrc: {src}\tnode: {node}\n")
            f.write(f"   left : {', '.join(left_collocates)}\n")
            f.write(f"   right: {', '.join(right_collocates)}\n")
            f.write("\n\n")

