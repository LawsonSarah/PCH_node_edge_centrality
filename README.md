Code contained in this repo accompanies the paper "An application of node and edge nonlinear hypergraph centrality to a protein complex hypernetwork." Lawson, S., Donovan, D., Lefevre, J. School of Mathematics and Physics, University of Queensland 2024. Please quote this paper if using the code.

This code incorporates code from the paper "Node and edge nonlinear eigenvector centrality for hypergraphs" Tudisco F, Higham DJ. Node and edge nonlinear eigenvector centrality for hypergraphs. Communications Physics. 2021 Jan;4:244. https://github.com/ftudisco/node-edge-hypergraph-centrality including but not limited to the make_mappings, read_data and compute_centrality functions. Please refer to this paper if using code and quote appropriately.

Please refer to licenses.txt for additional citation and licensing information including original data sources.

Code was written in julia and includes a .ipynb file to be used in jupyter notebook. To replicate results from this paper:

1) Download julia files into your file_path. Note setA_1_1_c_kc_centralities.jld2 is a large GIT LFS file which can be downloaded seperately, only the pointers are included in Github's Download zip.  

2) Create "$file_path\\Outputs folder with "$file_path\\Outputs\\plot_exports" subfolder.

3) In Main.ipynb, update file_path and output_path. 

4) (see VARIATION below*) 
    In Main.ipynb choose function set by setting varying=
    
   setA: centralities and figures for the Set A functions    
   setB_summary: centralities and figures for Set B summary functions    
    A_B_summary: centralities and figures for the overall classification      
    1_1_c_k/c:  Full set of c, d=k/c for c,k in range {0.1,...,0.9}U{1,...,95}. The resulting dictionary is presaved and can be loaded instead for efficiency. If choosing this set comment out AUC and plot creation code.    
    "setB_complete": Full set B centralitites for a,b,c,d in {0,1,95,1/95}. The resulting dictionary is presaved and can be loaded instead for efficiency. If choosing this set comment out AUC and plot creation code.
    
5) Uncomment "high_peform(n_essent, n_non_essent, e_essent, e_non_essent, node_ess_dict,edge_ess_dict)" if replicating identification of P:(1,1,46,29/46) and P:(1/95,95,1,1/95).

6) Run code from Main.ipynb. Plots will be saved in the plot_exports folder.
    Note: Delete outputs before rerunning.

    *VARIATION IF UPLOADING LARGE SAVED DICTIONARIES:

    -Choose any of varying=setA, setB or A_B_summary. 
    
    -Comment out "centralities, ranked_nodes_dict, ranked_edges_dict, mappings =
    initialization(varying).    
    
    -uncomment relevant presaved dictionary: 
    
    centralities=load_object("setA_1_1_c_kc_centralities.jld2")
        
    centralities=load_object("setB_comb_0_1_195_95_centralities.jld2").
   
    -Comment out AUC and plot creation code.



