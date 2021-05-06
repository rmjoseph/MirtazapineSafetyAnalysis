* Created 2021-02-24 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	DoseAdjustedAdjRegression_AllCause
* Creator:	RMJ
* Date:	20210224
* Desc:	Adjusted regression, self harm, adjusting for dose
* Version History:
*	Date	Reference	Update
*	20210224	DoseAdjustedAdjRegression_AllCause	Create file
*************************************

*** Log
capture log close doseadj4
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/doseadjusted_adjreg_outcome3_`date'.txt", text append name(doseadj4)
*******

frames reset
macro drop _all

** Load the imputed dataset
use data/clean/imputed_outcome3
sort patid

** Load the drug exposure dataset
frame create drugs
frame change drugs
use patid shevent start stop mirtazapine ssri amitriptyline venlafaxine using data/clean/antidepexp_selfharm.dta

** Drop exposure periods outside the followup window.
frlink m:1 patid, frame(default)
frget index newstop enddate6 serioussh_int outcome, from(default)

format enddate6 newstop  %dD/N/CY
drop default
drop if stop<=index
drop if start>=enddate6
drop if start>=newstop
drop if start>=serioussh_int

** Recode outcome if it happened after leaving cohort
replace shevent=0 if start<newstop & stop>newstop
replace stop=newstop if start<newstop & stop>newstop

** Merge drug info into the imputed dataset
sort patid start
drop outcome

tempfile temp
save "`temp'"
frame change default
mi merge 1:m patid using "`temp'", gen(merged)

drop if _merge==1 // all patients with stop==index==thirdaddate

**** RUN THE ANALYSES
frame create results

** Unadjusted
// Copy to new frame & change frame
frame change default
frame put *, into(newframe)
frame change newframe

// Remove multiple imputation
mi extract 0, clear

// Set as survival
stset stop, origin(index) enter(start) fail(shevent) scale(365.25) id(patid)

// Regression
stcox i.cohort // matches main analysis
stcox i.cohort ageindex i.sex // matches main analysis
stcox mirtazapine ssri amitriptyline venlafaxine i.cohort

// Save results in new frame, naming the model
tempfile estimates
regsave using "`estimates'"

frame change results
append using "`estimates'"
gen model="unadj"



** Age sex adjusted
// Go back to previous frame
frame change newframe

// Regress
stcox mirtazapine ssri amitriptyline venlafaxine i.cohort ageindex i.sex

// Append results to the existing results dataset, labelling
tempfile estimates
regsave using "`estimates'"

frame change results
append using "`estimates'"
replace model="agesex" if model==""



** Fully adjusted
frame change default

// stset
mi stset stop, origin(index) enter(start) fail(shevent) scale(365.25) id(patid)

// regress 
include scripts/analysis/model_outcome3.do 
mi estimate, hr noisily: stcox mirtazapine ssri amitriptyline venlafaxine i.cohort `imputedvars' `model' 

// Append results to the existing results dataset, labelling
tempfile estimates
regsave using "`estimates'"

frame change results
append using "`estimates'"
replace model="fulladj" if model==""




*** Format for output
// Drop the blank rows (comparison groups)
drop if coef==0 & stderr==0

// Calculate HR and confidence interval from coefficient and standard errors
gen hr = exp(coef)
gen cil = exp(coef - 1.96*stderr)
gen ciu = exp(coef + 1.96*stderr)

// Calculate the INVERSE HR (i.e. mirtaz/ssri rather than ssri/mirtaz)
gen pos = 0-coef
gen hr2 = exp(pos)
gen cil2 = exp(pos - 1.96*stderr)
gen ciu2 = exp(pos + 1.96*stderr)

// Create neat string variables of the results
gen HR1 = string(hr, "%9.2f") + " (" + string(cil, "%9.2f") + "-" + string(ciu, "%9.2f") + ")"
gen HR2 = string(hr2, "%9.2f") + " (" + string(cil2, "%9.2f") + "-" + string(ciu2, "%9.2f") + ")"

gen coeff = string(coef,"%9.3f")
gen se = string(stderr,"%9.3f")

// Tidy 
order var coeff se HR1 HR2 model
keep var coeff se HR1 HR2 model

replace var = "c_SSRI" if var=="2.cohort"
replace var = "c_amitriptyline" if var=="3.cohort"
replace var = "c_venlafaxine" if var=="4.cohort"


// Save
export delim using outputs/doseadj_adj_selffharm.csv, replace

log close doseadj4
exit
