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

meta_data <- read_csv(here("data/metadata.csv.gz"))

meta_data <- meta_data |>
    mutate(gene = sprintf("TEST%06d", 1:n())) |>
    rename(origin = model)

my_methods <- c("benchmark", "clustalo", "macse", "mafft", "prank",
    "coati-tri-mg")

cigar_data <- bench_data |> 
    filter(method %in% my_methods) |>
    select(gene, method, cigar) |>
    mutate(aln = simplify_cigar_exp(cigar)) |>
    select(gene, method, aln) |>
    arrange(gene, method)

methods <- unique(cigar_data$method)

## sanity check
# dat |> filter(method != methods, .by=gene)

xy <- combn(length(methods), 2)
x <- xy[1,]
y <- xy[2,]

tab_dseq <- cigar_data |>
    left_join(select(meta_data, gene, origin)) |>
    reframe(method1 = method[x], method2 = method[y],
        aln1 = aln[x], aln2 = aln[y], .by = c(origin,gene))

tab_dseq <- tab_dseq |>
    mutate(dseq = map2_dbl(aln1, aln2, calculate_dseq, .progress = TRUE))

tab_dist <- tab_dseq |> summarize(.by=c(origin,method1,method2), dseq = mean(dseq, na.rm = TRUE))

write_csv(tab_dist, here("tables", "benchmarks-dseq-split.csv"))
write_csv(tab_dist, here("supplementary_materials", "data", "benchmarks-dseq-split.csv"))
