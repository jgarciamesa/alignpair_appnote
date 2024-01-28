options(tidyverse.quiet = TRUE,
    readr.show_col_types = FALSE,
    conflicts.policy = list(warn = FALSE ))

library(tidyverse)
library(here)

simplify_cigar_exp <- function(x) {
    len <- str_extract_all(x, "\\d+")
    val <- str_extract_all(x, "\\D+")

    result <- map2_chr(len, val, function(n, v) {
        if(length(n) == 1L && is.na(n)) {
            return(NA_character_)
        }
        v[v == "=" | v == "X"] <- "M"
        m <- rep.int(v, as.integer(n))
        str_flatten(m)
    })
    result
}

calculate_dseq <- function(x, y) {
    if(is.na(x) || is.na(y)) {
        return(NA_real_)
    }
    if(x == y) {
        # fast path
        return(0.0);
    }

    # calculate homology sets
    h <- function(z) {
        z <- str_split_1(z, "")
        za <- if_else(z == "I", -1, cumsum(z %in% c("M", "D")))
        zd <- if_else(z == "D", -1, cumsum(z %in% c("M", "I")))
        ha <- zd[z %in% c("M", "D")]
        hd <- za[z %in% c("M", "I")]
        list(ha, hd)
    }

    hx <- h(x)
    hy <- h(y)

    # total sequence length
    tot_len <- length(hx[[1]]) + length(hx[[2]])
    # calculate hamming distances
    ham_dist <- sum(hx[[1]] != hy[[1]]) + sum(hx[[2]] != hy[[2]])

    ham_dist/tot_len
}

bench_data <- read_csv(here("data/benchmark_fasta_aligned_stats.csv.gz"))

# alignment analysis
aln_data <- bench_data |> select(gene, method, cigar, score) |>
    mutate(aln = simplify_cigar_exp(cigar)) |>
    pivot_wider(id_cols = gene, names_from = method, values_from=c(score, aln)) |>
    pivot_longer(-c(gene, score_benchmark, aln_benchmark),
        names_to = c(".value", "method"), names_sep = "_") |>
    relocate(gene, method)

aln_data <- aln_data |> mutate(
    dseq = map2_dbl(aln_benchmark, aln, calculate_dseq)
)

aln_data <- aln_data |> mutate(.by = gene,
    perfect = dseq == 0 | score == score_benchmark, # note that dseq == 0 implies score == score_benchmark
    best = dseq == min(dseq, na.rm = TRUE) | score %in% score_benchmark[dseq == min(dseq, na.rm = TRUE)],
    imperfect = any(perfect, na.rm = TRUE) & !perfect
)

aln_tab <- aln_data |> drop_na(dseq) |> summarize(.by=method,
    avg_dseq = mean(dseq),
    count_best = sum(best),
    count_perfect = sum(perfect),
    count_imperfect = sum(imperfect)
)

# k2p analysis

k2p_data <- bench_data |> 
    pivot_wider(id_cols=c(gene), names_from = method, values_from = k2p) |>
    pivot_longer(-c(gene,benchmark), names_to="method", values_to="k2p") |>
    relocate(gene, method)

k2p_tab <- k2p_data |> drop_na(k2p) |> summarize(.by=method,
    over_k2p = sum(k2p > benchmark)/n(),
    rmse_k2p = sqrt(mean((k2p-benchmark)^2)) )

# sel analysis
omega_data <- bench_data |> 
    pivot_wider(id_cols=c(gene), names_from = method, values_from = omega) |>
    pivot_longer(-c(gene,benchmark), names_to="method", values_to="omega") |>
    relocate(gene, method)

omega_data <- omega_data |> mutate(
    neg_cat = case_when(
        benchmark < 1 & omega < 1 ~ "TP",
        benchmark < 1 & !(omega < 1) ~ "FN",
        !(benchmark < 1) & omega < 1 ~ "FP",
        !(benchmark < 1) & !(omega < 1) ~ "TN" ),
    pos_cat = case_when(
        benchmark > 1 & omega > 1 ~ "TP",
        benchmark > 1 & !(omega > 1) ~ "FN",
        !(benchmark > 1) & omega > 1 ~ "FP",
        !(benchmark > 1) & !(omega > 1) ~ "TN" )
    )

omega_tab <- omega_data |> drop_na(neg_cat, pos_cat) |> summarize(.by = method,
    neg_f1 = 2 * sum(neg_cat == "TP")/(2 * sum(neg_cat == "TP") + 
        sum(neg_cat == "FP") + sum(neg_cat == "FN") ),
    pos_f1 = 2 * sum(pos_cat == "TP")/(2 * sum(pos_cat == "TP") + 
        sum(pos_cat == "FP") + sum(pos_cat == "FN") )
)

tab <- left_join(aln_tab, k2p_tab)
tab <- left_join(tab, omega_tab)

write_csv(tab, here("tables", "benchmarks.csv"))
write_csv(tab, here("supplementary_materials", "data", "benchmarks.csv"))

# print(xtable::xtable(t(tab)),
#     file = here("tables/benchmarks.tex"),
#     floating = FALSE, 
#     latex.environments = NULL,
#     booktabs = TRUE
#     )


