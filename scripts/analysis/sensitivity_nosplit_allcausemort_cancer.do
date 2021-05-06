* Created 2020-10-21 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sensitivity_nosplit_allcausemort_cancer
* Creator:	RMJ
* Date:	20201021
* Desc:	Runs the allcause mortality and cancer analyses without interaction with time
* Version History:
*	Date	Reference	Update
*	20201013	Regression_Outcome1_v2	Create file
*	20201022	sensitivity_nosplit_allcausemort_cancer	Add macro drop _all line
*************************************

*** Log
capture log close nosplit
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/sensitivity_notimeinteraction_`date'.txt", text append name(nosplit)
*******

frames reset
clear

******** ALL CAUSE MORTALITY
******** MAIN ANALYSIS - IPTW-adjusted regression
frames reset
macro drop _all
use data/clean/imputed_outcome1

*** Specify macros
include scripts/analysis/model_outcome1.do 
local stset "stset time [pw=sw], fail(died) scale(365.25) id(patid)"
local regression "stcox i.cohort"
local outcome died
local savetag allcausemort_nosplit

***** Extract counts info
local countsrowname "No time interaction"
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
local savetag allcausemort_nosplit

***** Extract counts info
local countsrowname "No time interaction"
gen outcome=died
include scripts/analysis/TabulateCounts.do
drop outcome
*****

*** Run the do-file
include scripts/analysis/AdjustedSurvival.do



**** CANCER MORTALITY - WITHOUT COMPETING RISK SECTIONS *****

******** MAIN ANALYSIS - IPTW-adjusted regression
********* Cox 
frames reset
macro drop _all
use data/clean/imputed_outcome2

*** Specify macros
include scripts/analysis/model_outcome2.do 
local outcome died_cause
local stset "stset time [pw=sw], fail(died_cause==2) scale(365.25) id(patid)"
local regression "stcox i.cohort"
local options

local savetag cancer_cox_202010_nosplit
local regression "stcox i.cohort"	

***** Extract counts info
local countsrowname "No time interaction cancer"
gen outcome=(died_cause==2)
include scripts/analysis/TabulateCounts.do
drop outcome
*****

*** Run the do-file
include scripts/analysis/WeightedAnalysis.do



********* STANDARD (UNWEIGHTED) SURVIVAL ANALYSIS
********* Cox
frames reset
macro drop savetag options regression stset imputedvars model
use data/clean/imputed_outcome2

*** Specify macros
include scripts/analysis/model_outcome2.do 
local stset "stset time, fail(died_cause==2) scale(365.25) id(patid)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg

local savetag cancer_cox_202010_nosplit


*** Run the do-file
include scripts/analysis/AdjustedSurvival.do



*********** END
log close nosplit
frames reset
exit
