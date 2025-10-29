# %%
import pandas as pd
import numpy as np
from pathlib import Path
import shutil
import re
import matplotlib.pyplot as plt
import seaborn as sns

# %%
plots_dir = Path("/Users/luisg/Desktop/SteppingStones_Parent/SteppingStones/paper/results/figures/stylized_facts")
plots_dir.mkdir(parents=True, exist_ok=True)

# %%
df_year_end = pd.read_stata("/Users/luisg/Desktop/SteppingStones_Parent/SteppingStones/data/interim/sample/RAIS_panel_endyear.dta",convert_categoricals=False)
df_quiters = pd.read_stata("/Users/luisg/Desktop/SteppingStones_Parent/SteppingStones/data/interim/quit_spells/RAIS_panel_quits.dta",convert_categoricals=False)
df_ipca = pd.read_csv("/Users/luisg/Desktop/SteppingStones_Parent/SteppingStones/data/raw/ipca.csv")

# %%
# merge ipca to df_year_end
d_year_end_ipca = df_year_end.merge(df_ipca, how='left', left_on=['year'], right_on=['year'])
d_year_end_ipca[['year','PIS','ipca_2015']].head()

# %%
# deflate wage variables in d_year_end_ipca:

wage_vars = ['remmedr', 'remdezr', 'remmedr_h', 'remdezr_h']

# create new deflated wage variables
for var in wage_vars:
    deflated_var = 'r_' + var 
    d_year_end_ipca[deflated_var] = d_year_end_ipca[var] / d_year_end_ipca['ipca_2015'] * 100
    loged_var = 'l' + deflated_var
    d_year_end_ipca[loged_var] = np.log(d_year_end_ipca[deflated_var].replace(0, np.nan))

d_year_end_ipca[['year','PIS','ipca_2015'] + wage_vars + ['r_' + var for var in wage_vars] + ['l' + 'r_' + var for var in wage_vars]].head()

# %%
# Generate quality of origin firms according to deflated average wages over the years

df_origin_quality = (d_year_end_ipca.groupby('identificad').agg(
    avg_r_remmedr = ('r_remmedr', 'mean'),
    avg_r_remdezr = ('r_remdezr', 'mean'),
    avg_r_remmedr_h = ('r_remmedr_h', 'mean'),
    avg_r_remdezr_h = ('r_remdezr_h', 'mean'),
    avg_lr_remmedr = ('lr_remmedr', 'mean'),
    avg_lr_remdezr = ('lr_remdezr', 'mean'),
    avg_lr_remmedr_h = ('lr_remmedr_h', 'mean'),
    avg_lr_remdezr_h = ('lr_remdezr_h', 'mean')
).reset_index())




df_origin_quality['identificad'].is_unique 

# %%
# Generate quality of origin by year:

df_origin_quality_year = (d_year_end_ipca.groupby(['year','identificad']).agg( 
    avg_r_remmedr_yearly = ('r_remmedr', 'mean'),
    avg_r_remdezr_yearly = ('r_remdezr', 'mean'),
    avg_r_remmedr_h_yearly = ('r_remmedr_h', 'mean'),
    avg_r_remdezr_h_yearly  = ('r_remdezr_h', 'mean'), 
    avg_lr_remmedr_yearly = ('lr_remmedr', 'mean'),
    avg_lr_remdezr_yearly = ('lr_remdezr', 'mean'),
    avg_lr_remmedr_h_yearly = ('lr_remmedr_h', 'mean'),
    avg_lr_remdezr_h_yearly  = ('lr_remdezr_h', 'mean')
).reset_index())

# %%
# Generate histogram of avg_remmedr:

# Plot histogram
plt.figure(figsize=(10,6))
plt.hist(df_origin_quality['avg_lr_remmedr'], bins=50, color='skyblue', edgecolor='black')
plt.title('Histogram of Log-Transformed Average Monthly Real Wage (Remmedr)')
plt.xlabel('Log Average Monthly Real Wage (Values Deflated to 2015)')
plt.ylabel('Frequency')
plt.grid(axis='y', alpha=0.75)
# Save plot
plt.savefig(plots_dir / 'histogram_avg_remmedr.png')
plt.show()

# %%
# Now, we make histograms for the yearly origin quality variables, only for lr_remmedr_yearly, but we do one graph per year:
for year in range(2006,2016):
    df_temp = df_origin_quality_year[df_origin_quality_year['year'] == year]
    plt.figure(figsize=(10,6))
    plt.hist(df_temp['avg_lr_remmedr_yearly'], bins=50, color='lightgreen', edgecolor='black')
    plt.title(f'Histogram of Log-Transformed Average Monthly Real Wage (Remmedr) - Year {year}')
    plt.xlabel('Log Average Monthly Real Wage (Values Deflated to 2015)')
    plt.ylabel('Frequency')
    plt.grid(axis='y', alpha=0.75)
    # Save plot
    plt.savefig(plots_dir / f'histogram_avg_remmedr_{year}.png')
    # plt.show()



# %% [markdown]
# # Now, instead of individual yearly histogram plots, we do lines and overlay each year to see evolution of quality distribution:
# 
# 

# %%
plt.figure(figsize=(10,6))
sns.kdeplot(
    data=df_origin_quality_year,
    x='avg_lr_remmedr_yearly',
    hue='year',
    common_norm=False,   # allows densities to vary freely
    fill=False,          # only outlines
    linewidth=1.5,
    palette='viridis'
)

plt.title('Kernel Density of Log Average Monthly Real Wage (Firm Quality) by Year')
plt.xlabel('Log Average Monthly Real Wage (deflated to 2015)')
plt.ylabel('Density')
plt.grid(alpha=0.3)
plt.tight_layout()

plt.savefig(plots_dir / 'kernel_density_firm_quality_over_years.png')
plt.show()

# %%
# Find quiters of year t in end of year data of year t+1. we need to get the origin and destination firm qualities

df_quiters['origin_id'] = df_quiters['identificad']
df_quiters['origin_year'] = df_quiters['year']
df_quiters['destination_year'] = df_quiters['year'] + 1

dest_matches = df_quiters.merge(
    d_year_end_ipca[['PIS','identificad', 'year']],
    left_on=['PIS', 'destination_year'],
    right_on=['PIS', 'year'],
    how='left',
    suffixes=('_origin', '_destination')
)

# %%
len(dest_matches['identificad_destination'].isna())


# %% [markdown]
# There is a potential issue with this quality measure:  I am not excluding the people who swithced jobs from one year to the next


