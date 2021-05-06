* CREATED BY RMJ AT THE UNIVERSITY OF NOTTINGHAM 2019-12-09
*************************************
* Name:	cohort_eligibility.do
* Creator:	RMJ
* Date:	20191209
* Desc: Combines all data needed to work out eligibility
* Requires: Stata 16 (Frames function)
* Version History:
*	Date	Reference	Update
*	20191209	linkage_eligibility	Create file
*	20191212	cohort_eligibility	Save file before looking at drug exp and conditions
*	20191213	cohort_eligibility	Merge in mortality; account for death date
*************************************

* VARS NEEDED: 
* patient: patid frd crd tod yob permanent acceptable
* practice: uts lcd 
* generate: studystart studyend date18 date100 cprdstartplus1year eligstart eligend
* linkage eligibility: link to ONS, link to HES, linkage date
* linked data: deathdate

** LOG
capture log close cohortlog
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/CohortEligibility_`date'.txt", text append name(cohortlog)

** CLEAR EVERYTHING
set more off
frames reset
clear

*** PATIENT FILE:
frame create patient
frame change patient
clear
use patid yob frd crd regstat tod accept deathdate gender using "data/raw/stata/allpatients.dta"

** Convert date variables from strings to dates
foreach X of varlist frd crd tod deathdate {
	rename `X' temp
	gen `X' = date(temp,"DMY")
	format `X' %dD/N/CY
	drop temp
	}

*** Label permanently registered patients
gen permanent = (regstat==0)
drop regstat 


*** PRACTICE FILE:
** Load practice data for uts and lcd
frame create practice
frame change practice
clear
use "data/raw/stata/allpractices.dta"

** Convert date variables from strings to dates
foreach X of varlist lcd uts {
	rename `X' temp
	gen `X' = date(temp,"DMY")
	format `X' %dD/N/CY
	drop temp
	}

*** Merge uts and lcd from practice into patient
frame change patient

* Generate patid
tostring patid, gen(patstr)
gen pracid=substr(patstr,-3,3)
drop patstr
destring pracid, replace

* Link patient and practice frames and get variables
frlink m:1 pracid, frame(practice)
frget *, from(practice)
drop practice
frame drop practice



*** LINKAGE ELIGIBILITY
** Get linkage eligibility and linkdate for those in hes, death
frame create linkage
frame change linkage
clear
use "data/raw/stata/linkageeligibility.dta", clear

count
keep if hes_e==1 & death_e==1 // & lsoa_e==1
count
keep patid linkdate hes_e death_e lsoa_e

** Convert linkdate from string to date
foreach X of varlist linkdate {
	rename `X' temp
	gen `X' = date(temp,"DMY")
	format `X' %dD/N/CY
	drop temp
	}

*** Merge linkage variables with main file
frame change patient
frlink 1:1 patid, frame(linkage)
frget *, from(linkage)
drop linkage
frame drop linkage




*** MORTALITY FILE
** Date of death, date of death registration, and death linkage ID (to identify duplicate patients)
frame create mortality
frame change mortality
clear

import delim "data/raw/19_241_Delivery/GOLD_linked/death_patient_19_241.txt"

gen onsdeath = date(dod,"DMY")
gen datereg = date(dor,"DMY")
format onsdeath datereg %dD/N/CY

count if onsdeath==.

keep patid gen_death_id onsdeath

frame change patient
frlink 1:1 patid, frame(mortality)
frget *, from(mortality)

* Tag those with death record
replace mortality = (mortality<.)
frame drop mortality

** If death date is missing but death was registered, replace with CPRD death date
** (<5 had missing dates but CPRD dates matched the partial dates provided)
replace onsdeath = deathdate if onsdeath==. & mortality<. 

// a small number of patients have two sets of records in the death data... 
// but presumably many other patients are duplicated and we can't do anything 
// about that as we don't know about it, so this shouldn't matter?




*** Create remaining variables for cohort eligibility
frame change patient

** Generate variable showing date 18, date 100, and dob
gen plus18 = yob + 18
tostring plus18, replace
gen date18=date(plus18,"Y")

gen plus100 = yob + 100
tostring plus100, replace
gen date100=date(plus100,"Y")

gen dob = date(string(yob),"Y")

format date18 date100 dob %dD/N/CY
drop yob plus18 plus100


** Date of CPRD follow-up start plus one year (max of uts+1y, crd+1y, frd+1y)
egen plus1 = rowmax(uts crd frd)
format plus1 %dD/N/CY
replace plus1 = plus1+365.25
label variable plus1 "Latest of uts crd or frd plus 1 year"

* Create variables for the study start and end date
gen studystart=date("01/01/2005","DMY")
gen studyend=date("30/11/2018","DMY")
format studystart studyend %dD/N/CY

* Create eligibility start and stop variables
egen eligstart = rowmax(plus1 date18 studystart)
egen eligstop = rowmin(lcd tod studyend onsdeath) // accounting for death date for first time 
format eligstart eligstop %dD/N/CY


** SAVE ALL COMBINED
saveold data/clean/combinedpatinfo.dta, replace

clear

log close cohortlog
exit


