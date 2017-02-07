## global variables
# set parameters for inference 
MODE=release 
# set parameters for debugging code
# MODE=debug

# main operations
all: analysis article

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
cover-letter: article/cover-letter.pdf

article: article/article.pdf article/supporting-information.pdf

rev-comments: article/reviewer-comments.pdf

article/cover-letter.pdf: code/rmarkdown/cover-letter.tex
	cd code/rmarkdown;\
	pdflatex cover-letter.tex
	mv code/rmarkdown/cover-letter.pdf article/
	rm -f code/rmarkdown/cover-letter.aux
	rm -f  code/rmarkdown/cover-letter.log
	rm -f  code/rmarkdown/cover-letter.out

article/article.docx: code/rmarkdown/preamble.tex code/rmarkdown/text.tex code/rmarkdown/figures.tex code/rmarkdown/article.Rmd
	-R --no-save -e "checkpoint::checkpoint('2016-11-26', R.version='3.3.2', scanForPackages=FALSE);rmarkdown::render('code/rmarkdown/article.Rmd')"
	rm -f code/rmarkdown/article.aux
	rm -f code/rmarkdown/article.log
	rm -f code/rmarkdown/article.sta
	cd code/rmarkdown && latexpand article.tex > docx.tex
	cp -R code/rmarkdown/figures_files code/rmarkdown/figures_files_docx
	R --no-save -e "sapply(dir('code/rmarkdown/figures_files_docx/figure-latex', full.names=TRUE), function(x) {system(paste('convert -density 300 -quality 85', x, gsub('.pdf', '.png', x, fixed=TRUE)))})"
	R --no-save -e "sapply(dir('code/rmarkdown/supporting-information_files_docx/figure-latex', full.names=TRUE), function(x) {system(paste('convert -density 300 -quality 85', x, gsub('.pdf', '.png', x, fixed=TRUE)))})"
	R --no-save -e "x <- readLines('code/rmarkdown/docx.tex'); pos <- grep('\\\\includegraphics', x, fixed=TRUE); x[pos] <- gsub('.pdf}', '.png}', x[pos], fixed=TRUE); writeLines(x, 'code/rmarkdown/docx.tex')"
	R --no-save -e "x <- readLines('code/rmarkdown/docx.tex'); pos <- grep('figures_files', x, fixed=TRUE); x[pos] <- gsub('figures_files', 'figures_files_docx', x[pos], fixed=TRUE); writeLines(x, 'code/rmarkdown/docx.tex')"
	cd code/rmarkdown;\
	pandoc +RTS -K512m -RTS docx.tex -o article.docx --highlight-style tango --latex-engine pdflatex --include-in-header preamble.tex --variable graphics=yes --variable 'geometry:margin=1in' --bibliography references.bib --filter /usr/bin/pandoc-citeproc
	mv code/rmarkdown/article.docx article/
	rm -f code/rmarkdown/article.knit.md
	rm -f code/rmarkdown/article.utf8.md
	rm -f code/rmarkdown/docx.tex
	rm -rf code/rmarkdown/figures_files_docx

article/article.pdf: code/rmarkdown/preamble.tex code/rmarkdown/text.tex code/rmarkdown/figures.tex code/rmarkdown/article.Rmd
	-R --no-save -e "checkpoint::checkpoint('2016-11-26', R.version='3.3.2', scanForPackages=FALSE);rmarkdown::render('code/rmarkdown/article.Rmd')"
	rm -f code/rmarkdown/article.aux
	rm -f code/rmarkdown/article.log
	rm -f code/rmarkdown/article.sta
	mv code/rmarkdown/article.pdf article/

article/supporting-information.pdf: code/rmarkdown/preamble.tex code/rmarkdown/supporting-information.Rmd code/rmarkdown/references.bib code/rmarkdown/reference-style.csl
	R --no-save -e "checkpoint::checkpoint('2016-11-26', R.version='3.3.2', scanForPackages=FALSE);rmarkdown::render('code/rmarkdown/supporting-information.Rmd')"
	rm -f code/rmarkdown/supporting-information.md
	rm -f code/rmarkdown/supporting-information.utf8.md
	rm -f code/rmarkdown/supporting-information.knit.md
	mv code/rmarkdown/supporting-information.pdf article/

code/rmarkdown/text.tex: code/rmarkdown/text.Rmd code/rmarkdown/references.bib code/rmarkdown/reference-style.csl
	-R --no-save --no-save -e "checkpoint::checkpoint('2016-11-26', R.version='3.3.2', scanForPackages=FALSE);rmarkdown::render('code/rmarkdown/text.Rmd', clean=FALSE)"
	cd code/rmarkdown;\
	/usr/bin/pandoc +RTS -K512m -RTS text.utf8.md --to latex --from markdown+autolink_bare_uris+ascii_identifiers+tex_math_single_backslash --output text.tex --highlight-style tango --variable graphics=yes --variable 'geometry:margin=1in' --bibliography references.bib --filter /usr/bin/pandoc-citeproc
	rm -f code/rmarkdown/text.md -f
	rm -f code/rmarkdown/text.utf8.md
	rm -f code/rmarkdown/text.knit.md

code/rmarkdown/figures.tex: code/rmarkdown/figures.Rmd
	-R --no-save -e "checkpoint::checkpoint('2016-11-26', R.version='3.3.2', scanForPackages=FALSE);rmarkdown::render('code/rmarkdown/figures.Rmd', clean=FALSE)"
	cd code/rmarkdown;\
	/usr/bin/pandoc +RTS -K512m -RTS figures.utf8.md --to latex --from markdown+autolink_bare_uris+ascii_identifiers+tex_math_single_backslash --output figures.tex --highlight-style tango --variable graphics=yes --variable 'geometry:margin=1in' --bibliography references.bib --filter /usr/bin/pandoc-citeproc
	rm -f code/rmarkdown/figures.md
	rm -f code/rmarkdown/figures.utf8.md
	rm -f code/rmarkdown/figures.knit.md

article/reviewer-comments.pdf: code/rmarkdown/reviewer-comments.md
	cd code/rmarkdown;\
	/usr/bin/pandoc reviewer-comments.md --output reviewer-comments.pdf --variable 'geometry:margin=1in'
	mv code/rmarkdown/reviewer-comments.pdf article/reviewer-comments.pdf

# commands for running analysis
analysis: data/final/results.rda

data/final/results.rda: data/intermediate/06-*.rda code/R/analysis/07-*.R
	R CMD BATCH --no-restore --no-save code/R/analysis/07-*.R
	mv *.Rout data/intermediate/

data/intermediate/06-*.rda: data/intermediate/05-*.rda code/R/analysis/06-*.R code/parameters/benchmark.toml
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




