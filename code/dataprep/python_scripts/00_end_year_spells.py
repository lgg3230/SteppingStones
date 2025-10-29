# %%
import pandas as pd
import numpy as np
from pathlib import Path
import shutil
import re

# %%
src_dir = Path("/kellogg/proj/lgg3230/SteppingStones/data/interim/rj_sample")
out_dir = Path("/kellogg/proj/lgg3230/SteppingStones/data/interim/sample")
out_dir.mkdir(parents=True, exist_ok=True)

# %%
dta_files = sorted(src_dir.glob("RAIS_*.dta"))
print(f"Found {len(dta_files)} files")


# %%
df_list = []

rng  = np.random.default_rng(seed=123)

for f in dta_files:
    year = re.search(r"RAIS_(\d{4})\_rj.dta", f.name).group(1)
    print(f"Processing year {year}...")
    df_year = pd.read_stata(f, convert_categoricals=False)
    df_year['emp_in_dec'] = ((df_year['empem3112']==1 )& (df_year['tempempr']>1)).astype(int)
    df_year = df_year[df_year['emp_in_dec'] == 1].copy()

    df_year['remmedr_h'] = (df_year['remmedr'])/(df_year['horascontr']*4.348)
    df_year['remdezr_h'] = (df_year['remdezr'])/(df_year['horascontr']*4.348)
    df_year['_rand'] = rng.random(len(df_year))

    worker_id  = df_year['PIS']
    hours = df_year['horascontr']
    avg_w_h = df_year['remmedr_h']
    max_hours = hours.groupby(worker_id).transform('max')
    max_hours.head()
    rank1 = hours.eq(max_hours)
    max_avg_w_and_rank1 = avg_w_h.where(rank1).groupby(worker_id).transform('max')
    rank2 = rank1 & avg_w_h.eq(max_avg_w_and_rank1)
    idx = (
    df_year.loc[rank2]
      .groupby(worker_id[rank2])['_rand']   # <- use the column name here
      .idxmax())
      # Grab the winning rows
    df_selected = df_year.loc[idx].copy()
    df_selected['year'] = int(year)
    df_list.append(df_selected)
    print(f"  Selected {len(df_selected)} unique workers.")
    # build panel AFTER the loop (faster)
df_panel = pd.concat(df_list, ignore_index=True)

# 1) Drop helper
if '_rand' in df_panel.columns:
    df_panel.drop(columns='_rand', inplace=True)

# 2) Replace +-inf from divisions
df_panel.replace([np.inf, -np.inf], np.nan, inplace=True)

# 3) Drop columns that are entirely NaN (e.g., clascnae95 in some years)
all_null_cols = [c for c in df_panel.columns if df_panel[c].isna().all()]
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
out_path = out_dir / "RAIS_panel_endyear.dta"
df_panel.to_stata(out_path, write_index=False, version=119)
print(f"✅ Combined panel: {len(df_panel):,} rows → {out_path}")



