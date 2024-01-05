
default: all

all: example-graph.pdf example-path.pdf

.PHONY: all default

.DELETE_ON_ERROR:

SHELL=/bin/bash -e -o pipefail

ARC_TYPE=log
RSCRIPT=Rscript --vanilla

input.fst: acceptor.R nuc_syms.txt
	$(RSCRIPT) acceptor.R CTC \
		| fstcompile --arc_type=$(ARC_TYPE) --isymbols=nuc_syms.txt --osymbols=nuc_syms.txt - \
		| fstarcsort --sort_type=olabel > $@

output.fst: acceptor.R nuc_syms.txt
	$(RSCRIPT) acceptor.R CTG \
		| fstcompile --arc_type=$(ARC_TYPE) --isymbols=nuc_syms.txt --osymbols=nuc_syms.txt - \
		| fstarcsort --sort_type=ilabel > $@

indel.fst: indel.R nuc_syms.txt
	$(RSCRIPT) indel.R \
		| fstcompile --arc_type=$(ARC_TYPE) --isymbols=nuc_syms.txt --osymbols=nuc_syms.txt - \
		| fstrmepsilon | fstarcsort --sort_type=ilabel > $@

mutation.fst: mutation.R nuc_syms.txt
	$(RSCRIPT) mutation.R \
		| fstcompile --arc_type=$(ARC_TYPE) --isymbols=nuc_syms.txt --osymbols=nuc_syms.txt - \
		| fstrmepsilon | fstarcsort --sort_type=ilabel > $@

input-o-mutation.fst: input.fst mutation.fst
	fstcompose input.fst mutation.fst | fstarcsort --sort_type=olabel > $@

input-o-mutation-o-indel.fst: input-o-mutation.fst indel.fst
	fstcompose input-o-mutation.fst indel.fst | fstarcsort --sort_type=olabel > $@

input-o-mutation-o-indel-o-output.fst: input-o-mutation-o-indel.fst output.fst
	fstcompose input-o-mutation-o-indel.fst output.fst | fstrmepsilon | fstarcsort --sort_type=olabel > $@

example2.fst : input-o-mutation-o-indel-o-output.fst
	fstrmepsilon $< | fstencode --encode_labels - example.codex example.enc.fst
	fstdisambiguate example.enc.fst > example.opt.fst
	fstencode --decode example.opt.fst example.codex > example.temp.fst
	fstmap --map_type=quantize example.temp.fst | \
		fstencode --encode_labels --encode_weights - example.codex example.enc.fst
	fstdeterminize example.enc.fst | fstminimize > example.opt.fst
	fstencode --decode example.opt.fst example.codex > $@
	rm example.codex example.enc.fst example.opt.fst

example.fst : input-o-mutation-o-indel-o-output.fst
	fstrmepsilon $< | fstencode --encode_labels - example.codex example.enc.fst
	fstdeterminize example.enc.fst | fstminimize > example.opt.fst
	fstencode --decode example.opt.fst example.codex > $@
	rm example.codex example.enc.fst example.opt.fst

example-path.fst : example.fst
	fstmap --map_type=to_std $< | fstshortestpath | fsttopsort > $@

example-graph.fst : example.fst
	fsttopsort $< > $@

example-graph.pdf: example-graph.dot

example-path.pdf: example-path.dot

# reduce an FST to a more efficient form
# %.min.fst: %.enc.fst
# 	fstrmepsilon $< | fstdeterminize | fstminimize > $@

%.dot: %.fst nuc_syms.txt
	fstdraw --width=7 --height=7  --portrait --isymbols=nuc_syms.txt --osymbols=nuc_syms.txt --show_weight_one $< > $@

# print an FST
%.pdf: %.dot
	dot -Tpdf -o$@ $<
