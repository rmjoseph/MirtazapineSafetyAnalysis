* Created 2020-04-27 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	Regression_Outcome1_v2
* Creator:	RMJ
* Date:	20200427
* Desc:	Runs main analysis for all-cause mortality
* Version History:
*	Date	Reference	Update
*	20200427	Regression_Outcome1	Create file
*	20200429	Regression_Outcome1_v2	Fix: add bmi_i to imputed
*	20200506	Regression_Outcome1_v2	Use do-file to specify models
*	20200507	Regression_Outcome1_v2	bug fix: rename `outcome' `savetag' and make new `outcome'
*	20200513	Regression_Outcome1_v2	bug fix: drop macros between analyses
*	20200514	Regression_Outcome1_v2	Recode sex in this script
*	20200515	Regression_Outcome1_v2	Run utility collecting counts info
*	20201009	Regression_Outcome1_v2	MI: merge in dose vars
*	20201009	Regression_Outcome1_v2	MI: create time interaction var
*	20201009	Regression_Outcome1_v2	MI: add extravars macro to add new vars to MI
*	20201009	Regression_Outcome1_v2	Remove multiple imp section - new dofile
*	20201013	Regression_Outcome1_v2	Add macro lines for stsplit
*	20201013	Regression_Outcome1_v2	Add split variable to model macro
*	20201013	Regression_Outcome1_v2	Add id(patid) to stset
*	20201203	Regression_Outcome1_v2	Update specification of model to extract interaction results
*	20201207	Regression_Outcome1_v2	Use AdjustedSurvivalWithInteraction for the adj reg
*************************************

*** Log
capture log close outcome1
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/regression_outcome1_`date'.txt", text append name(outcome1)
*******

frames reset
clear


******** SPECIFY MODEL FOR PROPENSITY SCORE ANALYSIS (ALSO USED FOR MULT IMP)
// Also specifies the imputed variables for the models
include scripts/analysis/model_outcome1.do


******** MAIN ANALYSIS - IPTW-adjusted regression
frames reset
macro drop _all
use data/clean/imputed_outcome1

*** Specify macros
include scripts/analysis/model_outcome1.do 
local stset "stset time [pw=sw], fail(died) scale(365.25) id(patid)"
local split "stsplit split, at(2)"
local splitvar "replace split=(split==2)"
local regression "stcox i.cohort#i.split i.split"
local outcome died
local savetag allcausemort_s

***** Extract counts info
local countsrowname "Main analysis"
gen outcome=died
include scripts/analysis/TabulateCounts.do
drop outcome
*****

*** Run the do-file
include scripts/analysis/WeightedAnalysis.do



********* STANDARD (UNWEIGHTED) SURVIVAL ANALYSIS
frames reset
macro drop _all
use data/clean/imputed_outcome1

*** Specify macros
include scripts/analysis/model_outcome1.do 

local stset "stset time, fail(died) scale(365.25) id(patid)" // the full stset command

local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag allcausemort_interaction

***** Extract counts info
local countsrowname "Main analysis"
gen outcome=died
include scripts/analysis/TabulateCounts.do
drop outcome
*****

*** Run the do-file
include scripts/analysis/AdjustedSurvivalWithInteraction.do // includes a split at time==2y


*********** END
capture log close outcome1
frames reset
exit
