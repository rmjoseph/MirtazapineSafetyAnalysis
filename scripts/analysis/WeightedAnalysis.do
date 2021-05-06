* Created 2020-04-17 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	WeightedAnalysis
* Creator:	RMJ
* Date:	20200417
* Desc:	Estimates propensity scores & saves results of weighted models
* Version History:
*	Date	Reference	Update
*	20200417	Regression_Outcome2	Create file
*	20200420	WeightedAnalysis	Add line creating imputation var
*	20200428	WeightedAnalysis	Change $imputedvars $model to local
*	20200429	WeightedAnalysis	Add 'options' macro to weighted model
*	20200507	WeightedAnalysis	Make 'outcome' 'savetag'
*	20200507	WeightedAnalysis	New 'outcome' macro for forcox
*	20200519	WeightedAnalysis	Remove frames reset at end
*	20201013	WeightedAnalysis	Add locals 'split' and 'splitvar'
*	20201013	WeightedAnalysis	Extra rows renaming vars before saving
*	20201022	WeightedAnalysis	Add optional common support code, save patids for counting later
*	20201203	WeightedAnalysis	Fix bug with commonsupport macro - set to 0 if undefined
*	20201203	WeightedAnalysis	Extra rows renaming vars before saving
*************************************


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

** FIND COMMON SUPPORT - find for each prob for each var, repeat over each imp
** (optional)
if "`commonsupport'" == "" {
	local commonsupport 0
	}

if `commonsupport'==1 {
	frame change forcox
	gen csexcl=0

	forvalues P=1/4 {
		sort minp`P'
		replace minp`P'=minp`P'[_N]
		sort maxp`P'
		replace maxp`P'=maxp`P'[1]
		
		replace csexcl=1 if p`P'<minp`P'
		replace csexcl=1 if p`P'>maxp`P'
		}

	bys patid (csexcl): replace csexcl=csexcl[_N]
	sort iteration cohort
	
	frame put patid csexcl, into(patsincommonsup)
	frame patsincommonsup {
		keep if csexcl!=1
		bys patid: keep if _n==1
		}
}

** SURVIVAL ANALYSIS
*NOTE - personal communication, Mark Lunt. Stata doesn't allow imputed weights in stset, so
* run separately then combine using Rubin's rules.

** (a) Run appropriate regression on each of the new datasets and post to new frame
frame create estimates
frame change estimates
gen imputation=.	// 20200420 new line

// Run regression using each of the imputed datasets in turn
forval X = 1/20 {
	frame change forcox
	
	// Post active dataset into a new frame and change to it
	capture frame drop runcox
	frame put if iteration==`X', into(runcox)
	frame change runcox
	
	// stset and regression
	capture tab csexcl
	`stset'
	`split' // aded 2020-10-13
	`splitvar' // aded 2020-10-13
	if `commonsupport' == 1 {
		`regression' if csexcl!=1 `options'	
	} 
	else {
		`regression' `options'	// `options' added 20200429
	}
	
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

replace var = "a_mirtazapine" if var=="b_1m"
replace var = "b_ssri" if var=="b_2s"
replace var = "c_amitriptyline" if var=="b_3a"
replace var = "d_venlafaxine" if var=="b_4v"

replace var = "a_mirtazapine" if var=="1b.cohort"
replace var = "b_ssri" if var=="2.cohort"
replace var = "c_amitriptyline" if var=="3.cohort"
replace var = "d_venlafaxine" if var=="4.cohort"

replace var = "a_mirtazapine" if var=="1b.cohort#0b.split"
replace var = "b_ssri" if var=="2.cohort#0b.split"
replace var = "c_amitriptyline" if var=="3.cohort#0b.split"
replace var = "d_venlafaxine" if var=="4.cohort#0b.split"
replace var = "e_mirtazapine" if var=="1b.cohort#1o.split"
replace var = "f_ssri" if var=="2.cohort#1.split"
replace var = "g_amitriptyline" if var=="3.cohort#1.split"
replace var = "h_venlafaxine" if var=="4.cohort#1.split"

replace var = "a_mirtazapine" if var=="eq1:1b.cohort#0b.split"
replace var = "b_ssri" if var=="eq1:2.cohort#0b.split"
replace var = "c_amitriptyline" if var=="eq1:3.cohort#0b.split"
replace var = "d_venlafaxine" if var=="eq1:4.cohort#0b.split"
replace var = "e_mirtazapine" if var=="eq1:1b.cohort#1o.split"
replace var = "f_ssri" if var=="eq1:2.cohort#1.split"
replace var = "g_amitriptyline" if var=="eq1:3.cohort#1.split"
replace var = "h_venlafaxine" if var=="eq1:4.cohort#1.split"

sort var
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
export delim using outputs/iptw_results_`savetag'.csv, replace


** End
exit
