* Created 2021-12-01 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sh30_Sensit_CompleteCaseAnalysis
* Creator:	RMJ
* Date:	20211201
* Desc:	Sensitivity analysis for self-harm showing complete case analysis (incs final output)
* Version History:
*	Date	Reference	Update
*	20211201	Sensit_CompleteCaseAnalysis_cod	Create file
*************************************

cd R:/QResearch/CPRD/Mirtazapine

*** Open log file
capture log close compcasesh
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/sensitivity_cc_sh30_`date'.txt", text append name(compcasesh)


**# COMPLETE CASE
frames reset
frame create estimates
frame estimates: gen model=""

**# Load data
use data/clean/imputed_sh30_outcome3
mi extract 0, clear

egen complete = rownonmiss(bmi smokestat alcoholintake)
replace complete = (complete==3)
keep if complete==1

**# Model
local model i.sex ageindex age2  i.(antipsychotics anxiolytics hypnotics statins substmisuse selfharm pud pancreatitis mentalhealthservices liverdis_mild intellectualdisab insomnia indigestion hypertension diabetes cancer anxiety asthma appetiteloss alcoholmisuse) bmi i.smokestat i.alcoholintake
*local imputedvars bmi_i i.(smokestat_i alcoholintake_i) 

**# Unadj probability for stabilisaton
capture drop p1 - p4
mlogit cohort, rrr base(1)
predict p1 p2 p3 p4

gen prob = p1 if cohort==1
replace prob = p2 if cohort==2
replace prob = p3 if cohort==3
replace prob = p4 if cohort==4
drop p1-p4

**# Propensity score estimation
mlogit cohort `model', rrr base(1)
predict p1 p2 p3 p4

// Four exposure categories
gen ps = p1 if cohort==1
replace ps = p2 if cohort==2
replace ps = p3 if cohort==3
replace ps = p4 if cohort==4
drop p1-p4

// Inverse probability of treatment weight and stabilized weight	
gen sw = prob/ps
drop prob ps

**# stset and regression, circulatory system
stset time [pw=sw], fail(outcome==1) scale(365.25) id(patid)
stcrreg i.cohort, compete(outcome==2)

tempfile estimates
regsave using "`estimates'"
frame estimates: append using "`estimates'"
frame estimates: replace model = "SH30 complete case" if model==""	






**# COMPLETE VARIABLES
clear
macro drop _all

**# Load data
use data/clean/imputed_sh30_outcome3
mi extract 0, clear

**# Model
local model i.sex ageindex age2  i.(antipsychotics anxiolytics hypnotics statins substmisuse selfharm pud pancreatitis mentalhealthservices liverdis_mild intellectualdisab insomnia indigestion hypertension diabetes cancer anxiety asthma appetiteloss alcoholmisuse)
*local imputedvars bmi_i i.(smokestat_i alcoholintake_i) 


**# Unadj probability for stabilisaton
capture drop p1 - p4
mlogit cohort, rrr base(1)
predict p1 p2 p3 p4

gen prob = p1 if cohort==1
replace prob = p2 if cohort==2
replace prob = p3 if cohort==3
replace prob = p4 if cohort==4
drop p1-p4

**# Propensity score estimation
mlogit cohort `model', rrr base(1)
predict p1 p2 p3 p4

// Four exposure categories
gen ps = p1 if cohort==1
replace ps = p2 if cohort==2
replace ps = p3 if cohort==3
replace ps = p4 if cohort==4
drop p1-p4

// Inverse probability of treatment weight and stabilized weight	
gen sw = prob/ps
drop prob ps

**# stset and regression, circulatory system
stset time [pw=sw], fail(outcome==1) scale(365.25) id(patid)
stcrreg i.cohort, compete(outcome==2)

tempfile estimates
regsave using "`estimates'"
frame estimates: append using "`estimates'"
frame estimates: replace model = "SH30 complete vars" if model==""	



**# REPORTING
frame change estimates
gen pos = 0-coef
gen hr2 = exp(pos)
gen cil2 = exp(pos - 1.96*stderr)
gen ciu2 = exp(pos + 1.96*stderr)

gen out = string(hr2, "%9.2f") + " (" + string(cil, "%9.2f") + "-" + string(ciu, "%9.2f") + ")"

keep model var out

replace var = "a_mirtazapine" if var=="eq1:1b.cohort"
replace var = "b_ssri" if var=="eq1:2.cohort"
replace var = "c_amitriptyline" if var=="eq1:3.cohort"
replace var = "d_venlafaxine" if var=="eq1:4.cohort"

sort model var

export delim using outputs/SH30_completecasesensit.csv, replace



**# Get counts for time and events
use data/clean/imputed_sh30_outcome3, clear

replace outcome = (outcome==1)
local countsrowname "SH30 complete vars"
include scripts/analysis/sh30_TabulateCounts.do

egen complete = rownonmiss(bmi smokestat alcoholintake)
replace complete = (complete==3)
keep if complete==1

local countsrowname "SH30 complete case"
include scripts/analysis/sh30_TabulateCounts.do
*****



**# Output
clear
import delim using outputs/SH30_completecasesensit.csv, varnames(1)
drop if var=="a_mirtazapine"

sort model var
replace var = substr(var,3,.)
by model: gen J=_n

drop var
rename out HR
reshape wide HR, i(model) j(J)

rename model analysis
merge 1:1 analysis using data/clean/sh30_sensitivitycounts.dta, keep(3) nogen
drop datetime
order analysis obs events totfup

export delim using outputs/SH30_CompleteCaseOutput.csv, replace 



**# Other counts
frames reset
use data/clean/imputed_sh30_outcome3
mi extract 0, clear
egen complete = rownonmiss(bmi smokestat alcoholintake)
replace complete = (complete==3)

drop if index==enddate30

tab complete,m
tab cohort complete if outcome==1, ro
tab cohort complete if outcome==2, ro
tab complete outcome,m


frames reset
capture log close compcasesh
exit
