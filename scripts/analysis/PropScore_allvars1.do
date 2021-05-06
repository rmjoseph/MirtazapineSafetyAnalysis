* Created 2020-10-06 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	PropScore_allvars1
* Creator:	RMJ
* Date:	20201006
* Desc:	Structured script defining propensity score for all variables
* Version History:
* Date	Reference	Update
* 20200106	PropScore_mortality1	
*************************************

**** PREPARATION
** Load data
frames reset
use if keep1==1 & cohort<=4 using data/clean/final_combined.dta
count
drop if enddate6 <= index

** Drop extra variables
drop inc_*
drop keep*
drop serioussh*
drop hescancerev hesmaligev hescancer1year hesmalig1year

** Recode sex and firstaddrug variables
recode sex (1=0) (2=1)
label drop sex
replace firstaddrug = 5 if firstaddrug==14

** Fill-in missing values
gen townsend_i=townsend
replace townsend_i=3 if townsend_i==.
gen ethnicity_i = ethnicity
replace ethnicity_i=5 if ethnicity_i==.
gen smokestat_i = smokestat
replace smokestat_i=1 if smokestat_i==.
gen alcoholintake_i = alcoholintake
replace alcoholintake_i=3 if alcoholintake_i==.
bys cohort sex: egen meanbmi = mean(bmi)
gen bmi_i = bmi
replace bmi_i = meanbmi if bmi==.
drop meanbmi

** Drop variables with low numbers of patients
drop bipolar schizophrenia
keep patid cohort firstaddrug ad1active lastad1_ddd currentad1_ddd bl_intselfharm sex region ageindex antipsychotics-abdompain yearindex timetoswitch townsend_i ethnicity_i smokestat_i alcoholintake_i bmi_i
drop depsev testseverity
order patid cohort lastad1_ddd currentad1_ddd ageindex yearindex timetoswitch bmi_i townsend_i ethnicity_i smokestat_i alcoholintake_i

foreach X of varlist antipsychotics-abdompain {
		
		qui count if `X'==1
		di "`X' = `r(N)'"
}

// liverdis_mod huntingtons aids <20
drop liverdis_mod huntingtons aids




**** SET UP MODEL INCLUDING ALL REMAINING VARS AND CHECK GOODNESS OF FIT
** define as program so easy to update and rerun
capture program drop FIT
program define FIT

	syntax [varlist(default=none)]
	mlogit cohort `varlist' ageindex i.sex ///
		lastad1_ddd currentad1_ddd yearindex timetoswitch bmi_i ///
		i.(townsend_i ethnicity_i smokestat_i alcoholintake_i) ///
		i.(firstaddrug ad1active bl_intselfharm region) ///
		i.(antipsychotics anxiolytics gc hypnotics nsaids opioids statins analgesics) ///
		i.(severe cancer1year weightloss vte ) ///
		i.(substmisuse sleepapnoea selfharm rheumatological renal) ///
		i.(pvd pud personalitydis parkinsons pancreatitis palliative obesity) ///
		i.(neuropathicpain ms mobility migraine mi metastatictumour mentalhealthservices) ///
		i.(liverdis_mild legulcer intellectualdisab insomnia indigestion ibd) ///
		i.(hypertension hospitaladmi hemiplegia fibromyalgia epilepsy eatingdis) ///
		i.(dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas) ///
		i.(carehome cancer anxiety asthma appetiteloss angina anaemia) ///
		i.(alcoholmisuse af abdompain)
	mlogitgof

end

** First run: no additions
FIT // mlogit chi2(24)==42, p==0.012

** add in age2
gen age2=ageindex^2
FIT age2 // mlogit chi2(24)=27, p=0.303

** add in agesex
gen agesex = ageindex*sex
FIT agesex // mlogit chi2(24)=33, p=0.109
FIT agesex age2 // mlogit chi2(24)=23, p=0.547
* add age2 and agesex 


**** LOOK AT BALANCE
** Define program to make easier to tweak
capture program drop BAL
program define BAL
	
	syntax [varlist(default=none)]

	
	** probability for stablizing
	capture drop p1-p4
	capture drop prob

	mlogit cohort
	predict p1 p2 p3 p4
	gen prob = p1 if cohort==1
	replace prob = p2 if cohort==2
	replace prob = p3 if cohort==3
	replace prob = p4 if cohort==4
	
	** prop score
	drop p1-p4
	capture drop ps iptw sw
	mlogit cohort `varlist' ageindex i.sex ///
		lastad1_ddd currentad1_ddd yearindex timetoswitch bmi_i ///
		i.(townsend_i ethnicity_i smokestat_i alcoholintake_i) ///
		i.(firstaddrug ad1active bl_intselfharm region) ///
		i.(antipsychotics anxiolytics gc hypnotics nsaids opioids statins analgesics) ///
		i.(severe cancer1year weightloss vte ) ///
		i.(substmisuse sleepapnoea selfharm rheumatological renal) ///
		i.(pvd pud personalitydis parkinsons pancreatitis palliative obesity) ///
		i.(neuropathicpain ms mobility migraine mi metastatictumour mentalhealthservices) ///
		i.(liverdis_mild legulcer intellectualdisab insomnia indigestion ibd) ///
		i.(hypertension hospitaladmi hemiplegia fibromyalgia epilepsy eatingdis) ///
		i.(dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas) ///
		i.(carehome cancer anxiety asthma appetiteloss angina anaemia) ///
		i.(alcoholmisuse af abdompain)
	
	predict p1 p2 p3 p4
	gen ps = p1 if cohort==1
	replace ps = p2 if cohort==2
	replace ps = p3 if cohort==3
	replace ps = p4 if cohort==4

	gen iptw = 1/ps
	gen sw = prob/ps
	
	drop prob
