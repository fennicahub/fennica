#%%
#Use the code to pick certain fields. 
#Usually the field_code has a subfield_code 
#but not in the case of leader fields 

#%%
import pandas as pd
import os
from tqdm import tqdm
import numpy as np
import more_itertools as mit
# %%
path_csvs = "/mnt/trial/csvs"
# list of files in pivoted_csvs folder
folder = f"{path_csvs}/pivoted_csvs"
csv_filenames = list(os.walk(folder))[0][2]
csv_filenames
#%%
# # select which columns to pick from  pivoted csvs
# columns_to_pick = [("001","a"),]

# # load specific columns and create a big dataframe
# dfs = []
# for filename in tqdm(csv_filenames):
#     df = pd.read_csv(f"{folder}/{filename}", sep='\t', header=[0,1])[columns_to_pick]
#     dfs += df,

# #%%
# df = pd.concat(dfs, ignore_index=True)
#%%
# df.to_csv("fields_picked/050a.csv", sep = "\t", index=False)


# %%
#check for all available fields
# pd.read_csv(f"{folder}/{filename}", sep='\t', header=[0,1]).columns.levels[0]

#%%
# load callnumbers database
df_callnumbers = pd.read_table('../../fen-callnumbers-20220902.tsv.gz', compression='gzip', sep="\t")
df_callnumbers.head(50)

#%%
# create new column where entries in f035 separated by space are combined into lists
df_callnumbers["f035a_list"] = df_callnumbers["f035a"].str.split(" ")
#%%
# explode lists of more than value into more than one row
df_callnumbers_exploded = df_callnumbers.explode("f035a_list", ignore_index=True)
#%%
# only keep those rows where the f035a_list starts with FCC 
df_callnumbers_exp_filtered = df_callnumbers_exploded[df_callnumbers_exploded["f035a_list"].str.startswith("FCC", na = False)]
#%%
# rename the FCC to (FI-MELINDA) 
df_callnumbers_exp_filtered["melinda_id"] = df_callnumbers_exp_filtered["f035a_list"].replace("FCC", "(FI-MELINDA)", regex=True)
#%%
# drop unnecessary columns
df_callnumbers_exp_filtered.drop(columns=["biblionumber","holding_id","f035a","f035a_list"], inplace=True)
#%%
# group by melinda_id and combine duplicate melinda_id's by |
df_callnumbers_grouped = df_callnumbers_exp_filtered.groupby("melinda_id").agg(lambda x: '|'.join([str(y) for y in x]))
#%%
# make new callnumbers df with proper column names
df_callnumbers_final = pd.DataFrame(df_callnumbers_grouped.reset_index().to_numpy(), columns=pd.MultiIndex.from_tuples([("035","a"),("callnumbers","a")]))
#%%
df_callnumbers_final

#%%
# df.merge(df_callnumbers_final, on=[("035","a")], how="left")
#%%
# Main loop:
# load a couple of csvs from pivoted_csvs, 
# concatenate them into a dataframe,
# explode the ("035", "a") column by | into multiple rows
# merge with df_callnumbers_final to add a new column
# save as new csv into pivoted_callnumbered_csvs

#%%
# use more_itertools package to create a list of chunks from the original list of files. chunks of size 5
csv_filenames_chunks = list(mit.chunked(csv_filenames, 5))
csv_filenames_chunks
#%%
for i, chunk in enumerate(csv_filenames_chunks):
    print(f"chunk number {i} out of {len(csv_filenames)/5}")
    df_temps = []
    for filename in chunk:
        # load a pivoted csv
        df_temp = pd.read_csv(f"{folder}/{filename}", sep='\t', header=[0,1,], index_col=0)
        # reset it's index to make record_number column again
        df_temp.reset_index(inplace=True)
        df_temps += df_temp, 

    # concatenate the dataframes in a list into one long one, ignoring the index
    df_temp = pd.concat(df_temps, ignore_index=True)

    # Create a new column , which is a list instead of melinda ID's separated by |
    df_temp[("035_list","a")] = df_temp[("035", "a")].str.split("|")
    # Explode each list into its own row
    df_temp_exploded = df_temp.explode([("035_list", "a")], ignore_index=True)
    # Drop original column with lists
    df_temp_exploded.drop(columns=[("035","a")], inplace=True)
    # Rename new exploded column into name of original field
    df_temp_exploded.rename(columns={"035_list":"035"},inplace=True)

    # add callnumbers from another dataframe on the "035","a" column as index
    df_temp_merged = df_temp_exploded.merge(df_callnumbers_final, on=[("035","a")], how="left")

    # save new dataframe as csv
    df_temp_merged.to_csv(f"{path_csvs}/pivoted_callnumbered_csvs/piv_callnum_chunk_{i}.csv", sep = '\t', index = False)
    # print(len(df_temp_merged.columns))

#%%
#### Since we did it all by chunks, not all chunks have the same column names, so we loop over all the csv's and combine their column names together


# get all possible column names and add them together to form a collection of all possible columns (field codes and subfield codes)
dfs_cols = []
for i, _ in enumerate(csv_filenames_chunks):
    # load a pivoted csv
    df_temp = pd.read_csv(f"{path_csvs}/pivoted_callnumbered_csvs/piv_callnum_chunk_{i}.csv", sep='\t', header=[0,1,], index_col=0, nrows=30)
    # reset it's index to make record_number column again
    df_temp.reset_index(inplace=True)
    # print the number of columns in the chunk
    print(len(df_temp.columns))
    # add the column names from the chunk to the list
    dfs_cols += df_temp.columns,

# combine all the columns in the list together using union
full_index = dfs_cols[0]
for i in range(1, len(dfs_cols)):
    full_index = full_index.union(dfs_cols[i])
#%%
# create empty dataframe which has all the columns 
df_fullindex = pd.DataFrame(columns = full_index)
#%%

for i, _ in tqdm(enumerate(csv_filenames_chunks)):
    # load a pivoted csv
    df_temp = pd.read_csv(f"{path_csvs}/pivoted_callnumbered_csvs/piv_callnum_chunk_{i}.csv", sep='\t', header=[0,1,], index_col=0)
    # reset it's index to make record_number column again
    df_temp.reset_index(inplace=True)
    # concatenate with empty df to get its column names but keep the data
    df_temp = pd.concat([df_temp, df_fullindex])
    # save
    df_temp.to_csv(f"{path_csvs}/pivoted_callnumbered_csvs/piv_callnum_chunk_{i}.csv", sep = '\t', index = False)

# %%
