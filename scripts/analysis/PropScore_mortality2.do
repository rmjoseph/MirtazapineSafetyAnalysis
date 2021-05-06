* Created 2020-10-13 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	PropScore_mortality2
* Creator:	RMJ
* Date:	20201013
* Desc:	Rechecking propensity score after multiple imputation
* Version History:
* Date	Reference	Update
* 20201013	PropScore_mortality2	Create file
*************************************

*** Log
capture log close pscheck1
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/PSChecks2_outcome1_`date'.txt", text append name(pscheck1)
*******

frames reset
set more off
clear

**** PREPARATION
** Load data
frames reset
use data/clean/imputed_outcome1.dta
mi extract 20, clear
count
tab cohort

drop if time==0
count


**** SET UP MODEL INCLUDING THE SIG VARS AND CHECK GOODNESS OF FIT
** Also include asthma as looking at respiratory mortality

include scripts/analysis/model_outcome1.do 
mlogit cohort `model' `imputedvars' , rrr base(1)
mlogitgof	//  chi2(24)=25, p=0.387


**** LOOK AT BALANCE
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
include scripts/analysis/model_outcome1.do 
mlogit cohort `model' `imputedvars' , rrr base(1)

predict p1 p2 p3 p4
gen ps = p1 if cohort==1
replace ps = p2 if cohort==2
replace ps = p3 if cohort==3
replace ps = p4 if cohort==4

gen iptw = 1/ps
gen sw = prob/ps

drop prob


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
svy: regress bmi_i i.cohort 
svy: regress lastad1_ddd i.cohort 
svy: regress yearindex i.cohort 
svy: regress age2 i.cohort 
svy: regress agesex i.cohort 
svy: regress invdose i.cohort 

foreach V of varlist sex smokestat_i alcoholintake_i townsend_i ethnicity_i {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}
	
foreach V of varlist firstaddrug bl_intselfharm antipsychotics anxiolytics gc hypnotics opioids statins analgesics {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}

foreach V of varlist severe cancer1year weightloss vte substmisuse selfharm rheumatological renal {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}

foreach V of varlist pvd pud parkinsons pancreatitis palliative neuropathicpain mobility migraine mi metastatictumour {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}
	
foreach V of varlist legulcer insomnia indigestion hypertension hospitaladmi hemiplegia epilepsy  {
	 di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}
	
foreach V of varlist dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas carehome  {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}
	
foreach V of varlist cancer asthma anxiety appetiteloss angina anaemia alcoholmisuse af {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}	 

// model appears adequately balanced	

*********
frames reset
capture log close pscheck1
exit
	