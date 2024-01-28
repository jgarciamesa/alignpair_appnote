library(here)
library(tidyverse)
library(ComplexUpset)
library(patchwork)

PDF_WIDTH <- 3.38 # 7=178mm 3.38=86mm
PDF_HEIGHT <- PDF_WIDTH

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
    filter(!any(is.na(omega)), .by=gene) |>
    mutate(sel = omega > 1) |>
    pivot_wider(id_cols = "gene", names_from = "method", values_from = "sel")

gg1 <- upset(omega_data, methods,
    wrap = FALSE,
    themes=upset_default_themes(text=element_text(size=9)),
    n_intersections = 16, set_sizes = FALSE, sort_sets = FALSE,
    name = "Selection Grouping",
    base_annotations=list(
        'Intersection size'= (
            intersection_size(
                mapping=aes(hjust=ifelse(after_stat(y) > 3000, 0.5, 0.0)),
                text=list(
                    vjust=0.5,
                    angle=90,
                    check_overlap=TRUE )
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

# base_annotations=list(
#         'Intersection size (>1500)'=(
#             intersection_size()
#             + coord_cartesian(ylim=c(1500, NA))
#             + ylab('')
#         ),
#         'Intersection size'=(
#             intersection_size()
#             + coord_cartesian(ylim=c(0, 300))
#         )
#     ),

omega_data <- aln_data |>
    filter(!any(is.na(omega)), .by=gene) |>
    mutate(neg_sel = omega > 1) |>
    pivot_wider(id_cols = "gene", names_from = "method", values_from = "neg_sel")

gg2 <- upset(omega_data, methods,
    n_intersections = 20, set_sizes = FALSE, sort_sets = FALSE,
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

# gg <- gg1 + gg2
#       plot_annotation(tag_levels = 'a',
#         theme = theme(plot.margin = margin()))

# gg <- gg & theme(plot.tag.position = c(0,1))

gg <- gg1 + plot_annotation(theme = theme(plot.margin = margin()))

#gg <- gg & theme_minimal(9)

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
