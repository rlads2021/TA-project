head -n 1 kmt.csv > kmt_small.csv  # Get header
tail -n +2 kmt.csv | shuf -n 5000 >> kmt_small.csv  # sample

head -n 1 taiwan.csv > taiwan_small.csv  # Get header
tail -n +2 taiwan.csv | shuf -n 5000 >> taiwan_small.csv