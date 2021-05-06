* Created 2020-10-21 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	MI_broadelig.do
* Creator:	RMJ
* Date:	20201009
* Desc:	Runs multiple imputation for all-cause mortality for the broadelig sensitivity analysis
* Version History:
*	Date	Reference	Update
*	20201021	sensitivity_broadeligibility_allcause	Create file	
*************************************

*** Log
capture log close mib
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/mi_broadelig_`date'.txt", text append name(mib)
*******

frames reset
clear


******** MULTIPLE IMPUTATION
display "$S_TIME  $S_DATE"
*** MACROS
// outcomes
local outcomes i.died

// specification of variables in model
local imputation "(regress) bmi_i (mlogit) ethnicity_i smokestat_i (ologit) townsend_i alcoholintake_i"

// Name identifier for resulting dataset
local tag sensit_outcome1_broadelig

// Specify the imputed variables for the models
include scripts/analysis/model_outcome1.do

// Local to add vars to imputation that are not used in propensity score
local extravars i.cohortX2years

// NOT INCLUDING THE DOSE VARS THIS TIME

di "`outcomes' `model' `extravars'" 

*** Load data, keeping eligible patients
use if keep4==1 & cohort<=4 using data/clean/final_combined.dta


** recode sex 
recode sex (1=0) (2=1)
label drop sex
*** Missing sex exists in this dataset. Drop or will cause error. Small n (<5).
drop if sex==.

*** Create new variables as needed
// Outcome
gen died = endreason6==1

// Follow-up time
gen time = enddate6 - index

// New terms 
gen age2 = ageindex^2
gen agesex = ageindex*sex
gen invdose = 1/lastad1

// Interaction with time (analysis will split at 2 years and include split*cohort)
gen cohortX2years = (time>=365.25*2)
replace cohortX2years = cohortX2years * cohort

// INVESTIGATE 
tab cohort died
tabstat time, by(cohort) stat(median p25 p75)

*** Run multiple imputation script
include scripts/analysis/MultipleImputation.do  // include allows to local macros to be preserved
display "$S_TIME  $S_DATE"


*********** END
log close mib
frames reset
exit

