import os
import re
import csv
import json
import random
import pathlib
import zipfile
import gdown
import jieba
import opencc
from tqdm import tqdm


with open("keyterms.txt", encoding="utf-8") as f:
    KEYTERMS = { l.strip() for l in f  if l.strip() != "" }
WEIBO_RAW = [ 
    "raw/weibo/kmt.csv",       # test: raw/weibo/kmt_small.csv
    "raw/weibo/taiwan.csv"     # test: raw/weibo/taiwan_small.csv
    ]
PTT_RAW = "raw/ptt_taiwan/"          # test: raw/ptt/
WEIBO_SEGGED = 'raw/weibo_sampled.csv'  # test: raw/weibo.csv
PTT_SEGGED = 'raw/ptt_sampled.csv'      # test: raw/ptt.csv
TS_COLLAPSED = pathlib.Path('time_sliced_collapsed/')
LSA_TERM = 'keyterm_annotated_lsa.csv'
LSA_DOC = 'doc_annotated_lsa.csv'
EMBEDDING_TRAIN = 'keyterm_annotated_wv_train.txt'

jieba.set_dictionary('jieba_large_dict.txt')
with open("custom_dict.txt", encoding="utf-8") as f:
    for w in f: 
        w = w.strip()
        if w != "": jieba.add_word(w)


def main():
    # Download raw data from Google Drive
    # download_data_weibo("raw/weibo/")
    # download_data_ptt("raw/")
    
    # # Convert raw data to segmented csv files
    # ptt_json_to_csv(force=True)
    # weibo_rawcsv_to_csv(force=True)

    # # Post sampling & timestep split
    # run_sample_posts()

    # Prepare data for Collocation/DependencyParsing/WordFreq analyses
    time_slice_collapse()

    # Prepare data for LSA doc vector extraction
    lsa_doc()

    # Prepare data for LSA term vector extraction
    annotate_keyterms()

    # Prepare data for training word Embeddings
    create_wv_train_text()



def create_wv_train_text():
    """Merge texts from LSA_DATA

    Output:
        EMBEDDING_TRAIN
    """
    with open(EMBEDDING_TRAIN, "w", encoding="utf-8") as fout:
        with open(LSA_TERM, encoding="utf-8", newline="") as fin:
            reader = csv.DictReader(fin)
            for row in reader:
                fout.write(row["text"])
                fout.write('\n')


def annotate_keyterms():
    """Annotate keyterms with timestamp & source info
       Prepare data for LSA analyses

    Output:
        LSA_TERM
    """
    with open(LSA_TERM, "w", encoding="utf-8", newline="") as fout:
        writer = csv.writer(fout)
        writer.writerow(["docid", "text"])
        
        segged_csv = [pathlib.Path(WEIBO_SEGGED), pathlib.Path(PTT_SEGGED)]
        for fp in segged_csv:
            src = fp.stem.split("_")[0]

            with open(fp, encoding="utf-8", newline="") as fin:
                reader = csv.DictReader(fin)
                
                for row in reader:
                    # Get time step info
                    ts = row['ts']

                    # Annotate terms with src & time step info
                    anno = f"{src}_T{ts}"
                    text = '\u3000'.join( f"{t}_{anno}" if t in KEYTERMS else t for t in row["text"].split('\u3000') )

                    # Save to new CSV
                    docid  = f"{src}_{row['id']}"
                    writer.writerow([docid, text])


def lsa_doc():
    """Annotate each document for timestep info for LSA analysis
    """
    with open(LSA_DOC, "w", encoding="utf-8", newline="") as fout:
        writer = csv.writer(fout)
        writer.writerow(["docid", "text"])
        
        segged_csv = [pathlib.Path(WEIBO_SEGGED), pathlib.Path(PTT_SEGGED)]
        for fp in segged_csv:
            src = fp.stem.split("_")[0]

            with open(fp, encoding="utf-8", newline="") as fin:
                reader = csv.DictReader(fin)
                
                for row in reader:
                    # Get time step info
                    ts = row['ts']

                    # Annotate doc with src & time step info
                    docid = f"{src}_{row['id']}_T{ts}"

                    # Save to new CSV
                    writer.writerow([docid, row["text"]])


def time_slice_collapse():
    """Concat post data into a time-sliced corpus with 12 time steps
       Prepare data for Collocation/DependencyParsing/WordFreq analyses

    Outputs: 
        TS_COLLAPSED / ptt_0.txt
        TS_COLLAPSED / ptt_1.txt
        ...
        TS_COLLAPSED / ptt_12.txt
        TS_COLLAPSED / weibo_0.txt
        ...
    """
    # Clea up
    for fp in TS_COLLAPSED.glob("*.txt"): fp.unlink()

    segged_csv = [pathlib.Path(WEIBO_SEGGED), pathlib.Path(PTT_SEGGED)]
    for fp in segged_csv:
        src = fp.stem.split("_")[0]

        with open(fp, encoding="utf-8", newline="") as fin:
            reader = csv.DictReader(fin)
            
            for row in reader:
                ts = row['ts']
                
                with open(TS_COLLAPSED / f"{src}_{ts}.txt", "a", encoding="utf-8") as f:
                    f.write(row['text'])
                    f.write('\n')


def run_sample_posts():
    """Run R script to split time steps & balance corpus data
    """
    cwd = os.getcwd()
    os.chdir("raw/")
    os.system("Rscript sample_posts.R")
    os.chdir(cwd)


