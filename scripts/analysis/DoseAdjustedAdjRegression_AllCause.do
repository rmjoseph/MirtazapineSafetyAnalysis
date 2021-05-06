* Created 2020-12-10 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	DoseAdjustedAdjRegression_AllCause
* Creator:	RMJ
* Date:	20201210
* Desc:	Adjusted regression, all cause mort, adjusting for dose
* Version History:
*	Date	Reference	Update
*	20201210	AdjustedSurvival	Create file
*************************************

*** Log
capture log close doseadj1
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/doseadjusted_adjreg_outcome1_`date'.txt", text append name(doseadj1)
*******

frames reset
macro drop _all

** Load the imputed dataset
use data/clean/imputed_outcome1
sort patid

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

** Merge drug info into the imputed dataset (need to rename died to merge across)
sort patid start
rename died D

tempfile temp
save "`temp'"
frame change default
mi merge 1:m patid using "`temp'", gen(merged)


**** RUN THE ANALYSES
frame create results

** Unadjusted
// Copy to new frame & change frame
frame change default
frame put *, into(newframe)
frame change newframe

// Remove multiple imputation
mi extract 0, clear

// Set as survival, and split
stset stop, origin(index) enter(start) fail(D) scale(365.25) id(patid)
stsplit split, at(2)

// Regression
stcox mirtazapine ssri amitriptyline venlafaxine i.cohort#i.split i.split

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
stcox mirtazapine ssri amitriptyline venlafaxine i.cohort#i.split i.split ageindex i.sex

// Append results to the existing results dataset, labelling
tempfile estimates
regsave using "`estimates'"

frame change results
append using "`estimates'"
replace model="agesex" if model==""



** Fully adjusted
frame change default

// stset and split
mi stset stop, origin(index) enter(start) fail(D) scale(365.25) id(patid)
mi stsplit split, at(2)

gen split1 = cohort * (split==2)
gen split2 = cohort * (split!=2)

// regress (split1)
include scripts/analysis/model_outcome1.do 
mi estimate, hr noisily: stcox mirtazapine ssri amitriptyline venlafaxine i.cohort i.split1 `imputedvars' `model' 

// Append results to the existing results dataset, labelling
tempfile estimates
regsave using "`estimates'"

frame change results
append using "`estimates'"
replace model="fulladj1" if model==""


// regress (split2)
frame change default
mi estimate, hr noisily: stcox mirtazapine ssri amitriptyline venlafaxine i.cohort i.split2 `imputedvars' `model' 

// Append results to the existing results dataset, labelling
tempfile estimates
regsave using "`estimates'"

frame change results
append using "`estimates'"
replace model="fulladj2" if model==""


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

* cox + interaction
replace var = "1a_mirtazapine" if var=="1b.cohort#0b.split"
replace var = "1b_ssri" if var=="2.cohort#0b.split"
replace var = "1c_amitriptyline" if var=="3.cohort#0b.split"
replace var = "1d_venlafaxine" if var=="4.cohort#0b.split"
replace var = "1e_mirtazapine" if var=="1b.cohort#2o.split"
replace var = "1f_ssri" if var=="2.cohort#2.split"
replace var = "1g_amitriptyline" if var=="3.cohort#2.split"
replace var = "1h_venlafaxine" if var=="4.cohort#2.split"

replace var = "1a_mirtazapine" if var=="1b.cohort" & model=="fulladj1"
replace var = "1b_ssri" if var=="2.cohort" & model=="fulladj1"
replace var = "1c_amitriptyline" if var=="3.cohort" & model=="fulladj1"
replace var = "1d_venlafaxine" if var=="4.cohort" & model=="fulladj1"
replace var = "1e_mirtazapine" if var=="1b.cohort" & model=="fulladj2"
replace var = "1f_ssri" if var=="2.cohort" & model=="fulladj2"
replace var = "1g_amitriptyline" if var=="3.cohort" & model=="fulladj2"
replace var = "1h_venlafaxine" if var=="4.cohort" & model=="fulladj2"


// Save
export delim using outputs/doseadj_adj_allcause.csv, replace

log close doseadj1
exit
