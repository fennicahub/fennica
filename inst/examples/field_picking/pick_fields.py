#%%
# Use the code to pick certain fields.
# Usually the field_code has a subfield_code.

import pandas as pd
import os
from tqdm import tqdm

#%%
path_csvs = "/mnt/trial/csvs_holdingsit"

#%%

columns_to_pick = [("004", "-"), ("852", "a"), ("852", "b"), ("852", "c"), 
                   ("852", "d"), ("852", "e"), ("852", "f"), ("852", "g"), ("852", "u"), 
                   ("852", "h"), ("852", "i"), ("852", "j"), ("852", "k"), ("852", "l"), 
                   ("852", "m"), ("852", "x"), ("852", "z")]

"""
columns_to_pick = [
    ("001", "-"), ("LDR", "-"), ("008", "-"), ("035", "a"),
    ("100", "a"), ("100", "d"), ("100", "0"),
    ("041", "a"), ("041", "h"),
    ("240", "a"),
    ("245", "a"), ("245", "b"), ("245", "n"),
    ("260", "a"), ("260", "b"),
    ("264", "a"),
    ("300", "c"), ("300", "a"),
    ("310", "a"),
    ("362", "a"),
    ("080", "a"), ("080", "x"),
    ("655", "a"), ("650", "a"), ("500", "a"),
    ("700", "a"), ("700", "0"), 
    ("336", "a"),  # content type
    ("505", "a"),  # contents
    ("520", "a"),  # summary
    ("246", "a"),  # variant title
    ("490", "a"),  # series
    ("502", "a"),  # dissertation
    ("130", "a"),  # uniform title main
    ("110", "a"),  # corporate author
    ("111", "a"),  # event author
]
"""

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
filename = "holdingsit_042026"
df.to_csv(f"{filename}.csv", sep="\t", index=False)

# %%