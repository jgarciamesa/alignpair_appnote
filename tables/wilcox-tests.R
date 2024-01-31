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

method_levels <- c("coati-tri-mg", "clustalo", "macse",
    "mafft", "prank")

tab_dseq <- aln_data |> filter( method %in% method_levels ) |>
    select(gene, method, dseq) |>
    pivot_wider(names_from = method, values_from = dseq) |>
    pivot_longer(-c(gene, `coati-tri-mg`), names_to = "method", values_to = "dseq") |>
    relocate(gene, method)


res <- tab_dseq |> summarize(.by = method,
    list(wilcox.test(x = `coati-tri-mg`, y = dseq, paired = TRUE, alternative = "less")))

res <- reframe(res)
