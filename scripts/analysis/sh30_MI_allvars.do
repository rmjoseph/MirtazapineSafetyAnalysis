* Created 2021-03-12 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sh30_MI_allvars.do
* Creator:	RMJ
* Date:	20210312
* Desc:	Runs multiple imputation for self harm/suicide (self harm only, and using enddate30)
* Version History:
*	Date	Reference	Update
*	20210312	MI_allvars	Create file (also ignore the split and mod to just self harm)
*************************************

*** Log
capture log close miall30
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/mi_sh30_allvars_`date'.txt", text append name(miall30)
*******

frames reset
clear


******** MULTIPLE IMPUTATION
display "$S_TIME  $S_DATE"
*** MACROS
// outcomes
local outcomes i.outcome

// specification of variables in model
local imputation "(regress) bmi_i (mlogit) ethnicity_i smokestat_i (ologit) townsend_i alcoholintake_i"

// Name identifier for resulting dataset
local tag sh30_allvars

// Specify the imputed variables for the models
include scripts/analysis/model_allvars.do
/** _troubleshooting_ try removing vars with zeros in some of the imputed var groups */
local model age2 agesex invdose ageindex i.sex ///
		lastad1_ddd currentad1_ddd yearindex timetoswitch  ///
		i.(firstaddrug ad1active bl_intselfharm region) ///
		i.(antipsychotics anxiolytics gc hypnotics nsaids opioids statins analgesics) ///
		i.(severe weightloss vte ) ///
		i.(substmisuse sleepapnoea selfharm rheumatological renal) ///
		i.(pvd pud pancreatitis  obesity) ///
		i.(neuropathicpain  mobility migraine mi mentalhealthservices) ///
		i.(intellectualdisab insomnia indigestion ibd) ///
		i.(hypertension hospitaladmi fibromyalgia epilepsy eatingdis) ///
		i.(dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas) ///
		i.(cancer anxiety asthma appetiteloss angina anaemia) ///
		i.(alcoholmisuse af abdompain)
// removed metastatictumour carehome parkinsons palliative ms. liverdis_mod huntingtons aids already removed.
// next removed cancer1year personalitydisorder liverdis_mild legulcer hemiplegia

// Local to add vars to imputation that are not used in propensity score
local extravars totMedOn_allantidep // time2 i.cohortX2years

di "`outcomes' `model' `extravars'"
*** Load data, keeping eligible patients
use if keep1==1 & cohort<=4 using data/clean/final_combined.dta

*** Merge in the dose variables
merge 1:1 patid using "data/clean/avgdose_selfharm30.dta"
// Some patients (those prescribed 3rd antidep on index date) have no avg dose info.
// This will crash the imputation. Fill in with 0s? Technically true.
// Can't drop them as needed for the sensititivy analysis ignoring 3rd antidep.
recode totMedOn* (.=0)

** recode sex 
recode sex (1=0) (2=1)
label drop sex

*** Create new variables as needed
// died
gen died = endreason30==1

// died suicide/self-harm
gen outcome = serioussh_int <= enddate30
replace outcome = 2 if outcome!=1 & died==1

// Follow-up time
egen newstop = rowmin(enddate30 serioussh_int)
gen time = newstop - index

// New terms 
gen age2 = ageindex^2
gen agesex = ageindex*sex
gen invdose = 1/lastad1


*** Run multiple imputation script
include scripts/analysis/MultipleImputation.do  // include allows to local macros to be preserved
display "$S_TIME  $S_DATE"


*********** END
capture log close miall30
frames reset
exit
