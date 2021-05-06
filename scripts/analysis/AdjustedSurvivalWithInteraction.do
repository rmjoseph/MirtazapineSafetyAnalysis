* Created 2020-12-07 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	AdjustedSurvivalWithInteraction
* Creator:	RMJ
* Date:	20201207
* Desc:	Runs normal adjusted survival analyses but allowing for interaction term
* Version History:
*	Date	Reference	Update
*	20201207	AdjustedSurvival	Create file
*	20201208	AdjustedSurvivalWithInteraction	Remove capture from mi stsplit
*	20201208	AdjustedSurvivalWithInteraction	Add optional code to avoid omission error
*************************************

frame create results

*** Unadjusted
// Copy to new frame & change frame
frame put *, into(newframe)
frame change newframe

// Remove multiple imputation
mi extract 0, clear

// Set as survival, and split
`stset'
stsplit split, at(2)

// Regression
`regression' i.cohort#i.split i.split `options'

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
`regression' i.cohort#i.split i.split ageindex i.sex `options'

// Append results to the existing results dataset, labelling
tempfile estimates
regsave using "`estimates'"

frame change results
append using "`estimates'"
replace model="agesex" if model==""


*** Fully adjusted
frame change default

// stset and split
mi `stset'
mi stsplit split, at(2)	// removed capture

gen split1 = cohort * (split==2)
gen split2 = cohort * (split!=2)

if "`o_error'" == "" {
	local o_error 0
	}
if `o_error' == 1 {
	replace split1 = cohort2 * (split==2)
	replace split2 = cohort2 * (split!=2)
	}


// Perform regression (split1)
mi estimate, hr noisily: `regression' i.cohort i.split1 `imputedvars' `model' `options'

// Append results to the existing results dataset, labelling
tempfile estimates
regsave using "`estimates'"

frame change results
append using "`estimates'"
replace model="fulladj1" if model==""

// Perform regression (split2)
frame change default
mi estimate, hr noisily: `regression' i.cohort i.split2 `imputedvars' `model' `options'

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

* competing risk + interaction
replace var = "1a_mirtazapine" if var=="eq1:1b.cohort#0b.split"
replace var = "1b_ssri" if var=="eq1:2.cohort#0b.split"
replace var = "1c_amitriptyline" if var=="eq1:3.cohort#0b.split"
replace var = "1d_venlafaxine" if var=="eq1:4.cohort#0b.split"
replace var = "1e_mirtazapine" if var=="eq1:1b.cohort#2o.split"
replace var = "1f_ssri" if var=="eq1:2.cohort#2.split"
replace var = "1g_amitriptyline" if var=="eq1:3.cohort#2.split"
replace var = "1h_venlafaxine" if var=="eq1:4.cohort#2.split"


// Save
export delim using outputs/adjsurvival_`savetag'.csv, replace


exit
