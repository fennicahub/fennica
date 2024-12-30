#%%
import pandas as pd
import math
from tqdm import tqdm
import numpy as np
#%%
path_csvs = "/mnt/trial/csvs"
#https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/full.csv
full_path = f"{path_csvs}/raw_full_fennica.csv"
# df = pd.read_csv(full_path, engine='c', low_memory=False)
# df = pd.read_csv(full_path, engine='pyarrow', dtype=str)
#%%
test = False
# df_small = pd.read_csv(full_path, engine='c', nrows = 10000)
print("Loading csv")
if test:
    df = pd.read_csv(full_path, engine='c', nrows = 10000, dtype={"value": str})
else:
    df = pd.read_csv(full_path, engine='pyarrow', dtype={"value": str})
print("Loaded csv")

#%%
df = df.drop(columns=['field_number','subfield_number'])
# # %%
# # print big table
# # with pd.option_context('display.max_rows', None, 'display.max_columns', None):  # more options can be specified also
# #     print(df.query("record_number == 400")) 
df["subfield_code"] = df["subfield_code"].replace(np.nan, "-")
#%%
if test:
    # # check if there are duplicate melinda codes (035a)
    #df_small_035 = df_small.query("field_code == '035' and subfield_code == 'a'")
    df_001 = df.query("field_code == '001' and subfield_code == '-'")
    df_001
#%%
if test:

    df_001.drop(columns=['field_code', 'subfield_code', ], inplace=True)
    df_001.rename(columns={'value': 'melinda_id'}, inplace=True)
# %%
if test:
    df_merged = df.merge(df_001, on="record_number")
#%%
if test:
    df_dup = df[df.duplicated(keep=False, subset=['record_number','field_code','subfield_code'])].sort_values(['record_number','field_code','subfield_code'])
#%%
if test:
    df_dup.to_csv("test.csv", sep = '\t', index = False)
#%%
# join duplicate entries by |
if test:
    df_pivoted = df.pivot_table(index = 'record_number', columns = ['field_code', 'subfield_code'], values = ['value'], aggfunc = lambda x: '|'.join([str(y) for y in x]),dropna=False)['value']
#%%
if test:
    df_pivoted.to_csv("test_pivoted.csv")
#%%
# to split into chunks, get number of chunks with 10k rows each
max_record_number = df['record_number'].astype(int).max()
max_record_number


chunk_size = 10_000
num_chunks = math.ceil(max_record_number / chunk_size)
num_chunks
#%%
print("Preprocessing done, pivoting table chunks...")
# for each chunk, pivot the table and save as csv
for i in tqdm(range(num_chunks)):
    df_test = df[df['record_number'].astype(int).between(1 + i * chunk_size,(i + 1)* chunk_size)]
    df_test_pivoted = df_test.pivot_table(index = 'record_number', columns = ['field_code', 'subfield_code'], values = ['value'], aggfunc = lambda x: '|'.join([str(y) for y in x]), dropna=False)['value']
    if test:
        df_test_pivoted.to_csv(f"{path_csvs}/pivoted_csvs/pivoted_chunk_test{i}.csv", sep = '\t')
    else:
        df_test_pivoted.to_csv(f"{path_csvs}/pivoted_csvs/pivoted_chunk_{i}.csv", sep = '\t')
#%%