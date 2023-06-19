#%%
import pandas as pd
import os
from tqdm import tqdm
#%%
# save picked field in a format "field_code"_"subfield_code"_"explanation.csv", for instance, "035_a_melinda_id.csv"

# select which columns to pick from  pivoted csvs
# priority fileds are 240_a_title, 100_a_author_name, 260_c_date_publication
columns_to_pick = [("100","a"),("035","a")]

# load specific columns and create a big dataframe
filename = "full_fennica.csv"
folder = "../../pivoted_callnumbered_csvs"
csv_filenames = list(os.walk(folder))[0][2]
csv_filenames
#%%

# load specific columns and create a big dataframe
dfs = []
for filename in tqdm(csv_filenames):
    df = pd.read_csv(f"{folder}/{filename}", sep='\t', header=[0,1])[columns_to_pick]
    dfs += df,

#%%
df = pd.concat(dfs, ignore_index=True)
#%%
#df_chunks = pd.read_csv(f"{folder}/{filename}", chunksize = 1_000_000, sep='\t', header=[0,1])
#pd.concat(df_chunks)

#%%
df.to_csv("fields_picked/100_a_author_name.csv", sep = "\t", index=False)


#%%
#check for all available fields
pd.read_csv(f"{folder}/{filename}", sep='\t', header=[0,1]).columns.levels[0]
