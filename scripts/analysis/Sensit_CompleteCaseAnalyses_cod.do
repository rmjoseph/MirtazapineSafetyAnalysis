* Created 2021-11-25 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	Sensit_CompleteCaseAnalysis_cod
* Creator:	RMJ
* Date:	20211125
* Desc:	Sensitivity analysis for cause spec mortality showing complete case analysis
* Version History:
*	Date	Reference	Update
*	20211125	Sensit_CompleteCaseAnalysis_cod	Create file
*	20211125	Sensit_CompleteCaseAnalysis_cod	Add log commands
*************************************

cd R:/QResearch/CPRD/Mirtazapine

*** Open log file
capture log close compcasecod
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/sensitivity_cc_cod_`date'.txt", text append name(compcasecod)


**# COMPLETE CASE
frames reset
frame create estimates
frame estimates: gen model=""

**# Load data
use data/clean/imputed_outcome2
mi extract 0, clear

egen complete = rownonmiss(bmi townsend smokestat alcoholintake ethnicity)
replace complete = (complete==5)
keep if complete==1

**# Model
local model age2 agesex invdose	///
	i.sex ageindex ///
	lastad1_ddd yearindex /// 
	i.(firstaddrug bl_intselfharm antipsychotics anxiolytics gc hypnotics opioids statins analgesics severe cancer1year weightloss vte substmisuse selfharm rheumatological renal pvd pud parkinsons pancreatitis palliative neuropathicpain mobility migraine mi metastatictumour legulcer insomnia indigestion hypertension hospitaladmi hemiplegia epilepsy dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas carehome cancer asthma anxiety appetiteloss angina anaemia alcoholmisuse af) ///
	smokestat alcoholintake bmi townsend ethnicity

**# Unadj probability for stabilisaton
capture drop p1 - p4
mlogit cohort, rrr base(1)
predict p1 p2 p3 p4

gen prob = p1 if cohort==1
replace prob = p2 if cohort==2
replace prob = p3 if cohort==3
replace prob = p4 if cohort==4
drop p1-p4

**# Propensity score estimation
mlogit cohort `model', rrr base(1)
predict p1 p2 p3 p4

// Four exposure categories
gen ps = p1 if cohort==1
replace ps = p2 if cohort==2
replace ps = p3 if cohort==3
replace ps = p4 if cohort==4
drop p1-p4

// Inverse probability of treatment weight and stabilized weight	
gen sw = prob/ps
drop prob ps

**# stset and regression, circulatory system
stset time [pw=sw], fail(died_cause==1) scale(365.25) id(patid)
stcrreg i.cohort, compete(died_cause== 2 3 4 5)

tempfile estimates
regsave using "`estimates'"
frame estimates: append using "`estimates'"
frame estimates: replace model = "Circulatory syst complete case" if model==""	


**# stset and regression, respiratory system
stset time [pw=sw], fail(died_cause==3) scale(365.25) id(patid)
stcrreg i.cohort, compete(died_cause== 1 2 4 5)

tempfile estimates
regsave using "`estimates'"
frame estimates: append using "`estimates'"
frame estimates: replace model = "Respiratory syst complete case" if model==""	


**# stset and regression, cancer
stset time [pw=sw], fail(died_cause==2) scale(365.25) id(patid)
stsplit split, at(2)
replace split=(split==2)
stcrreg i.cohort#i.split i.split, compete(died_cause== 1 3 4 5)

tempfile estimates
regsave using "`estimates'"
frame estimates: append using "`estimates'"
frame estimates: replace model = "Cancer complete case" if model==""	






**# COMPLETE VARIABLES
clear
macro drop _all

**# Load data
use data/clean/imputed_outcome2
mi extract 0, clear

