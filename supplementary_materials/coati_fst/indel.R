# construct an indel FST

library(stringr)
library(Matrix)

# parameters
deletion <- 0.001
insertion <- 0.001
deletion_ext <- 1-1/6
insertion_ext <- 1-1/6

nucs <- c("A", "C", "G", "T")
nuc_freqs <- c(0.308,0.185,0.199,0.308)

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

# build the fst
# 0 = M
# 1 = H
# 2 = I
# 3 = W
# 4 = C
# 5 = D
# 6 = S

# insertion
arc(0, 1, weight = insertion)
arc(0, 3, weight = 1.0 - insertion)

for(i in 1:4) {
    arc(1, 2, eps, nucs[i], weight = nuc_freqs[i])
}

arc(2, 1, weight = insertion_ext)
arc(2, 3, weight = 1.0 - insertion_ext)

# deletion
arc(3, 4, weight = deletion)
arc(3, 6, weight = 1.0 - deletion)

for(i in 1:4) {
    arc(4, 5, nucs[i], eps)
}

arc(5, 4, weight = deletion_ext)
arc(5, 6, weight = 1.0 - deletion_ext)

# matches
for(i in 1:4) {
    arc(6, 0, nucs[i], nucs[i])
}

# end
arc(6)
