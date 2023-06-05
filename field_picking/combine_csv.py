#%%
import pandas as pd
import os
from tqdm import tqdm
import numpy as np
import more_itertools as mit
# %%
# list of files in pivoted_csvs folder
folder = "pivoted_csvs"
csv_filenames = list(os.walk(folder))[0][2]
#%%
# select which columns to pick from  pivoted csvs
columns_to_pick = [("035","a"),]

# load specific columns and create a big dataframe
dfs = []
for filename in tqdm(csv_filenames):
    df = pd.read_csv(f"{folder}/{filename}", sep='\t', header=[0,1])[columns_to_pick]
    dfs += df,

#%%
df = pd.concat(dfs, ignore_index=True)
#%%
df.to_csv("fields_picked/050a.csv", sep = "\t", index=False)


# %%
#check for all available fields
pd.read_csv(f"{folder}/{filename}", sep='\t', header=[0,1]).columns.levels[0]

