function rank_arrays(centrality_list, cent_type, class_dict; reverse=true)
    #Helper function for class measures and area_UC
    #Input: centrality dictionary and mappings
    #Output: vector of top centralities  by node /edge number, by node name /edge number, by centralities,by class represented as binary by class represented by name
    
    rank_by_name = Array{String}(undef,0) #for rank by node name or edge number
    x = centrality_list#for each mapping get list of centralities
    xid = sortperm(vec(x),rev=reverse); # Output as a list of node/edge numbers by largest to smallest centralities 
    xx = x[xid]; #lists centrality values in order of largest to smallest (or smallest to largest if average rank)

    rank_by_centralities=xx
    rank_by_number=xid

    if cent_type=="x"   
        for x in xid
            name=node_names_list[x]
            push!(rank_by_name,name)
        end
    else rank_by_name=xid #no edge names
        
    end  
    
    rank_by_class = [class_dict[x] for x in rank_by_name]

    rank_by_name_exc=[]#exclude unknowns in ranking
    for i in rank_by_name
        if class_dict[i]!="unknown"
            push!(rank_by_name_exc, i)
        end
    end

    
    rank_by_binary=Vector{Real}(undef,0)

    for i in rank_by_class #creates binary vector. Excludes unknowns.
        if i =="essential"
            push!(rank_by_binary, 1.0)
        elseif i =="nonessential"
            push!(rank_by_binary, 0.0)
        end
    end    
 
    return  rank_by_number, rank_by_name, rank_by_name_exc, rank_by_centralities,rank_by_binary,rank_by_class
end




function pred_binary_ess_rank(class_dict, x)
    #Input: classification of nodes or edges in class_dict, x -threshold
    #Output: binary array with top x entries = 1 (essential) and remaining entries=0 (nonessential) 

    exc_unk=count(i->(i!= "unknown"), values(class_dict) ) #number of classified keys in class_dict
    predict_by_binary = ones(Float64,exc_unk) #float to use prec rec curve functions
     #predict_by_binary = ones(Int64,exc_unk)

    for i ∈ 1:x
        predict_by_binary[i] = 1
    end
    
    for i ∈ x+1:exc_unk
        predict_by_binary[i] = 0
    end

    return predict_by_binary
 end

function conf_matrix_measures(rank_by_binary, predict_by_binary; printlines=true)
     #create confusion matrix from comparing two binary arrays, print and return classification measures for use in class_measures
    cm1 = ConfusionMatrix(rank_by_binary, predict_by_binary)

    #targets/predicted values
    ppv=EvalMetrics.precision(rank_by_binary,predict_by_binary)
    acc=EvalMetrics.accuracy(rank_by_binary,predict_by_binary)
    f1=EvalMetrics.f1_score(rank_by_binary,predict_by_binary)
    tpr=EvalMetrics.true_positive_rate(rank_by_binary,predict_by_binary)
    tnr=EvalMetrics.true_negative_rate(rank_by_binary,predict_by_binary)
    npv=EvalMetrics.negative_predictive_value(rank_by_binary,predict_by_binary)
    
    tp=EvalMetrics.true_positive(rank_by_binary,predict_by_binary)
    tn=EvalMetrics.true_negative(rank_by_binary,predict_by_binary)
    fp=EvalMetrics.false_positive(rank_by_binary,predict_by_binary)
    fn=EvalMetrics.false_negative(rank_by_binary,predict_by_binary)
   
  
    if printlines
        println(" P/N/TP/TN/FP/FN: ", cm1)
        println(" TP/TN/FP/FN: ", tp," ",tn," ",fp, " ", fn, " ")
        println("Precision/Positive Predictive Value ", ppv)
        println("Accuracy ", acc)
        println("f1-score ", f1)   
        println("Recall/true_positive_rate/sensitivity ", tpr)
        println("Specificity/true_negative_rate ", tnr)
        println(" negative_predictive_value ", npv)
        println("------------------------------")
        println()
    end
    
    return tp,tn,fp,fn,ppv,acc,f1,tpr,tnr,npv
end

function class_measures(cent_dict, cent, class_dict, cent_type, top, ess; printlines=false, reverse=true)
    #create classification measures for function set inputted, cent_type (node or edge) and top threshold. Helper function for all_class_measures
    centrality_list=cent_dict[cent][cent_type]
    rank_by_number, rank_by_name, rank_by_name_exc, rank_by_centralities,rank_by_binary,rank_by_class=
    rank_arrays(centrality_list, cent_type, class_dict, reverse=reverse)
    predict_by_binary=pred_binary_ess_rank(class_dict, top) #array of top ess 1's
    
    if printlines
        println(cent)
    end
    
    top_rank=rank_by_binary
    top_predict=predict_by_binary

    tp,tn,fp,fn,ppv,acc,f1,tpr,tnr,npv=conf_matrix_measures(top_rank, top_predict; printlines)
    return predict_by_binary, tp,tn,fp,fn,ppv,acc,f1,tpr,tnr,npv
