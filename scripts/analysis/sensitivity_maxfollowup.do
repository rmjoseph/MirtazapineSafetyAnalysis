* Created 2020-04-30 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sensitivity_maxfollowup
* Creator:	RMJ
* Date:	20200430
* Desc:	Sensitivity analysis restricting the maximum follow-up
* Version History:
*	Date	Reference	Update
*	20200430	sensitivity_maxfollowup	Create file
*	20200506	sensitivity_maxfollowup	Specify model vars using do-files
*	20200506	sensitivity_maxfollowup	Rename output files to mention outcome
*	20200507	sensitivity_maxfollowup	Change macro outcome to savetag
*	20200521	sensitivity_maxfollowup	Drop macros between analyses
*	20200521	sensitivity_maxfollowup	Error fix: exit 365.25 not .35
*	20200521	sensitivity_maxfollowup	Include script to summarise fup
*************************************

*** Log
capture log close followup
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/sensitivity_maxfollowup_`date'.txt", text append name(followup)
*******

frames reset
clear

/***** RULES
* Change stset to max 1 and 5 years

* NOTE - use adjusted regression, as PS won't be balanced when drop people from groups
* NOTE - full for all-cause mortality and for cause-specific (cancer)
*****/


**** ALL-CAUSE MORTALITY

***** 5 YEARS MAX
*** Load imputed dataset (all-cause mort)
use data/clean/imputed_outcome1
macro drop _all

*** RUN THE REGRESSION SCRIPT 
*** Specify macros
include scripts/analysis/model_outcome1.do
local stset "stset time, fail(died) scale(365.25) exit(time 365.25*5)" // the full stset command
local regression stcox // type of regression
local options // fill in if using stcrreg
local savetag sensitivity_allcausemax5years

***** Extract counts info
local countsrowname "Max 5 years followup"
gen outcome=died if time<(365.25*5)
rename time time2
gen time = time2 
replace time = . if time >= (365.25*5)
include scripts/analysis/TabulateCounts.do
drop outcome time
rename time2 time
*****

*** Run the do-file
include scripts/analysis/AdjustedSurvival.do



***** 1 YEAR MAX
*** Load imputed dataset (all-cause mort)
frames reset
macro drop _all
use data/clean/imputed_outcome1

*** RUN THE REGRESSION SCRIPT (1 year max)
*** Specify macros
include scripts/analysis/model_outcome1.do
local stset "stset time, fail(died) scale(365.25) exit(time 365.25)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_allcausemax1year

***** Extract counts info
local countsrowname "Max 1 year followup"
gen outcome=died if time<(365.25)
rename time time2
gen time = time2 
replace time = . if time >= (365.25)
include scripts/analysis/TabulateCounts.do
drop outcome time
rename time2 time
*****

*** Run the do-file
include scripts/analysis/AdjustedSurvival.do


*** CLOSE
frames reset
capture log close followup
exit
