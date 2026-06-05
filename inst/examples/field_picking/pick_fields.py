#%%
# Use the code to pick certain fields.
# Usually the field_code has a subfield_code.

import pandas as pd
import os
from tqdm import tqdm

#%%
path_csvs = "/mnt/trial/csvs"

#%%
columns_to_pick = [("099", "a")]
#%%


#%%
output_folder = "field_picking"
folder = f"{path_csvs}/pivoted_csvs"
csv_filenames = list(os.walk(folder))[0][2]
print(csv_filenames)

#%%
# Load specific columns from each file.
# If some requested columns are missing, create them with NaN.
dfs = []

for filename in tqdm(csv_filenames):
    file_path = f"{folder}/{filename}"
    
    df = pd.read_csv(
        file_path,
        sep="\t",
        header=[0, 1],
        dtype=str,
        low_memory=False
    )
    
    # Add missing columns as NaN and keep only requested columns
    df = df.reindex(columns=pd.MultiIndex.from_tuples(columns_to_pick))
    
    dfs.append(df)

#%%
df = pd.concat(dfs, ignore_index=True)

#%%
# Save priority_fields file
filename = "field_099a"
df.to_csv(f"{filename}.csv", sep="\t", index=False)


# %%
