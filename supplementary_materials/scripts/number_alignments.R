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

    # perfect alignments (same score as the true alignment + dseq = 0)
    is_perfect = matrix(data = FALSE, nrow = row_s, ncol = col_s)

    for(i in 1:row_s) {
        perf =  which(score[i, ] == ref_score[i])
        is_perfect[i, perf] = TRUE

        results$perfect[perf] = results$perfect[perf] + 1
    }

    # best alignments (lower d_seq)
    for(r in 1:(row_s)) {
        for(i in which(min(dseq[r, ], na.rm = TRUE) == dseq[r, ])){
            results$best[i] = results$best[i] + 1
        }
    }

    # imperfect alignments (score is diff than the true aln when at least one method found a perf aln)
    for(r in 1:(row_s)) {
        if(any(is_perfect[r, ] == TRUE)) {
            imp = intersect(which(is_perfect[r, ] == FALSE), which(!is.na(dseq[r, ])))
            results$imperfect[imp] = results$imperfect[imp] + 1
        }
    }

    rownames(results) = split_results[[1]]$aligner
    return(results)
}


