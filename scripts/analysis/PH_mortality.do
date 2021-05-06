* Created 2020-10-06 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	PH_mortality.do
* Creator:	RMJ
* Date:	20201006
* Desc:	Testing the proportional hazards assumption
* Version History:
*	Date	Reference	Update
*	20201006	ProportionalHazards_20200820	Create file
*************************************

set more off
clear
 
***** PREPARE DATASET
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

** Make required variables
gen age2 = ageindex*ageindex
gen agesex = ageindex*sex
gen invdose = 1/lastad1_ddd




*******************************
frame put *, into(new)
frame change new 
*******************************

global model age2 agesex invdose	///
	i.sex ageindex ///
	lastad1_ddd yearindex /// 
	i.(firstaddrug bl_intselfharm antipsychotics anxiolytics gc hypnotics opioids statins analgesics severe cancer1year weightloss vte substmisuse selfharm rheumatological renal pvd pud parkinsons pancreatitis palliative neuropathicpain mobility migraine mi metastatictumour legulcer insomnia indigestion hypertension hospitaladmi hemiplegia epilepsy dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas carehome cancer asthma anxiety appetiteloss angina anaemia alcoholmisuse af) ///
	bmi_i i.(townsend_i smokestat_i alcoholintake_i) ib5.ethnicity_i


***** ESTIMATE PS
** probability for stablizing
mlogit cohort
predict p1 p2 p3 p4
gen prob = p1 if cohort==1
replace prob = p2 if cohort==2
replace prob = p3 if cohort==3
replace prob = p4 if cohort==4

** prop score
drop p1-p4
capture drop ps iptw sw
mlogit cohort $model
predict p1 p2 p3 p4
gen ps = p1 if cohort==1
replace ps = p2 if cohort==2
replace ps = p3 if cohort==3
replace ps = p4 if cohort==4

** weights
gen iptw = 1/ps
gen sw = prob/ps


***** TEST PH ASSUMPTION, ADJUSTED MODEL
stset time, fail(died) scale(365.25) id(patid)
stcox i.cohort $model
estat phtest, det // this is non-significant

** Draw KM plots (individual plots for each of the cohorts for clarity)
** mirtazapine
stcoxkm, by(cohort) ///
 obs1opts(msymb(i) ) pred1opts(msymbol(i) ) ///
 obs2opts(msymb(i) lpattern(blank)) pred2opts(msymbol(i) lpattern(blank)) ///
 obs3opts(msymb(i) lpattern(blank)) pred3opts(msymbol(i) lpattern(blank)) ///
 obs4opts(msymb(i) lpattern(blank)) pred4opts(msymbol(i) lpattern(blank)) name(ma, replace)
** fluoxetine
stcoxkm, by(cohort) ///
 obs1opts(msymb(i) lpattern(blank)) pred1opts(msymbol(i) lpattern(blank)) ///
 obs2opts(msymb(i) ) pred2opts(msymbol(i) ) ///
 obs3opts(msymb(i) lpattern(blank)) pred3opts(msymbol(i) lpattern(blank)) ///
 obs4opts(msymb(i) lpattern(blank)) pred4opts(msymbol(i) lpattern(blank)) name(sa, replace)
** amitriptyline
stcoxkm, by(cohort) ///
 obs1opts(msymb(i) lpattern(blank)) pred1opts(msymbol(i) lpattern(blank)) ///
 obs2opts(msymb(i) lpattern(blank)) pred2opts(msymbol(i) lpattern(blank)) ///
 obs3opts(msymb(i) ) pred3opts(msymbol(i) ) ///
 obs4opts(msymb(i) lpattern(blank)) pred4opts(msymbol(i) lpattern(blank)) name(aa, replace)
** venlafaxine
stcoxkm, by(cohort) ///
 obs1opts(msymb(i) lpattern(blank)) pred1opts(msymbol(i) lpattern(blank)) ///
 obs2opts(msymb(i) lpattern(blank)) pred2opts(msymbol(i) lpattern(blank)) ///
 obs3opts(msymb(i) lpattern(blank)) pred3opts(msymbol(i) lpattern(blank)) ///
 obs4opts(msymb(i) ) pred4opts(msymbol(i) ) name(va, replace)
// Amitrip and venlaf both diverge from observed over time


