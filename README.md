rapr: Representative and Adequate Prioritisations in R
======================================================

Jeffrey O. Hanson, Jonathan R. Rhodes, Hugh P. Possingham, Richard A. Fuller

Correspondance should be addressed to [jeffrey.hanson@uqconnect.edu.au](mailto:jeffrey.hanson@uqconnect.edu.au)

Source code for the analysis in the manuscript entitled 'rapr: Representative and Adequate Prioritisations in R'. 

To rerun all computational analyses, run `make clean && make all`.

### Repository overview

* article
	+ files to create article
* parameters
	+ TOML files containing parameters used to run analysis
* data
	+ raw data used for article
* R
	+ R scripts used for analysis 
* results
	+ results from analysis

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
	+ rmarkdown
	+ Hmisc
	+ knitr
	+ lazyweave
* R GitHub packages
	+ paleo13/rgurobi
	+ paleo13/rapr
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
