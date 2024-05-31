 # read and process raw data into dictionaries and related data files and create sparse incidence matrix

function yeast_complexes_set_dict(file)
    #INPUT raw data file with each line identifying complexes containing yeast proteins separated by	
    #OUTPUT dictionary of complexes with keys:complex id identifiers  and values:set of yeast proteins

    set_dict=Dict()
    f = open(file)

    for (i, line) in enumerate(eachline(file))
        complex_name=string("C",i) #name complex based on line in raw file
        if complex_name ∉ keys(set_dict) #add complex ID and name if not in dictionary
           set_dict[complex_name]= Set()
        end
        # create a set of participating yeast proteins to add to complex
        part=Set()
        prots = split(line,"\t")
        for k in Set(prots)
            if k !=""
                part=push!(part,k)
            end
        end

        set_dict[complex_name]=part
    end 
    
    return set_dict
end


function edge_by_names_text(dict,dataset,output_path)
#creates text file from set_dictionary with line i being the participating nodes in edge i (alphabetical) 

    file = open("$output_path\\$dataset-edge_by_names.txt", "w")  
    e=1
    for edge in sort(collect(keys(dict)))  # sorts edge names alphaebtically  
        nodes= dict[edge]    
        i=1
        for n in nodes
            if i < length(nodes)[1]
                write(file, n, ",")
                i=i+1
            elseif e==length(dict)
                write(file, n)              
            else
                write(file, n, "\n")
            end           
        end
    e=e+1
    end
    close(file) 
    return 
end    



function edge_by_numbers_text(set_dict, node_no_dict, dataset,output_path)
# create a text file with 1 edge per line with nodes listed by number. Duplicate edges are counted with multiplicty
    file = open("$output_path\\$dataset-edge_by_numbers.txt", "w")  
    e=1
    for edge in sort(collect(keys(set_dict)))  
        i=1
        for p in set_dict[edge]
            number=node_no_dict[p]
            if i < length(set_dict[edge])
                write(file, "$number", ",")
                i=i+1
            elseif e==length(set_dict) #last line
                number=node_no_dict[p]
                write(file, "$number")
            else
                number=node_no_dict[p]
                write(file, "$number", "\n") #end of line
            end
        end
    e=e+1
    end

    close(file)
end


function nodes_no_dict(set_dict,datasetname,output_path)
    # create a text file with all nodes from edges: must be in alphabetical order with no duplicates
    #outputs a dictionary with key:node name and value: node number 
    
    #create vector of nodes and add to text file
    nodes=Vector()
    for i in values(set_dict)
        for k in i
            if k ∉ nodes
                push!(nodes, k)
            end 
        end
    nodes=sort(nodes)  
    end

    #create a list of nodenames-node i is on line i

    c=1
    file = open("$output_path\\$datasetname-nodes_list.txt", "w")  
    for i in nodes
        if c<size(nodes)[1]
            write(file, i, "\n")
        else
            write(file, i)
        end 
        c=c+1
        end
    close(file)       
    node_numbers_dict=Dict()
    open("$output_path\\$datasetname-nodes_list.txt") do f
        for (e,line) in enumerate(eachline(f))
            node_numbers_dict[line]= e
        end
    end
    return node_numbers_dict   
end

function data_processing(set_dict,dataset,output_path)
    #run all data processing functions 
    edge_by_names_text(set_dict,dataset,output_path)
    node_numbers_dict=nodes_no_dict(set_dict,dataset, output_path)
    edge_by_numbers_text(set_dict,node_numbers_dict,dataset, output_path)

    return node_numbers_dict
end


