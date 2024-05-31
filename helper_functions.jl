#helper functions. Some functions are generic and not specific to the complex data set


function number_to_name(number, node_numbers_dict) 
    #turn node number to node name
    
    name=""    
    for (k,v) in node_numbers_dict
        if v==number
            name=k
        end
    end
    return name
end

function node_names_in_set(set_dict,set_name)
    #Outputs all nodes by name in original inputted set (ie original complex):
    
    k=get(set_dict, set_name, "set_name not in set list")
    return k
end
         
function numberset_to_nameset(numberset, node_numbers_dict) 
    #Input: set of node numbers and node numbers dict with key(node name) value(number)
    #Output list of names assoicated with node numbers
    
    named_set=Set([])   
    for i in numberset
        for (k,v) in node_numbers_dict
            if v==i
                name=k
                push!(named_set,name)
            end

        end
    end
    return named_set
end

function nameset_to_numberset(nameset, node_numbers)
    #Input: nameset-a list of node names, node_numbers- dictionary of node names with their node number
    #Output: list of numbers corresponding to inputted list of names
    
    number_set=Set([])
    for i in nameset
        for (k,v) in node_numbers        
            if k==i
                number=v
                push!(number_set,number)
            end
        end
     end
     return number_set
end


function sets_with_nodenumbers(numberset, node_numbers_dict) 
    #finds original sets (an edge may represent multiple sets) that contain exactly the set of inputted nodes (in any order)
    
    #Input: nodeset as node numbers, dictionary with node number(key)-name(value)
    #Output: list of keys from set_dict
    
    named_set=Set([])
    for i in numberset
        for (k,v) in node_numbers_dict
            if v==i
                name=k
                push!(named_set,name)
            end
        end
    end
    edges=Set([])
    for (k,v) in set_dict
        if v==named_set
            push!(edges,k)
        end
    end
    return edges
  
end

function edges_from_B(B)
    #Input: incidence matrix B 
    #Output: dictionary of edge number(key) and nodes in edge(value)
    
    s=findall(!iszero, B)
    edges_dictionary=Dict()
    for v in s
        if v[2] in keys(edges_dictionary)
            push!(edges_dictionary[v[2]],v[1])
        else
            edges_dictionary[v[2]]=Set([v[1]])
        end
    end
    return edges_dictionary
end




function node_in_sets(node_number,node_numbers_dict,set_dict)
    
    #Input node number, dictionary containing nodenames (key) and nodenumbers(value), and dictionary of original sets
    #returns list of original sets (ie complexes)  node is in   
    node_name=""
    for (k,v) in node_numbers_dict
        if v==node_number
            node_name=k
        end    
    end

    sets=Set([])
    for (k,v) in set_dict
        if node_name in v
            push!(sets,k)
        end
    end
    return sets
end


function max_edges(centralities, mapping)
    #returns edge numbers which have maximum centrality for mapping.
    v=centralities[mapping]["y"] ;
    maxval = maximum(v); 
    positions = [i for (i, x) in enumerate(v) if x == maxval];#edge numbers for maximum edges
    println("$mapping :",length(positions)," edge(s) with max centrality $maxval correspond to column(s) ",positions, " in B")
    return positions
end


function max_nodes(centralities, mapping)
    #returns node numbers which have maximum centrality for mapping.
    v=centralities[mapping]["x"] ;
    maxval = maximum(v); 
    positions = [i for (i, x) in enumerate(v) if x == maxval];#edge numbers for maximum edges
    println("$mapping : ",length(positions)," node(s) with max centrality $maxval are ",positions)
    return positions
end



function min_edges(centralities, mapping)
    #returns edge numbers which have minimum centrality for mapping.
    
    v=centralities[mapping]["y"] ;
    minval = minimum(v);
    positions = [i for (i, x) in enumerate(v) if x == minval];
    println("$mapping : ",length(positions)," edge(s) with min centrality $minval correspond to columns(s) ",positions, " in B")
    return positions
end


function min_nodes(centralities, mapping)
     #returns node numbers which have minimum centrality for mapping.
    v=centralities[mapping]["x"] ;
    minval = minimum(v); 
    positions = [i for (i, x) in enumerate(v) if x == minval];#edge numbers for maximum edges
    println("$mapping : ",length(positions)," node(s) with min centrality $minval are ",positions)
    return positions
