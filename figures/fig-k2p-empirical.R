library(tidyverse)
library(scales)
library(here)
library(patchwork)

PDF_WIDTH <- 7 # 178mm
PDF_HEIGHT <- PDF_WIDTH/2

#showtext_auto()

cbbPalette <- c("#000000", "#E69F00", "#56B4E9", "#009E73",
    "#F0E442", "#0072B2", "#D55E00", "#CC79A7", "#999999")
set.seed(17760)

# load data
aln_data <- read_csv(here("data/raw_fasta_aligned_stats.csv.gz"))

pal <- rev(cbbPalette[c(3,2,4,6,7,8)])

#### PLOT 1: K2P density plots
methods <- c("clustalo", "macse", "mafft", "prank", "coati-tri-mg", "rev-coati-tri-mg")
aln_data2 <- aln_data |> filter(method %in% methods)
aln_data2 <- aln_data2 |> mutate(method = fct_relevel(method, "coati-tri-mg"))

mean_k2p <- aln_data2 |>
    summarize(avg = mean(k2p, na.rm = TRUE), .by = "method") |>
    arrange(desc(avg))

gg1 <- ggplot(aln_data2, aes(x = k2p, color =  fct_rev(method))) + geom_density(linewidth = 1)
gg1 <- gg1 + scale_x_continuous(trans = transform_pseudo_log(0.0005, base=10),
    breaks=c(0, 0.001, 0.01, 0.1, 1))
gg1 <- gg1 + coord_cartesian(ylim=c(NA, 1.51))
gg1 <- gg1 + xlab("K2P Distance")
gg1 <- gg1 + scale_color_manual(values = pal,
    name="Aligner",  labels = c(
     "clustalo" = "ClustalΩ", #ClustalΩ
     "macse" = "MACSE",
     "mafft" = "MAFFT",
     "prank" = "PRANK",
     "coati-tri-mg" = "COATi",
     "rev-coati-tri-mg" = "COATi-rev"
     )
    )

gg1 <- gg1 + geom_vline(aes(xintercept = avg, color = method), data = mean_k2p,
    linewidth = 0.5, linetype = 2, show.legend = FALSE)

gg1 <- gg1 + guides(color = guide_legend(override.aes=list(fill=rev(pal)), reverse = TRUE))
gg1 <- gg1 + theme_minimal(9) + theme(
    legend.position = c(1,1),
    legend.justification = c(1, 1),
    legend.key.size = unit(11, 'pt'),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank()
)

#### PLOT 2: K2P difference density plots

pal <- pal[-6]

k2p_data <- aln_data2 |>
    mutate(k2p_norm = k2p - k2p[method == "coati-tri-mg"], .by = "gene") |>
    filter(method != "coati-tri-mg")

#k2p_data <- k2p_data |> filter(gene %in% seq_id)

gg2 <- ggplot(k2p_data, aes(x = k2p_norm, color = fct_rev(method))) + geom_density(linewidth = 1, bw=0.07)
gg2 <- gg2 + scale_x_continuous(trans = transform_pseudo_log(0.001, base=10),
    breaks=c(-1, -0.1, -0.01, 0, 0.01, 0.1, 1))
gg2 <- gg2 + coord_cartesian(ylim=c(NA, 0.26))
gg2 <- gg2 + xlab("ΔK2P Distance")
gg2 <- gg2 + scale_color_manual(values = pal,
    name="Aligner",  labels = c(
     "clustalo" = "ClustalΩ",
     "macse" = "MACSE",
     "mafft" = "MAFFT",
     "prank" = "PRANK",
     "tri-mg" = "COATi",
     "rev-coati-tri-mg" = "COATi-rev"
     )
    )
gg2 <- gg2 + guides(color =  guide_legend(override.aes=list(fill=rev(pal)), reverse = TRUE))
gg2 <- gg2 + theme_minimal(9) + theme(
    legend.position = c(1,1),
    legend.justification = c(1, 1),
    legend.key.size = unit(11, 'pt'),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank()
)

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

# k2p_data <- aln_data |>
#     pivot_wider(id_cols = "gene", names_from = "method", values_from = "k2p")

# gg <- ggplot(k2p_data, aes(x = mafft, y = `tri-mg`)) + geom_point(alpha = 0.3)
# gg <- gg + scale_x_continuous(trans = transform_pseudo_log(0.0005, base=10))
# gg <- gg + scale_y_continuous(trans = transform_pseudo_log(0.0005, base=10))