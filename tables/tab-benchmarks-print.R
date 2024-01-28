library(tidyverse)
library(here)
library(xtable)

tab <- read_csv(here("tables", "benchmarks.csv"))

tab <- tab |> mutate(
        avg_dseq = scales::percent(avg_dseq, accuracy = 0.01),
        over_k2p = scales::percent(over_k2p, accuracy = 0.1),
        rmse_k2p = formatC(signif(tab$rmse_k2p, 3), flag = "#", digits = 3),
        neg_f1 = scales::percent(neg_f1, accuracy = 0.1),
        pos_f1 = scales::percent(pos_f1, accuracy = 0.1) ) |>
    relocate(rmse_k2p, .before = over_k2p)

stat_names <- c(
    "Method" = "method",
    "Average Alignment Error ($d_{seq}$)" = "avg_dseq",
    "Number of Best Alignments" = "count_best",
    "Number of Perfect Alignments" = "count_perfect",
    "Number of Imperfect Alignments" = "count_imperfect",
    "RMSE for K2P Distances" = "rmse_k2p",
    "Overestimated K2P Distances" = "over_k2p",
    "F\\textsubscript{1} for Positive Selection" = "pos_f1",
    "F\\textsubscript{1} for Negative Selection" = "neg_f1"
)

method_levels <- c("coati-tri-mg", "clustalo", "macse",
    "mafft", "prank")

method_names <- c(
        "COATi" = "coati-tri-mg",
        "ClustalΩ" = "clustalo",
        "MACSE" = "macse",
        "MAFFT" = "mafft",
        "PRANK" = "prank"
)

tab <- tab |> 
    filter(method %in% method_levels) |>
    mutate(method = fct_recode(fct_relevel(method, method_levels), !!!method_names)) |>
    arrange(method) |>
    rename(!!!stat_names)

x <- t(tab)
colnames(x) <- x[1,]
x <- x[-1,]
x[,1] <- paste0("\\cellcolor{bestcolor}", x[,1])


print(xtable::xtable(x, align = c("r", "c", "c", "c", "c", "c")),
    file = here("tables/benchmarks.tex"),
    floating = FALSE, 
    latex.environments = NULL,
    booktabs = TRUE,
    sanitize.text.function = \(x) gsub("%", "\\\\%", x)
)
