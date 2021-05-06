* Created 2020-04-28 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	AdjustedSurvival
* Creator:	RMJ
* Date:	20200428
* Desc:	Runs normal adjusted survival analyses
* Version History:
*	Date	Reference	Update
*	20200428	AdjustedSurvival	Create file
*	20200507	AdjustedSurvival	Rename `outcome' `savetag'
*	20201013	AdjustedSurvival	Add optional stsplit and var
*	20201020	AdjustedSurvival	Add 'noisily' option to troubleshoot stcrreg
*	20201203	AdjustedSurvival	Remove space before 'addsplitvar' 
*	20201207	AdjustedSurvival	Fix error - interaction in agesex was with sex not cohort
*	20201207	AdjustedSurvival	Rename output row names for clarity
*	20201207	AdjustedSurvival	Remove interaction code
*************************************

frame create results

*** Unadjusted
// Copy to new frame & change frame
frame put *, into(newframe)
frame change newframe

// Remove multiple imputation
mi extract 0, clear

// Regress
`stset'
`regression' i.cohort `options'

// Save results in new frame, naming the model
tempfile estimates
regsave using "`estimates'"

frame change results
use "`estimates'"
gen model="unadj"


*** Age-sex adjusted
// Go back to previous frame
frame change newframe

// Regress
*`stset' // removed 2020-10-13
`regression' i.cohort ageindex i.sex `options'

// Append results to the existing results dataset, labelling
tempfile estimates
regsave using "`estimates'"

frame change results
append using "`estimates'"
replace model="agesex" if model==""


*** Fully adjusted
frame change default

// stset
mi `stset'

// Perform regression
mi estimate, hr noisily: `regression' i.cohort `imputedvars' `model' `options'

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

* competing risk no interaction
replace var = "a_mirtazapine" if var=="eq1:1b.cohort"
replace var = "b_ssri" if var=="eq1:2.cohort"
replace var = "c_amitriptyline" if var=="eq1:3.cohort"
replace var = "d_venlafaxine" if var=="eq1:4.cohort"

* otherwise
replace var = "a_mirtazapine" if var=="1b.cohort"
replace var = "b_ssri" if var=="2.cohort"
replace var = "c_amitriptyline" if var=="3.cohort"
replace var = "d_venlafaxine" if var=="4.cohort"



// Save
export delim using outputs/adjsurvival_`savetag'.csv, replace


exit
