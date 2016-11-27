raptr: Representative and Adequate Prioritisation Toolkit in R
==============================================================
[![Status](https://img.shields.io/badge/status-in%20prep-red.svg?style=flat-square)]()
[![License (GPL version 3)](https://img.shields.io/badge/license-GNU%20GPL%20version%203-brightgreen.svg?style=flat-square)](http://opensource.org/licenses/GPL-3.0)

[Jeffrey O. Hanson](http://www.jeffrey-hanson.com), [Jonathan R. Rhodes](https://rhodesconservation.com/people/jonathan-rhodes/), [Hugh P. Possingham](http://www.possinghamlab.org/people-new/all-lab-members/570-hugh-possingham.html), [Richard A. Fuller](https://www.fullerlab.org/drrichardfuller/)

Correspondance should be addressed to [jeffrey.hanson@uqconnect.edu.au](mailto:jeffrey.hanson@uqconnect.edu.au)

**1. An underlying aim in conservation planning is to maximize the long-term persistence of biodiversity. To fulfill this aim, the ecological and evolutionary processes that sustain biodiversity must be preserved. One way to conserve such processes at the feature level (eg. species, ecosystem) is to preserve a representative sample of the physical attributes that underpin them across the feature's geographic distribution. For example, preserving the adaptive processes currently acting on a species might be crucial for its long-term persistence in a world where environmental change is accelerating. By conserving individuals with the ability to persist in a range of climatic conditions--physical attributes associated with adaptation--protected areas can foster evolutionary processes. Despite this, current approaches overwhelmingly focus on securing a target proportion of each features' geographic range and little attention has been directed towards targeting a representative sample of them.**

**2. To address this issue, we developed the raptr: Representative and Adequate Prioritization Toolkit in R to guide reserve selection using targets for representing spatially explicit variables that underpin biodiversity processes as well as more typical area protection targets. Users set "amount targets"--similar to conventional reserve selection methods--to secure a target proportion of the features' geographic distributions. Additionally, users set attribute "space targets" to ensure that reserve systems also secure a representative sample of ecologically or evolutionary relevant attributes (space) across the features' geographic distributions (eg. an attribute space expressing variation in genetic characteristics between individuals, or variation in climatic conditions between areas). We demonstrate the functionality of this package using simulations and two case studies. We generate solutions that secure a proportion of the species' distributions using amount targets--representing conventional reserve selection--and compare them with solutions generated using both amount and attribute space targets.**

**3. We show that markedly different solutions emerge when explicitly considering within feature representation in reserve selection. Our simulations suggest that including representativeness in conservation planning is important where biodiversity features have multimodal distributions in an attribute space. The case studies show that explicitly setting space-based targets can result in solutions that preserve a much more representative sample of features. Additionally, the case studies suggest that securing a representative sample of features may not require a much greater area of reservation than traditional approaches.**

**4. The raptr R package provides a unified framework for achieving spatial conservation prioritizations that secure an adequate and representative sample of features. Prioritizations that achieve this are likely to result in a greater chance of achieving long-term biodiversity persistence than area-based planning alone.**

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
