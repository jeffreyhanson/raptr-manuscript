raptr: Representative and Adequate Prioritisation Toolkit in R
==============================================================
[![Status](https://img.shields.io/badge/status-in%20press-yellow.svg?style=flat-square)]()
[![License (GPL version 3)](https://img.shields.io/badge/license-GNU%20GPL%20version%203-brightgreen.svg?style=flat-square)](http://opensource.org/licenses/GPL-3.0)

[Jeffrey O. Hanson](http://www.jeffrey-hanson.com), [Jonathan R. Rhodes](https://rhodesconservation.com/people/jonathan-rhodes/), [Hugh P. Possingham](http://www.possinghamlab.org/people-new/all-lab-members/570-hugh-possingham.html), [Richard A. Fuller](https://www.fullerlab.org/drrichardfuller/)

Correspondence should be addressed to [jeffrey.hanson@uqconnect.edu.au](mailto:jeffrey.hanson@uqconnect.edu.au)

## Abstract

1. An underlying aim in conservation planning is to maximize the long-term persistence of biodiversity. To fulfill this aim, the ecological and evolutionary processes that sustain biodiversity must be preserved. One way to conserve such processes at the feature level (eg. species, ecosystem) is to preserve a sample of the feature (eg. individuals, areas) that is representative of the intrinsic or extrinsic physical attributes that underpin the process of interest. For example, by conserving a sample of populations with local adaptations---physical attributes associated with adaptation---that is representative of the range of adaptations found in the species, protected areas can maintain adaptive processes by ensuring these adaptations are not lost. Despite this, current reserve selection methods overwhelmingly focus on securing an adequate amount of area or habitat for each feature. Little attention has been directed towards capturing a representative sample of the variation within each feature.

2. To address this issue, we developed the _raptr R_ package to help guide reserve selection. Users set "amount targets"---similar to conventional methods---to ensure that solutions secure a sufficient proportion of area or habitat for each feature. Additionally, users set "space targets" to secure a representative sample of variation in ecologically or evolutionarily relevant attributes (eg. environmental or genetic variation). We demonstrate the functionality of this package using simulations and two case studies. In these studies, we generated solutions using amount targets---similar to conventional methods---and compared them with solutions generated using amount and space targets.

3. Our results demonstrate that markedly different solutions emerge when targeting a representative sample of each feature. We show that using these targets is important for features that have multimodal distributions in the process-related attributes (eg. species with multimodal niches). We also found that solutions could conserve a far more representative sample with only a slight increase in reserve system size.

4. The _raptr R_ package provides a toolkit for making prioritizations that secure an adequate and representative sample of variation within each feature. By using solutions that secure a representative sample of each feature, prioritizations may have a greater chance of achieving long-term biodiversity persistence.

### Overview

This repository contains the source code for the manuscript entitled "_raptr: Representative and Adequate Prioritisation Toolkit in R_". For more information on the _raptr R_ package, [check out the official version on CRAN](https://cran.r-project.org/web/packages/raptr/index.html) or the [the development version](http://www.github.com/jeffreyhanson/raptr).

[Download our data, code, results here](https://github.com/jeffreyhanson/raptr-manuscript/releases/latest). Alternatively, clone this repository, and rerun the entire analysis on your own computer using the system command `make all`.

* article
	+ manuscript main text, figures, and supporting information
* code
	+ [_R_](https://www.r-project.org): scripts used to run the analysis
	+ _parameters_: files used to run analysis in [TOML format](https://github.com/toml-lang/toml)
	+ [_rmarkdown_](https://wwww.rmarkdown.rstudio.com) files used to compile them manuscript
* data
	+ _raw_: raw data used to run the analysis
	+ _intermediate_: results generated during processing
	+ _final_: results used in the paper
* packrat
	+ _R_ packages used for analysis

### Software required

* Operating system
	+ Ubuntu (Trusty 14.04 LTS)
* Programs
	+ GNU make
	+ [Gurobi (version 7.0.0; academic licenses are available for no cost)](http://www.gurobi.com/)
	+ [pandoc (version 1.16.0.2+)](https://github.com/jgm/pandoc/releases)
	+ LaTeX
	+ [R (version 3.3.1)](https://www.r-project.org)
