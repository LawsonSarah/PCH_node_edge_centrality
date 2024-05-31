#CREATE PLOTS
ftlabels = 20
ftticks = 12
ftticks_edge = 7
fttitle = 18

function prec_plot(cent_dict_input, ness, ess,ess_dict,cent_type; inc_rand=true, inc_ideal=false) 
    #plot precision recall for everey centrality in the cent_dict_input array

    #input 
        #cent_dict_input: array of dictionairies containing centralities to be compared,
        #ness: total number of nonessential nodes/edges in dataset
        #ess: total number of essential nodes/edges in dataset
        #ess_dict: essentiality status of nodes/edges
        #cent_type: node "x" or edge "y"
   
    figure()
    plt.figure(figsize=(15,15))
    xlabel("Recall",fontsize=20, fontname="arial")
    ylabel("Precision",fontsize=20, fontname="arial")
    plt.xticks(fontsize=14, fontname="arial")
    plt.yticks(fontsize=14, fontname="arial")
    
    if cent_type=="x"
        tt="nodes"
    else tt="edges"
    end
    
    p=PyPlot.plot()
    legend=Vector{String}()


    tops=ness+ess #total number of nodes being analysed
    predictions=Array{Vector}(undef,tops+1)#array to compare results with
    for t in 0:tops               
        predict_by_binary=pred_binary_ess_rank(ess_dict, t)
        predictions[t+1]=predict_by_binary
    end
  
    for cents_dict in cent_dict_input  
        for cent in vcat(collect(keys(cents_dict)))
            push!(legend,cent)
            prec_plot=Array{Float64}(undef,tops+1) #precision values
            rec_plot=Array{Float64}(undef,tops+1)   #recall values       
            rank_by_number, rank_by_name, rank_by_name_exc, rank_by_centralities,rank_by_binary,rank_by_class=rank_arrays(cents_dict[cent][cent_type], cent_type, ess_dict)
            for t in 0:tops               
                predict_by_binary=predictions[t+1]
                ppv=EvalMetrics.precision(rank_by_binary,predict_by_binary)
                tpr=EvalMetrics.true_positive_rate(rank_by_binary,predict_by_binary)            
                prec_plot[t+1]=ppv
                rec_plot[t+1]=tpr
            end
            PyPlot.plot(rec_plot, prec_plot)
            AUC=Trapz.trapz(rec_plot,prec_plot)
            println("AUC for $cent is ", AUC)    
        end
    end
    
    if inc_rand      #plot random  if inc_rand=true     
        prec_plotr=Array{Float64}(undef,tops+1)        
        rec_plotr=Array{Float64}(undef,tops+1)      
        push!(legend,"random")      
        prob=ess/(ness+ess)   
        for t in 0:tops               
            prec_plotr[t+1]=prob
            rec_plotr[t+1]=t/(ness+ess)        
        end     
        PyPlot.plot(rec_plotr, prec_plotr, "--")
    end
    plt.legend(legend, fontsize=14)
    PyPlot.savefig("$output_path\\plot_exports\\prec_rec_$cent_type.jpg", dpi=300, bbox_inches="tight")    
end





function cumulative_essential(centralities, x_range, essent, class_dict, cent_dict_input, cent_type)
    #plot cumulative frequency of essential propteins/complexes for everey centrality in the cent_dict_input array
    
   if cent_type =="x"
        tt="nodes"
        tp="proteins"
    else
        tt="edges"
        tp="complexes"
    end
    

    figure()
    plt.figure(figsize=(15,15))
    xlabel("Number of $tt (t)",fontsize=20, fontname="arial")
    ylabel("Number of essential $tp",fontsize=20,fontname="arial")
    plt.xticks(fontsize=14)
    plt.yticks(fontsize=14)
    legend=Vector{String}()

    # x values
    x_plot=Vector{Int16}()
    for i in x_range
        push!(x_plot,i)
    end

    for cents_dict in cent_dict_input    
        for c in vcat(collect(keys(cents_dict)))
            push!(legend, c)
            y_plot=Vector{Int16}()
            centrality_list=cents_dict[c][cent_type]
            rank_by_number, rank_by_name, rank_by_name_exc, rank_by_centralities,rank_by_binary,rank_by_class=
            rank_arrays(centrality_list, cent_type, class_dict)
            for i in x_range
                y=EvalMetrics.true_positive(rank_by_binary,pred_binary_ess_rank(class_dict, i))
                push!(y_plot,y)
            end
        PyPlot.plot(x_plot, y_plot)
        end
    end  
        
   #plot random  
    push!(legend, "random")
    y_plot=Vector{Float64}()

    for i in x_range
        tp_av=(essent/maximum(x_range))*i
        push!(y_plot,tp_av)
    end

    PyPlot.plot(x_plot, y_plot, "--")
    
    plt.legend(legend, fontsize=14)  
    ranks_by_name_exc=[]
    ranks_by_binary=[]
    cent_name=[] 
    legend=Vector{String}()
    for i in keys(centralities)
        centrality_list=centralities[i][cent_type]
        rank_by_number, rank_by_name, rank_by_name_exc, rank_by_centralities,rank_by_binary,rank_by_class=
            rank_arrays(centrality_list, cent_type, class_dict)
        push!(ranks_by_name_exc, rank_by_name_exc)
        push!(ranks_by_binary, rank_by_binary)
     end    
    PyPlot.savefig("$output_path\\plot_exports\\cum_$cent_type.jpg", dpi=300, bbox_inches="tight")
   
    return  
end

