## global variables
# set parameters for inference 
# MODE=release 
# set parameters for debugging code
MODE=debug

# set misc parameters
COMMIT_ID=$(shell git ls-remote https://github.com/paleo13/raptr-manuscript.git HEAD | grep -o '^\S*')

# main operations
all: clean analysis manuscript

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
	git fetch
	git checkout '$(COMMIT_ID)' code/rmarkdown

# commands for generating manuscript
manuscript: article figures si

article: article/article.pdf

figures: article/figures.pdf

si: article/supporting-information.pdf

article/article.pdf: code/rmarkdown/article.Rmd code/rmarkdown/references.bib code/rmarkdown/preamble.tex code/rmarkdown/reference-style.csl
	R -e "rmarkdown::render('code/rmarkdown/article.Rmd', clean=FALSE)"
	cd code/rmarkdown && \
	/usr/bin/pandoc +RTS -K512m -RTS article.utf8.md --to docx --from markdown+autolink_bare_uris+ascii_identifiers+tex_math_single_backslash --output /home/jeff/GitHub/raptr-manuscript/code/rmarkdown/article.docx --template /home/jeff/R/x86_64-pc-linux-gnu-library/3.3/rmarkdown/rmd/latex/default.tex --highlight-style tango --latex-engine pdflatex --include-in-header preamble.tex --variable graphics=yes --variable 'geometry:margin=1in' --bibliography references.bib --filter /usr/bin/pandoc-citeproc && \
	rm article.knit.md && \
	rm article.utf8.md && \
	cd ../..
	mv code/rmarkdown/article.pdf article/
	mv code/rmarkdown/article.docx article/
	mv code/rmarkdown/article.tex article/

article/figures.pdf: code/rmarkdown/figures.Rmd code/rmarkdown/preamble.tex code/rmarkdown/figures-preamble.tex
	R -e "rmarkdown::render('code/rmarkdown/figures.Rmd')"
	mv code/rmarkdown/figures.pdf article/
	mv code/rmarkdown/figures.tex article/
	rm article/figures.md -f

article/supporting-information.pdf: code/rmarkdown/supporting-information.Rmd code/rmarkdown/preamble.tex code/rmarkdown/si-preamble.tex
	R -e "rmarkdown::render('code/rmarkdown/supporting-information.Rmd')"
	mv code/rmarkdown/supporting-information.pdf article/
	mv code/rmarkdown/supporting-information.tex article/
	rm code/rmarkdown/supporting-information.md -f

# commands for running analysis
analysis: data/final/results.rda

data/final/results.rda: data/intermediate/05-*.rda code/R/analysis/06-*.R
	R CMD BATCH --no-restore --no-save code/R/analysis/06-*.R
	mv *.Rout data/intermediate/

data/intermediate/05-*.rda: data/intermediate/02-*.rda data/intermediate/03-*.rda data/intermediate/04-*.rda code/R/analysis/05-*.R
	R CMD BATCH --no-restore --no-save code/R/analysis/05-*.R
	mv *.Rout data/intermediate/

data/intermediate/04-*.rda: data/intermediate/01-*.rda code/R/analysis/04-*.R code/parameters/case-study-2.toml
	R CMD BATCH --no-restore --no-save code/R/analysis/04-*.R
	mv *.Rout data/intermediate/

data/intermediate/03-*.rda: data/intermediate/01-*.rda code/R/analysis/03-*.R code/parameters/case-study-1.toml
	R CMD BATCH --no-restore --no-save code/R/analysis/03-*.R
	mv *.Rout data/intermediate/

data/intermediate/02-*.rda: data/intermediate/01-*.rda code/R/analysis/02*.R code/parameters/simulations.toml
	R CMD BATCH --no-restore --no-save code/R/analysis/02-*.R
	mv *.Rout data/intermediate/

data/intermediate/01-*.rda: data/intermediate/00-*.rda code/R/analysis/01-*.R
	R CMD BATCH --no-restore --no-save code/R/analysis/01-*.R
	mv *.Rout data/intermediate/

data/intermediate/00-*.rda: code/R/analysis/00-*.R code/parameters/general.toml code/R/functions/*.R
	R CMD BATCH --no-restore --no-save '--args MODE=$(MODE)' code/R/analysis/00-*.R
	mv *.Rout data/intermediate/


