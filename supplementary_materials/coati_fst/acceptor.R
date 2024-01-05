# convert a sequence in a fasta file into an acceptor
# Output format is described at http://www.openfst.org/twiki/bin/view/FST/FstQuickTour#CreatingFsts
 
library(stringr)
library(seqinr)

block_width <- 1

acceptor_main = function(str) {
	a <- str_split_1(str_to_upper(str),"")
	n <- seq_along(a)
	cat(str_c(n, n + 1, a, a, sep="\t"), sep="\n")
	cat(length(a)+1, sep="\n")
}

if(!interactive()) {
	ARGS = commandArgs(trailing=TRUE)
	acceptor_main(str=ARGS[1])
}
