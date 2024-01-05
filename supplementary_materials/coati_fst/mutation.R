# Construct an MG94 FST

library(stringr)
library(seqinr)
library(Matrix)
library(dplyr)
library(tidyr)

# parameters
# Yang (1994) Estimating the pattern of nucleotide substitution
params <- list(
    time = 0.0133,
    pi = c(0.308, 0.185, 0.199, 0.308),
    sigma = c(0.715523, 2.9480112, 0.3246753, 1.1614831, 2.9075202, 0.6430366),
    omega = 0.2
)

eps <- "ε"

# Function for creating a transition in an FST
# Output format is described at http://www.openfst.org/twiki/bin/view/FST/FstQuickTour#CreatingFsts
arc <- function(src, dest = NULL, ilab = eps, olab = eps, weight = 1.0) {
    if(weight == 1.0) {
        weight <- 0.0
    } else {
        weight <- -log(weight)
    }

    if(is.null(dest)) {
        cat(str_c(src, weight, sep = "\t"), sep = "\n")
    } else {
        cat(str_c(src, dest, ilab, olab, weight, sep = "\t"), sep = "\n")
    }
}

universal_genetic_code <- function(remove_stops = FALSE) {
    # genetic code in TCGA order
    aa    <- "FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG"
    base1 <- "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG"
    base2 <- "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG"
    base3 <- "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG"

    aa <- str_split_1(aa, "")
    base1 <- str_split_1(base1, "")
    base2 <- str_split_1(base2, "")
    base3 <- str_split_1(base3, "")

    names(aa) <- str_c(base1, base2, base3)
    
    if(isTRUE(remove_stops)) {
        aa <- aa[aa != "*"]
    }

    # return code in ACGT order
    aa[order(names(aa))]
}

# MG94 model - doi:10.1534/genetics.108.092254
#
# Qij \propto rho[ic,jc] phi[jc] if A
#             omega * rho[ic,jc] phi[jc] if B
#             0 if otherwise
# where
#   A: i and j are synonymous and differ only at codon position c
#   B: i and j are nonsynonymous and differ only at codon position c

# construct a MG94 matrix based on parameters
mg94 <- function(params, aa) {
    codons <- names(aa)
    tab <- expand_grid(x = codons, y = codons)
    tab <- tab |> mutate(syn = aa[x] == aa[y])

    # construct gtr matrix
    rho <- matrix(0, 4, 4)
    rho[lower.tri(rho)] <- params$sigma
    rho <- rho + t(rho)
    q_gtr <- t(rho * params$pi)
    # normalize rates
    q_gtr <- q_gtr/sum(q_gtr * params$pi)

    # identify which position differs or return NA
    find_pos <- function(x, y) {
        b1 <- str_sub(x, 1, 1) != str_sub(y, 1, 1)
        b2 <- str_sub(x, 2, 2) != str_sub(y, 2, 2)
        b3 <- str_sub(x, 3, 3) != str_sub(y, 3, 3)

        if_else(b1 + b2 + b3 == 1, b1 * 1L + b2 * 2L + b3 * 3L,
            NA_integer_)
    }
    NUC <- c("A" = 1, "C" = 2, "G" = 3, "T" = 4)
    tab <- tab |> mutate(pos = find_pos(x, y))
    tab <- tab |> mutate(x_nuc = NUC[str_sub(x, pos, pos)],
        y_nuc = NUC[str_sub(y, pos, pos)])

    array_ind <- cbind(tab$x_nuc, tab$y_nuc)

    # mg94 Q matrix
    tab <- tab |> mutate(Q = if_else(syn, 1, params$omega)*q_gtr[array_ind])
    tab <- tab |> mutate(Q = coalesce(Q, 0))
    Q <- matrix(tab$Q, length(codons), byrow = TRUE)
    diag(Q) <- -rowSums(Q)

    mat <- expm::expm(Q*params$time)
    rownames(mat) <- codons
    colnames(mat) <- codons
    mat
}

gc61 <- universal_genetic_code(TRUE)
base1 <- str_sub(names(gc61), 1, 1)
base2 <- str_sub(names(gc61), 2, 2)
base3 <- str_sub(names(gc61), 3, 3)

P <- mg94(params, gc61)

# build the FST
r <- 1
for(i in seq_along(gc61)) {
    for(j in seq_along(gc61)) {
        w <- P[i, j]^(1/3)
        arc(0,     r,     base1[i], base1[j], w)
        arc(r,     r + 1, base2[i], base2[j], w)
        arc(r + 1, 0,     base3[i], base3[j], w)
        r <- r + 2
    }
}

arc(0)
