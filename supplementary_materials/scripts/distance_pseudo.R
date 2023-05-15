# calculate distance between alignments using Blackburne and Whelan 2012
# doi: https://doi.org/10.1093/bioinformatics/btr701
# binary `metal` calculates the distance available on GitHub by the authors

distance_main = function(metric, coati_model, aligners) {
    # choose between d_seq and d_pos
    if(metric == "dseq") {
        flag = paste("-s")
    } else if(metric == "dpos") {
        flag = paste("-p")
    } else {
        stop(paste("Metric", metric, "not supported."))
    }
    
    distances = data.frame(filename = character(), aligner = character(), distance = numeric())
    ref_alns = list.files(paste0("supplementary_data/", coati_model, "/data/ref_alignments/"))
    for(filename in ref_alns) {
        ref = paste0("supplementary_data/", coati_model, "/data/ref_alignments/", filename)
        # calculate distance between reference for each method
        file_distances = c()
        for(model in aligners) {
            aln = paste0("supplementary_data/", coati_model, "/aln/ref/", model, "/", filename)
            # call metal to calculate distance
            d = system(paste("supplementary_materials/bin/metal", flag, ref, aln), intern = TRUE, ignore.stderr = TRUE)
            
            if(length(d) == 0) {
                break
            }
            # parse metal output ("fraction = double" --> double)
            d = gsub("\ =.*", "", d)
            num = as.double(gsub("/\ .*", "", d))
            den = as.double(gsub(".*\ /\ ", "", d))
            file_distances = rbind(file_distances, c(filename, model, (num+1)/(den+2)))
        }
        if(length(d) != 0) {
            distances = rbind(distances, file_distances)
        }
    }
    colnames(distances) = c("filename", "aligner", metric)
    write.csv(x = distances,
              file = paste0("supplementary_data/", coati_model, "/plot_distance.csv"),
              col.names = TRUE,
              quote = FALSE,
              row.names = FALSE)
}

if(!interactive()) {
    ARGS = commandArgs(trailingOnly = TRUE)
    
    # metric, coati_model, aligners
    distance_main(ARGS[1], ARGS[2], ARGS[-c(1, 2)])
}