def weibo_rawcsv_to_csv(force=False):
    if not force:
        if pathlib.Path(WEIBO_SEGGED).exists(): return

    clean = CleanText()
    with open(WEIBO_SEGGED, "w", encoding="utf-8", newline="") as fout:
        writer = csv.writer(fout)
        writer.writerow(["id", "date", "text"])
        id_count = 0

        for fp in WEIBO_RAW:
            # Set progress bar
            pbar = tqdm(total=sum(1 for line in open(fp, encoding="utf-8")))
            with open(fp, encoding="utf-8", newline="") as fin:
                reader = csv.DictReader(fin)
                for row in reader:
                    pbar.update(1)
                    id_count += 1
                    try:
                        text = clean.clean_weibo(row['text'])
                    except:
                        continue
                    text = '\u3000'.join(text)
                    date = row["date"]
                    # date = fake_date()
                    # Write a row in csv
                    writer.writerow([id_count, date, text ])
            
            pbar.close()
                    

def ptt_json_to_csv(force=False):
    if not force:
        if pathlib.Path(PTT_SEGGED).exists(): return

    ptt = pathlib.Path(PTT_RAW)
    clean = CleanText()

    with open(PTT_SEGGED, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["id", "date", "text"])
        id_count = 1

        for fp in tqdm(list(ptt.glob("*.json"))):
            with open(fp, encoding="utf-8") as f: post = json.load(f)

            # Get info
            date = fp.stem[:8]
            date = f"{date[:4]}-{date[4:6]}-{date[6:]}"
            # date = fake_date()
            text = clean.clean_ptt(post["post_body"])  # Word segmentation
            text = "\u3000".join(text)

            # Write a row in csv
            writer.writerow([id_count, date, text])
            id_count += 1


######## Generate Fake Dates (used for testing) ############
def fake_date():
    days = [ i + 1 for i in range(28) ]
    day = random.sample(days, 1)[0]
    day = str(day).zfill(2)

    return f"{random.sample(TIME_STEPS, 1)[0]}-{day}"
############################################################


def download_data_weibo(tgt_dir):
    tgt_dir = pathlib.Path(tgt_dir)
    url_weibo = {
        "kmt": "https://drive.google.com/uc?id=1A0hRf9ptWg4w61w-ThJVdfrwfPGEe1g6",
        "taiwan": "https://drive.google.com/uc?id=1XoQThJfb8_Kxbte_5jKSlB8k57QSQjYY"
    }
    for n, url in url_weibo.items():
        outfile = tgt_dir / f"{n}.csv"
        if outfile.exists(): continue
        gdown.download(url, str(outfile))


def download_data_ptt(extract_to):
    tmp = 'tmp.zip'
    url = 'https://drive.google.com/uc?id=1Z47OBwU1-297aEm9Ovp-lxPCPgQuUodU'
    gdown.download(url, tmp)

    with zipfile.ZipFile(tmp,"r") as zip_ref:
        zip_ref.extractall(extract_to)
    
    os.remove(tmp)


class CleanText:
    """Clean text and perform word segmentation
    """
    def __init__(self):
        self.cc = S2T()
        self.ignore = {'\r', '\r\n', '\n', '\t', '--', '-', '_', '─', ' ', '￣'}
        self.pat_url = re.compile(r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\), ]|(?:%[0-9a-fA-F][0-9a-fA-F]))+')
        self.pat_unicode = re.compile(r'<U\+[0-9A-Z]{4}>')
        self.norm = {
            "中國台灣": "中國臺灣",
            "中華台北": "中華臺北",
            "台灣": "臺灣",
            "台獨": "臺獨",
            "台商": "臺商",
            "台北": "臺北",
            "台中": "臺中",
            "台南": "臺南",
        }

    def clean_weibo(self, text):
        text = self.cleanEscapedUnicode(text)
        text = self.cleanURL(text)
        text = self.ws(text)
        text = self.trim_segged(text)
        return self.cc.fromList(text)

    def clean_ptt(self, text, s2t=False):
        text = self.cleanURL(text)
        text = self.ws(text)
        text = self.trim_segged(text)
        return self.variation_normalize(text)

    def cleanURL(self, text):
        return self.pat_url.sub('REMOVEDURL', text)
    
    def cleanEscapedUnicode(self, text):
        unicodes = self.pat_unicode.findall(text)
        for char in unicodes:
            text = text.replace(char, decode_unicode(char))
        return text

    def ws(self, text):
        return jieba.cut(text, cut_all=False)

    def trim_segged(self, segged: list):
        return [tk for tk in segged if tk not in self.ignore]
    
    def variation_normalize(self, segged: list):
        return [ self.norm[tk] if tk in self.norm else tk for tk in segged ]
    

class S2T:
    def __init__(self, mode="s2t.json"):
        self.cc = opencc.OpenCC(mode)

    def fromStr(self, string: str):
        return self.cc.convert(string)
    
    def fromList(self, str_list: list):
        return [ self.cc.convert(s) for s in str_list ]


def decode_unicode(s: str):
    """Takes input as formats like <U+8C01> and returns a character
    """
    s = chr(92) + s.lower().replace('<', '').replace('>', '').replace('+', '')
    return s.encode('utf-8').decode('unicode_escape')


if __name__ == "__main__":
    main()
