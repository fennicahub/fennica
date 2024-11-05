#%%
#Use the code to pick certain fields. 
#Usually the field_code has a subfield_code. 
import pandas as pd
import os
from tqdm import tqdm
#%%
path_csvs = "/mnt/trial/csvs"
#%%
columns_to_pick =[("035","a"),("leader", "nan"),("008", "nan"),("100","a"),("100","d"),
("041","a"),("041","h"),("042","a"),("240","a"),("245","a"),("245","b"),("250","a"), ("250","b"),("260","a"),("260","b"),
("300","c"),("300","a"),("310","a"),("362","a"),("callnumbers","a"),("080","a"),
("080","8"),("080","x"), ("245", "n"), ("655", "a"), ("650", "a"), ("700", "a"), ("264", "a")]
#%%
output_folder = "fields_picked"
#%%
output_folder_priority = ".."

#%%
#filename = "full_fennica_1024.csv"
folder = f"{path_csvs}/pivoted_callnumbered_csvs"

csv_filenames = list(os.walk(folder))[0][2]

print(csv_filenames)

#%%
# load specific columns and create a big dataframe
dfs = []
for filename in tqdm(csv_filenames):
    df = pd.read_csv(f"{folder}/{filename}", sep='\t', header=[0,1], low_memory = False)[columns_to_pick]
    dfs += df,

#%%
df = pd.concat(dfs, ignore_index=True)
#%%
#df_chunks = pd.read_csv(f"{folder}/{filename}", chunksize = 1_000_000, sep='\t', header=[0,1])
#pd.concat(df_chunks)

#%%
#change the name of the file for a specific field and save in fields_picked
#df.to_csv(f"{output_folder}/lan_title_date.csv", sep = "\t", index=False)

#%%
#save priority_fields file in gzip in examples
filename = 'priority_fields'
df.to_csv(f"{output_folder_priority}/{filename}.csv", sep="\t", index=False)

# %%
