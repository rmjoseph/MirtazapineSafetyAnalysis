* Created 2020-10-13 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	PropScore_allvars2
* Creator:	RMJ
* Date:	20201013
* Desc:	Rechecking propensity score after multiple imputation
* Version History:
* Date	Reference	Update
* 20201013	PropScore_mortality2	Create file
*************************************

*** Log
capture log close pscheckall
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/PSChecks2_allvars_`date'.txt", text append name(pscheckall)
*******

frames reset
set more off
clear

**** PREPARATION
** Load data
frames reset
use data/clean/imputed_allvars.dta
mi extract 20, clear
count
tab cohort

drop if time==0
count


**** SET UP MODEL INCLUDING THE SIG VARS AND CHECK GOODNESS OF FIT

include scripts/analysis/model_allvars.do 
mlogit cohort `model' `imputedvars' , rrr base(1)
mlogitgof	//  chi2(24)=38, p=0.034 - not a good fit?


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
include scripts/analysis/model_allvars.do 
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

graph tw kdensity p1 if cohort==1 || kdensity p1 if cohort==2 || kdensity p1 if cohort==3 || kdensity p1 if cohort==4
graph tw kdensity p2 if cohort==1 || kdensity p2 if cohort==2 || kdensity p2 if cohort==3 || kdensity p2 if cohort==4
graph tw kdensity p3 if cohort==1 || kdensity p3 if cohort==2 || kdensity p3 if cohort==3 || kdensity p3 if cohort==4
graph tw kdensity p4 if cohort==1 || kdensity p4 if cohort==2 || kdensity p4 if cohort==3 || kdensity p4 if cohort==4
// Amitrip not as balanced?


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
	
	
// all the vars seem balanced

*********
frames reset
capture log close pscheckall
exit
	