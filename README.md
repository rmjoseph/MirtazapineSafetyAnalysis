# README
Stata do-files for preparation and analysis of CPRD data for a project about the safety of mirtazapine

## INTRODUCTION
This repository contains all the Stata do-files required to prepare and analyse CPRD datasets for a project comparing the safety of mirtazapine to other antidepressants. The protocol for the analysis is available online (https://doi.org/10.1101/2021.02.08.21250305). The data contain anonymised health records from England and are provided under licence from CPRD and cannot be shared. For more information see https://www.cprd.com/. The code and additional information should allow anybody to repeat the analysis if they have permission to access CPRD.

The analysis, including the protocol and the Stata code in this repository, was designed and written by researchers at the University of Nottingham. The work was funded by the NIHR Nottingham Biomedical Research Centre. This code underpins all of the results of this study, including those presented in published works, and has been shared for purposes of transparency and reproducibility. Any views represented are the views of the authors alone and do not necessarily represent the views of the Department of Health in England, NHS, or the National Institute for Health Research.

We request that any use of or reference to the Stata code within this repository is cited appropriately using the information provided on its Zenodo entry. Additional considerations apply for use of the DrugPrep or SmokingDefinition files (see below).


## Using the files
### DrugPrep and SmokingDefinition
This analysis reused two published Stata algorithms available from Zenodo.org. To run the analysis, these files must be downloaded separately. More information is given in:
- scripts/preparation/DrugPrep200/README.md
- scripts/preparation/SmokingDefinition13/README.md

Links to these published algorithms are as follows:
- https://doi.org/10.5281/zenodo.1313712
- https://doi.org/10.5281/zenodo.1405937

### Stata information
The files were written using Stata 16. Reuse requires at least Stata 16 as the frames function is used throughout.
Stata modules required are:
- tvc_split (net from http://personalpages.manchester.ac.uk/staff/mark.lunt)
- tvc_merge (net from http://personalpages.manchester.ac.uk/staff/mark.lunt)
- distrate (net install distrate, from(http://fmwww.bc.edu/RePEc/bocode/d/))
- sxpose (ssc install sxpose)
- grstyle (ssc install grstyle)
- palettes (ssc install palettes)

### Data
The data were provided under licence by the Clinical Practice Research Datalink (CPRD, CPRD GOLD dataset Nov 2019). The database queries used to define primary care data have been provided (Word documents Define_*). The linked data (Hospital Episode Statistics (HES) admitted patient care data, Office for National Statisitics (ONS) mortality data, and deprivation data) were provided directly by CPRD for a subset of patients (the code to define these patients is provided).

The code lists and related information used in the analysis have been provided in this upload. No other data are attached (no raw or processed CPRD files are included). The files Appendix1_mirtaz_codelists.xlsx and DefinedDailyDose_20200220.csv should be moved to "data/codelists/". The files SmokingDrugs.csv and SmokingReadcodes.csv should be moved to "scripts/preparation/Smoking13/data/".

To replicate the analysis without altering paths within scripts the structure and contents of the data folder should be as follows:

#### data/clean
- contents produced by code

#### data/codelists
- data/codelists/Appendix1_mirtaz_codelists.xlsx
- data/codelists/DefinedDailyDose_20200220.csv

#### data/raw
- data/raw/19_241_Delivery
- data/raw/Define3_20191010
- data/raw/Denominators_2019_11
- data/raw/ICD10_Edition5_20160401
- data/raw/Lookups_2019_06
- data/raw/Mirt1f
- data/raw/Mirt1m
- data/raw/set_17_Source_GOLD
- data/raw/stata


### Running the code
- The file scripts/preparation/masterfile_preparation.do can be used to run all data preparation steps. The path to the working directory must be set at **line 33**. All other scripts use relative paths.
- The file scripts/analysis/masterfile_analysis.do can be used to run the analysis steps. The path to the working directory must be set at **line 33**. All other scripts use relative paths.
