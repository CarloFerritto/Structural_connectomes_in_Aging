import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.stats import entropy

# --- PARAMETERS ---
input_file = "dataset.xlsx"       # File Excel originale
output_file = "selected_patients.xlsx"  # File Excel di output
col_wmh = "WMH_WM"
col_gender = "Sex"
col_age = "Age"
age_threshold = 65
n_select = 50
n_bins = 20
np.random.seed(42)

# --- DATA LOADING ---
df_all = pd.read_excel(input_file,sheet_name="Tractography")

# --- AGE FILTER ---
if col_age not in df_all.columns:
    raise ValueError(f"The column '{col_age}' is not present in the Excel file.")
df = df_all[df_all[col_age] >= age_threshold].reset_index(drop=True)

print(f"✅ Found {len(df)} patients aged ≥ {age_threshold}")

if len(df) < n_select:
    raise ValueError(f"There are not enough patients aged ≥ {age_threshold} to select {n_select}.")

# --- SELECTABLE DATA ---
wmh_values = df[col_wmh].values
genders = df[col_gender].values
n_total = len(df)

target_gender_count = {'M': n_select // 2, 'F': n_select - n_select // 2}

# --- OBJECTIVE FUNCTION ---
def objective(indices):
    subset = wmh_values[indices]
    hist, _ = np.histogram(subset, bins=n_bins,
                           range=(wmh_values.min(), wmh_values.max()), density=True)
    uniform = np.ones_like(hist) / len(hist)
    kl = entropy(hist + 1e-8, uniform)
    selected_genders = genders[indices]
    penalty = sum(abs((selected_genders == g).sum() - target_gender_count[g]) for g in target_gender_count)
    return kl + 0.0005 * penalty

# --- SIMULATED ANNEALING ---
def simulated_annealing(iterations=2000, T_start=1.0, T_min=1e-3, alpha=0.95):
    current = np.random.choice(n_total, size=n_select, replace=False)
    current_score = objective(current)
    best = current.copy()
    best_score = current_score
    T = T_start

    for i in range(iterations):
        print(f"Iterazione {i+1}/{iterations}, T={T:.4f}, Score={current_score:.4f}")
        not_sel = list(set(range(n_total)) - set(current))
        i_out = np.random.randint(n_select)
        i_in = np.random.choice(not_sel)
        candidate = current.copy()
        candidate[i_out] = i_in
        score = objective(candidate)

        if score < current_score or np.random.rand() < np.exp(-(score - current_score) / T):
            current, current_score = candidate, score
            if current_score < best_score:
                best, best_score = current.copy(), current_score

        T = max(T_min, T * alpha)

    return best, best_score

# --- EXECUTION ---
best_idx, best_score = simulated_annealing()

# --- SAVING ---
df_selected = df.iloc[best_idx].copy()
df_selected = df_selected.sort_values(by=col_wmh)
df_selected.to_excel(output_file, index=False)
print(f"✅ Selected patients saved to: {output_file}")

# --- PLOT ---
plt.hist(df_selected[col_wmh], bins=n_bins, density=True, alpha=0.7, label="Selected")
plt.axhline(1/n_bins, color='red', linestyle='--', label='Ideal Uniform')
plt.title(f'WMH Distribution + Gender Balanced (score={best_score:.4f})')
plt.xlabel("WMH")
plt.ylabel("Density")
plt.legend()
plt.tight_layout()
plt.show()