end

** Run
BAL age2 agesex

** Do scores overlap?
graph box p1, over(cohort) name(p1, replace)
graph box p2, over(cohort) name(p2, replace)
graph box p3, over(cohort) name(p3, replace)
graph box p4, over(cohort) name(p4, replace)
// looks ok

graph tw kdensity p1 if cohort==1 || kdensity p1 if cohort==2 || kdensity p1 if cohort==3 || kdensity p1 if cohort==4
graph tw kdensity p2 if cohort==1 || kdensity p2 if cohort==2 || kdensity p2 if cohort==3 || kdensity p2 if cohort==4
graph tw kdensity p3 if cohort==1 || kdensity p3 if cohort==2 || kdensity p3 if cohort==3 || kdensity p3 if cohort==4
graph tw kdensity p4 if cohort==1 || kdensity p4 if cohort==2 || kdensity p4 if cohort==3 || kdensity p4 if cohort==4
// Looks ok, although amitrip isn't as good


** Are comparisons between groups non-sig?
fvset base 2 cohort
svyset [pweight=sw]

svy: regress age2 i.cohort 		
svy: regress agesex i.cohort
svy: regress ageindex i.cohort 
svy: regress lastad1_ddd i.cohort // SIG
svy: regress currentad1_ddd i.cohort // SIG
svy: regress yearindex i.cohort 
svy: regress timetoswitch i.cohort 
svy: regress bmi_i i.cohort 

** TRY IMPROVE the dose vars before checking the rest
gen invdose = 1/lastad1_ddd
FIT age2 agesex invdose // mlogitgof chi2(24)==32, p==0.129
qui BAL age2 agesex invdose

svyset [pweight=sw]

svy: regress age2 i.cohort 		
svy: regress agesex i.cohort
svy: regress invdose i.cohort
svy: regress ageindex i.cohort 
svy: regress lastad1_ddd i.cohort // NS
svy: regress currentad1_ddd i.cohort // NS
svy: regress yearindex i.cohort 
svy: regress timetoswitch i.cohort 
svy: regress bmi_i i.cohort // mirtaz is SIG
// fixes balance issue with dose vars, makes bmi less balanced but overall NS

** test remaining vars
local vars townsend_i ethnicity_i smokestat_i alcoholintake_i
di as error "=============== BREAK ================"
foreach V of local vars {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}

local vars firstaddrug ad1active bl_intselfharm region
di as error "=============== BREAK ================"
foreach V of local vars {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}
	
local  vars antipsychotics anxiolytics gc hypnotics nsaids opioids statins analgesics
di as error "=============== BREAK ================"
foreach V of local vars {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}
	
local  vars severe cancer1year weightloss vte 
di as error "=============== BREAK ================"
foreach V of local vars {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}
	
local vars  substmisuse sleepapnoea selfharm rheumatological renal
di as error "=============== BREAK ================"
foreach V of local vars {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}
	
local vars  pvd pud personalitydis parkinsons pancreatitis palliative obesity
di as error "=============== BREAK ================"
foreach V of local vars {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}
	
local vars neuropathicpain ms mobility migraine mi metastatictumour mentalhealthservices
di as error "=============== BREAK ================"
foreach V of local vars {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}
	
local  vars liverdis_mild legulcer intellectualdisab insomnia indigestion ibd
di as error "=============== BREAK ================"
foreach V of local vars {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}
	
local  vars hypertension hospitaladmi hemiplegia fibromyalgia epilepsy eatingdis
di as error "=============== BREAK ================"
foreach V of local vars {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}
	
local  vars dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas
di as error "=============== BREAK ================"
foreach V of local vars {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}
	
local  vars carehome cancer anxiety asthma appetiteloss angina anaemia
di as error "=============== BREAK ================"
foreach V of local vars {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}
	
local  vars alcoholmisuse af abdompain
di as error "=============== BREAK ================"
foreach V of local vars {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}
	
// all ok



** FINAL MODEL THEREFORE INCLUDES age2 agesex invdose
/*
	mlogit cohort age2 agesex invdose ageindex i.sex ///
		lastad1_ddd currentad1_ddd yearindex timetoswitch bmi_i ///
		i.(townsend_i ethnicity_i smokestat_i alcoholintake_i) ///
		i.(firstaddrug ad1active bl_intselfharm region) ///
		i.(antipsychotics anxiolytics gc hypnotics nsaids opioids statins analgesics) ///
		i.(severe cancer1year weightloss vte ) ///
		i.(substmisuse sleepapnoea selfharm rheumatological renal) ///
		i.(pvd pud personalitydis parkinsons pancreatitis palliative obesity) ///
		i.(neuropathicpain ms mobility migraine mi metastatictumour mentalhealthservices) ///
		i.(liverdis_mild legulcer intellectualdisab insomnia indigestion ibd) ///
		i.(hypertension hospitaladmi hemiplegia fibromyalgia epilepsy eatingdis) ///
		i.(dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas) ///
		i.(carehome cancer anxiety asthma appetiteloss angina anaemia) ///
		i.(alcoholmisuse af abdompain)
*/
	

	