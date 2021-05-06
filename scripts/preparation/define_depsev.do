** CREATED 2020-01-27 by RMJ at the University of Nottingham
*************************************
* Name:	define_depsev
* Creator:	RMJ
* Date:	20200127
* Desc:	Finds max depression severity prior to index
* Requires: Stata 16 for frames function; index date
* Version History:
*	Date	Reference	Update
*	20200121	define_ethnicity	Create file
*	20200309	define_depsev	Add section using the depression test results file
*************************************

/* DEFINITION: Max severity on/before index. 
*  DATA CLEANING APPLIED:
*		- if >1 record per day, keep most severe
*/

set more off
frames reset
clear

*** LOAD AND TIDY DEPRESSION SEVERITY RECORDS
frame create depression
frame change depression
use data/raw/stata/depressionrecords.dta

keep if depsev<.

*** DROP TRUE DUPLICATES
keep patid eventdate depsev
bys patid eventdate depsev: keep if _n==1

*** MORE THAN ONE RECORD PER DAY: keep most severe
bys patid eventdate (depsev): keep if _n==_N




*** MERGE WITH INDEX DATE
frame create index
frame change index
use patid secondaddate using data/clean/finalcohort.dta
rename secondaddate indexdate

frame change depression
frlink m:1 patid, frame(index)
keep if index<.
frget *, from(index)
drop index



*** KEEP RECORDS ON OR BEFORE INDEX
keep if indexdate<.
keep if eventdate<=indexdate

*** KEEP MAX SEVERITY
bys patid (depsev eventdate): keep if _n==_N


*** TIDY AND SAVE
keep patid depsev
*duplicates report patid




*** Depression scale scores
frame create tests
frame change tests
clear

use data/raw/stata/depressionscales
* Ultimately only two medcodes and all have the same enttype

// set to missing if out of range
replace data2 = . if data2>27 & medcode==13583
replace data2 = . if data2>21 & medcode==19409

// drop if missing
drop if data2==.

// set severity
gen severe=0
replace severe=1 if data2>=15 & data2<. & medcode==13583
replace severe=1 if data2>=16 & data2<. & medcode==19409

// drop if after indexdate
frlink m:1 patid, frame(index)
keep if index<.
frget indexdate, from(index)
drop index

keep if eventdate<=indexdate

// Max severity on or before index
bys patid: egen testseverity = max(severe)

// drop duplicates
bys patid: keep if _n==1
keep patid testseverity


**** Combine into one dataset
frame change index
frlink 1:1 patid, frame(depression)
frget *, from(depression)

frame change index
frlink 1:1 patid, frame(tests)
frget *, from(tests)




*** TIDY AND SAVE
keep if index<.
keep patid depsev testsev

drop if depsev==. & testsev==.

*duplicates report patid
saveold data/clean/baselinedepressionseverity.dta, replace



frames reset
clear
exit

