.DEFAULT_GOAL := alignpair_letter.pdf

TEX_FILES := $(addsuffix .tex, alignpair_letter header abstract introduction materials_methods results_discussion)
FIGS := $(addprefix figures/, fig-evolution-fst.pdf fig-aln.pdf)

alignpair_letter.pdf: $(TEX_FILES) alignpair_letter.bib $(FIGS) mbe.bst
	@latexmk -pdf $<
	@make clean

figures/fig-%.pdf: figures/fig-%.tex
	@lualatex $<
	@mv $(@F) figures/

suppl.pdf: suppl.tex figures/table-comp.tex
	@latexmk -pdf $<
	@make clean

clean:
	@rm -f *.{aux,log,fdb_latexmk,fls,bbl,bcf,blg,run.xml,out}
	@rm -f figures/*.{aux,log,fdb_latexmk,fls,bbl,bcf,blg,run.xml,out}
