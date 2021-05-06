** CREATED 18-03-2020 by RMJ at the University of Nottingham
*************************************
* Name:	define_cancer.do
* Creator:	RMJ
* Date:	20200318
* Desc:	Indicates if the patient had a cancer record in the year before index; 
*		also creates indicator variables using data from HES
* Requires: Stata 16 for frames function; index date
* Version History:
*	Date	Reference	Update
*	20200318	define_lastdepression	Create cancer file
*	20200522	define_cancer	Add in HES data and define additional vars
*************************************

set more off
frames reset
clear

**** Load cohort file and get index date and patid; keep if index isnt missing
use data/clean/finalcohort.dta
keep patid secondaddate
rename secondaddate index
keep if index<.

**** Open the cancer records in a new frame
frame create medevents
frame change medevents
clear

use "data/raw/stata/cancerrecords.dta"

keep patid cancer medcode

**** Merge across index date from default frame
frlink m:1 patid, frame(default)
frget index, from(default)
drop default

**** Drop events _after_ index date
keep if cancer <= index

**** Drop events more than a year before index
drop if cancer < (index - 365.25)

**** Create indicator variable
gen cancer1year = 1

**** Keep one record per patient
keep patid cancer1year
bys patid: keep if _n==1

**** Go back to default frame and merge across these new variables
frame change default
frlink 1:1 patid, frame(medevents)
frget *, from(medevents)

**** Replace missing indicator with 0
replace cancer1year = 0 if medevents==. & index<.


**** Merge in HES data; define cancer in past year
merge 1:1 patid using data/clean/hes_cancer.dta
drop if _merge==2 // i.e. patients with no index date
drop _merge

** gen past year vars
gen hescancer1year = (index-cancer)<=365.25 if cancer<.
gen hesmalig1year = (index-malignant)<=365.25 if malignant<.
gen hescancerev=(cancer<.)
gen hesmaligev=(malignant<.)

recode hes* cancer1year (.=0)

**** Tidy and save
keep patid cancer1year hes*
saveold data/clean/baselinecancer.dta, replace

clear
exit
