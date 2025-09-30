import os
import pandas as pd
import numpy as np
import networkx as nx
from tqdm import tqdm
from concurrent.futures import ProcessPoolExecutor

# === CONFIG ===
BASE_PATH = "path_to_connectomes"
EXCEL_PATH = "path_to_dataset.xlsx"
SAVE_PATH = "path_to_save_metrics"

os.makedirs(SAVE_PATH, exist_ok=True)
    
TECHNIQUES = ["25", "30", "35", "40", "45", "50", "act", "no_act"]
TEMPLATES = ["MIITRA", "MNI152NLin2009cAsym"]

# === UTILS ===
def convert_excel_id_to_folder_id(excel_id):
    return "sub-" + excel_id.replace("_", "")

def load_connectome_matrix(filepath):
    return np.loadtxt(filepath)

def global_efficiency_weighted(G, weight="weight"):
    nodes = list(G.nodes)
    n = len(nodes)
    if n < 2:
        return 0.0

    path_lengths = dict(nx.all_pairs_dijkstra_path_length(G, weight=weight))
    total = 0.0
    count = 0

    for u in nodes:
        for v in nodes:
            if u != v:
                try:
                    d = path_lengths[u][v]
                    total += 1 / d
                    count += 1
                except KeyError:
                    continue  

    return total / count if count > 0 else 0.0

def compute_local_efficiency_for_node(args):
    node, matrix = args
    G = nx.from_numpy_array(matrix)
    
    
    inv_weights = {(u, v): 1 / d["weight"] if d["weight"] > 0 else 1e6
                   for u, v, d in G.edges(data=True)}
    nx.set_edge_attributes(G, inv_weights, name="inv_weight")

    neighbors = list(G.neighbors(node))
    if len(neighbors) < 2:
        return (node, 0.0)

    subgraph = G.subgraph(neighbors).copy()
    path_lengths = dict(nx.all_pairs_dijkstra_path_length(subgraph, weight="inv_weight"))

    total = 0.0
    count = 0

    for u in neighbors:
        for v in neighbors:
            if u != v:
                try:
                    d = path_lengths[u][v]
                    total += 1 / d
                    count += 1
                except KeyError:
                    continue

    return (node, total / count if count > 0 else 0.0)


def local_efficiency_weighted_parallel(matrix, max_workers=None):
    nodes = range(matrix.shape[0])
    args = [(n, matrix) for n in nodes]

    local_eff = {}
    with ProcessPoolExecutor(max_workers=max_workers) as executor:
        for node, eff in executor.map(compute_local_efficiency_for_node, args):
            local_eff[node] = eff

    return local_eff

def compute_global_metrics(matrix):
    G = nx.from_numpy_array(matrix)
    inv_weights = {(u, v): 1 / d["weight"] if d["weight"] > 0 else 1e6
                   for u, v, d in G.edges(data=True)}
    nx.set_edge_attributes(G, inv_weights, name="inv_weight")

    weights = [d["weight"] for _, _, d in G.edges(data=True)]
    sparsity = 1.0 - (np.count_nonzero(matrix) / (matrix.shape[0] ** 2))
    mean_connectivity = np.mean(weights) if weights else 0
    try:
        avg_path = nx.average_shortest_path_length(G, weight="inv_weight") if nx.is_connected(G) else np.nan
    except:
        avg_path = np.nan

    metrics = {
        "sparsity": sparsity,
        "mean_connectivity": mean_connectivity,
        "assortativity": nx.degree_pearson_correlation_coefficient(G),
        "avg_clustering": nx.average_clustering(G, weight="weight"),
        "global_efficiency": global_efficiency_weighted(G, weight="inv_weight"), 
        "avg_shortest_path": avg_path,
        "transitivity": nx.transitivity(G)
    }
    return metrics

def compute_local_metrics(matrix):
    G = nx.from_numpy_array(matrix)

    inv_weights = {(u, v): 1 / d["weight"] if d["weight"] > 0 else 1e6
                   for u, v, d in G.edges(data=True)}
    nx.set_edge_attributes(G, inv_weights, name="inv_weight")
    degree = dict(G.degree())
    strength = dict(G.degree(weight="weight"))
    clustering = nx.clustering(G, weight="weight")
    closeness = nx.closeness_centrality(G, distance="inv_weight")
    betweenness = nx.betweenness_centrality(G, weight="inv_weight", normalized=True)
    local_eff = local_efficiency_weighted_parallel(matrix,max_workers=24)

    df = pd.DataFrame({
        "node": list(G.nodes),
        "degree": pd.Series(degree),
        "strength": pd.Series(strength),
        "clustering": pd.Series(clustering),
        "betweenness": pd.Series(betweenness),
        "closeness": pd.Series(closeness),
        "local_efficiency": pd.Series(local_eff)
    })
    return df

# === MAIN PROCESS ===
def main():
    df_info = pd.read_excel(EXCEL_PATH)
    id_map = {convert_excel_id_to_folder_id(r["Subject"]): r["Subject"] for _, r in df_info.iterrows()}

    results_global = []
    results_local = []

    for technique in TECHNIQUES:
        for template in TEMPLATES:
            print(f"Processing technique: {technique}, template: {template}")
            for folder_id in tqdm(id_map.keys()):
                connectome_file = os.path.join(BASE_PATH, folder_id, "dwi", f"connectome_10M_{technique}_{template}.txt")
                if not os.path.exists(connectome_file):
                    continue
                try:
                    mat = load_connectome_matrix(connectome_file)
                    global_metrics = compute_global_metrics(mat)
                    local_metrics = compute_local_metrics(mat)

                
                    global_metrics.update({
                        "folder_id": folder_id,
                        "excel_id": id_map[folder_id],
                        "technique": technique,
                        "template": template,
                    })
                    results_global.append(global_metrics)

                    local_metrics["folder_id"] = folder_id
                    local_metrics["excel_id"] = id_map[folder_id]
                    local_metrics["technique"] = technique
                    local_metrics["template"] = template
                    results_local.append(local_metrics)

                except Exception as e:
                    print(f"Error processing {connectome_file}: {e}")
                    continue

    # Save results
    df_global = pd.DataFrame(results_global)
    df_local = pd.concat(results_local)
    df_global.to_pickle(os.path.join(SAVE_PATH, "connectome_no_density_metrics_global.pkl"))
    df_local.to_pickle(os.path.join(SAVE_PATH, "connectome_no_density_metrics_local.pkl"))
    df_global.to_csv(os.path.join(SAVE_PATH, "connectome_no_density_metrics_global.csv"), index=False)
    df_local.to_csv(os.path.join(SAVE_PATH, "connectome_no_density_metrics_local.csv"), index=False)

if __name__ == "__main__":
    main()