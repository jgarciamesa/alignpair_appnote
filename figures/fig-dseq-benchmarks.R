library(tidyverse)
library(here)
library(ggrepel)

set.seed(17768)

PDF_WIDTH <- 3.38 # 7=178mm 3.38=86mm
PDF_HEIGHT <- 0.85*PDF_WIDTH

tab <- read_csv(here("tables", "benchmarks-dseq.csv"))
methods <- unique(c(tab$method1,tab$method2))

my_methods <- c("benchmark", "clustalo", "macse", "mafft", "prank",
    "coati-tri-mg")

tab2 <- tab |> filter(method1 %in% my_methods & method2 %in% my_methods)
methods2 <- unique(c(tab2$method1,tab2$method2))

# Create a PCoA
m <- matrix(0, length(methods2), length(methods2))
m[lower.tri(m)] <- tab2$dseq
colnames(m) <- methods2
rownames(m) <- methods2
d <- as.dist(m)
v <- cmdscale(d, 2)
colnames(v) <- c("x", "y")

pcoa_tab <- as_tibble(v, rownames = "method")

method_recode <- c(
        "Benchmark" = "benchmark",
        "COATi" = "coati-tri-mg",
        "ClustalΩ" = "clustalo",
        "MACSE" = "macse",
        "MAFFT" = "mafft",
        "PRANK" = "prank",
        "COATi-rev" = "rev-coati-tri-mg"
)

pcoa_tab <- pcoa_tab |> mutate(method = fct_recode(method, !!!method_recode))

# Okabe and Ito
#cbbPalette <- c("#000000", "#E69F00", "#56B4E9", "#009E73",
#    "#F0E442", "#0072B2", "#D55E00", "#CC79A7", "#999999")

# Paul Tol's Vibrant Set
# https://personal.sron.nl/~pault/#sec:qualitative
cbbPalette <- c(
    "COATi" = "#0077BB",
    "COATi-rev" = "#33BBEE",
    "MACSE" = "#009988",
    "MAFFT" = "#EE7733",
    "PRANK" = "#CC3311",
    "ClustalΩ" = "#EE3377",
    "Benchmark" = "#000000",
    "missing" = "#BBBBBB")

pal <- cbbPalette

gg1 <- ggplot(pcoa_tab , aes(x = x, y = y, label = method, color =  method)) +
    geom_point(show.legend = FALSE) +
    geom_text_repel(show.legend = FALSE, seed = 1)

gg1 <- gg1 + xlab("Coordinate 1") + ylab("Coordinate 2")

gg1 <- gg1 + scale_color_manual(values = pal)

gg1 <- gg1 + coord_fixed()

gg1 <- gg1 + theme_minimal(9)

gg <- gg1

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