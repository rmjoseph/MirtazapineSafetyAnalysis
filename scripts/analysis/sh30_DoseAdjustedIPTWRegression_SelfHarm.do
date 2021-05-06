* Created 2021-03-12 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sh30_DoseAdjustedIPTWRegression_SelfHarm
* Creator:	RMJ
* Date:	20210312
* Desc:	IPTW regression for self harm, adjusted for dose (enddate30 analysis)
* Version History:
*	Date	Reference	Update
*	20210312	DoseAdjustedIPTWRegression_SelfHarm	Create file
*************************************

*** Log
capture log close doseadj330
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/sh30_doseadjusted_iptw_outcome3_`date'.txt", text append name(doseadj330)
*******

frames reset
macro drop _all

** PREPARE THE TIME-VARYING EXP DATASET
*** Load the imputed dataset
use data/clean/imputed_sh30_outcome3

*** Load the drug exposure dataset
frame create drugs
frame change drugs
use patid shevent start stop mirtazapine ssri amitriptyline venlafaxine using data/clean/antidepexp_selfharm.dta

*** Drop exposure periods outside the followup window.
frlink m:1 patid, frame(default)
frget indexdate newstop enddate30 serioussh_int outcome, from(default)
drop default

format enddate30 newstop  %dD/N/CY
drop if stop<=index
drop if start>=enddate30
drop if start>=newstop
drop if start>=serioussh_int

** Recode outcome if it happened after leaving cohort
replace shevent=0 if start<newstop & stop>newstop
replace stop=newstop if start<newstop & stop>newstop




** Load imputed dataset & create local macros
frame change default
use data/clean/imputed_sh30_outcome3, clear
include scripts/analysis/model_outcome3.do
local stset "stset stop [pw=sw], fail(shevent==1) scale(365.25) origin(index) enter(start) exit(failure) id(patid)"
local regression "stcox i.cohort"

**********  CALCULATE PROPENSITY SCORE

** (a) Estimate probability of cohort ignoring covariates
*NOTE - to calculate stabilized weights as per Xu 2010 (https://doi.org/10.1111/j.1524-4733.2009.00671.x)
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
gen model=""

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
	drop outcome
	frget *, from(runcox)
	drop runcox
	
	// stset 
	`stset'
	
	// Original regression to check model spec
	`regression'
	tempfile estimates
	regsave using "`estimates'"
	frame change estimates
	append using "`estimates'"
	replace imputation = `X' if imputation==.	
	replace model = "orig" if model == ""
	
	// Model including dose variables
	frame change copydrugs
	`regression' mirtazapine ssri amitriptyline venlafaxine
	tempfile estimates
	regsave using "`estimates'"
	frame change estimates
	append using "`estimates'"
	replace imputation = `X' if imputation==.	
	replace model = "doseadj" if model == ""	
	
	}

	
** (b) Manually apply Rubin's rules
*NOTE - used info from following sources: https://bookdown.org/mwheymans/bookmi/rubins-rules.html#pooling-effect-estimates
* Marshall 2009 (https://dx.doi.org/10.1186%2F1471-2288-9-57)

frame change estimates 

frame put if model=="orig", into(estimates1)
frame put if model=="doseadj", into(estimates2)

forval X=1/2 {
	frame change estimates`X'
	
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

	gen HR1 = string(hr, "%9.2f") + " (" + string(cil, "%9.2f") + "-" + string(ciu, "%9.2f") + ")"
	gen HR2 = string(hr2, "%9.2f") + " (" + string(cil2, "%9.2f") + "-" + string(ciu2, "%9.2f") + ")"

	gen coeff = string(pooled,"%9.3f")
	gen se = string(sepooled,"%9.3f")

	order var coeff se HR1 HR2
	keep var coeff se HR1 HR2

	replace var="c_mirtazapine" if var=="1b.cohort"
	replace var="c_SSRI" if var=="2.cohort"
	replace var="c_amitriptyline" if var=="3.cohort"
	replace var="c_venlafaxine" if var=="4.cohort"

	list, clean noobs

	}

frame change estimates2
gen model = "doseadj"
tempfile temp
save "`temp'"
frame change estimates1
gen model = "orig"
append using "`temp'"


** Output
export delim using outputs/sh30_doseadj_iptw_selfharm.csv, replace


******************
frames reset
log close doseadj330
exit
