#=original code for make_mappings downloaded from https://github.com/ftudisco/node-edge-hypergraph-centrality used 
in "Node and Edge Eigenvector Centrality for Hypergraphs"    
https://arxiv.org/abs/2101.06215   
by    
[Francesco Tudisco](https://ftudisco.gitlab.io/), Gran Sasso Science Instiute  
and  
[Desmond J. Higham](https://www.maths.ed.ac.uk/~dhigham/), University of Edinburgh  =#

#creates mappings, hypergraph componenents,centrality and essentiality dictionaries

function    make_mappings(varying)
    #creates dictionary with key:function set name and value: functions based on "varying" parameter
        
    println("Creating mappings for function set $varying ")
   
    if varying== "setA"       
         mappings = Dict(        
            "P:(1,1,1,1)" => (x -> x.^1, x -> x.^1, x -> x.^1, x -> x.^1), #linear
            "P:(0,1,0,1)"   => (x -> x.^0, x -> x.^1, x -> x.^0, x -> x.^1), #degree
            "P:(1,1,95,1/95)"   => (x -> x.^1, x -> x.^1, x -> x.^95, x -> x.^(1/95)), #TH lin-max
            "log-exp"       => ( x -> x, x -> x.^(1/15), x -> log.(x), x -> exp.(x)), #TH lin-logexp with p=14 
            "P:(1,1,46,29/46)"   => (x -> x.^1, x -> x.^1, x -> x.^46, x -> x.^(29/46))
            )              

    elseif varying== "setB_summary" 
        mappings = Dict(
            "P:(95,1/95,95, 1/95)"   => (x -> x.^95, x -> x.^(1/95), x -> x.^95, x -> x.^(1/95)), #max-max          
            "P:(95,1/95,1,1)"   => (x -> x.^95, x -> x.^(1/95), x -> x.^1, x -> x.^1), #max-lin
            "P:(95,1/95,0,1)"   => (x -> x.^95, x -> x.^(1/95), x -> x.^0, x -> x.^1), #max-degree
            "P:(0,1,95,1/95)" => (x -> x.^0, x -> x.^1, x -> x.^95, x -> x.^(1/95)), #degree-max
            "P:(0,1,1,1)"   => (x -> x.^0, x -> x.^1, x -> x.^1, x -> x.^1), #degree-linear
            #"P:(0,1,0,1)"   => (x -> x.^0, x -> x.^1, x -> x.^0, x -> x.^1), #degree-degree
            "P:(1,1,0,1)"   => (x -> x.^1, x -> x.^1, x -> x.^0, x -> x.^1), #linear-degree
            # "P:(1,1,95, 1/95)"   => (x -> x.^1, x -> x.^1, x -> x.^95, x -> x.^(1/95)), #linear-max
            # "P:(1,1,1,1)"   => (x -> x.^1, x -> x.^1, x -> x.^1, x -> x.^1), #linear-linear
            "P:(1/95,95,1,1/95)"   => (x -> x.^(1/95), x -> x.^95, x -> x.^1, x -> x.^(1/95))
            )       

    elseif varying== "A_B_summary" 
         mappings = Dict(        
            "P:(0,1,0,1)"   => (x -> x.^0, x -> x.^1, x -> x.^0, x -> x.^1), #degrees
            "P:(1,1,95,1/95)"   => (x -> x.^1, x -> x.^1, x -> x.^95, x -> x.^(1/95)), #TH lin-max
            "P:(1,1,46,29/46)"   => (x -> x.^1, x -> x.^1, x -> x.^46, x -> x.^(29/46)),    #TH lin-logexp with p=14           
            "P:(1/95,95,1,1/95)"   => (x -> x.^(1/95), x -> x.^95, x -> x.^1, x -> x.^(1/95)),
            "P:(1,1,1,1)"   => (x -> x.^1, x -> x.^1, x -> x.^1, x -> x.^1),
            )

   
    elseif varying== "setB_complete" 
        #4 ranges for a,b,c,d to iterate over. If using large ranges then may need to be divided into subsets then combined for efficiency
        a_range=[0,1,1/95,95]
        b_range=[1,1/95,95]
        c_range=[0,1,1/95,95]
        d_range=[1,1/95,95]
     
        mappings=Dict()
        for a in a_range
            for b in b_range
                for c in c_range
                    for d in d_range
                        mappings["P:($a,$b,$c,$d)"]=
                        (x -> x.^a, x -> x.^b, x -> x.^c, x ->x.^d)
                    end
                end
            end
        end

    elseif varying== "1_1_c_k/c"
            #for set A: P:(1,1,c, k/c):
            a_range = [1]
            b_range = [1]
            c_range=sort(unique(vcat(range(start = 0.1, length = 9, stop = 0.9),range(start = 1, length = 95, stop = 95))))
            d_range=sort(unique(vcat(range(start = 0.1 , length = 9, stop = 0.9),range(start = 1, length = 95, stop = 95))))

            mappings=Dict()
            for a in a_range
                for b in b_range
                    for c in c_range
                        for d in d_range
                            mappings["P:($a,$b,$c,$d/$c)"]=
                            (x -> x.^a, x -> x.^b, x -> x.^c, x ->x.^d/c)
                        end
                    end
                end
            end
 
        
    else
    println("  ")
    println("WARNING:'$varying' function set does not exist") 

        
    end
    return mappings
end


function bipartite_connected(B)
    #create bipartite graph and check if connected 
    n,m=size(B)
    bp=hcat(vcat(zeros(n,n),transpose(B)),vcat(B, zeros(m,m)))
    connected=is_connected(SimpleGraph(bp))
    
    return bp,connected
end

function read_hypergraph_data(dataset_name, output_path; gamma=1, max_iterations=200, tolerance=1e-6)
    #extract incidence matrix, edge weights, node_information from raw data
    
    B,w, node_no, node_names_list, node_number_name_dict, edges = read_data("$dataset_name",output_path);
   labels=node_names_list 

    bp,connected = bipartite_connected(B) 

    if !connected
        println("WARNING:bipartite matrix [0 BW;B^TN 0] not connected-cannot guarantee existence of unique solution for original data")
    end     

    edges_fromB=edges_from_B(B)
    
    return B, w,edges,edges_fromB,labels, connected
end


function largest_component(B,node_numbers_dict, set_dict)
    # INPUT: Incidence matrix, dictionary of node numbers and original set dictionary
    # OUTPUT: 
    #     max_comp_dict:  dictionary with  key:edges and value:nodes for maximum component
    #     comps: sets of nodes (indexed by row in B) forming connected components 
    #     node_set: largest set of connected nodes by name  
    #     edges_with_nodes: set of edges containing any of the nodes in comps
    #     mc: true if unique maximum component
    #     numb_comps: number of connected components
    #     size_of_max_comp: Maximum component size 
    #     max_ten: 10 largest component sizes
    #     min_ten: 10 smallest component sizes
    #     numb_single_comp: number of single node componenets

    h = Hypergraph(replace(Matrix(B), 0=>nothing)) #turn incidence matrix into hypergraph
    comps=get_connected_components(h) #get sets of nodes (indexed by row in B) forming connected components
    numb_comps=size(comps)[1]
    size_of_max_comp=maximum(length, comps)
  
    #identify if unique largest component - otherwise mc=false
    idx = 0
    len = 0
    mc=false
    for i in 1:length(comps)
        l = length(comps[i])
        if l ==len 
            mc=true
        end
        l > len && (idx = i; len=l)
        end

    #create lists of sizes of top 10 largest/smallest components    
    lengths_of_comps=[]
    for i in comps
       push!(lengths_of_comps,length(i)) #create list of component sizes
    end
    sorted_dec=sort(lengths_of_comps, rev=true) #sort by size
    sorted_asc=sort(lengths_of_comps) #sort by size
    r= min(10,length(comps))    

    max_ten=[]
    for i in range(1,r)
        push!(max_ten, sorted_dec[i]) #create vector of top 10 component sizes.
    end

    min_ten=[]
    for i in range(1,r)
        push!(min_ten, sorted_asc[i]) #create vector of bottom 10 component sizes.
    end

    numb_single_comp=count(==(1), lengths_of_comps) # counts number of components with only one node

    #creates a list of nodes in largest component by name    
    node_set=numberset_to_nameset(comps[idx], node_numbers_dict) 
    edges_with_nodes=Set([]) 
    for node in node_set
        for k in keys(set_dict)
            if node in set_dict[k]           
                push!(edges_with_nodes,k)
            else 
            end
        end
    end

    #create dictionary
    max_comp_dict=Dict()
    for edge in edges_with_nodes        
        push!(max_comp_dict, edge => set_dict[edge])
    end
    number_of_nodes=length(node_set)
    number_of_edges=length(edges_with_nodes) 
    println(  "There are $numb_comps component(s)." )
    println("The top largest component sizes are $max_ten.")
    println("There is $numb_single_comp singleton component(s).")
    
    return max_comp_dict,comps, node_set, edges_with_nodes,mc,numb_comps, size_of_max_comp, max_ten,min_ten,numb_single_comp
end


function max_component_recalculate(B,node_numbers_dict,set_dict,dataset_name)
    #recalculate centralities based on maximum connected component
    
    max_comp_dict, comps, node_set, edges_with_nodes,mc,numb_comps, size_of_max_comp,max_ten,min_ten,numb_single_comp=
    largest_component(B,node_numbers_dict,set_dict)
    
    if !mc # if only 1 maximum sized component - rerun data processing function
        
        #recreate edges and node_numbers dictionaries based on largest comp data and calculate centralities
        set_dict=max_comp_dict #recreated edge dictionary for component edges
        dataset_name=string(dataset_name, "_max_comp") #rename data set
        node_numbers_dict=data_processing(set_dict,dataset_name,output_path)  #reassign node_numbers to component nodes
        B,w,edges,edges_fromB,node_names_list=
        read_hypergraph_data(
            dataset_name, output_path, max_iterations=
            max_iterations, tolerance=tolerance
            );
            Number_weighted_edges=size(B)[2]
        println("New hypergraph has $Number_weighted_edges weighted edges.")    
    else
        println("ERROR: Unable to calculate centralitites due to multiple maximum components of size $size_of_max_comp")
        return
    end
        
    return B,w,edges,edges_fromB,node_names_list,set_dict,dataset_name,node_numbers_dict
end


function initialization(varying)
    #calls mappings,centralities and rank and outp[uts dictionaries
    mappings =make_mappings(varying)       
    centralities=nsvc_centralities_dict(B,mappings;maxiter=max_iterations, edge_weights = w, tol=tolerance);

    #calculate ranks and averages for NSVC functions
    ranked_nodes_dict, ranked_edges_dict=rank(centralities, mappings); 

    return centralities,ranked_nodes_dict, ranked_edges_dict, mappings
end

function edge_numbers_dict(node_numbers_dict)
    edge_no_dict=Dict()
    for edge in 1:length(edges_fromB)
        edge_to_sets=sets_with_nodenumbers(edges_fromB[edge], node_numbers_dict)
        edge_no_dict[edge]=edge_to_sets
    end
    return edge_no_dict
end

function node_in_edges(node_numbers_dict,edges_fromB)  
    #creates dictionary with key:node number and value:array of edges node is in
    
    nodes_in_edges=Dict()
   for n in sort(collect(values(node_numbers_dict))) #for each node number
        n_in_edges=[]
        for j in keys(edges_fromB) #iterates through edges to see if node is in edge 
            if n in edges_fromB[j]
                push!(n_in_edges,j) 
            end
        end
    nodes_in_edges[n]=n_in_edges
    end
    return nodes_in_edges
end
      