## global variables
# set parameters for inference 
# MODE=release 
# set parameters for debugging code
MODE=debug

# set misc parameters
COMMIT_ID=$(shell git ls-remote https://github.com/paleo13/genetic.surrogates.git HEAD | grep -o '^\S*')

# main operations
all: clean analysis manuscript

clean:
	rm -f *.aux *.bbl *.blg *.log *.pdf *.bak *~ *.Rout */*.Rout */*.pdf */*.aux */*.log *.rda */*.rda */*/*.rda data/intermediate/*.rda data/intermediate/*.Rout
	rm data/intermediate/structure -rf
	rm data/intermediate/bayescan -rf
	rm data/intermediate/pcadapt -rf
	rm code/rmarkdown/article_files/figure-latex/*.pdf -f
	rm code/rmarkdown/supporting_information_files/figure-latex/*.pdf -f
	rm code/rmarkdown/figures_files/figure-latex/*.pdf -f
	rm code/rmarkdown/figures.tex -f
	rm code/rmarkdown/figures.md -f
	rm code/rmarkdown/figures.docx -f
	rm code/rmarkdown/figures.pdf -f
	rm code/rmarkdown/supporting_information.tex -f
	rm code/rmarkdown/supporting_information.md -f
	rm code/rmarkdown/supporting_information.docx -f
	rm code/rmarkdown/supporting_information.pdf -f
	rm code/rmarkdown/article.md -f
	rm code/rmarkdown/article.tex -f
	rm code/rmarkdown/article.docx -f
	rm code/rmarkdown/article.pdf -f
	rm code/rmarkdown/tables.md -f
	rm code/rmarkdown/tables.tex -f
	rm code/rmarkdown/tables.docx -f
	rm code/rmarkdown/tables.pdf -f
	rm article/*.csv -f

pull_ms:
	git fetch
	git checkout '$(COMMIT_ID)' code/rmarkdown

# commands for generating manuscript
manuscript: article/article.pdf article/figures.pdf article/supporting_information.pdf article/tables.pdf

article/article.pdf: code/rmarkdown/article.Rmd code/rmarkdown/Endnote_lib.bib code/rmarkdown/preamble-latex.tex code/rmarkdown/reference-style.csl
	R -e "rmarkdown::render('code/rmarkdown/article.Rmd')"
	mv code/rmarkdown/article.pdf article/
	rm article/article.tex -f
	rm article/article.md -f

article/figures.pdf: code/rmarkdown/figures.Rmd code/rmarkdown/preamble-latex.tex code/rmarkdown/preamble-latex2.tex
	R -e "rmarkdown::render('code/rmarkdown/figures.Rmd')"
	mv code/rmarkdown/figures.pdf article/
	rm article/figures.tex -f
	rm article/figures.md -f

article/tables.pdf: code/rmarkdown/tables.Rmd code/rmarkdown/preamble-latex.tex code/rmarkdown/preamble-latex2.tex
	R -e "rmarkdown::render('code/rmarkdown/tables.Rmd')"
	mv code/rmarkdown/tables.pdf article/
	rm code/rmarkdown/tables.tex -f
	rm code/rmarkdown/tables.md -f

article/supporting_information.pdf: code/rmarkdown/supporting_information.Rmd code/rmarkdown/preamble-latex.tex code/rmarkdown/preamble-latex3.tex
	R -e "rmarkdown::render('code/rmarkdown/supporting_information.Rmd')"
	mv code/rmarkdown/supporting_information.pdf article/
	rm code/rmarkdown/supporting_information.tex -f
	rm code/rmarkdown/supporting_information.md -f

# commands for running analysis
analysis: data/final/results.rda

data/final/results.rda: data/intermediate/12-*.rda code/R/analysis/13-*.R
	R CMD BATCH --no-restore --no-save code/R/analysis/13-*.R
	mv *.Rout data/intermediate/

data/intermediate/00-*.rda: code/R/analysis/00-*.R code/parameters/general.toml
	R CMD BATCH --no-restore --no-save '--args MODE=$(MODE)' code/R/analysis/00-*.R
	mv *.Rout data/intermediate/



