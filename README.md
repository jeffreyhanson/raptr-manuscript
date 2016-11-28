raptr: Representative and Adequate Prioritisation Toolkit in R
==============================================================
[![Status](https://img.shields.io/badge/status-in%20prep-red.svg?style=flat-square)]()
[![License (GPL version 3)](https://img.shields.io/badge/license-GNU%20GPL%20version%203-brightgreen.svg?style=flat-square)](http://opensource.org/licenses/GPL-3.0)

[Jeffrey O. Hanson](http://www.jeffrey-hanson.com), [Jonathan R. Rhodes](https://rhodesconservation.com/people/jonathan-rhodes/), [Hugh P. Possingham](http://www.possinghamlab.org/people-new/all-lab-members/570-hugh-possingham.html), [Richard A. Fuller](https://www.fullerlab.org/drrichardfuller/)

Correspondance should be addressed to [jeffrey.hanson@uqconnect.edu.au](mailto:jeffrey.hanson@uqconnect.edu.au)

**1. An underlying aim in conservation is to maximize the long-term persistence of biodiversity. To fulfill this aim, the ecological and evolutionary processes that sustain biodiversity must be preserved. One way to conserve such processes at the feature level (eg. species, ecosystem) is to preserve a representative sample of the physical attributes that underpin them across the feature's geographic distribution. For example, the long-term persistence of a species may depend on its ability to adapt to new climatic conditions. By conserving individuals with the ability to persist in a range of conditions--physical attributes associated with adaptation--protected areas can foster evolutionary processes. Despite this, current reserve selection methods overwhelmingly focus on securing an adequate proportion of features' geographic ranges and little attention has been directed towards capturing a representative sample.**

**2. To address this issue, we developed the raptr R package to guide reserve selection using targets for representing spatially explicit variables that underpin biodiversity processes as well as more typical area protection targets. Users set "amount targets"--similar to conventional methods--to secure a sufficient proportion of the features' geographic distributions. Additionally, users set "space targets" to secure a representative sample of variation in ecologically or evolutionary relevant attributes (eg. climatic or genetic variation). We demonstrate the functionality of this package using simulations and two case studies. We generate solutions using just amount targets--representing conventional methods--and compare them with solutions generated using amount and space targets.**

**3. We show that different solutions emerge when explicitly considering within feature representation in reserve selection. Our simulations suggest that targeting representativeness is particularly important for biodiversity features that have multimodal distributions in an attribute space. The case studies show that setting space targets can result in solutions that conserve a much more representative sample of features--and this can be achieved with only a slight increase in reserve size.**

**4. The raptr R package provides a toolkit for making spatial conservation prioritizations that secure an adequate and representative sample of features. By targeting representativeness, prioritizations may have a greater chance of achieving long-term biodiversity persistence.**

### Overview

This repository contains the source code for the manuscript entitled "_raptr: Representative and Adequate Prioritisation Toolkit in R_". For more information on the _raptr R_ package, [check out the official development repository](http://www.github.com/jeffreyhanson/raptr). 

[Download the data, code, results we used and generated here](https://github.com/jeffreyhanson/raptr-manuscript/releases/latest). Alternatively, clone this repository, and rerun the entire analysis on your own computer using the system commands `make all`. 

* article
	+ manuscript main text, figures, tables, and supporting information
* data
	+ _raw_: raw data used to run the analysis
	+ _intermediate_: results generated during processing
	+ _final_: results used in the paper
* code
	+ [_R_](https://www.r-project.org): scripts used to run the analysis 
	+ _parameters_: files used to run analysis in [TOML format](https://github.com/toml-lang/toml)
	+ [_rmarkdown_](https://wwww.rmarkdown.rstudio.com) files used to compile them manuscript

### Software required

* Operating system
	+ Ubuntu (Trusty 14.04 LTS)
* Programs
	+ GNU make
	+ [Gurobi (version 7.0.0; academic licenses are available for no cost)](http://www.gurobi.com/)
	+ [pandoc (version 1.16.0.2+)](https://github.com/jgm/pandoc/releases)
	+ LaTeX
	+ [R (version 3.3.1)](https://www.r-project.org)
