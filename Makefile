FIGS = fig-fst-base-calling-new.pdf fig-aln.pdf fig-fst-coati.pdf
TABS = $(addprefix figures/, table-comp.tex)
SCRIPTS = $(addprefix supplementary_materials/scripts/, kaks.R number_alignments.R plot_dseq.R)
PLOT_DATA = tri-mg tri-ecm mar-mg mar-ecm

default: all

all: alignpair_letter.pdf response_r1.pdf response_r2.pdf supplementary_materials/supplementary_materials.pdf

.PHONY: all default

alignpair_letter.pdf: alignpair_letter.tex alignpair_letter.bib $(TABS) mbe.bst
	latexmk -recorder -synctex=1 -lualatex $<

alignpair_letter.pdf: $(addprefix figures/, $(FIGS))

# Used for checking grammar with google docs
alignpair_letter.docx: alignpair_letter.tex
	pandoc $< -o $@

figures/fig-%.pdf: figures/fig-%.tex
	latexmk -cd -lualatex $<

figures/fig-%.pdf: figures/fig-%.R
	Rscript --vanilla $<

figures/figure-01.pdf: figures/fig-aln.pdf
	cp $< $@

figures/figure-02.pdf: figures/fig-fst-base-calling-new.pdf
	cp $< $@

figures/figure-03.pdf: figures/fig-fst-coati.pdf
	cp $< $@

figures/figure-04.pdf: figures/fig-k2p-empirical.pdf
	cp $< $@

figures/figure-05.pdf: figures/fig-sel-empirical.pdf
	cp $< $@

figures/figure-06.pdf: figures/fig-dseq-benchmarks.pdf
	cp $< $@

all: figures/figure-01.pdf figures/figure-02.pdf figures/figure-03.pdf
all: figures/figure-04.pdf figures/figure-05.pdf figures/figure-06.pdf

ALIGNERS = clustalo macse mafft prank

supplementary_materials/data/%/plot_distance.csv: supplementary_materials/scripts/distance_pseudo.R
	@echo creating $@
	cd supplementary_materials && Rscript --vanilla scripts/distance_pseudo.R dseq $* $* $(ALIGNERS)

supplementary_materials/supplementary_materials.pdf: supplementary_materials/supplementary_materials.Rmd figures/fig-base-calling-error.pdf
	cd supplementary_materials && Rscript -e "rmarkdown::render('supplementary_materials.Rmd')"

supplementary_materials/supplementary_materials.pdf: $(addprefix supplementary_materials/data/,$(addsuffix /plot_distance.csv, $(PLOT_DATA)))

response_r1.pdf: response_r1.md
	pandoc --pdf-engine=lualatex -o $@ $<

response_r2.pdf: response_r2.md
	pandoc --pdf-engine=lualatex -o $@ $<

clean:
	@rm -f *.{aux,log,fdb_latexmk,fls,bbl,bcf,blg,run.xml,out}
	@rm -f figures/*.{aux,log,fdb_latexmk,fls,bbl,bcf,blg,run.xml,out}


# latexdiff-vc --flatten --git -r aa8402cd50d72 alignpair_letter.tex
