* Created 2021-03-12 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sh30_sensitivity_ALLselfharm
* Creator:	RMJ
* Date:	20210312
* Desc:	All self harm sensitivity analyses (regression) (sh30 analysis)
* Version History:
*	Date	Reference	Update
*	20210312	sensitivity_ALLselfharm	combine all the self-harm sensitivity files into one
*	20210518	sh30_sensitivit_ALLselfharm	rename log file
*	20210518	sh30_sensitivit_ALLselfharm	Add analysis with primary care SH in outcome
*************************************

*** Log
capture log close allselfharm30
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/sh30_sensitivity_`date'.txt", text append name(allselfharm30)
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
use data/clean/imputed_sh30_outcome3

**** Drop if prevous primary care or secondary care self harm
drop if selfharm==1
drop if bl_intselfharm==1

**** RUN THE REGRESSION SCRIPT
***** Specify macros
local stset "stset time, fail(outcome==1) scale(365.25)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sh30_sensitivity_noselfharm

***** Extract counts info
local countsrowname "No prior self harm"
include scripts/analysis/sh30_TabulateCounts.do

***** Run the do-file
include scripts/analysis/AdjustedSurvival.do




** 2 AGE BANDS
*** 2.1 age 18-64
**** Load imputed dataset (outcome 3)
frames reset
macro drop _all
use data/clean/imputed_sh30_outcome3

**** Restrict based on age at index
keep if ageindex<65

**** RUN THE REGRESSION SCRIPT 
***** Specify macros
include scripts/analysis/model_outcome3.do
local stset "stset time, fail(outcome==1) scale(365.25)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sh30_sensitivity_age18to64_cox

***** Extract counts info
local countsrowname "Aged 18-64"
include scripts/analysis/sh30_TabulateCounts.do

***** Run the regression file
include scripts/analysis/AdjustedSurvival.do


*** 2.2 age 65-99
frames reset
macro drop _all
**** Load imputed dataset (outcome 3)
use data/clean/imputed_sh30_outcome3

**** Restrict based on age at index
keep if ageindex>=65

**** RUN THE REGRESSION SCRIPT 
***** Specify macros
include scripts/analysis/model_outcome3.do
local stset "stset time, fail(outcome==1) scale(365.25)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sh30_sensitivity_age65to99_cox

***** Extract counts info
local countsrowname "Aged 65-99"
include scripts/analysis/sh30_TabulateCounts.do

***** Run the regression file
include scripts/analysis/AdjustedSurvival.do





** 3 CHANGING THE RISK CARRY-OVER WINDOWS
*** 3.1 IGNORE THIRD ANTIDEP
frames reset
macro drop _all

**** Load imputed dataset
use data/clean/imputed_sh30_outcome3

**** Define new enddate variable and recalculate time
drop newstop
egen newstop = rowmin(serioussh_int deathdate eligstop switchenddate30)
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
local savetag sh30_sensitivity_thirdad

***** Extract counts info
local countsrowname "Ignore 3rd antidepressant"
include scripts/analysis/sh30_TabulateCounts.do

***** Run the do-file
include scripts/analysis/AdjustedSurvival.do



*** 3.2 NO CARRY-OVER WINDOW
frames reset
macro drop _all
use data/clean/imputed_sh30_outcome3

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
local savetag sh30_sensitivity_stop0

***** Extract counts info
local countsrowname "No carry-over window"
include scripts/analysis/sh30_TabulateCounts.do

***** Run the do-file
include scripts/analysis/AdjustedSurvival.do



*** 3.3 CARRY-OVER WINDOW // 6 MONTH
frames reset
macro drop _all
use data/clean/imputed_sh30_outcome3

**** redefine time and outcome variables
drop newstop
egen newstop = rowmin(serioussh_int enddate6)
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
local savetag sh30_sensitivity_stop6

***** Extract counts info
local countsrowname "6 month carry-over window"
include scripts/analysis/sh30_TabulateCounts.do

**** Run the do-file
include scripts/analysis/AdjustedSurvival.do



*** 3.4 FOLLOW-UP, IGNORING STOPPING ANTIDEP
frames reset
macro drop _all
use data/clean/imputed_sh30_outcome3

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
local savetag sh30_sensitivity_nostop

***** Extract counts info
local countsrowname "Follow-up to end"
include scripts/analysis/sh30_TabulateCounts.do

***** Run the do-file
include scripts/analysis/AdjustedSurvival.do



** 4 APPLY MAXIMUM FOLLOW-UP
*** 4.1 Censor after 5 years
frames reset
clear
macro drop _all

use data/clean/imputed_sh30_outcome3

***** Specify macros
include scripts/analysis/model_outcome3.do
local stset "stset time, fail(outcome==1) scale(365.25) exit(time 365.25*5)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sh30_sensitivity_max5years

***** Extract counts info
rename outcome outcome2
gen outcome=outcome2 if time<(365.25*5)
rename time time2
gen time = time2 
replace time = . if time >= (365.25*5)

local countsrowname "Max 5 years followup"
include scripts/analysis/sh30_TabulateCounts.do

drop outcome time
rename outcome2 outcome
rename time2 time
*****

***** Run the do-file
include scripts/analysis/AdjustedSurvival.do



*** 4.2 Censor after 1 year
frames reset
clear
macro drop _all

use data/clean/imputed_sh30_outcome3

***** Specify macros
include scripts/analysis/model_outcome3.do
local stset "stset time, fail(outcome==1) scale(365.25) exit(time 365.25)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sh30_sensitivity_max1year

***** Extract counts info
rename outcome outcome2
gen outcome=outcome2 if time<(365.25)
rename time time2
gen time = time2 
replace time = . if time >= (365.25)

local countsrowname "Max 1 year followup"
include scripts/analysis/sh30_TabulateCounts.do

drop outcome time
rename outcome2 outcome
rename time2 time
*****

***** Run the do-file
include scripts/analysis/AdjustedSurvival.do



** 5 Restrict the SSRI comparison group
*** 5.1 All start citalopram
frames reset
clear
macro drop _all

use data/clean/imputed_sh30_outcome3

// NOTE - remove firstaddrug from the model
**** MACROS FOR THE MODELS (no change - firstaddrug is not in model)

**** Keep only if first drug was citalopram
keep if firstaddrug==5

**** Drop SSRI switchers switch to citalopram (presumably none now?)
drop if cohort==2 & secondaddrug==5

**** RUN THE REGRESSION SCRIPT
***** Specify macros
include scripts/analysis/model_outcome3.do
local stset "stset time, fail(outcome==1) scale(365.25)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sh30_sensitivity_startcital

***** Extract counts info
local countsrowname "First ad is citalopram"
include scripts/analysis/sh30_TabulateCounts.do

***** Run the do-file
include scripts/analysis/AdjustedSurvival.do



*** 5.2 All switch to citalopram (drop if firstaddrug is citalopram)
frames reset
clear
macro drop _all

use data/clean/imputed_sh30_outcome3

**** Drop those in SSRI group who aren't prescribed citalopram
drop if cohort==2 & secondaddrug!=5

**** Drop everyone whose first drug was citalopram
drop if firstaddrug==5

**** RUN THE REGRESSION SCRIPT
***** Specify macros
include scripts/analysis/model_outcome3.do
local stset "stset time, fail(outcome==1) scale(365.25)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sh30_sensitivity_switchcital

***** Extract counts info
local countsrowname "Second ad is citalopram"
include scripts/analysis/sh30_TabulateCounts.do

***** Run the do-file
include scripts/analysis/AdjustedSurvival.do



*** 5.3 All switch to fluoxetine (drop if firstaddrug is fluoxetine)
frames reset
clear
macro drop _all

use data/clean/imputed_sh30_outcome3

**** Drop those in SSRI group who aren't prescribed fluoxetine
drop if cohort==2 & secondaddrug!=12

**** Drop everyone whose first drug was fluoxetine
drop if firstaddrug==12

**** RUN THE REGRESSION SCRIPT
***** Specify macros
include scripts/analysis/model_outcome3.do
local stset "stset time, fail(outcome==1) scale(365.25)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sh30_sensitivity_switchfluox

***** Extract counts info
local countsrowname "Second ad is fluoxetine"
include scripts/analysis/sh30_TabulateCounts.do

***** Run the do-file
include scripts/analysis/AdjustedSurvival.do




** 6 CHANGE OUTCOME TO INCLUDE PRIMARY CARE SELF-HARM (includes full model spec)
frames reset
clear
macro drop _all

**** MACROS FOR THE MODELS (removed self harm)
local model i.sex ageindex age2  i.(antipsychotics anxiolytics hypnotics statins substmisuse  pud pancreatitis mentalhealthservices liverdis_mild intellectualdisab insomnia indigestion hypertension diabetes cancer anxiety asthma appetiteloss alcoholmisuse)
// Also specify the imputed vars to include in regression
local imputedvars bmi_i i.(smokestat_i alcoholintake_i) 

**** Load imputed dataset
use data/clean/imputed_sh30_outcome3

**** Drop if prevous primary care or secondary care self harm
drop if selfharm==1
drop if bl_intselfharm==1

**** Redefine outcome to include primary care self-harm
drop newstop
egen newstop = rowmin(serioussh_int enddate30 SHdate)

drop time
gen time = newstop - index

drop outcome
gen outcome=1 if SHdate<=newstop | serioussh_int<=newstop
replace outcome=2 if deathdate<=newstop & outcome!=1
replace outcome = 0 if outcome==.

drop if time==0

***** Specify macros
local stset "stset time, fail(outcome==1) scale(365.25)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sh30_sensitivity_PCselfharm

***** Extract counts info
local countsrowname "Outcome includes primary care self-harm"
include scripts/analysis/sh30_TabulateCounts.do

***** Run the do-file
include scripts/analysis/AdjustedSurvival.do





******
frames reset
capture log close allselfharm30
exit
