library(ape)
library(tidyverse)
library(patchwork)

models <- c("clustalo", "macse", "mafft", "prank", "tri-mg")
ref_dir <- "supplementary_data/tri-mg/data/ref_alignments/"
# models <- c("clustalo", "macse", "mafft", "prank", "mar-mg")
# ref_dir <- "supplementary_data/mar-mg/data/ref_alignments/"
alns <- list.files(ref_dir)

distances <- matrix(data = NA, ncol = length(models)+1, nrow = length(alns))
dir <- "supplementary_data/tri-mg/aln/ref/"
# dir <- "supplementary_data/mar-mg/aln/ref/"

for(i in seq_along(models)) {
    for(j in seq_along(alns)) {
        aln <- paste0(dir, models[i], "/", alns[j])
        if(!file.exists(aln)) {
            next
        } else if(file.size(aln) == 0L) {
            next
        } else {
            distances[j, i] <- dist.dna(read.dna(aln, format = "fasta"), model = "K80")[1]
        }
    }
}

for(i in seq_along(alns)) {
    distances[i, length(models)+1] <- dist.dna(read.dna(paste0(ref_dir, alns[i]), format = "fasta"), model = "K80")[1]
}

distances <- as.data.frame(distances)
colnames(distances) <- c("Clustalo", "MACSE", "MAFFT", "PRANK", "COATi", "Reference")

plot_k2p <- function(distances, m) {
    ggplot(distances, aes(x = get(m), y = Reference)) +
        geom_point(alpha = 0.3) +
        geom_abline(slope = 1, intercept = 0, color  = "red") +
        xlim(0, 0.4) +
        ylim(0, 0.4) +
        coord_fixed(ratio = 1/1) +
        xlab(m) +
        theme_minimal()
}

gg1 = plot_k2p(distances, colnames(distances)[1])
gg2 = plot_k2p(distances, colnames(distances)[2])
gg3 = plot_k2p(distances, colnames(distances)[3])
gg4 = plot_k2p(distances, colnames(distances)[4])
gg5 = plot_k2p(distances, colnames(distances)[5])

for(m in colnames(distances)[-6]) {
    gg <- ggplot(distances, aes(x = get(m), y = Reference)) +
        geom_point(alpha = 0.3) +
        geom_abline(slope = 1, intercept = 0, color  = "red") +
        xlim(0, 0.4) +
        ylim(0, 0.4) +
        coord_fixed(ratio = 1/1) +
        xlab(m) +
        theme_minimal()
    
    plots <- c(plots, gg)
    
    # ggsave(filename = paste0(m, "_ref_distance.pdf"),
    #        plot = gg, device = "pdf", path = "figures/",
    #        width = 5, height = 5, dpi = 300)
}

ggsave(filename = "k2p_distances.pdf",
       plot = (gg5) / (gg4 | gg2) / (gg3 | gg1) + plot_layout(heights = c(4,4,4)),
       device = "pdf", path = "figures/",
       width = 8, height = 12, dpi = 300)


## Percentage of overestimated distances 
for(model in colnames(distances)[-6]) {
    over <- sum(distances[[model]] > distances$Reference, na.rm = TRUE)/length(!is.na(distances[[model]]))
    print(paste0("Model ", model, " overestimated ", round(over*100, digits = 1), "% of branch lengths; ",
                 "mean ", round(mean(distances[[model]], na.rm = TRUE), digits = 4),
                 " +/- ", round(sd(distances[[model]], na.rm = TRUE), digits = 4)))
}
print(paste0("Reference alignments mean distance: ", round(mean(distances$Reference, na.rm = TRUE), digits = 4),
             " +/- ", round(sd(distances$Reference, na.rm = TRUE), digits = 4)))

# ## Percentage of underestimated distances 
# for(model in colnames(distances)[-6]) {
#     over <- sum(distances[[model]] < distances$Reference, na.rm = TRUE)/length(!is.na(distances[[model]]))
#     print(paste0("Model ", model, " underestimated ", over, "% of branch lengths; "))
# }

rmse = function(data, true) {
    sqrt(mean((data - true)^2, na.rm = TRUE))
}

for(model in colnames(distances)[-6]) {
    print(paste0("Model ", model, " rmse: ",
                 round(rmse(distances[[model]], distances$Reference), digits = 4)))
}

################################################################################
# calculate FDR and FNR for positive and negative selection for each aligner
source("supplementary_materials/scripts/kaks.R")

