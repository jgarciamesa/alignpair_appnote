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
    #ggplot(dseq, aes(x = coati, y = mafft)) +
        #geom_hex(bins = 50) +
        #scale_fill_viridis_c() +
        #geom_abline(slope = 1, intercept = 0, color = "red") +
        #xlim(-0.01, max(dseq[, c("coati", "mafft")])) +
        #ylim(-0.01, max(dseq[, c("coati", "mafft")])) +
        #coord_fixed(ratio = 1/1)
    
    # Scatter plot
    
    prank = ggplot(dseq, aes(x = COATi, y = PRANK)) +
        geom_point(alpha = 0.1, color = "#33618B") +
        geom_abline(slope = 1, intercept = 0, color  = "black") +
        xlim(0, max(dseq[, c("COATi", "PRANK")])) +
        ylim(0, max(dseq[, c("COATi", "PRANK")])) +
        coord_fixed(ratio = 1/1)
    
    mafft = ggplot(dseq, aes(x = COATi, y = MAFFT)) +
        geom_point(alpha = 0.1, color = "#33618B") +
        geom_abline(slope = 1, intercept = 0, color  = "black") +
        xlim(0, max(dseq[, c("COATi", "MAFFT")])) +
        ylim(0, max(dseq[, c("COATi", "MAFFT")])) +
        coord_fixed(ratio = 1/1)
    
    macse = ggplot(dseq, aes(x = COATi, y = MACSE)) +
        geom_point(alpha = 0.1, color = "#33618B") +
        geom_abline(slope = 1, intercept = 0, color  = "black") +
        xlim(0, max(dseq[, c("COATi", "MACSE")])) +
        ylim(0, max(dseq[, c("COATi", "MACSE")])) +
        coord_fixed(ratio = 1/1)
    
    clustalo = ggplot(dseq, aes(x = COATi, y = ClustalOmega)) +
        geom_point(alpha = 0.1, color = "#33618B") +
        geom_abline(slope = 1, intercept = 0, color  = "black") +
        xlim(0, max(dseq[, c("COATi", "ClustalOmega")])) +
        ylim(0, max(dseq[, c("COATi", "ClustalOmega")])) +
        coord_fixed(ratio = 1/1)
    
    dseq_plots = ggarrange(prank, mafft, clustalo, macse,
                        ncol = 2, nrow = 2)
    
    #dseq_plots = annotate_figure(dseq_plots,
                    #bottom = "Pairwise comparison of distance (dseq) between coati and prank, mafft, clustal, and macse."
                    #fig.lab = "Figure S1", fig.lab.face = "bold", fig.lab.pos = "top.left",
    #)
    
    #ggsave(filename = "results/dseq-tri-mg.pdf", plot = dseq_plots, device = "pdf")
    #ggsave(filename = "results/dseq-tri-mg.png", plot = dseq_plots, device = "png")
    dseq_plots
}
