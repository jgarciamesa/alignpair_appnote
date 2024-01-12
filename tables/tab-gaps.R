options(tidyverse.quiet = TRUE,
    readr.show_col_types = FALSE,
    conflicts.policy = list(warn = FALSE ))

library(tidyverse)
library(here)

aln_data <- read_csv(here("data/raw_fasta_aligned_stats.csv.gz"))

cigar_to_rle <- function(x) {
    len <- str_extract_all(x, "\\d+")
    val <- str_extract_all(x, "[A-Za-z]")

    result <- map2(len, val, function(n, v) {
        structure(list(lengths = as.integer(n), values = v), class = "rle")
    })
    result
}

tbl_cigar <- function(x) {
    x <- cigar_to_rle(x)
    x <- map(x, \(y) as_tibble(unclass(y)))
    x
}

tab <- aln_data |> select(gene, method, cigar) |> 
    mutate(rle = tbl_cigar(cigar)) |>
    unnest(rle)

k <- tab |> filter(values != "M") |>
    mutate(lengths = if_else(lengths <= 6, lengths, 7 + ((lengths-1) %% 3))) |>
    arrange(lengths) |>
    count(method, lengths, values) |>
    complete(method, values, lengths = full_seq(lengths, 1), fill = list(n = 0)) |>
    pivot_wider(names_from = "lengths", values_from = "n")

# print(xtable::xtable(k), floating=FALSE, latex.environments=NULL, booktabs=TRUE)

# tab |> filter(lengths %% 3 > 0 & method == "clustalo")

# tab |> group_by(method, gene) |> summarize(p = sum(lengths[values != "M"])/(sum(lengths) + sum(lengths[values == "M"]))) |> summarize(mean(p, na.rm = TRUE))