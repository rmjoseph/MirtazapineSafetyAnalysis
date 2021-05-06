* Created 2020-12-10 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	DoseAdjustedIPTWRegression_AllCause
* Creator:	RMJ
* Date:	20201210
* Desc:	IPTW regression for all cause mort, adjusted for dose
* Version History:
*	Date	Reference	Update
*	20201210	WeightedAnalysis	Create file
*************************************

*** Log
capture log close doseadj2
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/doseadjusted_iptw_outcome1_`date'.txt", text append name(doseadj2)
*******

frames reset
macro drop _all


** Load imputed dataset
frames reset
macro drop _all

use data/clean/imputed_outcome1

** Load the drug exposure dataset
frame create drugs
frame change drugs
use patid died start stop mirtazapine ssri amitriptyline venlafaxine using data/clean/antidepexp_mortality.dta

** Drop exposure periods outside the followup window.
frlink m:1 patid, frame(default)
frget index enddate6, from(default)
format enddate6 %dD/N/CY
drop default
drop if stop<=index
drop if start>=enddate6

** Recode died if death happened after leaving cohort
replace died=0 if start<enddate6 & stop>enddate6
replace stop=enddate6 if start<enddate6 & stop>enddate6


** (a) Estimate probability of cohort ignoring covariates
*NOTE - to calculate stabilized weights as per Xu 2010 (https://doi.org/10.1111/j.1524-4733.2009.00671.x)
frame change default

capture drop p1 - p4
capture drop prob
mlogit cohort, rrr base(1)
predict p1 p2 p3 p4
gen prob = p1 if cohort==1
replace prob = p2 if cohort==2
replace prob = p3 if cohort==3
replace prob = p4 if cohort==4


** (b) Calculate propensity score for each imputed dataset
*NOTE - this step to use the 'within' method recommended by Granger 2019 (https://doi.org/10.1002/sim.8355)
* in which results are combined *after running final regression* rather than
* after estimating propensity scores

// Calculate PS in new frame by keeping one dataset in turn
include scripts/analysis/model_outcome1.do

// Prepare frame to contain estimated weights
frame create forcox
frame change forcox
gen iteration = .
frame change default

// Open loop to calculate PS for the 20 imputed datasets
forval X = 1/20 {

	// Create & change to frame in which each ps will be estimated
	capture frame drop forps
	frame put *, into(forps)
	frame change forps

	// Extract one imputed dataset in turn
	mi extract `X', clear
	
	// Run propensity score model
	capture drop p1-p4
	mlogit cohort `imputedvars' `model', rrr base(1)
	predict p1 p2 p3 p4

	// Four exposure categories
	gen ps = p1 if cohort==1
	replace ps = p2 if cohort==2
	replace ps = p3 if cohort==3
	replace ps = p4 if cohort==4

	// Inverse probability of treatment weight and stabilized weight	
	gen iptw = 1/ps 
	gen sw = prob/ps
	
	// Common support for each probability
	forvalues P= 1/4   {
		bys cohort: egen minp`P' = min(p`P')
		sort minp`P'
		replace minp`P'=minp`P'[_N]
		
		bys cohort: egen maxp`P' = max(p`P')
		sort maxp`P'
		replace maxp`P'= maxp`P'[1]
	}
	
	// Post results to new frame
	keep patid ps iptw sw `outcome' time cohort p1 p2 p3 p4 minp* maxp*
	tempfile temp
	save "`temp'", replace
	frame change forcox
	append using "`temp'"
	replace iteration = `X' if iteration==.
	
	frame change default
	}

** SURVIVAL ANALYSIS
*NOTE - personal communication, Mark Lunt. Stata doesn't allow imputed weights in stset, so
* run separately then combine using Rubin's rules.

** (a) Run appropriate regression on each of the new datasets and post to new frame
frame create estimates
frame change estimates
gen imputation=.

// Run regression using each of the imputed datasets in turn
forval X = 1/20 {
	frame change forcox
	
	// Post active dataset into a new frame and change to it
	capture frame drop runcox
	frame put if iteration==`X', into(runcox)
	
	// Link together the prop scores and the drug exposure windows
	frame change drugs
	capture frame drop copydrugs
	frame put *, into(copydrugs)
	
	frame change copydrugs
	
	frlink m:1 patid, frame(runcox)
	frget *, from(runcox)
	drop runcox
	
	// stset and regression
	capture tab csexcl
	stset stop [pw=sw], origin(index) enter(start) exit(failure) fail(died) scale(365.25) id(patid)
	stsplit split, at(2)
	replace split=(split==2)
	stcox mirtazapine ssri amitriptyline venlafaxine i.cohort#i.split i.split `options'	// `options' added 20200429
	
	// Save results and append to new frame
	tempfile estimates
	regsave using "`estimates'"
	frame change estimates
	append using "`estimates'"
	replace imputation = `X' if imputation==.	
	
	}

	
** (b) Manually apply Rubin's rules
*NOTE - used info from following sources: https://bookdown.org/mwheymans/bookmi/rubins-rules.html#pooling-effect-estimates
* Marshall 2009 (https://dx.doi.org/10.1186%2F1471-2288-9-57)

frame change estimates 

** Pooled parameter estimate (mean)
bys var: egen pooled = sum(coef)
replace pooled = pooled/20

** Within-imputation variance (mean of squared standard error)
gen se2 = stderr*stderr
bys var: egen vw = sum(se2)
replace vw = vw/20
drop se2

** Between-imputation variance (sample variance of estimated parameter)
gen sqd = (coef-pooled)*(coef-pooled)
bys var: egen vb = sum(sqd)
replace vb =vb/(20-1)
drop sqd

** Total variance
gen vtot = vw + vb + vb/20
gen sepooled = sqrt(vtot)

** Calculate HR and CI
gen hr = exp(pooled)
gen cil = exp(pooled - 1.96*sepooled)
gen ciu = exp(pooled + 1.96*sepooled)

** Calculate the inverse of the HR (i.e. the mirtaz/comparitors)
gen pos = 0-pooled
gen hr2 = exp(pos)
gen cil2 = exp(pos - 1.96*sepooled)
gen ciu2 = exp(pos + 1.96*sepooled)

** Tidy
keep var hr sepooled cil ciu hr2 cil2 ciu2 pooled
order var pooled sepooled hr cil ciu hr2 cil2 ciu2
duplicates drop

replace var = "a_mirtazapine" if var=="1b.cohort#0b.split"
replace var = "b_ssri" if var=="2.cohort#0b.split"
replace var = "c_amitriptyline" if var=="3.cohort#0b.split"
replace var = "d_venlafaxine" if var=="4.cohort#0b.split"
replace var = "e_mirtazapine" if var=="1b.cohort#1o.split"
replace var = "f_ssri" if var=="2.cohort#1.split"
replace var = "g_amitriptyline" if var=="3.cohort#1.split"
replace var = "h_venlafaxine" if var=="4.cohort#1.split"

list, clean noobs

gen HR1 = string(hr, "%9.2f") + " (" + string(cil, "%9.2f") + "-" + string(ciu, "%9.2f") + ")"
gen HR2 = string(hr2, "%9.2f") + " (" + string(cil2, "%9.2f") + "-" + string(ciu2, "%9.2f") + ")"
rename var cohort

list cohort HR1 HR2, clean noobs

gen coeff = string(pooled,"%9.3f")
gen se = string(sepooled,"%9.3f")

order cohort coeff se HR1 HR2, last
drop hr-ciu2

** Output
export delim using outputs/doseadj_iptw_allcause.csv, replace


******************
log close doseadj2
exit
