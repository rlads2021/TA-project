import pathlib

p = pathlib.Path("time_sliced_collapsed/")

for src in ["ptt", "weibo"]:
    with open(f"{src}_000.txt", "w", encoding="utf-8") as fout:
        
        for fp in p.glob(f"{src}*.txt"):
            with open(fp, encoding="utf-8") as fin:
                f = fin.read()
            fout.write(f)
