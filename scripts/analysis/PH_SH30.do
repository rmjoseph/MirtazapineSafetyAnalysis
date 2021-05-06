* Created 2021-03-15 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	PH_SH30.do
* Creator:	RMJ
* Date:	20210315
* Desc:	Testing the proportional hazards assumption for self harm outcome with 30 day carry-over window
* Version History:
*	Date	Reference	Update
*	20210315	PH_SH	Create file
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
drop hescancerev hesmaligev hescancer1year hesmalig1year

** Create variables for survival analysis
egen newend = rowmin(enddate30 serioussh_int)
gen SH = (serioussh_int==newend)
gen time_sh = newend-index
drop newend 
drop if (serioussh_int<=index)
drop if time_sh<=0

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

global model i.sex ageindex age2  i.(antipsychotics anxiolytics hypnotics statins substmisuse selfharm pud pancreatitis mentalhealthservices liverdis_mild intellectualdisab insomnia indigestion hypertension diabetes cancer anxiety asthma appetiteloss alcoholmisuse) bmi_i i.(smokestat_i alcoholintake_i) 


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
stset time_sh, fail(SH) scale(365.25) id(patid)
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
// mirtaz and ssri both diverge from observed over time

**log log plot
stphplot, by(cohort) nolntime plot1opts(msymbol(none)) plot2opts(msymbol(none) ) plot3opts(msymbol(none)) plot4opts(msymbol(none)) // looks ok


***** TEST PH ASSUMPTION, ADJUSTED MODEL
stset time_sh [pw=sw], fail(SH) scale(365.25) id(patid)
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
** similar to adjusted, is divergence for ssri and mirtaz over time.
 
** add an interaction term between cohort and time
stcox i.cohort, tvc(cohort)
// The interaction term is significant

**log log plot
stphplot, by(cohort) nolntime plot1opts(msymbol(none)) plot2opts(msymbol(none) ) plot3opts(msymbol(none)) plot4opts(msymbol(none))
// Looks ok


**** SUMMARY
** Overall tests look ok, possible issue with SSRI group. Looking at events over time, majority are at the start of treatment. Particularly true for SSRIs.
** Do a sensitivity analysis limiting follow-up rather than adding an interaction term.

frames reset
