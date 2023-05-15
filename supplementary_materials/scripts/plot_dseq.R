library(ggplot2)
library(ggpubr)

# x-y plot of dseq
plot_dseq_main = function(results_file, coati_model) {
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
        coord_fixed(ratio = 1/1)
    
    mafft = ggplot(dseq, aes(x = log10(COATi), y = log10(MAFFT))) +
        geom_hex() +
        scale_fill_viridis_c() +
        geom_abline(slope = 1, intercept = 0, color  = "black") +
        xlim(-4.5, 0) +
        ylim(-4.5, 0) +
        coord_fixed(ratio = 1/1)
    
    macse = ggplot(dseq, aes(x = log10(COATi), y = log10(MACSE))) +
        geom_hex() +
        scale_fill_viridis_c() +
        geom_abline(slope = 1, intercept = 0, color  = "black") +
        xlim(-4.5, 0) +
        ylim(-4.5, 0) +
        coord_fixed(ratio = 1/1)
    
    clustalo = ggplot(dseq, aes(x = log10(COATi), y = log10(ClustalOmega))) +
        geom_hex() +
        scale_fill_viridis_c() +
        geom_abline(slope = 1, intercept = 0, color  = "black") +
        xlim(-4.5, 0) +
        ylim(-4.5, 0) +
        coord_fixed(ratio = 1/1)
    
    dseq_plots = ggarrange(prank, mafft, clustalo, macse,
                        ncol = 2, nrow = 2, common.legend = TRUE, legend = "right")
    
    dseq_plots
}