***** TEST PH ASSUMPTION, ADJUSTED MODEL
stset time [pw=sw], fail(died) scale(365.25) id(patid)
** phtest
stcox i.cohort	
estat phtest, d // Significant, but not supposed to use for weighted

** KM plots
// mirtazapine
stcoxkm, by(cohort) ///
 obs1opts(msymb(i) ) pred1opts(msymbol(i) ) ///
 obs2opts(msymb(i) lpattern(blank)) pred2opts(msymbol(i) lpattern(blank)) ///
 obs3opts(msymb(i) lpattern(blank)) pred3opts(msymbol(i) lpattern(blank)) ///
 obs4opts(msymb(i) lpattern(blank)) pred4opts(msymbol(i) lpattern(blank)) name(mw, replace)
// fluoxetine
stcoxkm, by(cohort) ///
 obs1opts(msymb(i) lpattern(blank)) pred1opts(msymbol(i) lpattern(blank)) ///
 obs2opts(msymb(i) ) pred2opts(msymbol(i) ) ///
 obs3opts(msymb(i) lpattern(blank)) pred3opts(msymbol(i) lpattern(blank)) ///
 obs4opts(msymb(i) lpattern(blank)) pred4opts(msymbol(i) lpattern(blank)) name(sw, replace)
// amitriptyline
stcoxkm, by(cohort) ///
 obs1opts(msymb(i) lpattern(blank)) pred1opts(msymbol(i) lpattern(blank)) ///
 obs2opts(msymb(i) lpattern(blank)) pred2opts(msymbol(i) lpattern(blank)) ///
 obs3opts(msymb(i) ) pred3opts(msymbol(i) ) ///
 obs4opts(msymb(i) lpattern(blank)) pred4opts(msymbol(i) lpattern(blank)) name(aw, replace) 
// venlafaxine
stcoxkm, by(cohort) ///
 obs1opts(msymb(i) lpattern(blank)) pred1opts(msymbol(i) lpattern(blank)) ///
 obs2opts(msymb(i) lpattern(blank)) pred2opts(msymbol(i) lpattern(blank)) ///
 obs3opts(msymb(i) lpattern(blank)) pred3opts(msymbol(i) lpattern(blank)) ///
 obs4opts(msymb(i) ) pred4opts(msymbol(i) ) name(vw, replace)
** similar to adjusted, is divergence for amitrip and venlaf over time.
 
** add an interaction term between cohort and time
stcox i.cohort, tvc(cohort)
// The interaction term is significant

**log log plot
stphplot, by(cohort) nolntime plot1opts(msymbol(none)) plot2opts(msymbol(none) ) plot3opts(msymbol(none)) plot4opts(msymbol(none))
// amitrip diverges from mirtaz around 2, and crosses ssri at around 3-4. Venlafax appears to flatten around 2. 

