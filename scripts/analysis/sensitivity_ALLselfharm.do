* Created 2020-02-23 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sensitivity_ALLselfharm
* Creator:	RMJ
* Date:	20200223
* Desc:	All self harm sensitivity analyses (regression)
* Version History:
*	Date	Reference	Update
*	20200223	sensitivity_agebands	combine all the self-harm sensitivity files into one
*************************************

*** Log
capture log close allselfharm
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/sensitivity_agebands_`date'.txt", text append name(allselfharm)
*******

frames reset
clear

** 1 NO PRIOR SELF-HARM (includes full model spec)
frames reset
clear
macro drop _all

**** MACROS FOR THE MODELS (removed self harm)
local model i.sex ageindex age2  i.(antipsychotics anxiolytics hypnotics statins substmisuse  pud pancreatitis mentalhealthservices liverdis_mild intellectualdisab insomnia indigestion hypertension diabetes cancer anxiety asthma appetiteloss alcoholmisuse)
// Also specify the imputed vars to include in regression
local imputedvars bmi_i i.(smokestat_i alcoholintake_i) 

**** Load imputed dataset
use data/clean/imputed_outcome3

**** Drop if prevous primary care or secondary care self harm
drop if selfharm==1
drop if bl_intselfharm==1

**** RUN THE REGRESSION SCRIPT
***** Specify macros
local stset "stset time, fail(outcome==1) scale(365.25)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_selfharmnoselfharm

***** Extract counts info
local countsrowname "No prior self harm: selfharm"
include scripts/analysis/TabulateCounts.do

***** Run the do-file
include scripts/analysis/AdjustedSurvival.do




** 2 AGE BANDS
*** 2.1 age 18-64
**** Load imputed dataset (outcome 3)
frames reset
macro drop _all
use data/clean/imputed_outcome3

**** Restrict based on age at index
keep if ageindex<65

**** RUN THE REGRESSION SCRIPT 
***** Specify macros
include scripts/analysis/model_outcome3.do
local stset "stset time, fail(outcome==1) scale(365.25)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_selfharmage18to64_cox

***** Extract counts info
local countsrowname "Aged 18-64 selfharm"
include scripts/analysis/TabulateCounts.do

***** Run the regression file
include scripts/analysis/AdjustedSurvival.do


*** 2.2 age 65-99
frames reset
macro drop _all
**** Load imputed dataset (outcome 3)
use data/clean/imputed_outcome3

**** Restrict based on age at index
keep if ageindex>=65

**** RUN THE REGRESSION SCRIPT 
***** Specify macros
include scripts/analysis/model_outcome3.do
local stset "stset time, fail(outcome==1) scale(365.25)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_selfharmage65to99_cox

***** Extract counts info
local countsrowname "Aged 65-99 selfharm"
include scripts/analysis/TabulateCounts.do

***** Run the regression file
include scripts/analysis/AdjustedSurvival.do





** 3 CHANGING THE RISK CARRY-OVER WINDOWS
*** 3.1 IGNORE THIRD ANTIDEP
frames reset
macro drop _all

**** Load imputed dataset
use data/clean/imputed_outcome3

**** Define new enddate variable and recalculate time
drop newstop
egen newstop = rowmin(serioussh_int deathdate eligstop switchenddate6m)
drop time
gen time=newstop - index

**** Redefine the outcome variable
drop outcome
drop died
gen outcome = serioussh_int <= newstop
gen died = deathdate<=newstop & deathdate<serioussh_int
replace outcome = 2 if outcome!=1 & died==1

**** RUN THE REGRESSION SCRIPT
***** Specify macros
include scripts/analysis/model_outcome3.do
local stset "stset time, fail(outcome==1) scale(365.25)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_selfharmthirdad

***** Extract counts info
local countsrowname "SH: Ignore 3rd antidepressant"
include scripts/analysis/TabulateCounts.do

***** Run the do-file
include scripts/analysis/AdjustedSurvival.do



*** 3.2 NO CARRY-OVER WINDOW
frames reset
macro drop _all
use data/clean/imputed_outcome3

**** redefine time and outcome variables
drop newstop
egen newstop = rowmin(serioussh_int enddate0)
drop time
gen time=newstop - index

drop outcome
drop died
gen outcome = serioussh_int <= newstop
gen died = deathdate<=newstop & deathdate<serioussh_int
replace outcome = 2 if outcome!=1 & died==1

**** RUN THE REGRESSION SCRIPT
***** Specify macros
include scripts/analysis/model_outcome3.do
local stset  "stset time, fail(outcome==1) scale(365.25)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_selfharmstop0

***** Extract counts info
local countsrowname "SH: No carry-over window"
include scripts/analysis/TabulateCounts.do

***** Run the do-file
include scripts/analysis/AdjustedSurvival.do



*** 3.3 30 DAY CARRY-OVER WINDOW
frames reset
macro drop _all
use data/clean/imputed_outcome3

**** redefine time and outcome variables
drop newstop
egen newstop = rowmin(serioussh_int enddate30)
drop time
gen time=newstop - index

drop outcome
drop died
gen outcome = serioussh_int <= newstop
gen died = deathdate<=newstop & deathdate<serioussh_int
replace outcome = 2 if outcome!=1 & died==1

**** RUN THE REGRESSION SCRIPT
***** Specify macros
include scripts/analysis/model_outcome3.do
local stset "stset time, fail(outcome==1) scale(365.25)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_selfharmstop30

***** Extract counts info
local countsrowname "SH: 30 day carry-over window"
include scripts/analysis/TabulateCounts.do

**** Run the do-file
include scripts/analysis/AdjustedSurvival.do



*** 3.4 FOLLOW-UP, IGNORING STOPPING ANTIDEP
frames reset
macro drop _all
use data/clean/imputed_outcome3

**** Define new enddate variable and recalculate time
drop newstop
egen newstop = rowmin(serioussh_int deathdate eligstop thirdaddate)
drop time
gen time=newstop - index

**** Redefine the outcome variable
drop outcome
drop died
gen outcome = serioussh_int <= newstop
gen died = deathdate<=newstop & deathdate<serioussh_int
replace outcome = 2 if outcome!=1 & died==1

**** RUN THE REGRESSION SCRIPT
***** Specify macros
include scripts/analysis/model_outcome3.do
local stset "stset time, fail(outcome==1) scale(365.25)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_selfharmnostop

***** Extract counts info
local countsrowname "SH: Follow-up to end"
include scripts/analysis/TabulateCounts.do

***** Run the do-file
include scripts/analysis/AdjustedSurvival.do




******
frames reset
capture log close allselfharm
exit
