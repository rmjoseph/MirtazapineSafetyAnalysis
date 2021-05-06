* Created 2020-04-30 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sensitivity_agebands
* Creator:	RMJ
* Date:	20200430
* Desc:	Sensitivity analysis restricting for ages 18-64 and 65-99
* Version History:
*	Date	Reference	Update
*	20200430	sensitivity_maxfollowup	Create file
*	20200506	sensitivity_agebands	Specify model vars using do-files
*	20200506	sensitivity_agebands	Rename output files to mention outcome
*	20200507	sensitivity_agebands	Change macro outcome to savetag
*	20200515	sensitivity_agebands	Run utility collecting counts info
*	20200522	sensitivity_agebands	Repeat for selfharm outcome
*	20201013	sensitivity_agebands	Add optional stsplit
*	20201022	sensitivity_agebands	Add option id()
*	20201207	sensitivity_agebands	Change specn of interaction - use new dofile
*	20210223	sensitivity_agebands	Remove the self harm section
*************************************

*** Log
capture log close agebands
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/sensitivity_agebands_`date'.txt", text append name(agebands)
*******

frames reset
clear

/***** RULES
* Change stset to max 1 and 5 years

* NOTE - use adjusted regression, as PS won't be balanced when drop people from groups
* NOTE - full for all-cause mortality and for cause-specific (cancer)
*****/


**** ALL-CAUSE MORTALITY
***** 18-64
*** Load imputed dataset (all-cause mort)
frames reset
use data/clean/imputed_outcome1

*** Restrict based on age at index
keep if ageindex<65

*** Examine
tab cohort died
gen months = round(time/(365.25/12),.1)
tabstat months, by(cohort) stat(median p25 p75)

*** RUN THE REGRESSION SCRIPT 
*** Specify macros
include scripts/analysis/model_outcome1.do
local stset "stset time, fail(died) scale(365.25) id(patid)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_allcauseage18to64

***** Extract counts info
local countsrowname "Aged 18-64"
gen outcome=died
include scripts/analysis/TabulateCounts.do
drop outcome
*****

*** Run the do-file
include scripts/analysis/AdjustedSurvivalWithInteraction.do



***** 65-99
frames reset
macro drop _all
*** Load imputed dataset (all-cause mort)
use data/clean/imputed_outcome1

*** Restrict based on age at index
keep if ageindex>=65

*** RUN THE REGRESSION SCRIPT 
*** Specify macros
include scripts/analysis/model_outcome1.do
local stset "stset time, fail(died) scale(365.25) id(patid)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_allcauseage65to99

***** Extract counts info
local countsrowname "Aged 65-99"
gen outcome=died
include scripts/analysis/TabulateCounts.do
drop outcome
*****

*** Run the do-file
include scripts/analysis/AdjustedSurvivalWithInteraction.do




*** CLOSE
frames reset
capture log close agebands
exit
