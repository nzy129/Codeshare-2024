import pandas as pd
import zipfile
import urllib.request
import numpy as np
import matplotlib.pyplot as plt
from Clean import clean_data
df = pd.DataFrame()
# I don't have 2023Q4 data yet
for y in [2019, 2020, 2021, 2022, 2023]:
    if y != 2023:
        for q in range(1, 5):
            output = clean_data(y, q)
            df = pd.concat([df, output], ignore_index=True)
    else:
        for q in range(1, 4):
            output = clean_data(y, q)
            df = pd.concat([df, output], ignore_index=True)

df.to_csv('Cleaned_2019_2023.csv', index=False)