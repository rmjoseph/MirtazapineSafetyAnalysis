* Created 2020-10-05 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	PropScore_mortality1
* Creator:	RMJ
* Date:	20201005
* Desc:	Structured script defining propensity score for mortality
* Version History:
* Date	Reference	Update
* 20201005	BuildingPropensityScoreModels.do	Tidy and annotate code; make sure all vars checked
* 20200105	PropScore_mortality1	Rechecked all vars; new vars are included in the model
*************************************

**** PREPARATION
** Load data
frames reset
use if keep1==1 & cohort<=4 using data/clean/final_combined.dta
count

** Drop extra variables
drop inc_*
drop keep*
drop serioussh*
drop hescancerev hesmaligev hescancer1year hesmalig1year

** Create variables for survival analysis
gen time = enddate6 - index
gen died = endreason6==1
drop if time==0

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



**** BASELINE VARIABLES vs OUTCOME
stset time, fail(died) scale(365.25)

foreach X of varlist firstaddrug ad1active cohort region bl_intselfharm {
	stcox i.`X'
	stcox ageindex i.sex i.`X'
	}

foreach X of varlist lastad1_ddd currentad1_ddd yearindex timetoswitch bmi_i {
	stcox `X'
	stcox ageindex i.sex `X'
	}

foreach X of varlist townsend_i ethnicity_i smokestat_i alcoholintake_i {
	stcox i.`X'
	stcox ageindex i.sex i.`X'
	}

foreach X of varlist antipsychotics-analgesics {
	stcox i.`X'
	stcox ageindex i.sex i.`X'
	}

foreach X of varlist severe-pvd {
	stcox i.`X'
	stcox ageindex i.sex i.`X'
	}

foreach X of varlist pud-legulcer {
	stcox i.`X'
	stcox ageindex i.sex i.`X'
	}

foreach X of varlist intellectualdisab-copd {
	stcox i.`X'
	stcox ageindex i.sex i.`X'
	}

foreach X of varlist chf-abdompain {
	stcox i.`X'
	stcox ageindex i.sex i.`X'
	}


/* Results:
Sig (univariate and/or age-sex adj):
cohort firstaddrug bl_intselfharm lastad1_ddd yearindex bmi_i townsend_i ethnicity_i smokestat_i alcoholintake_i antipsychotics anxiolytics gc hypnotics opioids statins analgesics severe cancer1year weightloss vte substmisuse selfharm rheumatological renal pvd pud parkinsons pancreatitis palliative neuropathicpain mobility migraine mi metastatictumour legulcer insomnia indigestion hypertension hospitaladmi hemiplegia epilepsy dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas carehome cancer anxiety appetiteloss angina anaemia alcoholmisuse af 

Borderline: 
liverdis_mild

Non-sig:
ad1active region currentad1_ddd timetoswitch nsaids sleepapnoea obesity mentalhealthservices liverdis_mod intellectualdisab ibd fibromyalgia asthma 

No/extreme estimates:
schizophrenia personalitydis ms huntingtons eatingdis bipolar aids abdompain
*/


**** SET UP MODEL INCLUDING THE SIG VARS AND CHECK GOODNESS OF FIT
** Also include asthma as looking at respiratory mortality

** define as program so easy to update and rerun
capture program drop FIT
program define FIT

	syntax [varlist(default=none)]
	
	mlogit cohort `varlist'		///
	i.sex ageindex ///
		bmi_i i.smokestat_i i.alcoholintake_i i.townsend_i i.ethnicity_i ///
		lastad1_ddd yearindex /// 
		i.(firstaddrug bl_intselfharm antipsychotics anxiolytics gc hypnotics opioids statins analgesics severe cancer1year weightloss vte substmisuse selfharm rheumatological renal pvd pud parkinsons pancreatitis palliative neuropathicpain mobility migraine mi metastatictumour legulcer insomnia indigestion hypertension hospitaladmi hemiplegia epilepsy dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas carehome cancer asthma anxiety appetiteloss angina anaemia alcoholmisuse af )
	mlogitgof	
	
end	

** First run: no additions
FIT // mlogit chi2(24)=33, p=0.098

** add in age2
gen age2=ageindex^2
FIT age2 // mlogit chi2(24)=20, p=0.705

** add in agesex
gen agesex = ageindex*sex
FIT agesex // mlogit chi2(24)=29, p=0.235
FIT agesex age2 // mlogit chi2(24)=24, p=0.695
* don't need agesex


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
	mlogit cohort `varlist'		///
		i.sex ageindex ///
		bmi_i i.smokestat_i i.alcoholintake_i i.townsend_i i.ethnicity_i ///
		lastad1_ddd yearindex /// 
		i.(firstaddrug bl_intselfharm antipsychotics anxiolytics gc hypnotics opioids statins analgesics severe cancer1year weightloss vte substmisuse selfharm rheumatological renal pvd pud parkinsons pancreatitis palliative neuropathicpain mobility migraine mi metastatictumour legulcer insomnia indigestion hypertension hospitaladmi hemiplegia epilepsy dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas carehome cancer asthma anxiety appetiteloss angina anaemia alcoholmisuse af )
	
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
BAL age2

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