end



function all_class_measures(top, ess,  non_essent,cent_dict_input, class_dict, cent_type; print=false)
    #Input: Cent_dict - array of centrality names
     #Outputs classification measures dictionary and array of values of true positives and centrality names for plotting. Helper function for all_class_measures_plots. 
    measures_dict=Dict()   
    top_int=Int(ceil(top)) #threshold
    x_ess_plot=Vector{String}()
    y_ess_plot=Vector{Real}()
    
    for cents_dict in cent_dict_input
        
         if @isdefined rank_av_cent_dict 
            if cents_dict==rank_av_cent_dict
                rev = false #want average degree to be ranked from smallest to larger when ranking arrays
            else 
                rev=true
            end
        else 
             rev=true
        end
        
        for i in vcat(collect(keys(cents_dict)))
            predict_by_binary, tp,tn,fp,fn,ppv,acc,f1,tpr,tnr,npv=
            class_measures(cents_dict, i, class_dict, cent_type, top_int, ess, printlines=print, reverse=rev);
            measures_dict["$i $top_int"]=[tp,tn,fp,fn,ppv,acc,f1,tpr,tnr,npv]
            push!(x_ess_plot,i)
            push!(y_ess_plot,tp)
        end
    end

    push!(x_ess_plot,"random")
    push!(y_ess_plot, Int(floor(top_int*(ess/(ess+non_essent))))) 

    
    return   measures_dict, x_ess_plot, y_ess_plot
end


function all_class_measures_plots(cent_type, centralities, deg_centralities, edge_deg_centralities, n_essent, n_non_essent, node_ess_dict, e_essent, e_non_essent, edge_ess_dict, range_top; comb_centralities=[], rank_av_cent_dict=[], printlines=false, varying="none") 
    #prints measures, box plots, precision-recall curve and cumulative plots
    
    println("cent_type  ", cent_type)

    if cent_type=="x"
        if printlines
            println("NODE RESULTS")
        end
        
        tt="proteins"
        data_size=n_essent + n_non_essent
        cent_dict_input=[centralities]   
        essent=n_essent
        non_essent=n_non_essent
        class_dict=node_ess_dict
               
    else #edges
        if printlines
            println("EDGE RESULTS")
        end
        
        tt="complexes"
        data_size=e_essent+ e_non_essent
        essent=e_essent
        non_essent=e_non_essent        
        cent_dict_input=[centralities]     
        class_dict=edge_ess_dict
        
    end

    measures_dict, x_names_plot, y_essent_plot=all_class_measures(
    essent, essent,  non_essent,cent_dict_input, class_dict, cent_type; print=printlines)

    k=prec_plot(cent_dict_input,non_essent,essent, class_dict, cent_type) 
    perc=range_top
    rt=floor.(perc.*essent)

    
    function addlabels(x,y)
        for i in range(1,length(x))
            plt.text(i,y[i]+0.2,y[i],fontsize=14, ha = "center")
        end
    end
    
    
    plt.figure(figsize=(18,18))
    plt.subplots_adjust(bottom=0.4,                    
                    top=0.9, 
                    #wspace=0.4, 
                    hspace=0.8)

    sp=1
    for i in rt          
        i=Int(ceil(i))
        subplot(2,3,sp)
        if printlines
            println("_________________________")
            println("FOR $i TOP $tt")
        end
        
        measures_dict,x_names_plot, y_essent_plot=all_class_measures(
            i, essent, non_essent, cent_dict_input, class_dict, cent_type; print=printlines)
        b = PyPlot.bar(x_names_plot,y_essent_plot,color="#0f87bf",align="center",alpha=0.4)
        pc=Int(perc[sp]*100)
        addlabels(x_names_plot,y_essent_plot)

        title("Top $i $tt ($pc%)", fontsize=20,fontname="arial", )
        if sp in[1,4]
            ylabel("Number of essential $tt",fontsize=16)
        end
        plt.xticks(fontsize=14, fontname="arial", rotation=80)
        plt.yticks(fontsize=14,fontname="arial", )
        sp+=1
        plt.margins(y=0.2)
    end
    PyPlot.savefig("$output_path\\plot_exports\\boxplot_tops_$cent_type.jpg", dpi=300, bbox_inches="tight")
        
    #draw cumulative graph
    x_range=range(1,essent+non_essent)
    cumulative_essential(centralities,x_range,essent,class_dict,cent_dict_input,cent_type)
    
    return measures_dict
end

