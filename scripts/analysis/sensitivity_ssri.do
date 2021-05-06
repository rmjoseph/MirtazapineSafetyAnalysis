* Created 2020-04-29 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sensitivity_ssri
* Creator:	RMJ
* Date:	20200429
* Desc:	Sensitivity analysis restricting to those starting/switching to specific SSRIs
* Version History:
*	Date	Reference	Update
*	20200429	sensitivity_ssri	Create file
*	20200506	sensitivity_ssri	Specify model vars using do-files
*	20200506	sensitivity_ssri	Rename output files to mention outcome
*	20200507	sensitivity_ssri	Change macro outcome to savetag
*	20200515	sensitivity_ssri	Run utility collecting counts info
*	20200521	sensitivity_ssri	Drop macros between analyses
*	20200521	sensitivity_ssri	Remove firstaddrug from model for start citalopram
*	20201013	sensitivity_ssri	Update model spec
*	20201013	sensitivity_ssri	Add optional stsplit
*	20201022	sensitivity_ssri	Add id(patid)
*	20201207	sensitivity_ssri	Change specn of interaction - use new dofile
*	20210415	sensitivity_ssri	BUG fix: start citalopram recode secondaddrug to 5 not 28
*************************************

*** Log
capture log close ssri
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/sensitivity_ssri_`date'.txt", text append name(ssri)
*******

frames reset
clear

/***** RULES
* switch to citalopram
* switch to sertraline
* start citalopram

* NOTE - use adjusted regression, as PS won't be balanced when drop people from groups
*****/




**** SWITCH TO SERTRALINE (all-cause mortality)
frames reset
*** Load imputed dataset (all-cause mort)
use data/clean/imputed_outcome1

*** Drop SSRI switchers who don't switch to sertraline
drop if cohort==2 & secondaddrug!=28

*** Drop everyone whose first drug was sertraline
drop if firstaddrug==28

*** Investigate
tab firstaddrug secondaddrug
tab cohort died

*** RUN THE REGRESSION SCRIPT
*** Specify macros
include scripts/analysis/model_outcome1.do
local stset "stset time, fail(died) scale(365.25) id(patid)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_allcauseswitchsert


***** Extract counts info
local countsrowname "SSRI is sertraline"
gen outcome=died
include scripts/analysis/TabulateCounts.do
drop outcome
*****

*** Run the do-file
include scripts/analysis/AdjustedSurvivalWithInteraction.do



**** SWITCH TO CITALOPRAM (all-cause mortality)
frames reset
macro drop _all
*** Load imputed dataset (all-cause mort)
use data/clean/imputed_outcome1

*** Drop SSRI switchers who don't switch to citalopram
drop if cohort==2 & secondaddrug!=5

*** Drop everyone whose first drug was citalopram
drop if firstaddrug==5

*** Investigate
tab firstaddrug secondaddrug
tab cohort died

*** RUN THE REGRESSION SCRIPT
*** Specify macros
include scripts/analysis/model_outcome1.do
local stset "stset time, fail(died) scale(365.25) id(patid)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_allcauseswitchcita

***** Extract counts info
local countsrowname "SSRI is citalopram"
gen outcome=died
include scripts/analysis/TabulateCounts.do
drop outcome
*****

*** Run the do-file
include scripts/analysis/AdjustedSurvivalWithInteraction.do



**** START CITALOPRAM (all-cause mortality)
frames reset
macro drop _all

// NOTE - remove firstaddrug from the model
local model i.sex ageindex age2 agesex invdose	///
	yearindex lastad1_ddd /// 
	i.(bl_intselfharm ) /// 
	i.(antipsychotics anxiolytics gc hypnotics opioids statins analgesics) ///
	i.(severe cancer1year weightloss vte substmisuse selfharm rheumatological renal) ///
	i.(pvd pud parkinsons pancreatitis palliative neuropathicpain mobility migraine mi metastatictumour) ///
	i.(legulcer insomnia indigestion hypertension hospitaladmi hemiplegia epilepsy) ///
	i.(dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas carehome) ///
	i.(cancer asthma anxiety appetiteloss angina anaemia alcoholmisuse af)

local imputedvars bmi_i i.(townsend_i smokestat_i alcoholintake_i) ib5.ethnicity_i

*** Load imputed dataset (all-cause mort)
use data/clean/imputed_outcome1

*** Keep only if first drug was citalopram
keep if firstaddrug==5

*** Drop SSRI switchers switch to citalopram (presumably none now?)
drop if cohort==2 & secondaddrug==5

*** Investigate
tab firstaddrug secondaddrug
tab cohort died

*** RUN THE REGRESSION SCRIPT
*** Specify macros
include scripts/analysis/model_outcome1.do
local stset "stset time, fail(died) scale(365.25) id(patid)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_allcausestartcita

***** Extract counts info
local countsrowname "All start citalopram"
gen outcome=died
include scripts/analysis/TabulateCounts.do
drop outcome
*****

*** Run the do-file
include scripts/analysis/AdjustedSurvivalWithInteraction.do







*** CLOSE
frames reset
capture log close ssri
exit
