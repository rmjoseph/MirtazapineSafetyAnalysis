* Created 2021-03-12 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sh30_MI_outcome3.do
* Creator:	RMJ
* Date:	20210312
* Desc:	Runs multiple imputation for self harm/suicide (using enddate30)
* Version History:
*	Date	Reference	Update
*	20210312	Regression_Outcome3_v2	Create file
*************************************

*** Log
capture log close mi330
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/sh30_mi_outcome3_`date'.txt", text append name(mi330)
*******

frames reset
clear


******** MULTIPLE IMPUTATION
display "$S_TIME  $S_DATE"
*** MACROS
// outcomes
local outcomes i.outcome 

// specification of variables in model
local imputation "(regress) bmi_i (mlogit) smokestat_i (ologit) alcoholintake_i"

// Name identifier for resulting dataset
local tag sh30_outcome3

// Specify the imputed variables for the models
include scripts/analysis/model_outcome3.do

// Local to add vars to imputation that are not used in propensity score
local extravars totMedOn_ssri totMedOn_amitriptyline totMedOn_venlafaxine totMedOn_mirtazapine 


*** Load data, keeping eligible patients
use if keep1==1 & cohort<=4 using data/clean/final_combined.dta

*** Merge in the dose variables
merge 1:1 patid using "data/clean/avgdose_selfharm.dta" // RMJ 2021-02-23 changed from avgdose_mortality
// Some patients (those prescribed 3rd antidep on index date) have no avg dose info.
// This will crash the imputation. Fill in with 0s? Technically true.
// Can't drop them as needed for the sensititivy analysis ignoring 3rd antidep.
recode totMedOn* (.=0)

** recode sex 
recode sex (1=0) (2=1)
label drop sex

*** Create new variables as needed
// Outcome
gen outcome = serioussh_int <= enddate30
gen died = endreason30==1
replace outcome = 2 if outcome!=1 & died==1

// Follow-up time
egen newstop = rowmin(enddate30 serioussh_int)
gen time = newstop - index

// New terms 
gen age2 = ageindex^2
*gen agesex = ageindex*sex // RMJ 09-10-2020 Updated model only needs age2

*** Keep only if no prior serious self-harm
drop if time<0
drop if serioussh_int==index

*** Run multiple imputation script
include scripts/analysis/MultipleImputation.do  // include allows to local macros to be preserved
display "$S_TIME  $S_DATE"


*********** END
capture log close mi330
frames reset
exit

