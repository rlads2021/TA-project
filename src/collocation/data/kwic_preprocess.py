#%%
import json
import pathlib
from tqdm import tqdm

FILTER_TERMS = set("大陸 臺灣 中國 日本 韓國 美國".split(" "))

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


def read_textfile(fp):
    src, ts = fp.stem.split("_")
    with open(fp) as f:
        text = []
        for line in f:
            line = line.strip()
            if line == "": continue
            skip = True
            for term in FILTER_TERMS:
                if term in line.split('\u3000'):
                    skip = False
                    break
            if skip: continue

            sentence = []
            for tk in line.split("\u3000"):
                tk = tk.strip()
                if tk == "": continue
                token = {
                    'w': tk,
                    't': ts,
                }
                sentence.append(token)
            if len(sentence) != 0:
                text.append(sentence)
    return text


if __name__ == "__main__":
    main()
    # pass
# %%
