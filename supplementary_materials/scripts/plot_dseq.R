library(ggplot2)
library(ggpubr)

# x-y plot of dseq
plot_dseq_main = function(results_file, coati_model, save = FALSE) {
    # read results
    results = read.csv(results_file)
    
    # extract dseq values for each aligner
    dseq = data.frame(COATi = results$dseq[which(results$aligner == coati_model)],
                      ClustalOmega = results$dseq[which(results$aligner == "clustalo")],
                      MACSE = results$dseq[which(results$aligner == "macse")],
                      MAFFT = results$dseq[which(results$aligner == "mafft")],
                      PRANK = results$dseq[which(results$aligner == "prank")])
    
    # Hex plot

    prank = ggplot(dseq, aes(x = log10(COATi), y = log10(PRANK))) +
        geom_hex() +
        scale_fill_viridis_c() +
        geom_abline(slope = 1, intercept = 0, color  = "black") +
        xlim(-4.5, 0) +
        ylim(-4.5, 0) +
        coord_fixed(ratio = 1/1) +
        theme_minimal()
    
    mafft = ggplot(dseq, aes(x = log10(COATi), y = log10(MAFFT))) +
        geom_hex() +
        scale_fill_viridis_c() +
        geom_abline(slope = 1, intercept = 0, color  = "black") +
        xlim(-4.5, 0) +
        ylim(-4.5, 0) +
        coord_fixed(ratio = 1/1) +
        theme_minimal()
    
    macse = ggplot(dseq, aes(x = log10(COATi), y = log10(MACSE))) +
        geom_hex() +
        scale_fill_viridis_c() +
        geom_abline(slope = 1, intercept = 0, color  = "black") +
        xlim(-4.5, 0) +
        ylim(-4.5, 0) +
        coord_fixed(ratio = 1/1) +
        theme_minimal()
 
    clustalo = ggplot(dseq, aes(x = log10(COATi), y = log10(ClustalOmega))) +
        geom_hex() +
        scale_fill_viridis_c() +
        geom_abline(slope = 1, intercept = 0, color  = "black") +
        xlim(-4.5, 0) +
        ylim(-4.5, 0) +
        coord_fixed(ratio = 1/1) +
        theme_minimal()

    # dseq_plots = ggarrange(prank, mafft, clustalo, macse,
    #                     ncol = 2, nrow = 2, common.legend = TRUE, legend = "right")

    dseq_plots1 = ggarrange(mafft, macse, ncol = 2, common.legend = TRUE, legend = "right")
    dseq_plots2 = ggarrange(prank, clustalo, ncol = 2, common.legend = TRUE, legend = "right")
    
    if(save) {
        ggsave(filename = paste0("dseq_plots_mafft_macse_", coati_model, ".png"),
               plot = dseq_plots1, device = "png", path = "figures",
               width = 11, height = 5, dpi = 300)
        ggsave(filename = paste0("dseq_plots_prank_clustalo_", coati_model, ".png"),
               plot = dseq_plots2, device = "png", path = "figures",
               width = 11, height = 5, dpi = 300)
    } else {
        dseq_plots
    }
}
