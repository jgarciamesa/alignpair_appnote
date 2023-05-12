.DEFAULT_GOAL := alignpair_letter.pdf

TEX_FILES := $(addsuffix .tex, alignpair_letter header abstract introduction materials_methods results_discussion)
FIGS := $(addprefix figures/, fig-evolution-fst.pdf fig-aln.pdf)
SCRIPTS := $(addprefix supplementary_materials/scripts/, kaks.R number_alignments.R plot_dseq.R)

alignpair_letter.pdf: $(TEX_FILES) alignpair_letter.bib $(FIGS) mbe.bst
	@latexmk -pdf $<
	@make clean

figures/fig-%.pdf: figures/fig-%.tex
	@lualatex $<
	@mv $(@F) figures/

ALIGNERS := clustalo macse mafft prank

supplementary_data/%/plot_distance.csv: supplementary_materials/scripts/distance_pseudo.R
	@Rscript --vanilla $^ dseq $* $* $(ALIGNERS)

supplementary_materials.pdf: supplementary_materials.Rmd figures/fig-base-calling-error.pdf
	@Rscript -e "rmarkdown::render('supplementary_materials.Rmd')"
	@mv $@ supplementary_materials/

clean:
	@rm -f *.{aux,log,fdb_latexmk,fls,bbl,bcf,blg,run.xml,out}
	@rm -f figures/*.{aux,log,fdb_latexmk,fls,bbl,bcf,blg,run.xml,out}