**# Model
local model age2 agesex invdose	///
	i.sex ageindex ///
	lastad1_ddd yearindex /// 
	i.(firstaddrug bl_intselfharm antipsychotics anxiolytics gc hypnotics opioids statins analgesics severe cancer1year weightloss vte substmisuse selfharm rheumatological renal pvd pud parkinsons pancreatitis palliative neuropathicpain mobility migraine mi metastatictumour legulcer insomnia indigestion hypertension hospitaladmi hemiplegia epilepsy dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas carehome cancer asthma anxiety appetiteloss angina anaemia alcoholmisuse af)

**# Unadj probability for stabilisaton
capture drop p1 - p4
mlogit cohort, rrr base(1)
predict p1 p2 p3 p4

gen prob = p1 if cohort==1
replace prob = p2 if cohort==2
replace prob = p3 if cohort==3
replace prob = p4 if cohort==4
drop p1-p4

**# Propensity score estimation
mlogit cohort `model', rrr base(1)
predict p1 p2 p3 p4

// Four exposure categories
gen ps = p1 if cohort==1
replace ps = p2 if cohort==2
replace ps = p3 if cohort==3
replace ps = p4 if cohort==4
drop p1-p4

// Inverse probability of treatment weight and stabilized weight	
gen sw = prob/ps
drop prob ps

**# stset and regression, circulatory system
stset time [pw=sw], fail(died_cause==1) scale(365.25) id(patid)
stcrreg i.cohort, compete(died_cause== 2 3 4 5)

tempfile estimates
regsave using "`estimates'"
frame estimates: append using "`estimates'"
frame estimates: replace model = "Circulatory syst complete vars" if model==""	


**# stset and regression, respiratory system
stset time [pw=sw], fail(died_cause==3) scale(365.25) id(patid)
stcrreg i.cohort, compete(died_cause== 1 2 4 5)

tempfile estimates
regsave using "`estimates'"
frame estimates: append using "`estimates'"
frame estimates: replace model = "Respiratory syst complete vars" if model==""	


**# stset and regression, cancer
stset time [pw=sw], fail(died_cause==2) scale(365.25) id(patid)
stsplit split, at(2)
replace split=(split==2)
stcrreg i.cohort#i.split i.split, compete(died_cause== 1 3 4 5)

tempfile estimates
regsave using "`estimates'"
frame estimates: append using "`estimates'"
frame estimates: replace model = "Cancer complete vars" if model==""	


**# REPORTING
frame change estimates
gen pos = 0-coef
gen hr2 = exp(pos)
gen cil2 = exp(pos - 1.96*stderr)
gen ciu2 = exp(pos + 1.96*stderr)

gen out = string(hr2, "%9.2f") + " (" + string(cil, "%9.2f") + "-" + string(ciu, "%9.2f") + ")"

keep model var out

replace var = "a_mirtazapine" if var=="eq1:1b.cohort"
replace var = "b_ssri" if var=="eq1:2.cohort"
replace var = "c_amitriptyline" if var=="eq1:3.cohort"
replace var = "d_venlafaxine" if var=="eq1:4.cohort"


replace var = "a_mirtazapine" if var=="eq1:1b.cohort#0b.split"
replace var = "b_ssri" if var=="eq1:2.cohort#0b.split"
replace var = "c_amitriptyline" if var=="eq1:3.cohort#0b.split"
replace var = "d_venlafaxine" if var=="eq1:4.cohort#0b.split"
replace var = "e_mirtazapine" if var=="eq1:1b.cohort#1o.split"
replace var = "f_ssri" if var=="eq1:2.cohort#1.split"
replace var = "g_amitriptyline" if var=="eq1:3.cohort#1.split"
replace var = "h_venlafaxine" if var=="eq1:4.cohort#1.split"
sort model var

export delim using outputs/mortality_completecasesensit_cod.csv, replace


**# Other counts
frames reset
use data/clean/imputed_outdcome2
mi extract 0, clear
egen complete = rownonmiss(bmi townsend smokestat alcoholintake ethnicity)
replace complete = (complete==5)

drop if index==enddate6

tab cohort complete if died_cause==1, ro
tab cohort complete if died_cause==2, ro
tab cohort complete if died_cause==3, ro



frames reset
capture log close compcasecod
exit
