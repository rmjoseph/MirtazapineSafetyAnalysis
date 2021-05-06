* Created 2020-10-13 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	PropScore_SH2
* Creator:	RMJ
* Date:	20201013
* Desc:	Rechecking propensity score after multiple imputation
* Version History:
* Date	Reference	Update
* 20201013	PropScore_mortality2	Create file
*************************************

*** Log
capture log close pscheck3
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/PSChecks2_outcome3_`date'.txt", text append name(pscheck3)
*******

frames reset
set more off
clear

**** PREPARATION
** Load data
frames reset
use data/clean/imputed_outcome3.dta
mi extract 20, clear
count
tab cohort

drop if serioussh_int<index
drop if time==0
count


**** SET UP MODEL INCLUDING THE SIG VARS AND CHECK GOODNESS OF FIT
include scripts/analysis/model_outcome3.do 
mlogit cohort `model' `imputedvars' , rrr base(1)
mlogitgof	//  chi2(24)=27, p=0.324


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
include scripts/analysis/model_outcome3.do 
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
// Looks ok

** Are comparisons between groups non-sig?
fvset base 2 cohort
svyset [pweight=sw]

svy: regress ageindex i.cohort 
svy: regress age2 i.cohort 

foreach V of varlist sex smokestat_i alcoholintake_i  {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}
	
foreach V of varlist antipsychotics anxiolytics hypnotics statins substmisuse selfharm pud pancreatitis mentalhealthservices liverdis_mild intellectualdisab insomnia indigestion hypertension diabetes cancer anxiety asthma appetiteloss alcoholmisuse {
	di "**VAR: `V'"
	svy: tab `V' cohort
	di ""
	}

// model appears adequately balanced	

*********
frames reset
capture log close pscheck3
exit
	