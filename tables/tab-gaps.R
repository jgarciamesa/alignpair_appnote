options(tidyverse.quiet = TRUE,
    readr.show_col_types = FALSE,
    conflicts.policy = list(warn = FALSE ))

library(tidyverse)
library(here)

aln_data <- read_csv(here("data/raw_fasta_aligned_stats.csv.gz"))

cigar_to_rle <- function(x) {
    len <- str_extract_all(x, "\\d+")
    val <- str_extract_all(x, "\\D+")

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
    unnest(rle) |> select(-cigar) |>
    rename(length = lengths, op = values)

write_csv(tab, here("tables", "gaps.csv.gz"))
write_csv(tab, here("supplementary_materials", "data", "gaps.csv.gz"))

# print(xtable::xtable(k), floating=FALSE, latex.environments=NULL, booktabs=TRUE)


