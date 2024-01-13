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

#### LENGTHS ###################################################################

k <- tab |> filter(values != "M") |>
    mutate(lengths = if_else(lengths <= 6, lengths, 7 + ((lengths-1) %% 3))) |>
    arrange(lengths) |>
    count(method, lengths, values) |>
    complete(method, values, lengths = full_seq(lengths, 1), fill = list(n = 0)) |>
    pivot_wider(names_from = "lengths", values_from = "n")

write_csv(k, here("tables", "gap-lengths.csv"))
write_csv(k, here("supplementary_materials", "data", "gap-lengths.csv"))

#### PHASES ####################################################################

k <- tab |> group_by(gene, method) |>
    mutate(mlen = if_else(values == "I", 0L, lengths),
        pos = cumsum(mlen) - mlen,
        phase = ((pos-1) %% 3) + 1) |>
    ungroup() |>
    count(method, phase) |>
    drop_na(phase) |>
    complete(method, phase = full_seq(phase, 1), fill = list(n = 0)) |>
    pivot_wider(names_from = "phase", values_from = "n")

write_csv(k, here("tables", "gap-phases.csv"))
write_csv(k, here("supplementary_materials", "data", "gap-phases.csv"))

#### GAPINESS ##################################################################

k <- tab |> group_by(method, gene) |> 
    summarize(p = sum(lengths[values != "M"])/(sum(lengths) + sum(lengths[values == "M"]))) |>
    summarize(p = mean(p, na.rm = TRUE))

write_csv(k, here("tables", "gapiness.csv"))
write_csv(k, here("supplementary_materials", "data", "gapiness.csv"))

# print(xtable::xtable(k), floating=FALSE, latex.environments=NULL, booktabs=TRUE)


