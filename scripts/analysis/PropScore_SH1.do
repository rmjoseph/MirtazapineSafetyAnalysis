* Created 2020-10-05 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	PropScore_SH1
* Creator:	RMJ
* Date:	20201005
* Desc:	Structured script defining propensity score for self harm
* Version History:
* Date	Reference	Update
* 20201005	BuildingPropensityScoreModels.do	Tidy and annotate code; make sure all vars checked
* 20200105	PropScore_SH1	Rechecked all vars; new vars are included in the model
*************************************

**** PREPARATION
** Load data
frames reset
use if keep1==1 & cohort<=4 using data/clean/final_combined.dta
drop if serioussh_int<index
count

** Drop extra variables
drop inc_*
drop keep*
drop serioussh_any
drop hescancerev hesmaligev hescancer1year hesmalig1year

** Create variables for survival analysis
egen newend = rowmin(enddate6 serioussh)
gen SH = serioussh==newend
gen time = newend-index
drop if time==0
drop newend index enddate* endreason*

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
stset time, fail(SH) scale(365.25)

foreach X of varlist firstaddrug ad1active cohort region  {
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
cohort bmi_i smokestat_i alcoholintake_i antipsychotics anxiolytics hypnotics statins  substmisuse selfharm pud pancreatitis mentalhealthservices liverdis_mild intellectualdisab insomnia indigestion hypertension diabetes cancer anxiety asthma appetiteloss alcoholmisuse

Borderline: 
ad1active analgesics

Non-sig:
firstaddrug region lastad1_ddd currentad1_ddd yearindex timetoswitch townsend_i ethnicity_i gc nsaids opioids severe cancer1year weightloss vte sleepapnoea personalitydis obesity neuropathicpain mobility migraine legulcer hospitaladmi epilepsy eatingdis dyspnoea diab_comp depscale copd chf cerebrovas angina anaemia af abdompain

No/extreme estimates:
schizophrenia rheumatological renal pvd parkinsons palliative ms mi metastatictumour liverdis_mod ibd huntingtons hemiplegia fibromyalgia dementia carehome bipolar aids
*/


**** SET UP MODEL INCLUDING THE SIG VARS AND CHECK GOODNESS OF FIT
mlogit cohort i.sex ageindex ///
	bmi_i i.smokestat_i i.alcoholintake_i ///
	i.(antipsychotics anxiolytics hypnotics statins substmisuse selfharm pud pancreatitis mentalhealthservices liverdis_mild intellectualdisab insomnia indigestion hypertension diabetes cancer anxiety asthma appetiteloss alcoholmisuse)
mlogitgof // chi2(24)=80, p=0.000

** add in age2
gen age2=ageindex^2

mlogit cohort i.sex ageindex age2 ///
	bmi_i i.smokestat_i i.alcoholintake_i ///
	i.(antipsychotics anxiolytics hypnotics statins substmisuse selfharm pud pancreatitis mentalhealthservices liverdis_mild intellectualdisab insomnia indigestion hypertension diabetes cancer anxiety asthma appetiteloss alcoholmisuse)
mlogitgof // chi2(24)=24, p=0.465

** add in agesex
gen agesex = ageindex*sex

mlogit cohort i.sex ageindex age2 agesex ///
	bmi_i i.smokestat_i i.alcoholintake_i ///
	i.(antipsychotics anxiolytics hypnotics statins substmisuse selfharm pud pancreatitis mentalhealthservices liverdis_mild intellectualdisab insomnia indigestion hypertension diabetes cancer anxiety asthma appetiteloss alcoholmisuse)
mlogitgof // chi2(24)=24 p=0.323
** don't need agesex


**** LOOK AT BALANCE
** probability for stablizing
mlogit cohort
predict p1 p2 p3 p4
gen prob = p1 if cohort==1
replace prob = p2 if cohort==2
replace prob = p3 if cohort==3
replace prob = p4 if cohort==4

** prop score
drop p1-p4
mlogit cohort i.sex ageindex age2  ///
	bmi_i i.smokestat_i i.alcoholintake_i ///
	i.(antipsychotics anxiolytics hypnotics statins substmisuse selfharm pud pancreatitis mentalhealthservices liverdis_mild intellectualdisab insomnia indigestion hypertension diabetes cancer anxiety asthma appetiteloss alcoholmisuse)
	
predict p1 p2 p3 p4
gen ps = p1 if cohort==1
replace ps = p2 if cohort==2
replace ps = p3 if cohort==3
replace ps = p4 if cohort==4

gen iptw = 1/ps
gen sw = prob/ps

** Do scores overlap?
graph box p1, over(cohort) name(p1, replace)
graph box p2, over(cohort) name(p2, replace)
graph box p3, over(cohort) name(p3, replace)
graph box p4, over(cohort) name(p4, replace)
// looks good

graph tw kdensity p1 if cohort==1 || kdensity p1 if cohort==2 || kdensity p1 if cohort==3 || kdensity p1 if cohort==4
graph tw kdensity p2 if cohort==1 || kdensity p2 if cohort==2 || kdensity p2 if cohort==3 || kdensity p2 if cohort==4
graph tw kdensity p3 if cohort==1 || kdensity p3 if cohort==2 || kdensity p3 if cohort==3 || kdensity p3 if cohort==4
graph tw kdensity p4 if cohort==1 || kdensity p4 if cohort==2 || kdensity p4 if cohort==3 || kdensity p4 if cohort==4
// Looks ok, amitrip slightly separate but not bad


** Are comparisons between groups non-sig?
fvset base 2 cohort
svyset [pweight=sw]

svy: regress ageindex i.cohort 
svy: regress age2 i.cohort 
svy: regress bmi_i i.cohort 

foreach V of varlist sex smokestat_i alcoholintake_i {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}

foreach V of varlist antipsychotics anxiolytics hypnotics statins substmisuse selfharm pud pancreatitis {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}

foreach V of varlist mentalhealthservices liverdis_mild intellectualdisab insomnia indigestion hypertension {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}

foreach V of varlist diabetes cancer anxiety asthma appetiteloss alcoholmisuse {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}
	

** THESE ALL LOOK OK - CAN BE THE FINAL MODEL
/*
mlogit cohort i.sex ageindex age2  ///
	bmi_i i.smokestat_i i.alcoholintake_i ///
	i.(antipsychotics anxiolytics hypnotics statins substmisuse selfharm pud pancreatitis mentalhealthservices liverdis_mild intellectualdisab insomnia indigestion hypertension diabetes cancer anxiety asthma appetiteloss alcoholmisuse)
*/
	

	