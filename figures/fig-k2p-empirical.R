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
aln_data <- read_csv(here("data/aln_data.csv.gz"))

kounts <- aln_data |> count(method, failed=is.na(k2p)) |> filter(failed)

cat("Table of failed sequences\n")
cat("=========================\n")
print(kounts)

# identify files that didn't show variation
k2p_sum <- aln_data |> summarize(
    coati_na = is.na(k2p[method == "tri-mg"]),
    all_same = n_distinct(k2p) == 1L,
    .by = "sequence")

kounts <- k2p_sum |> count(all_same)

cat("Table of trivial alignments\n")
cat("=========================\n")
print(kounts)

# remove sequences that COATi failed on
seq_ids <- k2p_sum |> filter(coati_na == FALSE) |> pull(sequence)
aln_data <- aln_data |> filter(sequence %in% seq_ids)


pal <- cbbPalette[c(2,3,4,6,7)]

#### PLOT 1: K2P density plots

gg1 <- ggplot(aln_data, aes(x = k2p, color=method)) + geom_density(linewidth = 1)
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
     "tri-mg" = "COATi"
     )
    )
gg1 <- gg1 + guides(color = guide_legend(override.aes=list(fill=pal)))
gg1 <- gg1 + theme_minimal(9) + theme(
    legend.position = c(1,1),
    legend.justification = c(1, 1),
    legend.key.size = unit(11, 'pt'),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank()
)

#### PLOT 2: K2P difference density plots

pal <- pal[-5]

seq_id <- k2p_sum |> filter(all_same == FALSE) |> pull(sequence)

k2p_data <- aln_data |>
    mutate(k2p_norm = k2p - k2p[method == "coati-tri-mg"], .by = "gene") |>
    filter(method != "coati-tri-mg")

#k2p_data <- k2p_data |> filter(sequence %in% seq_id)

gg2 <- ggplot(k2p_data, aes(x = k2p_norm, color=method)) + geom_density(linewidth = 1, bw=0.05)
gg2 <- gg2 + scale_x_continuous(trans = transform_pseudo_log(0.0005, base=10),
    breaks=c(-1, -0.1, -0.01, 0, 0.01, 0.1, 1))
gg2 <- gg2 + coord_cartesian(ylim=c(NA, 0.26))
gg2 <- gg2 + xlab("ΔK2P Distance")
gg2 <- gg2 + scale_color_manual(values = pal,
    name="Aligner",  labels = c(
     "clustalo" = "ClustalΩ",
     "macse" = "MACSE",
     "mafft" = "MAFFT",
     "prank" = "PRANK",
     "tri-mg" = "COATi"
     )
    )
gg2 <- gg2 + guides(color = guide_legend(override.aes=list(fill=pal)))
gg2 <- gg2 + theme_minimal(9) + theme(
    legend.position = c(1,1),
    legend.justification = c(1, 1),
    legend.key.size = unit(11, 'pt'),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank()
)



gg <- gg1 + gg2

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

# k2p_data <- aln_data |>
#     pivot_wider(id_cols = "sequence", names_from = "method", values_from = "k2p")

# gg <- ggplot(k2p_data, aes(x = mafft, y = `tri-mg`)) + geom_point(alpha = 0.3)
# gg <- gg + scale_x_continuous(trans = transform_pseudo_log(0.0005, base=10))
# gg <- gg + scale_y_continuous(trans = transform_pseudo_log(0.0005, base=10))