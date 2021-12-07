* Created 2021-11-22 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	Sensit_CompleteCaseAnalysis
* Creator:	RMJ
* Date:	20211122
* Desc:	Sensitivity analysis for mortality showing complete case  analysis not MI
* Version History:
*	Date	Reference	Update
*	20211122	Sensit_CompleteCaseAnalysis	Create file
*	20211124	Sensit_CompleteCaseAnalysis	Add analysis excluding alcohol intake
*************************************

cd R:/QResearch/CPRD/mirtazapine
frames reset

*** Open log file
capture log close compcase
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/sensitivity_completecase_`date'.txt", text append name(compcase)




**********
**# Main analysis, excluding alcohol intake

******** MAIN ANALYSIS - IPTW-adjusted regression
frames reset
macro drop _all
use data/clean/imputed_outcome1

*** Specify macros
local model i.sex ageindex age2 agesex invdose	///
	yearindex lastad1_ddd /// 
	i.(bl_intselfharm firstaddrug) /// 
	i.(antipsychotics anxiolytics gc hypnotics opioids statins analgesics) ///
	i.(severe cancer1year weightloss vte substmisuse selfharm rheumatological renal) ///
	i.(pvd pud parkinsons pancreatitis palliative neuropathicpain mobility migraine mi metastatictumour) ///
	i.(legulcer insomnia indigestion hypertension hospitaladmi hemiplegia epilepsy) ///
	i.(dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas carehome) ///
	i.(cancer asthma anxiety appetiteloss angina anaemia alcoholmisuse af)
local imputedvars bmi_i i.(townsend_i smokestat_i) ib5.ethnicity_i

local stset "stset time [pw=sw], fail(died) scale(365.25) id(patid)"
local split "stsplit split, at(2)"
local splitvar "replace split=(split==2)"
local regression "stcox i.cohort#i.split i.split"
local outcome died
local savetag sensitivity_noalc_allcausemort_s

*** Run the do-file
include scripts/analysis/WeightedAnalysis.do

**************




*** complete case...
capture program drop ANALYSIS
program define ANALYSIS

	syntax , [complete(integer 0)] [imputed(string)] other(string) desc(string)
	
	frame put *, into(TEMPFRAME)
	frame TEMPFRAME {
		*** Unadj probability for stabilisaton
		capture drop p1 - p4
		if `complete'==1 {
			mlogit cohort if complete==1, rrr base(1)
		}
		else {
			mlogit cohort, rrr base(1)
		}
		predict p1 p2 p3 p4

		gen prob = p1 if cohort==1
		replace prob = p2 if cohort==2
		replace prob = p3 if cohort==3
		replace prob = p4 if cohort==4
		drop p1-p4

		*** Propensity score estimation
		mlogit cohort `imputed' `other', rrr base(1)
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

		*** stset and regression
		stset time [pw=sw], fail(died) scale(365.25) id(patid)
		stsplit split, at(2)
		replace split=(split==2)
		stcox i.cohort#i.split i.split

		tempfile estimates
		regsave using "`estimates'"
		frame estimates: append using "`estimates'"
		frame estimates: replace version = "`desc'" if version==""	

		drop sw	
	}	
	frame drop TEMPFRAME
end


** complete case
frames reset
use data/clean/imputed_outcome1
frame put *, into(nomi)
frame change nomi
mi extract 0, clear
drop if index==enddate6

frame create estimates
frame estimates: gen version=""

egen complete = rownonmiss(bmi townsend smokestat alcoholintake ethnicity)
replace complete = (complete==5)

local model i.sex ageindex age2 agesex invdose	///
	yearindex lastad1_ddd /// 
	i.(bl_intselfharm firstaddrug) /// 
	i.(antipsychotics anxiolytics gc hypnotics opioids statins analgesics) ///
	i.(severe cancer1year weightloss vte substmisuse selfharm rheumatological renal) ///
	i.(pvd pud parkinsons pancreatitis palliative neuropathicpain mobility migraine mi metastatictumour) ///
	i.(legulcer insomnia indigestion hypertension hospitaladmi hemiplegia epilepsy) ///
	i.(dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas carehome) ///
	i.(cancer asthma anxiety appetiteloss angina anaemia alcoholmisuse af)

local imputedvars bmi i.(townsend smokestat alcoholintake) ib5.ethnicity

ANALYSIS, complete(1) imputed("`imputedvars'") other("`model'") desc("Complete case")



