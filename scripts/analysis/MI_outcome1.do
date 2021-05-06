* Created 2020-10-09 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	MI_outcome1.do
* Creator:	RMJ
* Date:	20201009
* Desc:	Runs multiple imputation for all-cause mortality
* Version History:
*	Date	Reference	Update
*	20201009	Regression_Outcome1_v2	Create file
*	20201009	MI_outcome1	Simplify extravars for convergence
*	20201012	MI_outcome1	Bug fix: time>= 2*365.25, not 2
*************************************

*** Log
capture log close mi1
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/mi_outcome1_`date'.txt", text append name(mi1)
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
local tag outcome1

// Specify the imputed variables for the models
include scripts/analysis/model_outcome1.do

// Local to add vars to imputation that are not used in propensity score
local extravars i.cohortX2years // converges (now fixed definition)
local extravars totMedOn_allantidep i.cohortX2years 

di "`outcomes' `model' `extravars'" 

*** Load data, keeping eligible patients
use if keep1==1 & cohort<=4 using data/clean/final_combined.dta

*** Merge in the dose variables
merge 1:1 patid using "data/clean/avgdose_mortality.dta"
// Some patients (those prescribed 3rd antidep on index date) have no avg dose info.
// This will crash the imputation. Fill in with 0s? Technically true.
// Can't drop them as needed for the sensititivy analysis ignoring 3rd antidep.
recode totMedOn* (.=0)

** recode sex 
recode sex (1=0) (2=1)
label drop sex

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

*** Run multiple imputation script
include scripts/analysis/MultipleImputation.do  // include allows to local macros to be preserved
display "$S_TIME  $S_DATE"


*********** END
capture log close mi1
frames reset
exit

