raptr: Representative and Adequate Prioritisation Toolkit in R
==============================================================
[![Status](https://img.shields.io/badge/status-in%20prep-red.svg?style=flat-square)]()
[![License (GPL version 3)](https://img.shields.io/badge/license-GNU%20GPL%20version%203-brightgreen.svg?style=flat-square)](http://opensource.org/licenses/GPL-3.0)

[Jeffrey O. Hanson](www.jeffrey-hanson.com), Jonathan R. Rhodes, Hugh P. Possingham, Richard A. Fuller

Correspondance should be addressed to [jeffrey.hanson@uqconnect.edu.au](mailto:jeffrey.hanson@uqconnect.edu.au)

Source code for the manuscript entitled "_raptr: Representative and Adequate Prioritisation Toolkit in R_" and analyses contained therein. 

The source code for the [_raptr_ R package can be found here](www.github.com/paleo13/raptr).

To rerun all computational analyses, run `make clean && make all`.

### Repository overview

* article
	+ manuscript main text, figures, tables, and supporting information
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