** Complete variables
local model i.sex ageindex age2 agesex invdose	///
	yearindex lastad1_ddd /// 
	i.(bl_intselfharm firstaddrug) /// 
	i.(antipsychotics anxiolytics gc hypnotics opioids statins analgesics) ///
	i.(severe cancer1year weightloss vte substmisuse selfharm rheumatological renal) ///
	i.(pvd pud parkinsons pancreatitis palliative neuropathicpain mobility migraine mi metastatictumour) ///
	i.(legulcer insomnia indigestion hypertension hospitaladmi hemiplegia epilepsy) ///
	i.(dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas carehome) ///
	i.(cancer asthma anxiety appetiteloss angina anaemia alcoholmisuse af)

local imputedvars 
ANALYSIS, complete(0) other("`model'") desc("Complete variables")


** Complete ignoring alcohol intake
capture drop complete
egen complete = rownonmiss(bmi townsend smokestat ethnicity)
replace complete = (complete==4)

local model i.sex ageindex age2 agesex invdose	///
	yearindex lastad1_ddd /// 
	i.(bl_intselfharm firstaddrug) /// 
	i.(antipsychotics anxiolytics gc hypnotics opioids statins analgesics) ///
	i.(severe cancer1year weightloss vte substmisuse selfharm rheumatological renal) ///
	i.(pvd pud parkinsons pancreatitis palliative neuropathicpain mobility migraine mi metastatictumour) ///
	i.(legulcer insomnia indigestion hypertension hospitaladmi hemiplegia epilepsy) ///
	i.(dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas carehome) ///
	i.(cancer asthma anxiety appetiteloss angina anaemia alcoholmisuse af)

local imputedvars bmi i.(townsend smokestat) ib5.ethnicity

ANALYSIS, complete(1) imputed("`imputedvars'") other("`model'") desc("Complete case ignoring alcohol")



** Complete variables (new alcohol var)
gen alc = 1 if alcoholintake<3
replace alc = 2 if alc==. & alcoholintake!=.
replace alc=2 if alc==.

local model i.sex ageindex age2 agesex invdose	///
	yearindex lastad1_ddd /// 
	i.(bl_intselfharm firstaddrug) /// 
	i.(antipsychotics anxiolytics gc hypnotics opioids statins analgesics) ///
	i.(severe cancer1year weightloss vte substmisuse selfharm rheumatological renal) ///
	i.(pvd pud parkinsons pancreatitis palliative neuropathicpain mobility migraine mi metastatictumour) ///
	i.(legulcer insomnia indigestion hypertension hospitaladmi hemiplegia epilepsy) ///
	i.(dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas carehome) ///
	i.(cancer asthma anxiety appetiteloss angina anaemia alcoholmisuse af) i.alc

local imputedvars 
ANALYSIS, complete(0) other("`model'") desc("different alcohol var")




*** Reporting
frame change estimates

gen pos = 0-coef
gen hr2 = exp(pos)
gen cil2 = exp(pos - 1.96*stderr)
gen ciu2 = exp(pos + 1.96*stderr)

gen out = string(hr2, "%9.2f") + " (" + string(cil, "%9.2f") + "-" + string(ciu, "%9.2f") + ")"

drop if coef==0

keep version var out

replace var = "a_mirtazapine" if var=="1b.cohort#0b.split"
replace var = "b_ssri" if var=="2.cohort#0b.split"
replace var = "c_amitriptyline" if var=="3.cohort#0b.split"
replace var = "d_venlafaxine" if var=="4.cohort#0b.split"
replace var = "e_mirtazapine" if var=="1b.cohort#1o.split"
replace var = "f_ssri" if var=="2.cohort#1.split"
replace var = "g_amitriptyline" if var=="3.cohort#1.split"
replace var = "h_venlafaxine" if var=="4.cohort#1.split"
sort version var

export delim using outputs/mortality_completecasesensit.csv, replace



*** other info

frame change nomi
drop complete
egen complete = rownonmiss(bmi townsend smokestat alcoholintake ethnicity)
replace complete = (complete==5)


gen miss_smok = smokestat==.
gen miss_eth = ethnicity==.
gen miss_bmi = bmi==.
gen miss_townsend = townsend==.
gen miss_alc = alcoholintake==.

tab cohort miss_smok, ro
tab cohort miss_alc, ro
tab cohort miss_bmi, ro
tab cohort miss_eth, ro
tab cohort miss_town, ro

tab cohort complete, ro

tab cohort complete if died==1, ro


capture log close compcase

exit