svy: regress ageindex i.cohort 
svy: regress age2 i.cohort 
svy: regress bmi_i i.cohort 
svy: regress lastad1_ddd i.cohort // SIGNIFICANT
svy: regress yearindex i.cohort 

foreach V of varlist sex smokestat_i alcoholintake_i townsend_i ethnicity_i {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}

foreach V of varlist firstaddrug bl_intselfharm antipsychotics anxiolytics gc hypnotics opioids statins {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}

foreach V of varlist analgesics severe cancer1year weightloss vte substmisuse selfharm rheumatological renal pvd {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}

foreach V of varlist pud parkinsons pancreatitis palliative neuropathicpain mobility migraine mi metastatictumour {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}
	
foreach V of varlist legulcer insomnia indigestion hypertension hospitaladmi hemiplegia epilepsy dyspnoea {
	 di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}
	
foreach V of varlist diab_comp diabetes depscale dementia copd chf cerebrovas carehome cancer asthma anxiety {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}
	
foreach V of varlist appetiteloss angina anaemia alcoholmisuse af {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}	 

	
**** EDITS NEEDED: improve balance of lastad1_ddd
** try invdose
gen invdose = 1/lastad1_ddd

FIT age2 invdose // mlogitgof chi2(24)=33, p=0.097 (not v good)
FIT age2 agesex invdose // mlogitgof chi2(24)=31, p=0.165 (better)

qui BAL age2 agesex invdose
fvset base 2 cohort
svyset [pweight=sw]
svy: regress agesex i.cohort
svy: regress ageindex i.cohort 
svy: regress age2 i.cohort 
svy: regress bmi_i i.cohort 
svy: regress lastad1_ddd i.cohort // NOT SIGNIFICANT
svy: regress yearindex i.cohort // SIG, amitrip only
svy: regress invdose i.cohort

** try age*dose instead of invdose
gen agedose = ageindex*lastad1_ddd
FIT age2 agedose // mlogitgof chi2(24)=18, p=0.817 (good)
qui BAL age2 agedose
fvset base 2 cohort
svyset [pweight=sw]

svy: regress agesex i.cohort
svy: regress ageindex i.cohort 
svy: regress age2 i.cohort 
svy: regress bmi_i i.cohort 
svy: regress lastad1_ddd i.cohort // SIG
svy: regress yearindex i.cohort
svy: regress agedose i.cohort // SIG


** try without lastad1_ddd
gen templastad1 = lastad1_ddd
replace lastad1_ddd=1

FIT age2 invdose // mlogitgof chi2(24)=24, p=0.440 (good)
qui BAL age2 invdose
fvset base 2 cohort
svyset [pweight=sw]

svy: regress ageindex i.cohort 
svy: regress bmi_i i.cohort 
svy: regress yearindex i.cohort // SIG, amitrip
svy: regress age2 i.cohort 
svy: regress invdose i.cohort // SIG

FIT age2 invdose agesex // mlogitgof chi2(24)=31, p=0.139 (OK)
qui BAL age2 invdose agesex
fvset base 2 cohort
svyset [pweight=sw]

svy: regress ageindex i.cohort 
svy: regress bmi_i i.cohort 
svy: regress yearindex i.cohort // SIG, amitrip
svy: regress age2 i.cohort 
svy: regress agesex i.cohort
svy: regress invdose i.cohort // SIG

** reverse
replace lastad1_ddd=templastad1


**** EDITS NEEDED: improve balance of yearindex
gen ageyear = ageindex*yearindex
FIT age2 ageyear // mlogitgof chi2(24)=25, p=0.379
FIT age2 ageyear invdose // mlogitgof chi2(24)=43, p=0.010 (poor fit)

gen yeardose = yearindex*invdose
FIT age2 agesex invdose yeardose // mlogitgof chi2(24)=30, p=0.173 (ok fit)
FIT age2 invdose yeardose // mlogitgof chi2(24)=32, p=0.139 (ok fit)

qui BAL age2 invdose yeardose
fvset base 2 cohort
svyset [pweight=sw]

svy: regress ageindex i.cohort 
svy: regress age2 i.cohort 
svy: regress bmi_i i.cohort 
svy: regress lastad1_ddd i.cohort // NS
svy: regress yearindex i.cohort // STILL SIG, amitrip only
svy: regress invdose i.cohort
svy: regress yeardose i.cohort // NS


** leave with yearindex still sig?
** FINAL MODEL THEREFORE INCLUDES age2 agesex invdose
/*
mlogit cohort age2 agesex invdose	///
	i.sex ageindex ///
	bmi_i i.smokestat_i i.alcoholintake_i i.townsend_i i.ethnicity_i ///
	lastad1_ddd yearindex /// 
	i.(firstaddrug bl_intselfharm antipsychotics anxiolytics gc hypnotics opioids statins analgesics severe cancer1year weightloss vte substmisuse selfharm rheumatological renal pvd pud parkinsons pancreatitis palliative neuropathicpain mobility migraine mi metastatictumour legulcer insomnia indigestion hypertension hospitaladmi hemiplegia epilepsy dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas carehome cancer asthma anxiety appetiteloss angina anaemia alcoholmisuse af)
*/
	

	