import pandas as pd

# Classified id
DIABETIC_IDS = [
    "1636-69-001", "1636-69-091", "2133-004", "2133-018", "2133-039"
]

PREDIABETIC_IDS = [
    "1636-69-026", "1636-69-032", "1636-69-090", "1636-69-114", "1636-70-1005",
    "1636-70-1010", "2133-015", "2133-017", "2133-019", "2133-021", "2133-024",
    "2133-027", "2133-035", "2133-036"
]

NORMOGLYCEMIC_IDS = [
    "1636-69-028", "1636-69-035", "1636-69-048", "1636-69-053", "1636-69-060",
    "1636-69-064", "1636-69-069", "1636-69-100", "1636-69-104", "1636-69-107",
    "1636-69-111", "1636-69-123", "1636-70-1002", "1636-70-1003", "1636-70-1008",
    "2133-001", "2133-002", "2133-003", "2133-006", "2133-007", "2133-008",
    "2133-009", "2133-010", "2133-011", "2133-012", "2133-013", "2133-020",
    "2133-022", "2133-023", "2133-025", "2133-026", "2133-028", "2133-030",
    "2133-032", "2133-033", "2133-037", "2133-040", "2133-041"
]

df = pd.read_csv("/home/gaspichou/Documents/git/permutation_entropy/Database/diabet/Hall/raw_datas.csv", sep='\t')

df_diabetic = df[df['subjectId'].isin(DIABETIC_IDS)]
df_prediabetic = df[df['subjectId'].isin(PREDIABETIC_IDS)]
df_normoglycemic = df[df['subjectId'].isin(NORMOGLYCEMIC_IDS)]

df_diabetic.to_csv("cgm_diabetics.csv", index=False)
df_prediabetic.to_csv("cgm_prediabetics.csv", index=False)
df_normoglycemic.to_csv("cgm_normoglycemic.csv", index=False)

print("--- Split sum up ---")
print(f"Total measurements : {len(df)}")
print(f"Diabetics      : {len(df_diabetic)} (5 sujets)")
print(f"Prediabetics    : {len(df_prediabetic)} (14 sujets)")
print(f"Non diabetics   : {len(df_normoglycemic)} (38 sujets)")
