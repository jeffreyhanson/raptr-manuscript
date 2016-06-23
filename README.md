rapr: Representative and Adequate Prioritisations in R
======================================================

[Jeffrey O. Hanson](www.jeffrey-hanson.com), Jonathan R. Rhodes, Hugh P. Possingham, Richard A. Fuller

Correspondance should be addressed to [jeffrey.hanson@uqconnect.edu.au](mailto:jeffrey.hanson@uqconnect.edu.au)

Source code for the manuscript entitled "_rapr: Representative and Adequate Prioritisations in R_" and analyses contained therein. 

The source code for the [_rapr_ R package can be found here](www.github.com/paleo13/rapr).

To rerun all computational analyses, run `make clean && make all`.

### Repository overview

* article
	+ manuscript main text, figures and tables
* data
	+ _raw_: raw data used to run the analysis
	+ _intermediate_: results generated during processing
	+ _final_: results used in the paper
* code
	+ [_R_](www.r-project.org): scripts used to run the analysis 
	+ _parameters_: files used to run analysis in [TOML format](https://github.com/toml-lang/toml)
	+ [_rmarkdown_](wwww.rmarkdown.rstudio.com) files used to compile them manuscript

### Software required

* Operating system
	+ Ubuntu (Trusty 14.04 LTS)
* Programs
	+ R (version 3.2.3)
	+ GNU make
	+ pandoc
	+ pandoc-citeproc
	+ LaTeX
* R packages
	+ stats
	+ hexbin
	+ RColorBrewer
	+ fields
	+ ape
	+ Hmisc
	+ data.table
	+ grid
	+ gridExtra
	+ plotrix
	+ plyr
	+ dplyr
	+ tidyr
	+ pander
	+ vegan
	+ rgeos
	+ testthat
	+ parallel
	+ rworldxtra
	+ doParallel
	+ english
	+ session
	+ maptools
	+ RcppTOML
	+ knitr
	+ lazyWeave
	+ broom
	+ adehabitatHR
* R GitHub packages
	+ AtlasOfLivingAustralia/ALA4R
	+ paleo13/spThin
	+ paleo13/bayescanr
	+ paleo13/structurer
	+ paleo13/ggplot2
* LaTeX packages
	+ amsfonts
	+ amsmath
	+ amssymb
	+ fixltx2e
	+ float
	+ fontenc
	+ hyperref
	+ geometry
	+ ifluatex
	+ ifxetec
	+ inputenc
	+ lmodern
	+ makecell
	+ microtype
	+ titlesec
	+ titletoc
	+ titling
	+ tocloft
	+ natbib
