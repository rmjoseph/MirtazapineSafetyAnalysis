* Created 2021-03-12 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sh30_Regression_allvars_selfharm
* Creator:	RMJ
* Date:	20210312
* Desc:	Analysis for self harm, all variables. (for sh30 analysis)
* Version History:
*	Date	Reference	Update
*	20210312	Regression_allvars_selfharm	Create file
*************************************

*** Log
capture log close allvarsSH30
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/sh30_regression_allvarsSH_`date'.txt", text append name(allvarsSH30)
*******

frames reset
clear


******** SPECIFY MODEL FOR PROPENSITY SCORE ANALYSIS (ALSO USED FOR MULT IMP)
// Also specifies the imputed variables for the models
include scripts/analysis/model_allvars.do


******** MAIN ANALYSIS - IPTW-adjusted regression
******** Cox
frames reset
macro drop _all
use data/clean/imputed_sh30_allvars

*** Specify macros
include scripts/analysis/model_allvars.do
local stset "stset time [pw=sw], fail(outcome==1) scale(365.25)"
local regression "stcox i.cohort"
local options 
local outcome outcome
local savetag sh30_allvars_cox

***** Extract counts info
local countsrowname "Use all variables"
include scripts/analysis/sh30_TabulateCounts.do
*****	
	
*** Run the do-file
include scripts/analysis/WeightedAnalysis.do



********* STANDARD (UNWEIGHTED) SURVIVAL ANALYSIS
******** cox
frames reset
macro drop _all
use data/clean/imputed_sh30_allvars

*** Specify macros
include scripts/analysis/model_allvars.do 
local stset "stset time, fail(outcome==1) scale(365.25)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sh30_allvars_cox

*** Run the do-file
include scripts/analysis/AdjustedSurvival.do




*********** END
capture log close allvarsSH30
frames reset
exit