# results = read.csv("supplementary_data/tri-mg/results/results_summary.csv")
results = read.csv("supplementary_data/mar-mg/results/results_summary.csv")
selection = data.frame("FDR.pos" = double(),
                       "FNR.pos" = double(),
                       "FDR.neg" = double(),
                       "FNR.neg" = double())

for(model in models) {
    model_rows = results |> filter(aligner == model, !is.na(aln_omega))
    fdr_ps <- fdr_pos(model_rows$ref_omega, model_rows$aln_omega)
    fnr_ps <- fnr_pos(model_rows$ref_omega, model_rows$aln_omega)
    fdr_ng <- fdr_neg(model_rows$ref_omega, model_rows$aln_omega)
    fnr_ng <- fnr_neg(model_rows$ref_omega, model_rows$aln_omega)
    
    selection[model,] <- c(fdr_ps, fnr_ps, fdr_ng, fnr_ng)
}

round(selection, digits = 3)

####################################

diff_distances <- distances |>
    mutate(COATi = abs(COATi - Reference),
           MAFFT = abs(MAFFT - Reference),
           PRANK = abs(PRANK - Reference),
           MACSE = abs(MACSE - Reference),
           Clustalo = abs(Clustalo - Reference))

ggplot(diff_distances, aes(x = COATi, y = MAFFT)) +
    geom_hex(bins = 50) +
    scale_fill_viridis_c()
    # geom_abline(slope = 1, intercept = 0, color  = "black") +
    # xlim(-1.7, 3.2) +
    # ylim(-1.7, 3.2) +
    # coord_fixed(ratio = 1/1)

ggplot(diff_distances, aes(x = log10(COATi), y = log10(PRANK))) +
    geom_hex(bins = 30) +
    scale_fill_viridis_c() +
    # geom_abline(slope = 1, intercept = 0, color  = "black") +
    # xlim(-1.7, 3.2) +
    # ylim(-1.7, 3.2) +
    coord_fixed(ratio = 1/1)

ggplot(diff_distances, aes(x = log10(COATi), y = log10(MACSE))) +
    geom_hex(bins = 30) +
    scale_fill_viridis_c() +
    # geom_abline(slope = 1, intercept = 0, color  = "black") +
    # xlim(-1.7, 3.2) +
    # ylim(-1.7, 3.2) +
    coord_fixed(ratio = 1/1)

ggplot(diff_distances, aes(x = log10(COATi), y = log10(Clustalo))) +
    geom_hex(bins = 30) +
    scale_fill_viridis_c() +
    # geom_abline(slope = 1, intercept = 0, color  = "black") +
    # xlim(-1.7, 3.2) +
    # ylim(-1.7, 3.2) +
    coord_fixed(ratio = 1/1)

##########################################################3
library(ggplot2)
library(hrbrthemes)
library(viridis)
# Plot
# create a dataset
diff_distances2 <- distances |>
    mutate(COATi = COATi - Reference,
           MAFFT = MAFFT - Reference,
           PRANK = PRANK - Reference,
           MACSE = MACSE - Reference,
           Clustalo = Clustalo - Reference)

df <- data.frame(
    values <- c(diff_distances2$COATi[!is.na(diff_distances2$COATi)],
            diff_distances2$MAFFT[!is.na(diff_distances2$MAFFT)],
            diff_distances2$PRANK[!is.na(diff_distances2$PRANK)],
            diff_distances2$MACSE[!is.na(diff_distances2$MACSE)],
            diff_distances2$Clustalo[!is.na(diff_distances2$Clustalo)]),
            # diff_distances$Reference[!is.na(diff_distances$Reference)]),
    aligner <- c(rep("COATi", sum(!is.na(diff_distances2$COATi))),
          rep("MAFFT", sum(!is.na(diff_distances2$MAFFT))),
          rep("PRANK", sum(!is.na(diff_distances2$PRANK))),
          rep("MACSE", sum(!is.na(diff_distances2$MACSE))),
          rep("Clustalo", sum(!is.na(diff_distances2$Clustalo))))
          # rep("Reference", sum(!is.na(diff_distances$Reference))))
)

k2p_plot <- df |>
    ggplot(aes(x = aligner, y = values, color = aligner)) +
    # geom_boxplot() +
    scale_fill_discrete() +
    geom_jitter(size = 1, alpha = 0.7, width = 0.3) +
    # ylim(-1, 50) +
    labs(x = "Aligner", y = "Relative Error Rate with Pseudocounts", fill = "Aligner") +
    theme_ipsum(base_size = 18, axis_title_size = 14, axis_col = "black")

ggsave(plot = k2p_plot, filename = "figures/k2p_error.png", device = "png", height = 9, width = 16, dpi = 300)
