* Created 2021-03-12 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sh30_Regression_Outcome3_v2
* Creator:	RMJ
* Date:	20210312
* Desc:	Runs main analysis for serious self-harm & suicide (enddate30 version)
* Version History:
*	Date	Reference	Update
*	20210312	Regression_Outcome3_v2	create file
*************************************

*** Log
capture log close outcome330
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/regression_sh30_`date'.txt", text append name(outcome330)
*******

frames reset
clear


******** SPECIFY MODEL FOR PROPENSITY SCORE ANALYSIS (ALSO USED FOR MULT IMP)
// Also specifies the imputed variables for the models
include scripts/analysis/model_outcome3.do




******** MAIN ANALYSIS - IPTW-adjusted regression
******** first time = competing risk
frames reset
macro drop _all
use data/clean/imputed_sh30_outcome3

*** Specify macros
include scripts/analysis/model_outcome3.do
local stset "stset time [pw=sw], fail(outcome==1) scale(365.25)"
local regression "stcrreg i.cohort"
local options ", compete(outcome==2)"
local outcome outcome
local savetag sh30_cr

***** Extract counts info
local countsrowname "Main analysis selfharm"
include scripts/analysis/sh30_TabulateCounts.do
*****

*** Run the do-file
include scripts/analysis/WeightedAnalysis.do


******** second time = Cox
frames reset
macro drop _all
use data/clean/imputed_sh30_outcome3

*** Specify macros
include scripts/analysis/model_outcome3.do
local stset "stset time [pw=sw], fail(outcome==1) scale(365.25)"
local regression "stcox i.cohort"
local options 
local outcome outcome
local savetag sh30_cox
*** Run the do-file
include scripts/analysis/WeightedAnalysis.do



********* STANDARD (UNWEIGHTED) SURVIVAL ANALYSIS
******** first time = competing risk
frames reset
macro drop _all
use data/clean/imputed_sh30_outcome3
*** Specify macros
include scripts/analysis/model_outcome3.do 
local stset "stset time, fail(outcome==1) scale(365.25)" // the full stset command
local regression stcrreg // type of regression
local options ", compete(outcome==2)" // fill in if using stcrreg
local savetag sh30_cr

*** Run the do-file
include scripts/analysis/AdjustedSurvival.do



******** second time = cox
frames reset
macro drop _all
use data/clean/imputed_sh30_outcome3
*** Specify macros
include scripts/analysis/model_outcome3.do 
local stset "stset time, fail(outcome==1) scale(365.25)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sh30_cox

*** Run the do-file
include scripts/analysis/AdjustedSurvival.do


*********** END
capture log close outcome330
frames reset
exit