function area_uc(cent_dict_input, cent_type, n_essent, n_non_essent, e_essent, e_non_essent, node_ess_dict,edge_ess_dict)
   # cent_dict_input - array of centrality dictionaries
        #outputs AUC's as auc_arrayy with centrality names at same index in cent_array 
    if cent_type=="x"
        essent=n_essent
        non_essent=n_non_essent
        class_dict=node_ess_dict         
        
    else #edges
        essent=e_essent
        non_essent=e_non_essent
        class_dict=edge_ess_dict

    end
    tops=non_essent+essent
        
    predictions=Array{Vector}(undef,tops+1)
    for t in 0:tops               
        predict_by_binary=pred_binary_ess_rank(class_dict, t)
        predictions[t+1]=predict_by_binary
    end
  
    auc_array=[]
    cent_array=[]
    
    for cents_dict in cent_dict_input  
        for cent in vcat(collect(keys(cents_dict)))
            prec_plot_array=Array{Float64}(undef,tops+1)
            rec_plot_array=Array{Float64}(undef,tops+1)
            rank_by_number, rank_by_name, rank_by_name_exc, rank_by_centralities,rank_by_binary,rank_by_class=
            rank_arrays(cents_dict[cent][cent_type], cent_type, class_dict)
                   for t in 0:tops               
                        predict_by_binary=predictions[t+1]
                        ppv=EvalMetrics.precision(rank_by_binary,predict_by_binary)
                        tpr=EvalMetrics.true_positive_rate(rank_by_binary,predict_by_binary)
                        prec_plot_array[t+1]=ppv
                        rec_plot_array[t+1]=tpr
                    end
            auc1=Trapz.trapz(rec_plot_array,prec_plot_array)
            push!(auc_array, auc1)
            push!(cent_array, cent)

        end
    end
    return cent_array, auc_array
end




function print_max_mins(centralities, node_numbers_dict,B,w,set_dict,node_edges_dict ;min_inc=false)
    #prints various mins and max stats
    #WARNING: INEFFICIENCY FOR LARGE DATA
    
    #max set size
    m,p=max_size_value_set(set_dict)
    println("Maximum set size: ",m)
    println("for sets", p)

    #max edge size:
    m,p=max_size_value_set(edges_fromB)
    println("Maximum edge size: ",m)
    println("for edges", p)

    #max edge weight:
    max_w=maximum(w)
    m=findall(==(max_w), w)

    println("Maximum edge weight: ",max_w)
    println("for edges", m)

    #max number of edges a node belongs to:
    m=0
    p=[]
    for k in node_edges_dict 
        if length(k[2])>m
            m=length(k[2])
            p=[k[1]]
        elseif length(k[2])==m
            push!(p, k[1])

        end
    end
    
    println("Maximum number of edges a node belongs to: ",m)
    println("for nodes", p)   

    println("-----------------")
    println("MAXIMUM NODE CENTRALITIES")
    
    for cent in keys(centralities) #identify which nodes have the maximum centrality
        println(" ")  
        mn=max_nodes(centralities,cent)
        for p in mn
            k=number_to_name(p, node_numbers_dict)
            print(k, ", ") 
        end
        println(" ")
    end
    
    println("-----------------")
    
    println("MAXIMUM EDGE CENTRALITIES")
    for cent in keys(centralities) #identify which edges have the maximum centrality
        println(" ")  
        me=max_edges(centralities,cent)
        for idx in me #for each maximum edge corresponding to a column index in B
            println(" ")   
            nodes_in_idx=edges_fromB[idx] #list of nodes in column idx
            println("Edge ", idx," represents ", length(sets_with_nodenumbers(nodes_in_idx, node_numbers_dict)),
                    " set(s): ")
            println(sets_with_nodenumbers(nodes_in_idx, node_numbers_dict)) #turns edge # to representing set list            
            println("containing ",length(nodes_in_idx), " node(s): ") 
            println(nodes_in_idx)
                for p in nodes_in_idx
                    k=number_to_name(p, node_numbers_dict)
                    print(k, ", ")
                end
            println(" ")
        end
    end
    
    if min_inc==true
        println("-----------------")
        println("MINIMUM NODE CENTRALITIES")
        for cent in keys(centralities) #identify which nodes have the maximum centrality
            println(" ")
            min_n=min_nodes(centralities,cent)
            for p in minn
                k=number_to_name(p, node_numbers_dict)
                print(k, ", ")

            end
            println(" ")
        end
        println("-----------------")
        println("MINIMUM EDGE CENTRALITIES")
        for cent in keys(centralities) #identify which edges have the minimum centrality
           println(" ")
           min_e=min_edges(centralities,cent)
           for m in min_e #for each minimum edge
                nodes_in_m=edges_fromB[m]
                println("Sets are ")
                println(sets_with_nodenumbers(nodes_in_m, node_numbers_dict))#turns edge # to representing set list
                println("containing nodes ")
                println(nodes_in_m)    
                for p in nodes_in_m
                        k=number_to_name(p, node_numbers_dict)
                        print(k, ", ")
                end
                println(" ")
            end
        end

    end
        
end







