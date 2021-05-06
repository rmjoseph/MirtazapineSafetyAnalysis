** CREATED 12-03-2021 by RMJ at the University of Nottingham
*************************************
* Name: selfharm30_TimeVaryingAntidepExposure
* Creator:	RMJ
* Date:	20210312
* Desc:	Modifies existing file to use enddate30 for the selfharm analysis (only keep the avd dose section)
* Requires: Stata 16 for frames functionality; tvc_split; tvc_merge
* Version History:
*	Date	Reference	Update
*	20210312	TimeVaryingAntidepExposure	Create file
*************************************

** LOG
capture log close tvad30
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/sh30_timevaryingantideps_`date'.txt", text append name(tvad30)

**
set more off
frames reset



** CALCULATE AVERAGE DOSES OVER SPECIFIED TIMES
** Run the utility to calculate average dose
include scripts/preparation/CalcAvgDose.do

**** Self harm
** Load data and get/make follow-up variables (core analysis)
frame create selfharm
frame change selfharm
use data/clean/antidepexp_selfharm.dta, clear

merge m:1 patid using data/clean/final_combined.dta, keepusing(ageindex sex cohort index enddate3 keep1 eligstart eligstop) keep(3) nogen
order patid cohort sex ageindex eligstart eligstop index start stop

gen time = stop if shevent==1
replace time = enddate3 if time==.
bys patid: egen exit = min(time)
format exit enddate3 %dD/N/CY
drop time

** Loop the utility over variables of interest
**	syntax, ORIGFrame(string) ENTER(varlist max=1) EXIT(varlist max=1) DRUG(varlist max=1)
frame change selfharm
foreach X of varlist mirtazapine ssri amitriptyline venlafaxine allantidep citalopram escitalopram fluoxetine fluvoxamine paroxetine sertraline {
	CALCDOSE, origf(selfharm) enter(index) exit(exit) drug(`X')
}

** Restrict dataset
keep if keep1==1
keep if cohort<5
drop if stop<=index
drop if start>=exit
misstable sum

** Keep first record per patient
codebook patid
keep if start==index
count

** Keep vars of interest
keep patid mirtazapine ssri amitriptyline venlafaxine citalopram escitalopram fluoxetine fluvoxamine paroxetine sertraline allantidep totMed*

** Rename vars 
foreach X of varlist mirtazapine ssri amitriptyline venlafaxine citalopram escitalopram fluoxetine fluvoxamine paroxetine sertraline allantidep {
	rename `X' firstDose_`X'
	label var firstDose_`X' "Dose (ddd) of drug `X' on index date"
}

foreach X of varlist totMed_* {
	label var `X' "Median dose (ddd) over followup (including when off drug)"
}

foreach X of varlist totMedOn_* {
	label var `X' "Median dose (ddd) over followup (only when on drug)"
}

** Save
saveold data/clean/avgdose_selfharm30.dta, replace



*****
frames reset
capture log close tvad30
exit