end

function max_size_value_set(dict)
    #find all entries with maximum length of value in a dictionary
    
    m=0
    p=[]
    for k in dict  
        if length(k[2])>m
            m=length(k[2])
            p=[k[1]]
        elseif length(k[2])==m
            push!(p, k[1])
        end
    end
    return m,p
end



function max_cent_list(list, centralities, cent, cent_type)
    #find maximum centrality of a list of either node numbers or edge numbers for chosen centrality
    #Input: node or edge numbers list (matching cent_type), centralities dictionary, centrality name, cent type "y" or "x".
    #Output: max centrality and associated node(edge) numbers
    
    m=0
    p=[]
    for k in list 
        if centralities[cent][cent_type][k]>m
            m=centralities[cent][cent_type][k]
            p=[k]
        elseif centralities[cent][cent_type][k]==m
            push!(p, k)
        end
    end
    return m,p
end

function min_cent_list(list, centralities, cent, cent_type)
    #find minimum centrality of a list of either node numbers or edge numbers for chosen centrality
    #Input: node or edge numbers list (matching cent_type), centralities dictionary, centrality name, cent type "y" or "x".
    #Output: min centrality and associated node(edge) numbers
    m=1
    p=[]
    for k in list 
        if centralities[cent][cent_type][k]<m
            m=centralities[cent][cent_type][k]
            p=[k]
        elseif centralities[cent][cent_type][k]==m
            push!(p, k)

        end
    end
        return m,p
end



function tab_to_dict(mappingfile,key,value)
    #Takes a tab delimited file and creates dictionary based on 2 column numbers.
    #ONLY WORKS FOR 1:1 NOT FOR MULIPLTE VALUES 
    #Inputs:    mappingfile: text file of the format key=column #	value=column #
    #Outputs:   dictionary key with value set
  
    dict_name=Dict()
    f = open(mappingfile)
    for line in eachline(f)
        k = split(line,"	")  
        dict_name[k[key]]=k[value]       
    end
    close(f)
    return dict_name
end


function rank(centralities, mappings)
    #creates dictinaries key:cent name, value: arrays with rank of node/edge idx at position idx
    ranked_nodes=Dict()
    ranked_edges=Dict()

   
    for cent in keys(mappings)
        noderank=competerank(centralities[cent]["x"], rev=true)
        ranked_nodes[cent]=noderank       
        edgerank=competerank(centralities[cent]["y"], rev=true)
        ranked_edges[cent]=edgerank
    end    
    return ranked_nodes, ranked_edges
end

function essentiality_count(names_list, class_dict)
    #counts number ofessential proteins or complexes in given name_list
    
    no_ess=0
    for i in names_list        
        if class_dict[i]=="essential"
               no_ess+=1
        end
    end
    return no_ess
end
             



function ess_in_edge(nodes)
    #Input array of node numbers
    #Outputs number of essential and nonessential proteins and list of ess and ness node numbers. Excludes unknowns
    node_ess=[]
    node_ness=[]
    ess=0
    ness=0

    for node in nodes
        name=number_to_name(node, node_numbers_dict) 
        # node_no=findfirst(x->x==node, node_names_list) #node number       
        if node_ess_dict[name]=="essential"              
            push!(node_ess, node)
            ess+=1                
        elseif node_ess_dict[name]=="nonessential"
            push!(node_ness, node)
            ness+=1
        end 
    end  
    return ess,ness,node_ess,node_ness
end    

function protein_node_summary(node_names_set,node_numbers_dict)
    #summer of protein info for proteins in node_names_set
    
    node_set=nameset_to_numberset(node_names_set, node_numbers_dict) 

    for node_number in node_set
        println("Protein number: ", node_number, ". Protein name: ",numberset_to_nameset([node_number], node_numbers_dict))#Input set of node numbers Output set of names
        println("Contained in ",length(node_in_sets(node_number,node_numbers_dict,set_dict)) ," original set(s):")
        println(node_in_sets(node_number,node_numbers_dict,set_dict))
        println( "and ", sum(B, dims=2)[node_number], " hypergraph edges.") # list of edges containing Inputted node_number
    end
end



