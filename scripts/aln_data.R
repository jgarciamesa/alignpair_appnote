library(ape)
library(stringr)
library(seqinr)

# sequence,method,CIGAR,K2P,omega

filtered = "tri-mg/data/filtered.csv"
methods = c("clustalo", "macse", "mafft", "prank", "tri-mg")

files = read.csv(file = filtered, header = FALSE)[,1]
N = length(files) * length(methods)

results = data.frame(sequence = character(N),
                     method = character(N),
                     cigar = character(N),
                     k2p = numeric(N),
                     omega = numeric(N))

index = 1
for(i in seq_along(files)) {
    gene = files[i]
    for(j in seq_along(methods)) {
        method = methods[j]
        path = paste0("tri-mg/aln/", method, "/", gene)
        # if the file doesn't exist or the size is 0
        if(!file.exists(path) | file.info(path)$size == 0) {
            results[index,] = c(gene, method, NA, NA, NA)
            index = index + 1
            next
        }
        # cigar
        cigar = create_cigar(path)
        # k2p
        distance = dist.dna(read.dna(path, format = "fasta"), model = "K80")[1]
        # omega
        omega = calculate_omega(path)
        # save data
        results[index,] = c(gene, method, cigar, distance, omega)
        index = index + 1
    }
}

write.csv(x = results, file = "aln_data.csv", quote = FALSE, row.names = FALSE)

############################## Helper functions ################################
## omega
calculate_omega = function(fasta) { #dN/dS
    if(!file.exists(fasta)) { return(NA) }
    a = read.alignment(fasta, format = "fasta")
    if(class(a) != "alignment") {return(NA)}
    k = kaks(a)
    if(length(k) == 1) {return(NA)}
    ka = k$ka[1]
    ks = k$ks[1]
    if(ka < 0 || ks < 0) {
        return(0)
    } else if(ka == 0 && ks == 0) {
        return(0)
    } else if(ks == 0) {
        return(10)
    } else {
        return(ka/ks)
    }
}

## CIGAR
create_cigar = function(fasta) {
  if(file.exists(fasta)) {
    seqs = read.fasta(fasta, set.attributes = TRUE, forceDNAtolower = FALSE)
  } else {
      return(NA)
  }
  s1 = getSequence(seqs)[[1]]
  s2 = getSequence(seqs)[[2]]
  
  cigar = "" 	# cigar string
  current = ""
  nxt = ""
  count = 0
  
  stopifnot(length(s1) == length(s2))
  
  for(i in 1:length(s1)) {
    if(s1[i] == '-'){
      if(current == "I") {
        count = count + 1
        next
      } else {
        nxt = "I"
      }
    } else if(s2[i] == '-') {
      if(current == "D") {
        count = count + 1
        next
      } else {
        nxt = "D"
      }
    } else if((s1[i] != '-') & (s2[i] != '-')) {
      if(current == "M") {
        count = count + 1
        next
      } else {
        nxt = "M"
      }
    }
    
    if(count > 0) {
      cigar = paste(cigar,paste(count,current, sep = ""), sep = "")
    }
    current = nxt
    count = 1
    
  }
  
  cigar = paste(cigar,paste(count,current,sep=""),sep="")
  #paste0(basename(fasta), ",", cigar, ",", basename(dirname(fasta)))
}
