#%%
import pandas as pd
import os
from tqdm import tqdm
#%%
path_csvs = "/mnt/trial/csvs"
# save picked field in a format "field_code"_"subfield_code"_"explanation.csv", for instance, "035_a_melinda_id.csv"
# select which columns to pick from  pivoted csvs, the list of columns to pick will be ready shortly
# priority fileds are 240_a_title, 100_a_author_name, 260_c_date_publication
columns_to_pick = [("035","a"), ("leader","-"),("008","-"),("100","a"),("100","d"),("041","a"),("240","a"),("245","a"),("245","b"),("260","a"),("260","b"),("300","c"),("300","a"),("310","a"), ("362","a"),("callnumbers","a"), ("080", "a"), ("250", "a"), ("250", "b")]
output_folder = "fields_picked"

output_folder_priority = ".."

#("035","a"),("100","a"),("100","d"),("041","a"),("240","a"),("245","a"),("245","b"),("260","a"),("260","b"),("260","c"),("310","a"),("362","a"),("502","a"),("502","c"),("502","d"), ("510","a"),("650","a"),("651","a"), ("710","a"),("720","a"), ("785","t"), ("852","a")
filename = "full_fennica.csv"
# folder = f"{os.getenv('HOME')}/git/pivoted_callnumbered_csvs"
folder = f"{path_csvs}/pivoted_callnumbered_csvs"
csv_filenames = list(os.walk(folder))[0][2]

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
#change the name of the file for a specific field and save in fields_picked
#df.to_csv(f"{output_folder}/lan_title_date.csv", sep = "\t", index=False)

#%%
#save priority_fields file in gzip in examples
filename = 'priority_fields'
compression_options = dict(method='zip', archive_name=f'{filename}.csv')
df.to_csv(f"{output_folder_priority}/priority_fields.zip", sep = "\t", index=False, compression=compression_options)
