* Created 2021-12-01 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sh30_SensitBroadElig
* Creator:	RMJ
* Date:	20211201
* Desc:	Sensitivity analysis with broader eligibility criteria
* Version History:
*	Date	Reference	Update
*	20211201	sh30_SensitBroadElig	Create file
*************************************
** to use imputed dataset would need to rerun imputations using the broader criteria
cd R:/QResearch/CPRD/Mirtazapine

*** Open log file
capture log close broadelig
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/sensitivity_broadelig_sh30_`date'.txt", text append name(broadelig)

**# COMPLETE VARIABLES
frames reset
macro drop _all

**# Set up variables needed
use if keep4==1 & cohort<=4 using data/clean/final_combined.dta // which keep??

** recode sex 
recode sex (1=0) (2=1)
label drop sex
// Missing sex exists in this dataset. Drop or will cause error. Small n (<5).
drop if sex==.

*** Create new variables as needed
// Outcome
gen outcome = serioussh_int <= enddate30
gen died = endreason30==1
replace outcome = 2 if outcome!=1 & died==1

// Follow-up time
egen newstop = rowmin(enddate30 serioussh_int)
gen time = newstop - index

// New terms 
gen age2 = ageindex^2
*gen agesex = ageindex*sex // RMJ 09-10-2020 Updated model only needs age2

*** Keep only if no prior serious self-harm
drop if time<0
drop if serioussh_int==index



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

**# stset and regression
stset time [pw=sw], fail(outcome==1) scale(365.25) id(patid)
stcrreg i.cohort, compete(outcome==2)

tempfile estimates
regsave using "`estimates'"
frame create estimates
frame estimates: gen model = ""
frame estimates: append using "`estimates'"
frame estimates: replace model = "SH30 broadelig" if model==""	



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

export delim using outputs/SH30_broadelig.csv, replace



**# Get counts for time and events
frame change default

keep time outcome
replace outcome = (outcome==1)
local countsrowname "SH30 broadelig"

** calculate total time and N
count if time>0
scalar def sc_obs = string(`r(N)', "%9.0fc")
count if outcome==1 & time>0
scalar def sc_events = string(`r(N)')
sum time if time>0, d
scalar def sc_time = string(`r(sum)'/365.25, "%9.0fc")

** Create dataset that only contains this info
clear
set obs 1
gen analysis = "`countsrowname'"
gen obs = sc_obs
gen events = sc_events
gen totfup = sc_time

** Multiple records may be generated if analysis is re-run: create a time stamp
*	so that the most recent record can be identified and retained
gen temp = c(current_date) + " " + c(current_time)
gen datetime = clock(temp, "DMY hms")
format datetime %tc
drop temp

** Add the new record to the output dataset, keep most recent, and save
capture append using data/clean/sh30_sensitivitycounts.dta
sort analysis datetime
by analysis: keep if _n==_N
save data/clean/sh30_sensitivitycounts.dta, replace




**# Output
clear
import delim using outputs/SH30_broadelig.csv, varnames(1)
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

export delim using outputs/SH30_BroadEligOutput.csv, replace 




*****
frames reset
capture log close broadelig
exit