***** Need to account for PH
** Try various interaction terms
forval X=1/5 {
	stsplit split, at(`X')
	stcox i.cohort i.cohort#i.split
	drop split
	stjoin
	}
// sig interactions for 2 and 5

** split at 2
stsplit split, at(2)
stcox i.cohort i.cohort#i.split, tvc(cohort) // no longer significant
stcox i.cohort i.cohort#i.split
gen interaction = split==2
replace interaction = interaction*cohort
stcox i.cohort i.interaction
estat phtest, det
drop split
drop interaction
stjoin

** split at 2 and 5
stsplit split, at(2 5)
stcox i.cohort i.cohort#i.split, tvc(cohort) // no longer significant

gen i1=(split==2)
gen i2=(split==5)
replace i1=i1*cohort
replace i2=i2*cohort
stcox i.cohort i.cohort#split
stcox i.cohort i.i1 i.i2

drop split
drop i1 i2
stjoin
// this second option gives exactly the same results for cohort as just split2


***** Test split using adjusted regression
stset time, fail(died) scale(365.25) id(patid)
stsplit split, at(2)
gen i1 = split==2
replace i1=i1*cohort
stcox i.cohort $model i.i1
drop split i1
stjoin




***** This is all-cause mortality. What about cause-specific mortality?
gen died_cause = 0
replace died_cause = 1 if died==1 & cod_L1==5	// cardiovasc
replace died_cause = 2 if died==1 & cod_L1==2	// cancer
replace died_cause = 3 if died==1 & cod_L1==9	// respiratory
replace died_cause = 4 if died==1 & cod_L3==9	// suicide (intentional/undetermined) // changed from cod_L2==30
replace died_cause = 5 if died==1 & died_cause == 0	// other death

** cardovasc
stset time [pw=sw], fail(died_cause==1) scale(365.25)
stcox i.cohort , tvc(cohort)
stcox i.cohort // tvc is p==0.049, but does make a slight difference to results (ssri more certainly ns)

stphplot, by(cohort) nolntime plot1opts(msymbol(none)) plot2opts(msymbol(none) ) plot3opts(msymbol(none)) plot4opts(msymbol(none)) // this plot looks mostly ok

** cancer
stset time [pw=sw], fail(died_cause==2) scale(365.25)
stcox i.cohort , tvc(cohort)
stcox i.cohort // tvc is sig. Does affect results. 

stphplot, by(cohort) nolntime plot1opts(msymbol(none)) plot2opts(msymbol(none) ) plot3opts(msymbol(none)) plot4opts(msymbol(none)) // ami and ven level off around2-3, and cross ssri around 4

** respiratory
stset time [pw=sw], fail(died_cause==3) scale(365.25)
stcox i.cohort , tvc(cohort)
stcox i.cohort // tvc p==0.648, but does affect move ssri from sig to p=0.06. 

stphplot, by(cohort) nolntime plot1opts(msymbol(none)) plot2opts(msymbol(none) ) plot3opts(msymbol(none)) plot4opts(msymbol(none)) // looks ok


**** Test impact of a splitting, cancer
stset time [pw=sw], fail(died_cause==2) scale(365.25) id(patid)

forval X=1/5 {
	stsplit split, at(`X')
	gen i1 = split==`X'
	replace i1 = i1*cohort
	stcox i.cohort
	stcox i.cohort i.i1
	stcox i.cohort i.i1, tvc(cohort)
	drop split
	drop i1
	stjoin
	}
// significant interaction term and NS tvc term for t=4 and t=5. Borderline for t=1.
// Effects huge for t=3 to 5, few events?

// try using adj reg, see if helps
stset time, fail(died_cause==2) scale(365.25) id(patid)
stcox i.cohort $model
estat phtest

forval X=1/5 {
	di as result "time = `X'"
	stsplit split, at(`X')
	gen i1 = split==`X'
	replace i1 = i1*cohort
	stcox i.cohort i.i1 $model
	estat phtest
	drop split
	drop i1
	stjoin
	}
// all phtests were fine


**** easier to see in unadjusted?
stcox i.cohort
estat phtest
stcox i.cohort, tvc(cohort)

forval X=1/5 {
	di as error "time = `X'"
	stsplit split, at(`X')
	gen i1 = split==`X'
	replace i1 = i1*cohort
	
	stcox i.cohort i.i1, tvc(cohort)
	stcox i.cohort i.i1 
	estat phtest
	drop split
	drop i1
	stjoin
	}
// all but X=3 have ok phtests and NS tvc results. 2 Might be better as
// the interaction effect sizes seem more reasonable.

stset time [pw=sw], fail(died_cause==2) scale(365.25) id(patid)
stsplit split, at(2)
gen i1 = split==2
replace i1=i1*cohort
stcox i.cohort i.i1, tvc(cohort)
drop split i1
stjoin

// impact on the other CODs?
stset time [pw=sw], fail(died_cause==1) scale(365.25) id(patid)
stsplit split, at(2)
gen i1 = split==2
replace i1=i1*cohort
stcox i.cohort
stcox i.cohort i.i1
stcox i.cohort i.i1, tvc(cohort)
drop split i1
stjoin // tvc is NS, but interaction also NS. Don't include.

stset time [pw=sw], fail(died_cause==3) scale(365.25) id(patid)
stsplit split, at(2)
gen i1 = split==2
replace i1=i1*cohort
stcox i.cohort
stcox i.cohort i.i1
stcox i.cohort i.i1, tvc(cohort)
drop split i1
stjoin //no impact. Don't include.


**** SUMMARY
* for all-cause mortality and cancer death, include split at t=2 years

frames reset
