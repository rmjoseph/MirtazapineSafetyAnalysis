* Created 2020-04-30 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sensitivity_noselfharm
* Creator:	RMJ
* Date:	20200430
* Desc:	Sensitivity analysis restricting to those without prior self-harm
* Version History:
*	Date	Reference	Update
*	20200430	sensitivity_ssri	Create file
*	20200507	sensitivity_noselfharm	Change macro outcome to savetag
*	20200515	sensitivity_noselfharm	Run utility collecting counts info
*	20200521	sensitivity_noselfharm	Remove bl_intselfharm from model
*	20200521	sensitivity_noselfharm	Drop macros between analyses
*	20200521	sensitivity_noselfharm	Repeat for self harm outcome
*	20201013	sensitivity_noselfharm	Update model spec
*	20201013	sensitivity_noselfharm	Add optional stsplit
*	20201022	sensitivity_noselfharm	Bug fix: add id() option and drop macros
*	20201207	sensitivity_noselfharm	Change specn of interaction - use new dofile
*	20201207	sensitivity_noselfharm	Removed the self harm/outcome3 analysis
*************************************

*** Log
capture log close nosh
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/sensitivity_ssri_`date'.txt", text append name(nosh)
*******

frames reset
clear
macro drop _all

/***** RULES
* no previous self-harm record in primary care or secondary care

* NOTE - use adjusted regression, as PS won't be balanced when drop people from groups
* NOTE - all of the outcomes
*****/


******** ALL-CAUSE MORTALITY
**** MACROS FOR THE MODELS (all-cause mortality) (removed selfharm)
local model i.sex ageindex age2 agesex invdose	///
	yearindex lastad1_ddd /// 
	i.( firstaddrug) /// 
	i.(antipsychotics anxiolytics gc hypnotics opioids statins analgesics) ///
	i.(severe cancer1year weightloss vte substmisuse  rheumatological renal) ///
	i.(pvd pud parkinsons pancreatitis palliative neuropathicpain mobility migraine mi metastatictumour) ///
	i.(legulcer insomnia indigestion hypertension hospitaladmi hemiplegia epilepsy) ///
	i.(dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas carehome) ///
	i.(cancer asthma anxiety appetiteloss angina anaemia alcoholmisuse af)

local imputedvars bmi_i i.(townsend_i smokestat_i alcoholintake_i) ib5.ethnicity_i

*** Load imputed dataset (all-cause mort)
use data/clean/imputed_outcome1

*** Drop if prevous primary care or secondary care self harm
drop if selfharm==1
drop if bl_intselfharm==1

*** Investigate
tab cohort died

*** RUN THE REGRESSION SCRIPT
*** Specify macros
local stset "stset time, fail(died) scale(365.25) id(patid)" // the full stset command
local regression stcox // type of regression
local options  // fill in if using stcrreg
local savetag sensitivity_allcausenoselfharm


***** Extract counts info
local countsrowname "No prior self-harm"
gen outcome=died
include scripts/analysis/TabulateCounts.do
drop outcome
*****

*** Run the do-file
include scripts/analysis/AdjustedSurvivalWithInteraction.do


*** CLOSE
frames reset
capture log close nosh
exit
