.DEFAULT_GOAL := pairwise_appnote.pdf

TEX_FILES := $(addsuffix .tex, pairwise_appnote description header introduction results)

outline.pdf: outline.tex
	@latexmk -pdf $<

pairwise_appnote.pdf: $(TEX_FILES) pairwise_appnote.bib
	@latexmk -pdf $<
	@make clean

figures/fig-aln.pdf: figures/fig-aln.tex
	@lualatex $<
	@mv fig-aln.pdf figures/

clean:
	@rm -f *.{aux,log,fdb_latexmk,fls,bbl,bcf,blg,run.xml,out}
	@rm -f figures/*.{aux,log,fdb_latexmk,fls,bbl,bcf,blg,run.xml,out}
