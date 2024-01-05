library(here)
library(tidyverse)
library(ComplexUpset)
library(patchwork)

PDF_WIDTH <- 7 # 178mm
PDF_HEIGHT <- PDF_WIDTH/2

# load data
aln_data <- read_csv(here("data/aln_data.csv.gz"))

# omega_data <- aln_data |>
#     mutate(neg_sel = (!is.na(omega) & omega < 1)) |>
#     filter(neg_sel) |>
#     (\(x) split(x, x$method))() |>
#     map(\(x) pull(x, "sequence"))

####

omega_data <- aln_data |>
    mutate(neg_sel = omega < 1) |>
    pivot_wider(id_cols = "sequence", names_from = "method", values_from = "neg_sel") |>
    rename(coati = "tri-mg")

gg1 <- upset(omega_data, c("clustalo", "macse", "mafft", "prank", "coati"),
    wrap = TRUE,
    n_intersections=10, set_sizes = FALSE, sort_sets = FALSE,
    name = "Negative Selection Grouping",
    base_annotations=list(
        'Intersection size'=intersection_size(
            mapping=aes(hjust=ifelse(after_stat(y)>3000, 0.5, 0.0)),
            text=list(
                vjust=0.5,
                angle=90,
                check_overlap=TRUE
            )
        )
    ),
    labeller = ggplot2::as_labeller(c(
        coati = "COATi",
        prank = "PRANK",
        mafft = "MAFFT",
        macse = "MACSE",
        clustalo = "ClustalΩ"
    ))
)


omega_data <- aln_data |>
    mutate(neg_sel = omega > 1) |>
    pivot_wider(id_cols = "sequence", names_from = "method", values_from = "neg_sel") |>
    rename(coati = "tri-mg")

gg2 <- upset(omega_data, c("clustalo", "macse", "mafft", "prank", "coati"),
    n_intersections=10, set_sizes = FALSE, sort_sets = FALSE,
    wrap = TRUE,
    name = "Positive Selection Grouping",
    base_annotations=list(
        'Intersection size'=intersection_size(
            mapping=aes(hjust=ifelse(after_stat(y)>3000, 0.5, 0.0)),
            text=list(
                vjust=0.5,
                angle=90,
                check_overlap=TRUE
            )
        )
    ),
    labeller = ggplot2::as_labeller(c(
        coati = "COATi",
        prank = "PRANK",
        mafft = "MAFFT",
        macse = "MACSE",
        clustalo = "ClustalΩ"
    ))
)

#gg <- wrap_plots(gg1, gg2, ncol = 2) + plot_annotation(tag_levels = c('a', '1'))

gg <- gg1 + gg2 + plot_annotation(tag_levels = 'a')

if(interactive()) {
    print(gg)
} else {
    scriptname <- commandArgs() |> str_subset("^--file=") |> str_replace("^--file=","")
    pdfname <- scriptname |> str_replace("\\.[^.]*$", ".pdf")
    pdfname <- here("figures", pdfname)

    cairo_pdf(file=pdfname, width=PDF_WIDTH, height=PDF_HEIGHT)
    print(gg)
    invisible(dev.off())

    embedFonts(pdfname)
}
