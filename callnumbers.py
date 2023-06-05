 %%
df_callnumbers = pd.read_table('fen-callnumbers-20220902.tsv.gz', compression='gzip', sep="\t")
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


#%%
df.merge(df_callnumbers_final, on=[("035","a")], how="left")
#%%
# Main loop:
# load a couple of csvs from pivoted_csvs, 
# concatenate them into a dataframe,
# explode the ("035", "a") column by | into multiple rows
# merge with df_callnumbers_final to add a new column
# save as new csv into pivoted_callnumbered_csvs

#%%
# use more_itertools package to create a list of chunks from the original list of files. chunks of size 5
csv_filenames_chunks = mit.chunked(csv_filenames, 5)
csv_filenames_chunks

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
    df_temp_merged.to_csv(f"pivoted_callnumbered_csvs/piv_callnum_chunk_{i}.csv", index = False)



