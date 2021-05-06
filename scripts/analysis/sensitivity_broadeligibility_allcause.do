* Created 2020-05-01 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sensitivity_broadeligibility_allcause
* Creator:	RMJ
* Date:	20200501
* Desc:	Runs main analysis for all-cause mortality
* Version History:
*	Date	Reference	Update
*	20200501	Regression_Outcome1_v2	Create file
*	20200506	sensitivity_broadeligibility_allcause	Specify model vars using do-files
*	20200507	sensitivity_broadeligibility_allcause	Change macro outcome to savetag
*	20200514	sensitivity_broadeligibility_allcause	Add code to clear macros
*	20200514	sensitivity_broadeligibility_allcause	Drop if sex is missing
*	20200514	sensitivity_broadeligibility_allcause	Recode sex in this script
*	20200515	sensitivity_broadeligibility_allcause	Run utility collecting counts info
*	20201013	sensitivity_broadeligibility_allcause	Add optional stsplit
*	20201020	sensitivity_broadeligibility_allcause	Move the multiple imp code to separate script
*	20201022	sensitivity_broadeligibility_allcause	Add id() option
*	20201022	sensitivity_broadeligibility_allcause	Collapse split categories to avoid omission error
*	20201207	sensitivity_broadeligibility_allcause	Change specn of interaction - use new dofile
*	20201208	sensitivity_broadeligibility_allcause	Add local to allow alt specn of interaction to avoid error
*	20210302	sensitivity_broadeligibility_allcause	Remove the use of cohort2 - error gone after upstream change
*************************************

*** Log
capture log close eligibility
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/sensitivity_broadelig_allcause_`date'.txt", text append name(eligibility)
*******

frames reset
clear
macro drop _all


/***** RULES
* Use keep4 for eligibile: depression symptoms ever (keep switch date as 90 days)

* NOTE - use adjusted regression, as PS won't be balanced
*****/




********* STANDARD (UNWEIGHTED) SURVIVAL ANALYSIS
frames reset
macro drop _all
use data/clean/imputed_sensit_outcome1_broadelig


*** Specify macros
include scripts/analysis/model_outcome1.do
local stset "stset time, fail(died) scale(365.25) id(patid)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_broadelig_allcause

***** Extract counts info
local countsrowname "Widen eligibily criteria"
gen outcome=died
include scripts/analysis/TabulateCounts.do
drop outcome
*****

*** Run the do-file
include scripts/analysis/AdjustedSurvivalWithInteraction.do



*********** END
log close eligibility
frames reset
exit




