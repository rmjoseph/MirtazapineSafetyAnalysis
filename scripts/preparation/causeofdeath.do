** CREATED 20-Dec-2019 by RMJ at the University of Nottingham
*************************************
* Name:	causeofdeath
* Creator:	RMJ
* Date:	20191220
* Desc:	Links underlying cause of death field to the ONS short list cause of death
* Requires: Stata 16 for frames function
* Version History:
*	Date	Reference	Update
*	20200121	causeofdeath	add line changing erroneous icd9 code
*	20200121	causeofdeath	further small mods for unknown cod
*	20200434	causeofdeath	don't add descriptions for unknown cod
*************************************

set more off
frames reset
clear

** LOG
capture log close causeofdeath
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/causeofdeath_`date'.txt", text append name(causeofdeath)
**


*** Open cause of death code list and prepare for linking
capture frame create deathcodes
frame change deathcodes
clear

import excel data/codelists/Appendix1_mirtaz_codelists.xlsx, sheet(death_expanded) firstrow case(lower)

rename code icd10
replace all_cause=0 if all_cause==.


*** Open ONS data file and prepare for linking
frame change default
clear

import delim "data/raw/19_241_Delivery/GOLD_linked/death_patient_19_241.txt"

keep patid cause
rename cause icd10

*** Link the code list to the ONS data file
sort icd10
frlink m:1 icd10, frame(deathcodes)

*** Investigate where the linkage was not successful
levelsof icd10 if deathcodes==., clean sep("  ")
tab icd10 if deathcodes==.

replace icd10 = "N18" if icd10 == "N18.0"
replace icd10 = "K35" if icd10 == "K35.0"
replace icd10 = "I25.9" if icd10 == "414.9" // icd9 code (2020-01-21)

*replace desc = "Multi-system degeneration (G90.3)" if icd10=="G90.3" // 2020-01-21, not included in TRUD download // 23/04/2020 var not brought across yet
replace icd10 = "G90" if icd10=="G90.3" // 2020-01-21

*replace desc = "Acute appendicitis with peritoneal abscess (K35.1)" if icd10=="K35.1" // 2020-01-21, not included in TRUD download // 23/04/2020 var not brought across yet
replace icd10 = "K35" if icd10=="K35.1" // 2020-01-21

// I84.9 .... I84 not included at all in TRUD download
// M72.5 ... Not included in TRUD download nor the WHO site
// U99 ... U is codes for special purposes, but no info about U99


// Some patients have no listed cause
// Some patints have a code that does not exist in the current version of the ICD10
// Both of the above involve small numbers

*** Re-link the datasets and merge the fields across
frlink rebuild deathcodes
frget *, from(deathcodes)

*** Create an indicator to show patients without a (currently used) cause of death
gen unknowncauseofdeath = (deathcodes==.)

*** Code the cause of death fields as categories rather than strings
encode death_group, gen(cause_chapt) label("causeofdeath_1")
encode death_group2, gen(cause_sub1) label("causeofdeath_2")
encode death_group3, gen(cause_sub2) label("causeofdeath_3")
encode death_group4, gen(cause_sub3) label("causeofdeath_4")

label var cause_chapt "Cause of death, chapter level"
label var cause_sub1 "Cause of death, sub-chapter level 1"
label var cause_sub2 "Cause of death, sub-chapter level 2"
label var cause_sub3 "Cause of death, sub-chapter level 3"

*** Tidy and save
keep patid icd10 all_cause cause* unknown desc
compress
sort patid
saveold data/clean/causeofdeath.dta, replace

*** Exit
frames reset
clear

log close causeofdeath
exit