function read_data(dataset::String,output_path)
    #read data and output incidence matrix, weights, node_no,  node_names_list, node_number_name_dict, edges
    
    #returns:
    #     sparse(Is,Js,1): B-incidence matrix if product(node) bought in trip(edge), 
    #     Float64.(w): edge weight 
    #     node_no: numbers allocated to nodes in alphabetical order
    #     node_names_list: name of nodes in alphabetical order
    #     edges dictionary  with key:set of nodes in edge, value: number of duplicate edges
    
    edges = Dict() 
    
    open("$output_path\\$dataset-edge_by_numbers.txt") do f 
        for (e,line) in enumerate(eachline(f))
            nodes = [parse(Int64, v) for v in split(line, ',')]
            edge = Set(nodes)
            if (edge in keys(edges)) #counts number of occurences of that edge ie edge weight
                edges[edge] = edges[edge]+1       
            else
                edges[edge] = 1 #new key
            end
        end
    end
    
    #Create incidence matrix edges (rows) and nodes in edges:
    Is = [] #nodes
    Js = [] #edges
    w = [] #weights ie no. occurances of edge
       
    for (e,edge) in enumerate(keys(edges)) #index edges
        append!(Is,edge) #creates a list of nodes in the edge
        append!(Js,[e for _ in edge]) # adds edge index to J ( eg 4 times if 4 nodes in edge)
        append!(w,edges[edge]) # creates w- weight edge ie # of times edge occurs
    end
    m = length(w)

    node_no = Int64[]
    for i in 1:countlines("$output_path\\$dataset-nodes_list.txt")
        push!(node_no, i)
    end
  
    node_number_name_dict = Dict() 
    open("$output_path\\$dataset-nodes_list.txt") do f #subcategory to name
        for (idx,name) in enumerate(eachline(f))
            node_number_name_dict[idx] = name
        end
    end

    node_names_list=[]
    for i in 1:length(node_no)
        push!(node_names_list, node_number_name_dict[node_no[i]])
    end
    return sparse(Is,Js,1),  Float64.(w), node_no,  node_names_list, node_number_name_dict, edges
end


function node_class_dict(nodes, essential, nonessential; printlines=true)
    #Input: list of **disjoint** text files of essential and nonessential proteins
    #Output class_dict dictionary of nodes and whether essential or nonessential ie in  file 1 or file 2 and number of essential, nonessential and unknown proteins 
    
    f1=open(essential)
    f_1=readlines(f1)
    f2=open(nonessential)
    f_2=readlines(f2)
    class_dict=Dict()
    
    for i in nodes
        if i in f_1 && i in f_2
            println(i, " is in both files. Files not disjoint")
        end
        
        if i in f_1
                class_dict[i]="essential"
        elseif i in f_2
            class_dict[i]="nonessential"
        else class_dict[i]="unknown"
        end
    end
    #count number of value types in dictionary:    
    ne=count(==("nonessential"),values(class_dict))
    e=count(==("essential"),values(class_dict))
    u=count(==("unknown"),values(class_dict))
    if printlines
        println(u, " unknown, ",e, " essential and " , ne , " nonessential proteins")
    end
    return class_dict,u,e,ne
end

function edge_class_dict(node_ess_dict, edges_fromB, node_names_list;printlines=true, per_ess=0.60, per_ness=0.40)  
         #Output:
        # class_dict: dictionary of edge essentiality 
        # essent, non_essent: number of essential and nonessential edges

        class_dict=Dict()
        essent=0
        non_essent=0
        #count number of essential proteins in edge
        for c in keys(edges_fromB) #for each edge
            ess_node=0
            ness_node=0
            unk_node=0
            for i in edges_fromB[c] #for each node
                 if node_ess_dict[node_names_list[i]]=="essential"
                    ess_node+=1
                elseif node_ess_dict[node_names_list[i]]=="nonessential"
                    ness_node+=1
                elseif node_ess_dict[node_names_list[i]]=="unknown"
                    unk_node+=1
                end
            end


            ess_per=ess_node/length(edges_fromB[c])       
            if ess_per>=per_ess
                class_dict[c]="essential"
            else 
                class_dict[c]="nonessential" #count unknowns with nonessentials
            end                        

       end 
     
        #count number of essential and nonessential complexes
        for i in values(class_dict)
            if i=="nonessential"
                non_essent+=1
            elseif i=="essential" 
                essent+=1
            else
                println("missing value")
            end
        end
    
      if printlines  
         println(essent, " essential and " , non_essent , " nonessential/unknown edges")       
        end     
        return class_dict, essent, non_essent
    end
