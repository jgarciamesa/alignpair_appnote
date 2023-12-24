FIGS = fig-fst-base-calling-new.pdf fig-aln.pdf fig-fst-coati.pdf
TABS := $(addprefix figures/, table-comp.tex)
SCRIPTS := $(addprefix supplementary_materials/scripts/, kaks.R number_alignments.R plot_dseq.R)
PLOT_DATA := $(addprefix supplementary_data/,$(addsuffix /plot_distance.csv, tri-mg tri-ecm mar-mg mar-ecm))

default: all

all: alignpair_letter.pdf

.PHONY: all default

alignpair_letter.pdf: alignpair_letter.tex alignpair_letter.bib $(TABS) mbe.bst
	latexmk -recorder -synctex=1 -lualatex $<

alignpair_letter.pdf: $(addprefix figures/, $(FIGS))

figures/fig-%.pdf: figures/fig-%.tex
	latexmk -cd -lualatex $<

ALIGNERS := clustalo macse mafft prank

supplementary_data/%/plot_distance.csv: supplementary_materials/scripts/distance_pseudo.R
	@echo creating $@
	@Rscript --vanilla $^ dseq $* $* $(ALIGNERS)

supplementary_materials.pdf: supplementary_materials.Rmd figures/fig-base-calling-error.pdf $(PLOT_DATA)
	@Rscript -e "rmarkdown::render('supplementary_materials.Rmd')"
	@mv $@ supplementary_materials/

clean:
	@rm -f *.{aux,log,fdb_latexmk,fls,bbl,bcf,blg,run.xml,out}
	@rm -f figures/*.{aux,log,fdb_latexmk,fls,bbl,bcf,blg,run.xml,out}
