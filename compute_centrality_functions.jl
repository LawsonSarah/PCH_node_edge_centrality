function compute_centrality(B,(f,g,ϕ,ψ); 
                maxiter=100, #if doesn't converge after 100 iterations then fails
                tol=1e-6,
                edge_weights = ones(size(B)[2],1),#vector for W
                node_weights = ones(size(B)[1],1), #vector for N
                mynorm = (x -> norm(x,1))  ) #1 norm to be used
    
    #Uses algorithm by Tudisco and HIgham to compute NSVC centralities
    #INPUT: hypergraph via incidence matrix B and 4 nonlinear functions
    #RETURNS:: two vectors  based on Algorithm 1 from paper   
    
    B = sparse(B)
    n,m = size(B) #n- nodes, m edges
        
    #Initialize with positive vectors
    x0 = ones(n,1)./n
    y0 = ones(m,1)./m 

    #x0 = rand(n,1)./n # random starting vector
    #y0 = rand(m,1)./m

    W = spdiagm(0=>edge_weights[:]) #creates a sparse diagonal matrix of the edge weights
    N = spdiagm(0=>node_weights[:]) #creates a sparse diagonal matrix of the node weights

    check=0
    for it in 1:maxiter
        u = sqrt.( x0 .* g(B*W*f(y0)) ) #entrywise multiplication and square root
        v = sqrt.( y0 .* ψ(B'*N*ϕ(x0)) ) #entrywise multiplication and square root
        x = u./mynorm(u)
        y = v./mynorm(v)


        #check to see if converging
        check = mynorm(x-x0) + mynorm(y-y0) 
        if check < tol
            #println("$it ===")  
           # println("# iterations = ", "$it ")
           # println()
            return vec(x),vec(y) #if reaches tolerance function ends
        else
            #if not yet converges continue iterations with:

            x0 = copy(x)
            y0 = copy(y)
        end
    end
    #if doesn't converge after maxiter iterations:
    println("Warning: Centrality did not reach tol = $tol in $maxiter iterations\n-------  Relative error reached so far = $check")         
    print("x",x0)
    print("y",y0)
    return vec(x0),vec(y0) #returns current centrality vectors but hasn't yet converged.
end



function nsvc_centralities_dict(B,mappings;maxiter=max_iterations,edge_weights = w, tol=tolerance)
    #create dictionary containing centralities based on mappings
    centralities = Dict();
    for maps in mappings
        x,y = compute_centrality(B,maps[2],maxiter=max_iterations,edge_weights = w, tol=tolerance );      
        centralities[maps[1]] = Dict("x"=>x, "y"=>y)
    end
    return centralities
end


function deg_centralities_dict(B,node_edges_dict, edges_fromB; edge_weights = w, inc_adj=true)
    #Output: (node) tralities: based on # edges a node belongs to. If inc_adj=true includes adj-deg: number of adjacent nodes, max-edge: maximum edge cardinality a node belongs to and mean_edge:average edge cardinality a node belongs to 
    #(edge) edge_centralities: edge cardinality
    
    deg_centralities = Dict();
    edge_deg_centralities=Dict();
    
    #compute edgesize
    edge_deg=Vector{Int64}()
    for i in 1:size(B)[2] # number of edges        
        edge_size=length(edges_fromB[i]) # edge cardinality
        push!(edge_deg,edge_size)
    end
    edge_deg=vec(edge_deg)
                
    edge_deg_centralities["edge_deg"] = Dict("y" => edge_deg)
    
       
    #compute UNWEIGHTED node degree centrality
    inc=Vector{Int64}()
 
    for i in 1:size(B)[1] # number of nodes        
        incdeg=sum(B, dims = 2 )[i] # sum number of edges a node is in
        push!(inc,incdeg)    
    end
                   
    deg_centralities["node_deg"] = Dict("x" => inc)
       
    if inc_adj==true

        max_edge=Vector{Int64}()
        mean_edge=Vector{Float64}()
        adj=Vector{Int64}()

       for i in 1:size(B)[1] # number of nodes
            iedges=node_edges_dict[i]
            adjdeg=0
            for e in iedges
                adjdeg=adjdeg+length(edges_fromB[e])-1
            end
            push!(adj,adjdeg)

            max_e=findmax(B[i, :].*edge_deg)[1]
            push!(max_edge,max_e)

            non_zero=[]
            for e in iedges
               s=edge_deg[e]  
                push!(non_zero,s)
            end 
            mean_e=mean(non_zero)
            push!(mean_edge,mean_e)


            deg_centralities["Max_edge"] = Dict("x" => max_edge)
            deg_centralities["Mean_edge"] = Dict("x" => mean_edge)
            deg_centralities["Adj_deg"] = Dict("x" => adj)
        end        

    end

    return deg_centralities, edge_deg_centralities
end

