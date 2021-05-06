* Created 2020-04-29 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	Regression_Outcome3_v2
* Creator:	RMJ
* Date:	20200429
* Desc:	Runs main analysis for serious self-harm & suicide
* Version History:
*	Date	Reference	Update
*	20200429	Regression_Outcome1_v2	Create file
*	20200506	Regression_Outcome3_v2	Use do-files to specify vars for models
*	20200507	Regression_Outcome3_v2	bug fix: rename `outcome' `savetag' and make new `outcome'
*	20200513	Regression_Outcome3_v2	bug fix: drop macros between analyses
*	20200514	Regression_Outcome3_v2	run the weighted model using cox reg
*	20200514	Regression_Outcome3_v2	Recode sex in this script
*	20200515	Regression_Outcome3_v2	Run utility collecting counts info
*	20200526	Regression_Outcome3_v2	Drop the pats with outcome on index date before MI
*	20201009	Regression_Outcome3_v2	Moved MI section to separate dofile
*	20201013	Regression_Outcome3_v2	New tag names so don't overwrite prev results
*************************************

*** Log
capture log close outcome3
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/regression_outcome3_`date'.txt", text append name(outcome3)
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
use data/clean/imputed_outcome3

*** Specify macros
include scripts/analysis/model_outcome3.do
local stset "stset time [pw=sw], fail(outcome==1) scale(365.25)"
local regression "stcrreg i.cohort"
local options ", compete(outcome==2)"
local outcome outcome
local savetag selfharm_cr_202010

***** Extract counts info
local countsrowname "Main analysis selfharm"
include scripts/analysis/TabulateCounts.do
*****

*** Run the do-file
include scripts/analysis/WeightedAnalysis.do


******** second time = Cox
frames reset
macro drop _all
use data/clean/imputed_outcome3

*** Specify macros
include scripts/analysis/model_outcome3.do
local stset "stset time [pw=sw], fail(outcome==1) scale(365.25)"
local regression "stcox i.cohort"
local options 
local outcome outcome
local savetag selfharm_cox_202010

*** Run the do-file
include scripts/analysis/WeightedAnalysis.do



********* STANDARD (UNWEIGHTED) SURVIVAL ANALYSIS
******** first time = competing risk
frames reset
macro drop _all
use data/clean/imputed_outcome3
*** Specify macros
include scripts/analysis/model_outcome3.do 
local stset "stset time, fail(outcome==1) scale(365.25)" // the full stset command
local regression stcrreg // type of regression
local options ", compete(outcome==2)" // fill in if using stcrreg
local savetag selfharm_cr_202010

*** Run the do-file
include scripts/analysis/AdjustedSurvival.do



******** second time = cox
frames reset
macro drop _all
use data/clean/imputed_outcome3
*** Specify macros
include scripts/analysis/model_outcome3.do 
local stset "stset time, fail(outcome==1) scale(365.25)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag selfharm_cox_202010

*** Run the do-file
include scripts/analysis/AdjustedSurvival.do


*********** END
capture log close outcome3
frames reset
exit
