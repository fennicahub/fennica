#%%
import pandas as pd
import math
from tqdm import tqdm
#%%
path_csvs = "/mnt/trial/csvs"
#https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/full.csv
full_path = f"{path_csvs}/full.csv"
df = pd.read_csv(full_path, engine='c')

#%%
df_small = pd.read_csv(full_path, engine='c', nrows = 10000)

#%%
#df_small = df_small.drop(columns=['field_number','subfield_number'])
#%%
df_small.query("field_code == '008'")
# %%
# print big table
with pd.option_context('display.max_rows', None, 'display.max_columns', None):  # more options can be specified also
    print(df.query("record_number == 400"))    
#%%
# check if there are duplicate melinda codes (035a)
df_small_035 = df_small.query("field_code == '035' and subfield_code == 'a'")
#%%
df_small_035.drop(columns=['field_number', 'subfield_number', 'field_code', 'subfield_code', ], inplace=True)
df_small_035.rename(columns={'value': 'melinda_id'}, inplace=True)
df_small_035
#%%
df_small_merged = df_small.merge(df_small_035, on="record_number")
df_small_merged
#%%

#%%
df_small.head()
#%
#%%
df_sm_dup = df_small[df_small.duplicated(keep=False, subset=['record_number','field_code','subfield_code'])].sort_values(['record_number','field_code','subfield_code'])
#%%
df_sm_dup.to_csv("test.csv", sep = '\t', index = False)
#%%
df_dup = df[df.duplicated(keep=False, subset=['record_number','field_code','subfield_code'])].sort_values(['record_number','field_code','subfield_code'])
#%%
# join duplicate entries by |
df_small_pivoted = df_small.pivot_table(index = 'record_number', columns = ['field_code', 'subfield_code'], values = ['value'], aggfunc = lambda x: '|'.join([str(y) for y in x]), dropna=False)['value']
#%%
df_small_pivoted
#df_small_pivoted.loc[:,('value', '035','a')]
#%%
df_small_pivoted.to_csv("test_pivoted.csv")
#%%
# to split into chunks, get number of chunks with 10k rows each
max_record_number = df['record_number'].max()
max_record_number

chunk_size = 10_000
num_chunks = math.ceil(max_record_number / chunk_size)
num_chunks
#%%
# for each chunk, pivot the table and save as csv
for i in tqdm(range(num_chunks)):
    df_test = df[df['record_number'].between(1 + i * chunk_size,(i + 1)* chunk_size)]
    df_test_pivoted = df_test.pivot_table(index = 'record_number', columns = ['field_code', 'subfield_code'], values = ['value'], aggfunc = lambda x: '|'.join([str(y) for y in x]), dropna = False)['value']
    df_test_pivoted.to_csv(f"{path_csvs}/pivoted_csvs/pivoted_chunk_{i}.csv", sep = '\t')


#%%
# checked for duplicates
df_test = df[df['record_number'].between(8559,8559)]
df_test_pivoted = df_test.pivot_table(index = 'record_number', columns = ['field_code', 'subfield_code'], values = ['value'], aggfunc = lambda x: '|'.join([str(y) for y in x]))
df_test_pivoted

# %%
df.loc[df['value'].str.startswith("(FI-MELINDA)017493651", na = False)]
# %%
# check for duplicates in field 240a 
df_240 = df.query("field_code == '240' and subfield_code == 'a'")

title_counts = df_240.groupby('value').count()
title_counts[title_counts['record_number'] > 1]

# %%
title_counts['record_number'] > 1

# %%
df_dups = df[title_counts['record_number'] > 1]
#%%
df_small_merged['field_subfield_code']  = df_small_merged['field_code'].fillna('') + df_small_merged['subfield_code'].fillna('')
df_small_merged
#%%
df_small_merged
#%%
df_small_pivoted = df_small_merged.pivot_table(index = 'melinda_id', columns = ['field_code', 'subfield_code'], values = ['value'], aggfunc = 'sum')
#%%
df_small_pivoted.loc[:, ('value', '240', 'a' )].head(30)
#%%
df_small_merged
#%%
df_small.pivot_table(values = 'value', index = 'record_number', columns = ['field_code', 'subfield_code'], aggfunc = 'first')
#%%

#%%
df_dropped = df.drop(columns=['field_number','subfield_number'])
# %%
df_melinda_full = df_dropped.pivot_table(values = 'value', index = 'value', columns = ['field_code', 'subfield_code'], aggfunc = 'first')

#%%
df.head(50)