# %%
import pandas as pd
import numpy as np
from pathlib import Path
import shutil
import re

# %%
# Configure source and output directories:
src_dir = Path("/kellogg/proj/lgg3230/SteppingStones/data/interim/rj_sample") 
out_dir = Path("/kellogg/proj/lgg3230/SteppingStones/data/interim/layoff_spells")
# Create output directory if it doesn't exist
out_dir.mkdir(parents=True, exist_ok=True)

# %%
# List all .dta files in the source directory
dta_files = sorted(src_dir.glob("RAIS_*.dta"))
print(f"Found {len(dta_files)} files")


# %%
# Process each year's data and build panel of unique laid off workers
df_list = []

rng  = np.random.default_rng(seed=123)

for f in dta_files:
    # Extract year from filename
    year = re.search(r"RAIS_(\d{4})\_rj.dta", f.name).group(1)
    print(f"Processing year {year}...")
    # Load data
    df_year = pd.read_stata(f, convert_categoricals=False)
    # Filter to laid off workers only (causadesli 10 or 11)
    df_year['layoff'] = ((df_year['causadesli']==10 )| (df_year['causadesli']==11)).astype(int)
    # Keep only laid off workers
    df_year = df_year[df_year['layoff'] == 1].copy()
    # Genenrate hourly average wage per month
    df_year['remmedr_h'] = (df_year['remmedr'])/(df_year['horascontr']*4.348)
    # Generate hourly total wage for december wage
    df_year['remdezr_h'] = (df_year['remdezr'])/(df_year['horascontr']*4.348)
    # Add random column for tie-breaking
    df_year['_rand'] = rng.random(len(df_year))

    # Select unique worker with max hours worked; if tie, max avg wage; if tie, random
    worker_id  = df_year['PIS'] # Unique worker identifier
    hours = df_year['horascontr'] # Hours worked
    avg_w_h = df_year['remmedr_h'] # Average hourly wage
    max_hours = hours.groupby(worker_id).transform('max') # identify max hours per worker
    rank1 = hours.eq(max_hours) # boolean mask for max hours
    max_avg_w_and_rank1 = avg_w_h.where(rank1).groupby(worker_id).transform('max') # max avg wage among max hours
    rank2 = rank1 & avg_w_h.eq(max_avg_w_and_rank1) # boolean mask for max avg wage among max hours
    idx = (
    df_year.loc[rank2]
      .groupby(worker_id[rank2])['_rand']   # <- use the column name here
      .idxmax()) # index of selected rows
      # Grab the winning rows
    df_selected = df_year.loc[idx].copy() # selected unique quitters
    df_selected['year'] = int(year) # add year column
    df_list.append(df_selected) # append to list
    print(f"  Selected {len(df_selected)} unique workers.") # log progress
    # build panel AFTER the loop (faster)
df_panel = pd.concat(df_list, ignore_index=True) # combine all years

# 1) Drop helper
if '_rand' in df_panel.columns:
    df_panel.drop(columns='_rand', inplace=True)

# 2) Replace +-inf from divisions
df_panel.replace([np.inf, -np.inf], np.nan, inplace=True)

# 3) Drop columns that are entirely NaN (e.g., clascnae95 in some years)
all_null_cols = [c for c in df_panel.columns if df_panel[c].isna().all()] # identify all-null columns
if all_null_cols:
    df_panel.drop(columns=all_null_cols, inplace=True)

# 4) Coerce object columns to pure strings (Stata requires string-like)
for c in df_panel.select_dtypes(include='object').columns:
    df_panel[c] = df_panel[c].astype(str).where(df_panel[c].notna(), None)

# 5) Pandas nullable integers (Int64) → float (to keep NaN)
for c in df_panel.columns:
    if str(df_panel[c].dtype) == 'Int64':
        df_panel[c] = df_panel[c].astype('float64')

# 6) Booleans → tiny ints
for c in df_panel.select_dtypes(include='bool').columns:
    df_panel[c] = df_panel[c].astype('int8')

# Save with UTF-8 Stata format
out_path = out_dir / "RAIS_panel_layoffs.dta" # output path
df_panel.to_stata(out_path, write_index=False, version=119) # save as Stata file
print(f"✅ Combined panel: {len(df_panel):,} rows → {out_path}")



