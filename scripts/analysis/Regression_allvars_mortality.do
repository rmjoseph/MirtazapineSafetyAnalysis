* Created 2020-10-13 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	Regression_allvars_mortality
* Creator:	RMJ
* Date:	20201013
* Desc:	Runs main analysis for all-cause mortality
* Version History:
*	Date	Reference	Update
*	20201013	Regression_Outcome1_v2	Create file
*	20201207	Regression_allvars_mortality	Update specn of interaction
*************************************

*** Log
capture log close allvars
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/regression_allvarsMort_`date'.txt", text append name(allvars)
*******

frames reset
clear


******** SPECIFY MODEL FOR PROPENSITY SCORE ANALYSIS (ALSO USED FOR MULT IMP)
// Also specifies the imputed variables for the models
include scripts/analysis/model_allvars.do

******** MAIN ANALYSIS - IPTW-adjusted regression
frames reset
macro drop _all
use data/clean/imputed_allvars

*** Specify macros
include scripts/analysis/model_allvars.do 
local stset "stset time [pw=sw], fail(died) scale(365.25) id(patid)"
local split "stsplit split, at(2)"
local splitvar "replace split=(split==2)"
local regression "stcox i.cohort#i.split i.split"
local outcome died
local savetag allcausemort_allvars_s

***** Extract counts info
local countsrowname "Use all variables"
drop outcome
gen outcome=died
include scripts/analysis/TabulateCounts.do
drop outcome
*****

*** Run the do-file
include scripts/analysis/WeightedAnalysis.do



********* STANDARD (UNWEIGHTED) SURVIVAL ANALYSIS
frames reset
macro drop _all
use data/clean/imputed_allvars

*** Specify macros
include scripts/analysis/model_allvars.do 

local stset "stset time, fail(died) scale(365.25) id(patid)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag allcausemort_allvars_interaction

***** Extract counts info
local countsrowname "Use all variables"
drop outcome
gen outcome=died
include scripts/analysis/TabulateCounts.do
drop outcome
*****

*** Run the do-file
include scripts/analysis/AdjustedSurvivalWithInteraction.do



*********** END
capture log close allvars
frames reset
exit
