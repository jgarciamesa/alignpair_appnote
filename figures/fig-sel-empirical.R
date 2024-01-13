library(here)
library(tidyverse)
library(ComplexUpset)
library(patchwork)

PDF_WIDTH <- 7 # 178mm
PDF_HEIGHT <- PDF_WIDTH*0.6

# load data
aln_data <- read_csv(here("data/raw_fasta_aligned_stats.csv.gz"))

# omega_data <- aln_data |>
#     mutate(neg_sel = (!is.na(omega) & omega < 1)) |>
#     filter(neg_sel) |>
#     (\(x) split(x, x$method))() |>
#     map(\(x) pull(x, "sequence"))

####

methods <- rev(c("coati-tri-mg", "clustalo", "macse", "mafft", "prank", "rev-coati-tri-mg"))

omega_data <- aln_data |>
    mutate(neg_sel = omega < 1) |>
    pivot_wider(id_cols = "gene", names_from = "method", values_from = "neg_sel")

gg1 <- upset(omega_data, methods,
    wrap = TRUE,
    n_intersections = 10, set_sizes = FALSE, sort_sets = FALSE,
    name = "Negative Selection Grouping",
    base_annotations=list(
        'Intersection size'=intersection_size(
            mapping=aes(hjust=ifelse(after_stat(y) > 3000, 0.5, 0.0)),
            text=list(
                vjust=0.5,
                angle=90,
                check_overlap=TRUE
            )
        )
    ),
    labeller = ggplot2::as_labeller(c(
        "coati-tri-mg" = "COATi",
        prank = "PRANK",
        mafft = "MAFFT",
        macse = "MACSE",
        clustalo = "ClustalΩ",
        "rev-coati-tri-mg" = "COATi-rev"
    ))
)


omega_data <- aln_data |>
    mutate(neg_sel = omega > 1) |>
    pivot_wider(id_cols = "gene", names_from = "method", values_from = "neg_sel")

gg2 <- upset(omega_data, methods,
    n_intersections = 10, set_sizes = FALSE, sort_sets = FALSE,
    wrap = TRUE,
    name = "Positive Selection Grouping",
    base_annotations=list(
        'Intersection size'=intersection_size(
            mapping=aes(hjust=ifelse(after_stat(y) > 3000, 0.5, 0.0)),
            text=list(
                vjust=0.5,
                angle=90,
                check_overlap=TRUE
            )
        )
    ),
    labeller = ggplot2::as_labeller(c(
        "coati-tri-mg" = "COATi",
        prank = "PRANK",
        mafft = "MAFFT",
        macse = "MACSE",
        clustalo = "ClustalΩ",
        "rev-coati-tri-mg" = "COATi-rev"
    ))
)

#gg <- wrap_plots(gg1, gg2, ncol = 2) + plot_annotation(tag_levels = c('a', '1'))

gg <- gg1 + gg2 +
      plot_annotation(tag_levels = 'a',
        theme = theme(plot.margin = margin()))

gg <- gg & theme(plot.tag.position = c(0,1))

if(rlang::is_interactive()) {
    print(gg)
} else {
    scriptname <- grep("^--file=", commandArgs(), value = TRUE)
    scriptname <- sub("^--file=", "", scriptname)
    scriptname <- scriptname[[length(scriptname)]]
    if(scriptname == "-") {
        pdfname <- "Rplots.pdf"
    } else {
        pdfname <- sub("\\.[^.]*$", ".pdf", basename(scriptname))
    }
    
    pdfname <- here::here("figures", pdfname)

    cairo_pdf(file=pdfname, width=PDF_WIDTH, height=PDF_HEIGHT)
    print(gg)
    invisible(dev.off())

    embedFonts(pdfname)
}
