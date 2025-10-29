import subprocess
import os
import pathlib as Path

# ==== PATH SETUP ====
PYTHON = "/home/lgg3230/venvs/lgg3230-py312/bin/python"
PYTHON_SCRIPTS_DIR = "/kellogg/proj/lgg3230/SteppingStones/code/dataprep/python_scripts"

# ==== SCRIPTS TO RUN (edit this list to add new ones) ====
scripts = [
    
    # Python scripts
    # f'{PYTHON} {PYTHON_SCRIPTS_DIR}/test.py',
    f'{PYTHON} {PYTHON_SCRIPTS_DIR}/00_end_year_spells.py',
    f'{PYTHON} {PYTHON_SCRIPTS_DIR}/01_quit_year_spells.py',
    f'{PYTHON} {PYTHON_SCRIPTS_DIR}/02_layoff_spells.py',
    f'{PYTHON} {PYTHON_SCRIPTS_DIR}/03_quiters_destinations.py'

]

# ==== RUN SCRIPTS SEQUENTIALLY ====
for cmd in scripts:
    print(f"\n=== Running: {cmd} ===")
    result = subprocess.run(cmd, shell=True)
    if result.returncode != 0:
        print(f"⚠️  Script failed with exit code {result.returncode}. Stopping.")
        break