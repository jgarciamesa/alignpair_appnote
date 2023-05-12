suppressMessages(suppressWarnings(library(dplyr)))


num_alns = function(filename) {
    results_summary = read.csv(file = filename, header = TRUE, stringsAsFactors = FALSE)

    # extract dseq values for all aligners per each reference alignment
    split_tibble <- function(tibble, col = 'col') tibble %>% split(., .[, col])
    split_results = split_tibble(results_summary, 'ref_name')
    dseq = t(sapply(split_results, function(x){ return(x$dseq)}))
    score = t(sapply(split_results, function(x){ return(x$score)}))
    ref_score = t(sapply(split_results, function(x){ return(x$ref_score)}))

    col_s = ncol(dseq)
    row_s = nrow(dseq)

    results = data.frame("perfect" = integer(col_s),
                         "best" = integer(col_s),
                         "imperfect" = integer(col_s))

    # perfect alignments (dseq = 0)
    # alignments with same score as the reference alignment are considered dseq = 0
    for(i in 1:row_s) {
        alt = which(score[i, ] == ref_score[i])
        if(length(alt) > 0) {
            dseq[i, alt] = 0
        }
        z = which(dseq[i, ] == 0)
        if(length(z) > 0){
            results$perfect[z] = results$perfect[z] + 1
        }
    }

    # best alignments (lower d_seq)
    for(r in 1:(row_s)) {
        for(i in which(min(dseq[r, ], na.rm = TRUE) == dseq[r, ])){
            results$best[i] = results$best[i] + 1
        }
    }

    # imperfect alignments (dseq != 0 when another methods has dseq = 0)
    for(r in 1:(row_s)) {
        if(min(dseq[r, ], na.rm = TRUE) == 0){
            for(i in which(dseq[r, ]>0)) {
            results$imperfect[i] = results$imperfect[i] + 1
            }
        }
    }

    rownames(results) = split_results[[1]]$aligner
    return(results)
}


