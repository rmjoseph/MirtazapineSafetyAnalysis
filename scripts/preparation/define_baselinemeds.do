** CREATED 20-01-2020 by RMJ at the University of Nottingham
*************************************
* Name:	define_baselinemeds
* Creator:	RMJ
* Date:	20200120
* Desc:	Classify status of drugs at index date
* Requires: Stata 16 for frames function
* Version History:
*	Date	Reference	Update
*	20192020	define_baselinemeds	Create file
*	20200713	define_baselinemeds	Add analgesics
*************************************

set more off
frames reset
clear

**** Load cohort file and get index date and patid
use data/clean/finalcohort.dta
keep patid secondaddate
rename secondaddate index


**** Keep if index date is not missing
keep if index<.


**** Create variable with date 6 months prior to index
gen sixm = index - (365.25/2)


**** Loop opening each drug file and generating presence indicator
frame create drug

local drugname antipsychotics anxiolytics gc hypnotics nsaids opioids statins analgesics

** Open loop
foreach X of local drugname {

	** Change to drug frame and open the records for that drug
	frame change drug
	clear
	use data/raw/stata/`X'_records.dta

	** Link with default frame and merge across index and sixm vars
	frlink m:1 patid, frame(default)
	frget *, from(default)

	** Keep only records which were linked
	keep if default<.
	drop default

	** Keep only prescriptions recorded within the 6 months up to & including index
	keep if eventdate <= index & index<.
	keep if eventdate >= sixm & eventdate<.

	** Keep patid and the indicator variable; keep single record per pat
	keep patid `X'
	bys patid: keep if _n==1

	** Change back to default frame and merge across the new indicator var
	frame change default
	frlink 1:1 patid, frame(drug)
	frget `X', from(drug)
	drop drug

	** Replace missing values with 0
	replace `X'=0 if `X'==.

	** Close loop
	}

**** Tidy and save
frame drop drug
drop index sixm
saveold data/clean/baselinemeds.dta, replace

clear

exit