function max_true_pos(cent_type,centralities, top, n_essent, e_essent, n_non_essent, e_non_essent,node_ess_dict, edge_ess_dict;printlines=false, reverse=true)
    # Calculates number of true positives for each centrality in dictionary for cent type then prints the maximum number of true positives and the associated centrality names

    #input:
    # cent_type node "x" or edge "y"
    # centralities dictionary of centralities
    # top : percentage value to calculate threshold
    # n_essent, # of essential nodes
    # e_essent, # of essential edges
    # n_non_essent, # of nonessential nodes
    # e_non_essent,# of nonessential edges
    # node_ess_dict, edge_ess_dict dictioanries containing node and egde essentiality status

    if cent_type=="x"
        class_dict=node_ess_dict
        ess=n_essent
        ness=n_non_essent
        tt="proteins"
    else
        class_dict=edge_ess_dict
        ess=e_essent
        ness=e_non_essent
        tt="complexes"
    end    

    topthreshold=Int(floor(top* ess))

    cents=[]
    no_tp=[]
    cent_dict=centralities
    for cent in keys(cent_dict) #calculate true positives for each centrality
        push!(cents,cent)
        predict_by_binary, tp,tn,fp,fn,ppv,acc,f1,tpr,tnr,npv=
        class_measures(cent_dict, cent, class_dict, cent_type,  topthreshold, ess; printlines=false, reverse=true)
        push!(no_tp,tp)
    end

    max=0
    indices_max=[]
    for i in 1:length(no_tp) #find max # of true positives and the corresponding centrality vector indices
        if no_tp[i]>max
            max=no_tp[i]
            indices_max=[i]
        elseif no_tp[i] ==max
            push!(indices_max,i)
        end
    end
    max_centrality_names=[]
    for i in indices_max #create array of corresponding centrality names for indices
        push!(max_centrality_names,cents[i])
    end

    println(Int(top*100), "%: ", topthreshold, " $tt")
    println("max number of TP $tt: ", max, " for ", length(max_centrality_names)," set(s): ",  max_centrality_names) 
    println("---------------------------------------------------------" )
        
    return 
end
    

function centdict2table(centralities)
    #create latex code for table with summary of node and edge centralities
    println("LATEXS CENTRALITY STATS TABLE:") 
    println("\\begin{table}[H]")
    println("\\caption{}")
    println("\\begin{center}")
    println("\\begin{tabular}{ |c|c|c|c|c|c|c|c|c|}" )
    println("\\hline")
    println("\\textbf{Function set} & \\textbf{Node Min} & \\textbf{Node Max} & \\textbf{Edge Minimum} & \\textbf{Edge Max} & \\textbf{Node Range} & \\textbf{Node Std} & \\textbf{Edge Range}&\\textbf{Edge Std} \\\\") 
    println("\\hline")
    
    for (key, value) in sort(centralities)
        node_std=std(centralities[key]["x"])
        edge_std=std(centralities[key]["y"])
        min_n=minimum(centralities[key]["x"]) 
        max_n =maximum(centralities[key]["x"]) 
        min_e=minimum(centralities[key]["y"])
        max_e = maximum(centralities[key]["y"])        
        println(key, " & ",round(min_n,digits=5)," & ",round(max_n,digits=5), " & ",round(min_e,digits=5)," & ",round(max_e,digits=5), " & ",round(max_n-min_n,digits=5)," & ",round(node_std,digits=5)," & ",round(max_e-min_e,digits=5)," & ",round(edge_std,digits=5))
        println("\\\\")
        println("\\hline")
    end  
    
    println("\\end{tabular}")
    println("\\label{}")
    println("\\end{center}")
    println("\\end{table}")
end



function centrality_limits(centralities, cent, cent_type, value, node_numbers_dict)
    #Input: centralities dictionary, function set name, cent_type = "x" or "y", value to compare to, node_numbers_dict).
    #Output list of edge or node numbers and names greater than value
    indexes=[]
    for i in eachindex(centralities[cent][cent_type])
        if centralities[cent][cent_type][i]>value
            push!(indexes,i)
        end
    end
    names=numberset_to_nameset(indexes, node_numbers_dict)
    indexes=join(indexes|>collect|>sort,',')
    names=join(names|>collect|>sort,',')
    return indexes,names
end
