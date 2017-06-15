## global variables
# set parameters for inference
MODE=release
# set parameters for debugging code
# MODE=debug

R = /opt/R/R-3.3.2/bin/R

# main operations
all: install analysis article

R:
	$(R) --no-save

clean:
	@rm -f *.aux *.bbl *.blg *.log *.pdf *.bak *~ *.Rout */*.Rout */*.pdf */*.aux */*.log *.rda */*.rda */*/*.rda data/intermediate/*.rda data/intermediate/*.Rout data/intermediate/*.rds
	@rm data/intermediate/structure -rf
	@rm data/intermediate/bayescan -rf
	@rm data/intermediate/pcadapt -rf
	@rm data/intermediate/ala_cache -rf
	@rm code/rmarkdown/article_files/figure-latex/*.pdf -f
	@rm code/rmarkdown/supporting-information_files/figure-latex/*.pdf -f
	@rm code/rmarkdown/figures_files/figure-latex/*.pdf -f
	@rm code/rmarkdown/figures.tex -f
	@rm code/rmarkdown/figures.md -f
	@rm code/rmarkdown/figures.docx -f
	@rm code/rmarkdown/figures.pdf -f
	@rm code/rmarkdown/supporting_information.tex -f
	@rm code/rmarkdown/supporting_information.md -f
	@rm code/rmarkdown/supporting_information.docx -f
	@rm code/rmarkdown/supporting_information.pdf -f
	@rm code/rmarkdown/article.md -f
	@rm code/rmarkdown/article.tex -f
	@rm code/rmarkdown/article.docx -f
	@rm code/rmarkdown/article.pdf -f
	@rm code/rmarkdown/tables.md -f
	@rm code/rmarkdown/tables.tex -f
	@rm code/rmarkdown/tables.docx -f
	@rm code/rmarkdown/tables.pdf -f
	@rm article/* -f

pull_ms:
	@scp -P 443 uqjhans4@cbcs-comp01.server.science.uq.edu.au:/home/uqjhans4/GitHub/raptr-manuscript/article/* article

push_ms:
	@scp -P 443 code/rmarkdown/* uqjhans4@cbcs-comp01.server.science.uq.edu.au:/home/uqjhans4/GitHub/raptr-manuscript/code/rmarkdown

# commands for generating manuscript
article: article/article.docx article/article.pdf article/figures.pdf article/supporting-information.pdf

article/article.pdf: code/rmarkdown/article.Rmd code/rmarkdown/references.bib code/rmarkdown/reference-style.csl
	$(R) --no-save -e "rmarkdown::render('code/rmarkdown/article.Rmd')"
	rm -f code/rmarkdown/article.md
	rm -f code/rmarkdown/article.utf8.md
	rm -f code/rmarkdown/article.knit.md
	rm -f code/rmarkdown/article.tex
	mv code/rmarkdown/article.pdf article/

article/article.docx: code/rmarkdown/preamble.tex code/rmarkdown/article.Rmd code/rmarkdown/references.bib code/rmarkdown/reference-style.csl
	$(R) --no-save -e "rmarkdown::render('code/rmarkdown/article.Rmd', output_file='article.tex')"
	rm -f code/rmarkdown/article.md
	cd code/rmarkdown && pandoc +RTS -K512m -RTS article.tex -o article.docx --highlight-style tango --latex-engine pdflatex --include-in-header preamble.tex --variable graphics=yes --variable 'geometry:margin=1in' --bibliography references.bib --filter /usr/bin/pandoc-citeproc
	rm -f code/rmarkdown/article.tex
	mv code/rmarkdown/article.docx article/

article/supporting-information.pdf: code/rmarkdown/preamble.tex code/rmarkdown/supporting-information.Rmd code/rmarkdown/references.bib code/rmarkdown/reference-style.csl
	$(R) --no-save -e "rmarkdown::render('code/rmarkdown/supporting-information.Rmd')"
	rm -f code/rmarkdown/supporting-information.md
	rm -f code/rmarkdown/supporting-information.utf8.md
	rm -f code/rmarkdown/supporting-information.knit.md
	rm -f code/rmarkdown/supporting-information.tex
	mv code/rmarkdown/supporting-information.pdf article/

article/figures.pdf: code/rmarkdown/figures.Rmd
	$(R) --no-save -e "rmarkdown::render('code/rmarkdown/figures.Rmd')"
	rm -f code/rmarkdown/figures.md
	rm -f code/rmarkdown/figures.utf8.md
	rm -f code/rmarkdown/figures.knit.md
	rm -f code/rmarkdown/figures.tex
	mv code/rmarkdown/figures.pdf article/

# commands for running analysis
analysis: data/final/results.rda

data/final/results.rda: data/intermediate/06-*.rda code/R/analysis/07-*.R
	$(R) CMD BATCH --no-restore --no-save code/R/analysis/07-*.R
	mv *.Rout data/intermediate/

data/intermediate/06-*.rda: data/intermediate/02-*.rda data/intermediate/03-*.rda data/intermediate/04-*.rda data/intermediate/05-*.rda code/R/analysis/06-*.R
	$(R) CMD BATCH --no-restore --no-save code/R/analysis/06-*.R
	mv *.Rout data/intermediate/

data/intermediate/05-*.rda: data/intermediate/00-*.rda code/R/analysis/05-*.R code/parameters/benchmark.toml
	$(R) CMD BATCH --no-restore --no-save code/R/analysis/05-*.R
	mv *.Rout data/intermediate/

data/intermediate/04-*.rda: data/intermediate/01-*.rda code/R/analysis/04-*.R code/parameters/case-study-2.toml
	$(R) CMD BATCH --no-restore --no-save code/R/analysis/04-*.R
	mv *.Rout data/intermediate/

data/intermediate/03-*.rda: data/intermediate/01-*.rda code/R/analysis/03-*.R code/parameters/case-study-1.toml
	$(R) CMD BATCH --no-restore --no-save code/R/analysis/03-*.R
	mv *.Rout data/intermediate/

data/intermediate/02-*.rda: data/intermediate/01-*.rda code/R/analysis/02*.R code/parameters/simulations.toml
	$(R) CMD BATCH --no-restore --no-save code/R/analysis/02-*.R
	mv *.Rout data/intermediate/

data/intermediate/01-*.rda: data/intermediate/00-*.rda code/R/analysis/01-*.R
	$(R) CMD BATCH --no-restore --no-save code/R/analysis/01-*.R
	mv *.Rout data/intermediate/

data/intermediate/00-*.rda: code/R/analysis/00-*.R code/parameters/general.toml code/R/functions/*.R
	$(R) CMD BATCH --no-restore --no-save '--args MODE=$(MODE)' code/R/analysis/00-*.R
	mv *.Rout data/intermediate/

# command to install package dependencies
install:
	$(R) CMD BATCH --no-restore --no-save '--args --bootstrap-packrat' packrat/init.R
	mv -f *.Rout data/intermediate/

.PHONY: clean install analysis article R
