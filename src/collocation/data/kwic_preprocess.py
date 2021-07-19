#%%
import os
import json
import pathlib
from tqdm import tqdm

FILTER_TERMS = set("大陸|臺灣|中國|日本|美國|香港".split("|"))

p = pathlib.Path("time_sliced_collapsed/")
paths = {
    "ptt": p.glob("ptt*"),
    "weibo": p.glob("weibo*")
}

def main():
    for src in ["ptt", "weibo"]:
        fps = list(paths[src])
        with open(f"corpus_{src}.jsonl", "w") as f:
            for fp in tqdm(fps):
                text = read_textfile(fp)
                if len(text) == 0: continue
                json.dump({'text': text}, f, ensure_ascii=False)
                f.write('\n')
    
    os.system("cat corpus_ptt.jsonl > corpus.jsonl")
    os.system("cat corpus_weibo.jsonl >> corpus.jsonl")


def read_textfile(fp):
    src, ts = fp.stem.split("_")
    with open(fp) as f:
        text = []
        for line in f:
            line = line.strip()
            if line == "": continue
            line_terms = line.split('\u3000')
            skip = True
            for term in FILTER_TERMS:
                # Get terms around node word
                term_loc = [i for i, x in enumerate(line_terms) if x == term]
                if len(term_loc) == 0: continue
                window_terms = []
                for i in term_loc:
                    if i > 0:
                        window_terms.append(line_terms[i-1])
                    if i + 1 < len(line_terms):
                        window_terms.append(line_terms[i+1])

                # Check if matches collocates
                has_collo = False
                for collocate in get_collocates(term, src, ts):
                    if collocate in window_terms: 
                        has_collo = True
                        break
                if has_collo:
                    skip = False
                    break
            if skip: continue

            sentence = []
            for tk in line_terms:
                tk = tk.strip()
                if tk == "": continue
                token = {
                    'w': tk,
                    's': f"{src[0]}_{ts}",
                }
                sentence.append(token)
            if len(sentence) != 0:
                text.append(sentence)
    return text


def get_collocates(term, src, ts):
    with open(f"collocates/{term}.txt") as f:
        file = [ l for l in f]
    for i, line in enumerate(file):
        if line.startswith(f"timestep: {ts}"):
            data = file[i+1:i+5]
            break
    
    for line in data:
        line = line.strip()
        if line.startswith(f"front_{src[:3]}"):
            front = line.replace(f"front_{src[:3]}", "").strip().split("|")
        if line.startswith(f"back_{src[:3]}"):
            back = line.replace(f"back_{src[:3]}", "").strip().split("|")

    return front + back




if __name__ == "__main__":
    main()
    # pass
# %%
