# /// script
# dependencies = [
#   "pandas",
# ]
# ///

import os
import sys

import pandas as pd

# 1. Chemin vers le fichier à découper
input_file = "/home/gaspichou/Documents/git/permutation_entropy/Database/diabet/Hall/PDBT2/cgm_prediabetics.csv"

print(f"File loaded : {input_file}")

try:
    df = pd.read_csv(input_file, sep=None, engine="python")
except Exception as e:
    print(f"Erreur lors de la lecture du fichier : {e}")
    sys.exit(1)

# cleaning spaces
df.columns = df.columns.str.strip()

if "subjectId" not in df.columns:
    print(f"❌ 'subjectId' column does not exist. Columns founded : {list(df.columns)}")
    sys.exit(1)

output_dir = os.path.join(os.path.dirname(input_file), "subjects_split")
os.makedirs(output_dir, exist_ok=True)

grouped = df.groupby("subjectId")

for subject_id, group_df in grouped:
    file_name = f"subject_{subject_id}.csv"
    file_path = os.path.join(output_dir, file_name)
    group_df.to_csv(file_path, index=False)

print(f" Success! {len(grouped)} CSV files generated in:\n{output_dir}")
