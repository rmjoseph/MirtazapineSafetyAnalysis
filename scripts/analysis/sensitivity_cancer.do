* Created 2020-04-30 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sensitivity_cancer
* Creator:	RMJ
* Date:	20200430
* Desc:	Sensitivity analysis restricting to those without baseline cancer record
* Version History:
*	Date	Reference	Update
*	20200430	sensitivity_ssri	Create file
*	20200507	sensitivity_cancer	Change macro outcome to savetag
*	20200515	sensitivity_cancer	Run utility collecting counts info
*	20200521	sensitivity_cancer	Drop macros between analyses
*	20200521	sensitivity_cancer	Remove cancer1year and metastatictumour from model
*	20200521	sensitivity_cancer	Add section for cancer mortality
*	20201013	sensitivity_cancer	Update model spec
*	20201013	sensitivity_cancer	Add optional stsplit
*	20201022	sensitivity_cancer	Add id() to stsplit
*	20201022	sensitivity_cancer	collapse split categories to prevent omission error (allcause only)
*	20201207	sensitivity_cancer	Change specn of interaction - use new dofile
*************************************

*** Log
capture log close cancer
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/sensitivity_cancer_`date'.txt", text append name(cancer)
*******

frames reset
clear
macro drop _all

/***** RULES
* Drop if have (ever) baseline cancer in primary care records

* NOTE - full for all-cause mortality and for cause-specific (cancer)
*****/


**** ALL-CAUSE MORTALITY
**** MACROS FOR THE MODELS (all-cause mortality) (remove cancer cancer1year metastatictumour)
local model i.sex ageindex age2 agesex invdose	///
	yearindex lastad1_ddd /// 
	i.(bl_intselfharm firstaddrug) /// 
	i.(antipsychotics anxiolytics gc hypnotics opioids statins analgesics) ///
	i.(severe  weightloss vte substmisuse selfharm rheumatological renal) ///
	i.(pvd pud parkinsons pancreatitis palliative neuropathicpain mobility migraine mi ) ///
	i.(legulcer insomnia indigestion hypertension hospitaladmi hemiplegia epilepsy) ///
	i.(dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas carehome) ///
	i.( asthma anxiety appetiteloss angina anaemia alcoholmisuse af)

local imputedvars bmi_i i.(townsend_i smokestat_i alcoholintake_i) ib5.ethnicity_i


*** Load imputed dataset (all-cause mort)
use data/clean/imputed_outcome1

gen cohort2 = cohort	// to collapse split categories, prevent regression crash
replace cohort2 = 3 if cohort==4	// to collapse split categories, prevent regression crash
local o_error 1	// local allows use of cohort2 in creating interactions (avoids omission error) 

*** Drop those who have cancer record at baseline
drop if cancer==1

*** Investigate
tab cohort died
gen months = round(time/(365.25/12),.1)
tabstat months, by(cohort) stat(median p25 p75)

*** RUN THE REGRESSION SCRIPT
*** Specify macros
local stset "stset time, fail(died) scale(365.25) id(patid)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_allcausecancer

***** Extract counts info
local countsrowname "No prior cancer"
gen outcome=died
include scripts/analysis/TabulateCounts.do
drop outcome
*****

*** Run the do-file
include scripts/analysis/AdjustedSurvivalWithInteraction.do



**** CANCER MORTALITY
frames reset
macro drop _all
**** MACROS FOR THE MODELS (cause-specific mort) (remove cancer cancer1year metastatictumour)
local model i.sex ageindex age2 agesex invdose	///
	yearindex lastad1_ddd /// 
	i.(bl_intselfharm firstaddrug) /// 
	i.(antipsychotics anxiolytics gc hypnotics opioids statins analgesics) ///
	i.(severe  weightloss vte substmisuse selfharm rheumatological renal) ///
	i.(pvd pud parkinsons pancreatitis palliative neuropathicpain mobility migraine mi ) ///
	i.(legulcer insomnia indigestion hypertension hospitaladmi hemiplegia epilepsy) ///
	i.(dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas carehome) ///
	i.( asthma anxiety appetiteloss angina anaemia alcoholmisuse af)

local imputedvars bmi_i i.(townsend_i smokestat_i alcoholintake_i) ib5.ethnicity_i

*** Load imputed dataset (all-cause mort)
use data/clean/imputed_outcome2

*** Drop those who have cancer record at baseline
drop if cancer==1

*** RUN THE REGRESSION SCRIPT
*** Specify macros
local stset "stset time, fail(died_cause==2) scale(365.25) id(patid)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_cancercancer


***** Extract counts info
local countsrowname "No prior cancer: cancer mort"
gen outcome=(died_cause==2)
include scripts/analysis/TabulateCounts.do
drop outcome
*****

*** Run the do-file
include scripts/analysis/AdjustedSurvivalWithInteraction.do

*** CLOSE
frames reset
log close cancer
exit
