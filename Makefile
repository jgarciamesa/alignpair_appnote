.DEFAULT_GOAL := pairwise_appnote.pdf

TEX_FILES := $(addsuffix .tex, pairwise_appnote description header introduction results methods)
FIGS := $(addprefix figures/, fig-evolution-fst.pdf)

.PHONY: default
default: outline.pdf

outline.pdf: outline.tex
	@latexmk -pdf $<

pairwise_appnote.pdf: $(TEX_FILES) pairwise_appnote.bib $(FIGS)
	@latexmk -pdf $<
	@make clean

figures/fig-evolution-fst.pdf: figures/fig-evolution-fst.tex
	@lualatex $<
	@mv $(@F) figures/

suppl.pdf: suppl.tex
	@latexmk -pdf $<
	@make clean

clean:
	@rm -f *.{aux,log,fdb_latexmk,fls,bbl,bcf,blg,run.xml,out}
	@rm -f figures/*.{aux,log,fdb_latexmk,fls,bbl,bcf,blg,run.xml,out}
