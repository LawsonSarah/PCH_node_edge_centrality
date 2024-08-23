#CREATE PLOTS
ftlabels = 20
ftticks = 12
ftticks_edge = 7
fttitle = 18

#colours for prec-rec and cumulative plots for A_B summary
A_Bcols =  Dict("LBBC" =>"blue"   ,     
            "P:(0,1,0,1)"   => "orange", 
            "P:(1,1,95,1/95)"   => "cyan", 
            "P:(1,1,46,29/46)"   => "red",             
            "P:(1/95,95,1,1/95)"   => "green",
            "P:(1,1,1,1)"   => "purple",
    "random"=>"grey",
    "ideal"=>"magenta",
        "PCHrandom"=>"black",
    "PCHideal"=>"greenyellow"
            )


function prec_plot(cent_dict_input, ness, ess,ess_dict,cent_type; inc_rand=true,pin_pch_int= false, int_node_numbers=[]) 
    #plot precision recall for every centrality in the cent_dict_input array

    #input 
        #cent_dict_input: array of dictionairies containing centralities to be compared,
        #ness: total number of nonessential nodes/edges in dataset
        #ess: total number of essential nodes/edges in dataset
        #ess_dict: essentiality status of nodes/edges
        #cent_type: node "x" or edge "y"
   
    figure()
    plt.figure(figsize=(15,8))
   
    xlabel("Recall",fontsize=12, fontname="arial")
    ylabel("Precision",fontsize=12, fontname="arial")
    plt.xticks(fontsize=12, fontname="arial")
    plt.yticks(fontsize=12, fontname="arial")
    
    if cent_type=="x"
        tt="nodes"
    else tt="edges"
    end
    
    p=PyPlot.plot()
    legend=Vector{String}()

       
        
    #plot NSVC
    tops=ness+ess #total number of nodes being analysed
    predictions=Array{Vector}(undef,tops+1)#array to compare results with
    for t in 0:tops               
        predict_by_binary=pred_binary_ess_rank(ess_dict, t)
        predictions[t+1]=predict_by_binary
    end
  
    for cents_dict in cent_dict_input  
        cents=vcat(collect(keys(cents_dict)))
        for cent in cents
                push!(legend,cent)
                prec_plot=Array{Float64}(undef,tops+1) #precision values
                rec_plot=Array{Float64}(undef,tops+1)   #recall values       
                rank_by_number, rank_by_name, rank_by_name_exc, rank_by_centralities,rank_by_binary,rank_by_class=rank_arrays(cents_dict[cent][cent_type], cent_type, ess_dict,  pin_pch_int= pin_pch_int, int_node_numbers=int_node_numbers)

                for t in 0:tops               
                    predict_by_binary=predictions[t+1]
                    ppv=EvalMetrics.precision(rank_by_binary,predict_by_binary)
                    tpr=EvalMetrics.true_positive_rate(rank_by_binary,predict_by_binary)            
                    prec_plot[t+1]=ppv
                    rec_plot[t+1]=tpr
                end
            if varying=="A_B_summary" 
                PyPlot.plot(rec_plot, prec_plot, color=A_Bcols[cent])
            else
                PyPlot.plot(rec_plot, prec_plot)
            end
                AUC=Trapz.trapz(rec_plot,prec_plot)
                println("AUC for $cent is ", AUC)    
        end
    end
    
    #ideal
      ideal="ideal"
      leg="Ideal"
      prec_ploti=Array{Float64}(undef,tops+1)        
      rec_ploti=Array{Float64}(undef,tops+1)      
      push!(legend,leg) 
      prob=ess/(ess+ness)   
        
    for t in 0:ess              
        prec_ploti[t+1]=1
        rec_ploti[t+1]=t/ess      
    end  


    for t in ess +1:tops               
        prec_ploti[t+1]=ess/t
        rec_ploti[t+1]=1       
    end  
        PyPlot.plot(rec_ploti, prec_ploti, "-.", color=A_Bcols[ideal])
        
        
    
    if inc_rand      #plot random  if inc_rand=true  

        random= "random"
        leg="Random" 
        prec_plotr=Array{Float64}(undef,tops+1)        
        rec_plotr=Array{Float64}(undef,tops+1)      
        push!(legend,leg)      
        prob=ess/(ness+ess)   
        for t in 0:tops               
            prec_plotr[t+1]=prob
            rec_plotr[t+1]=t/(ness+ess)        
        end     
        PyPlot.plot(rec_plotr, prec_plotr, "--", color=A_Bcols[random])
    end 
    plt.legend(legend, fontsize=12, loc="lower right")
        
    if pin_pch_int
        PyPlot.savefig("$output_path\\plot_exports\\int_prec_rec_$cent_type.jpg", dpi=300, bbox_inches="tight") 
    else
    PyPlot.savefig("$output_path\\plot_exports\\prec_rec_$cent_type.jpg", dpi=300, bbox_inches="tight")   
    end
end





function cumulative_essential(centralities, x_range, essent, class_dict, cent_dict_input, cent_type;pin_pch_int= false, int_node_numbers=[])
    #plot cumulative frequency of essential propteins/complexes for everey centrality in the cent_dict_input array
    
   if cent_type =="x"
        tt="nodes"
        tp="proteins"
    else
        tt="edges"
        tp="complexes"
    end
    

    figure()
    plt.figure(figsize=(15,8))
    xlabel("Number of $tt (t)",fontsize=12, fontname="arial")
    ylabel("Number of essential $tp",fontsize=12,fontname="arial")

    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)
    legend=Vector{String}()
    

    # NSVC centrality 
    
    #x values
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
            rank_arrays(centrality_list, cent_type, class_dict,pin_pch_int= pin_pch_int, int_node_numbers=int_node_numbers)      
            for i in x_range
                y=EvalMetrics.true_positive(rank_by_binary,pred_binary_ess_rank(class_dict, i))
                push!(y_plot,y)
            end
            
            if varying=="A_B_summary" 
                PyPlot.plot(x_plot, y_plot, color=A_Bcols[c])
            else
                 PyPlot.plot(x_plot, y_plot)
            end
        end
    end  

    #plot random  
    push!(legend, "Random")
    y_plot=Vector{Float64}()

    for i in x_range
        tp_av=(essent/maximum(x_range))*i
        push!(y_plot,tp_av)
    end

    PyPlot.plot(x_plot, y_plot, "--", color=A_Bcols["random"])
    plt.legend(legend, fontsize=12,loc="lower right")     
    
    if pin_pch_int
        PyPlot.savefig("$output_path\\plot_exports\\int_cum_$cent_type.jpg", dpi=300, bbox_inches="tight")
    else
        PyPlot.savefig("$output_path\\plot_exports\\cum_$cent_type.jpg", dpi=300, bbox_inches="tight")
    end
    return  
end

