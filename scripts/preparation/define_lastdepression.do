** CREATED 20-01-2020 by RMJ at the University of Nottingham
*************************************
* Name:	define_lastdepression
* Creator:	RMJ
* Date:	20200120
* Desc:	Finds the most recent depression record on or before index
* Requires: Stata 16 for frames function; index date
* Version History:
*	Date	Reference	Update
*	20200120	define_lastdepression	Create file
*	20200128	define_lastdepression	Use new depressionrecords file not combinedmedevents
*************************************

set more off
frames reset
clear

**** Load cohort file and get index date and patid; keep if index isnt missing
use data/clean/finalcohort.dta
keep patid secondaddate
rename secondaddate index
keep if index<.

**** Open the medevents file in new frame and keep depression records
frame create medevents
frame change medevents
clear

use "data/raw/stata/depressionrecords.dta"

keep patid depev medcode

**** Merge across index date from default frame
frlink m:1 patid, frame(default)
frget index, from(default)
drop default

**** Drop events after index date
keep if depev <= index

**** Keep most recent event before index date (should have one record per pat)
bys patid (depev): keep if _n==_N

**** Create variables: most recent depression, depression ever
rename depev lastdepdate
gen depression = 1

**** Go back to default frame and merge across these new variables
frame change default
frlink 1:1 patid, frame(medevents)
frget lastdepdate depression, from(medevents)

**** Replace missing depression indicator with 0
replace depression = 0 if depression==.
replace lastdepdate = . if medevents==.

**** Tidy and save
keep patid lastdepdate depression
saveold data/clean/baselinedepression.dta, replace

clear
exit
