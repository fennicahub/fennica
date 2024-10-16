#%%
import os
import pandas as pd
from tqdm import tqdm
#%%
output_fname = "full_fennica_1024.csv"
#%%
chunkfiles = [f"/mnt/trial/csvs/pivoted_callnumbered_csvs/piv_callnum_chunk_{n}.csv" for n in range(0,24)]
chunkfiles
#%%
# get header from 0th file and write it in the output file
header = []
with open(f"/mnt/trial/{output_fname}", "w") as outfile:
    with open(chunkfiles[0], "r") as f:
        lines = f.readlines()
        nmax = 2
        i = 0
        for line in lines:
            if i < nmax:
                outfile.write(line)
                i += 1
            

#%%
# loop over all the files, skip header (first 2 lines) and append the lines one by one to the output file
with open(f"/mnt/trial/{output_fname}", "a", newline='\n') as outfile:
    for chunkfile in tqdm(chunkfiles):
        with open(chunkfile, "r") as f:
            lines = f.readlines()
            nmin = 2
            i = 0
            for line in lines:
                if i >= nmin:
                    if i < 10 or True:
                        outfile.write(line)
                i += 1
#%%
#pd.read_csv(f"/home/ubuntu/git/fennica/{output_fname}", engine = 'c', delimiter = '\t', on_bad_lines='warn')


# %%
