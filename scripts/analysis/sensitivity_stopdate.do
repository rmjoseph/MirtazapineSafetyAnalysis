* Created 2020-04-30 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sensitivity_stopdate.do
* Creator:	RMJ
* Date:	20200430
* Desc:	Sensitivity analysis changing the definition of stop dates
* Version History:
*	Date	Reference	Update
*	20200430	sensitivity_noselfharm	Create file
*	20200506	sensitivity_stopdate	Specify model vars using do-files
*	20200507	sensitivity_stopdate	Change macro outcome to savetag
*	20200515	sensitivity_stopdate	Run utility collecting counts info
*	20200521	sensitivity_stopdate	Drop macros between analyses
*	20201013	sensitivity_stopdate	Add optional stsplit
*	20201022	sensitivity_stopdate	Add id(patid) option
*	20201022	sensitivity_stopdate	Collapse split categories to avoid omission error (stop30 only)
*	20201207	sensitivity_stopdate	Change specn of interaction - use new dofile
*	20201208	sensitivity_stopdate	Add local to allow alt definition of interaction (stop30)
*************************************

*** Log
capture log close stopdate
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/sensitivity_stopdate_`date'.txt", text append name(stopdate)
*******

frames reset
clear

/***** RULES
* ignore starting third antidepressant
* stop date with no carry-over window
* stop date with 30 day carry-over window
* ignore stopping the index antidepressant

* NOTE - use adjusted regression
* NOTE - all of the outcomes? Start with all-cause
*****/


******** ALL-CAUSE MORTALITY

******** IGNORE THIRD ANTIDEP
macro drop _all

*** Load imputed dataset (all-cause mort)
use data/clean/imputed_outcome1

*** Define new enddate variable and recalculate time
egen newstop = rowmin(deathdate eligstop switchenddate6m)
drop time
gen time=newstop - index

*** Redefine the death variable
drop died
gen died = (deathdate<=newstop)


*** RUN THE REGRESSION SCRIPT
*** Specify macros
include scripts/analysis/model_outcome1.do
local stset "stset time, fail(died) scale(365.25) id(patid)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_allcausethirdad

***** Extract counts info
local countsrowname "Ignore 3rd antidepressant"
gen outcome=died
include scripts/analysis/TabulateCounts.do
drop outcome
*****

*** Run the do-file
include scripts/analysis/AdjustedSurvivalWithInteraction.do



******** NO CARRY-OVER WINDOW
frames reset
macro drop _all
use data/clean/imputed_outcome1

** redefine time and died variables
drop time
gen time = enddate0-index
drop died
gen died = endreason0==1

*** RUN THE REGRESSION SCRIPT
*** Specify macros
include scripts/analysis/model_outcome1.do
local stset "stset time, fail(died) scale(365.25) id(patid)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_allcausestop0

***** Extract counts info
local countsrowname "No carry-over window"
gen outcome=died
include scripts/analysis/TabulateCounts.do
drop outcome
*****

*** Run the do-file
include scripts/analysis/AdjustedSurvivalWithInteraction.do



******** 30 DAY CARRY-OVER WINDOW
frames reset
macro drop _all
use data/clean/imputed_outcome1

gen cohort2=cohort
replace cohort2=3 if cohort2==4	// use to fix problem with term omission
local o_error 1	// local allows use of cohort2 in creating interactions (avoids omission error) 

** redefine time and died variables
drop time
gen time = enddate30-index
drop died
gen died = endreason30==1


*** RUN THE REGRESSION SCRIPT
*** Specify macros
include scripts/analysis/model_outcome1.do
local stset "stset time, fail(died) scale(365.25) id(patid)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_allcausestop30

***** Extract counts info
local countsrowname "30 day carry-over window"
gen outcome=died
include scripts/analysis/TabulateCounts.do
drop outcome
*****

*** Run the do-file
include scripts/analysis/AdjustedSurvivalWithInteraction.do



******** FOLLOW-UP, IGNORING STOPPING ANTIDEP
frames reset
macro drop _all
use data/clean/imputed_outcome1

*** Define new enddate variable and recalculate time
egen newstop = rowmin(deathdate eligstop thirdaddate)
drop time
gen time=newstop - index

*** Redefine the death variable
drop died
gen died = (deathdate<=newstop)

*** Investigate
tab cohort died


*** RUN THE REGRESSION SCRIPT
*** Specify macros
include scripts/analysis/model_outcome1.do
local stset "stset time, fail(died) scale(365.25) id(patid)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_allcausenostop

***** Extract counts info
local countsrowname "Follow-up to end"
gen outcome=died
include scripts/analysis/TabulateCounts.do
drop outcome
*****

*** Run the do-file
include scripts/analysis/AdjustedSurvivalWithInteraction.do





*** CLOSE
frames reset
log close stopdate
exit
