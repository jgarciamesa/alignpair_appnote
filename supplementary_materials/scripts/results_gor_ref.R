# create a results file only using the reference alignments that COATi triplet-mg
#  was able to align with gorilla as the reference

library(tidyverse)

gor_ref_results = function() {
    
    ## Clean and save gor-ref results
    results_raw = read.csv("supplementary_data/gor-ref/results/results_summary.csv",
                       header = TRUE)
    alns = results_raw |> filter(aligner == "gor-ref") |> drop_na(score) |> select(ref_name) |> unlist()
    results = results_raw |> filter(ref_name %in% alns)
    results_file = "supplementary_data/gor-ref/results/results_summary_clean.csv"
    write_csv(x = results, file = results_file)
    
    trimg = results |> filter(aligner == "tri-mg")
    mafft = results |> filter(aligner == "mafft")
    prank = results |> filter(aligner == "prank")
    macse = results |> filter(aligner == "macse")
    clustal = results |> filter(aligner == "clustalo")
    goref = results |> filter(aligner == "gor-ref")
    
    aligners = c("tri-mg", "mafft", "prank", "macse", "clustalo", "gor-ref")
    stats_table = data.frame(dseq = c(mean(trimg$dseq, na.rm = TRUE),
                                      mean(mafft$dseq, na.rm = TRUE),
                                      mean(prank$dseq, na.rm = TRUE),
                                      mean(macse$dseq, na.rm = TRUE),
                                      mean(clustal$dseq, na.rm = TRUE),
                                      mean(goref$dseq, na.rm = TRUE)),
                             row.names = aligners)
    
    stats_table
    
    ###########################################################################
    # perfect, best, and imperfect alignments
    source("supplementary_materials/scripts/number_alignments.R")
    alns = num_alns(results_file)
    
    # fix row and column names and add to stats table
    colnames(alns) = c("Perfect alns", "Best alns", "Imperfect alns")
    alns = alns[aligners, ]
    stats_table = cbind(stats_table, alns)
    
    ############################################################################
    # selection (ka ks)
    source("supplementary_materials/scripts/kaks.R")
    
    selection = data.frame("F1.pos" = double(),
                           "F1.neg" = double())
    
    # calculate F1 score for positive and negative selection for each aligner
    for(model in aligners) {
        model_rows = results |> filter(aligner == model)
        pos = ps_accuracy(model_rows$ref_omega, model_rows$aln_omega)
        neg = ns_accuracy(model_rows$ref_omega, model_rows$aln_omega)
        
        selection[nrow(selection) + 1, ] = c(pos, neg)
    }
    
    # fix row and column names and add to stats table
    colnames(selection) = c("F1 pos selection", "F1 neg selection")
    rownames(selection) = aligners
    stats_table = cbind(stats_table, selection)
    
    rownames(stats_table) = c("Triplet-MG", "MAFFT", "PRANK", "MACSE", "ClustalOmega", "Triplet-MG-gor-ref")
    
    # display stats table
    stats_table
    
}

library(seqinr)
# count how many alignments didn't pass filtering for coati using gorilla as the reference
#  and the reasons (i.e., incomplete codons, early stop codons, ambiguous nucleotides)
filter_counts = function() {
    results = read.csv("supplementary_data/gor-ref/results/results_summary.csv", header = TRUE)
    filtered = results |> filter(aligner == "gor-ref") |>
        filter(is.na(score)) |> select(ref_name) |> unlist()
    incomplete = 0
    early_stop = 0
    ambiguous = 0
    
    for(aln_name in filtered) {
        aln = read.fasta(file = paste0("supplementary_data/tri-mg/data/no_gaps_ref/",
                                       aln_name),
                         seqonly = TRUE)
    
        gor = aln[[2]]
        
        # check for incomplete codons in the gorilla sequence
        if(nchar(gor) %% 3 != 0) {
            incomplete = incomplete + 1
        }
        
        # check for early stop codons in the gorilla sequence
        codons = unlist(strsplit(gor, "(?<=.{3})", perl = TRUE))
        if(any(c("TAA", "TAG", "TGA") %in% codons[-length(codons)])) {
            early_stop = early_stop + 1
        }
        
        # check for ambiguous nucs on gorilla sequence
        gor_nucs = sort(unique(unlist(strsplit(gor, split = ""))))
        if(length(gor_nucs) != 4) {
            ambiguous = ambiguous + 1
        } else if(!all.equal(gor_nucs, c("A", "C", "G", "T"))) {
            ambiguous = ambiguous + 1
        }
    }
}
