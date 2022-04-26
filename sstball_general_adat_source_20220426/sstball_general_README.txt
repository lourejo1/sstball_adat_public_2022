sstball_general_code - tarball already extracted and .adat in a folder named 'data'
Joseph.loureiro@novartis.com

+++ Source available to expert users provided, as is.  Collaboration is encouraged.

+++ This version configured to run on MacOS with pandoc installed. 

+++ Environment must be configured to run r 4.0.2 or later and have all required libraries installed.  See source for latest requirements and current is provided at end.

+++ .adat Somalogic proprietary SomaScan data file format is converted to R/Bioconductor eSet object for further analysis with publicly available SomaDataIO software shared by Somalogic.  

Notes:
A) somaTechUnpackv1.5.R takes as INPUT a folder within (./data/) that contains the .adats and supporting .md5 file
	- Does not require adat.md5 but will check and require match to complete
		- Blind adat.md5 and script will bypass md5 check
	- Code instruction below provides option to specify project name instead of deriving project code from file name, which must start with 'Novartis_' or 'Novartis.' And will parse subsequent six characters


%%%%%%%%%%%%%%%%%%%%%%

EXAMPLE starting configuration:
|____sstball_general_code
| |____somaTechUnpackv1.5.R
| |____SomaScan_v4.1_annotationsPUBLIC2022_vlite.RDS
| |____README_general.txt
|____data
| |____example_data_v4.1_plasma.adat

%%%%%%%%%%%%%%%%%%%%%%

The publicly available .adat from Somalogic is in a 'data' folder in same directory.  https://github.com/SomaLogic/SomaLogic-Data 

%%%%%%%%%%%%%%%%%%%%%%

For manual execution, especially if you want to specify project name (e.g - ABC123) to be appended to output:

1) Code to run on unix command line from sstball directory for data processing:

1a) Rscript somaTechUnpackv1.5.R

     OR

1b) Rscript somaTechUnpackv1.5.R ABC123


%%%%%%%%%%%%%%%%%%%%%%

Currently working in MacOS .zsh environment with pandoc installed.  User is responsible for configuring their system.  SomaDataIO is available at https://github.com/SomaLogic and other requirements are publicly available for use in R/4.1.2 or later.

somaTechUnpackv1.5.R requirements
  	library(dplyr)
  	library(Biobase)
  	library(SomaDataIO)
  	library(rjson)
  	library(tools)


somaTechQCv3.4.Rmd requirements
	library(tidyverse)
	library(arrayQualityMetrics)
	library(Biobase)
	library(matrixStats)
	library(SomaDataIO)
	library(knitr)
	library(xtable)
	library(janitor)
	library(rjson)
	require(graphics)
	library(ggforce)