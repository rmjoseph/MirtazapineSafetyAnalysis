* Created 2020-10-13 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	Regression_allvars_mortality
* Creator:	RMJ
* Date:	20201013
* Desc:	Runs main analysis for all-cause mortality
* Version History:
*	Date	Reference	Update
*	20201013	Regression_Outcome1_v2	Create file
*	20201021	Regression_allvars_selfharm	Remove competing risk sections
*	20201021	Regression_allvars_selfharm	Bug fix: drop time and rename time2
*************************************

*** Log
capture log close allvarsSH
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/regression_allvarsSH_`date'.txt", text append name(allvarsSH)
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
use data/clean/imputed_allvars
drop time
rename time2 time

*** Specify macros
include scripts/analysis/model_allvars.do
local stset "stset time [pw=sw], fail(outcome==1) scale(365.25)"
local regression "stcox i.cohort"
local options 
local outcome outcome
local savetag allvars_selfharm_cox

***** Extract counts info
local countsrowname "Use all variables selfharm"
include scripts/analysis/TabulateCounts.do
*****	
	
*** Run the do-file
include scripts/analysis/WeightedAnalysis.do



********* STANDARD (UNWEIGHTED) SURVIVAL ANALYSIS
******** cox
frames reset
macro drop _all
use data/clean/imputed_allvars
drop time
rename time2 time

*** Specify macros
include scripts/analysis/model_allvars.do 
local stset "stset time, fail(outcome==1) scale(365.25)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag allvars_selfharm_cox

*** Run the do-file
include scripts/analysis/AdjustedSurvival.do




*********** END
capture log close allvarsSH
frames reset
exit
