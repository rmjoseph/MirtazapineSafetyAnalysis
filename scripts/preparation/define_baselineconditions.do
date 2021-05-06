** CREATED 20-01-2020 by RMJ at the University of Nottingham
*************************************
* Name:	define_baselineconditions
* Creator:	RMJ
* Date:	20200120
* Desc:	Classify status of comorbidities at index date
* Requires: Stata 16 for frames function
* Version History:
*	Date	Reference	Update
*	20200120	define_baselineconditions	Create file
*	20200128	define_baselineconditions	Remove section accounting for multiple depn recs
*	20200218	define_baselineconditions	Replace vte with weightloss in varlist
*	20200723	define_baselineconditions	Change varlist from weightloss-af to weightloss-abdompain
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


**** Merge with the combined medical events file; make sure one rec per patient
** Open the medevents file in a new frame
frame create medevents
frame change medevents
clear

use data/clean/combinedmedevents.dta


** Keep one record per patient (currently may be >1 depn record per patient)
*capture drop depev depression
*capture drop medcode
*bys patid: keep if _n==1
drop depression

** Merge with index date using frames
frame change default

frlink 1:1 patid, frame(medevents)
frget *, from(medevents)

drop medevents

frame drop medevents


**** Loop over each of the comorbidities to create binary status at index
** create local macro containing variable names
unab conditions: weightloss - abdompain 
di "`conditions'"

** Loop to replace onset date with binary indicator of present at baseline
foreach X of local conditions {
	replace `X' = (`X' <= index) //	less than or equal to
	format `X' %9.0g
	}



**** Tidy and save
drop index
saveold data/clean/baselinecomorbidities.dta, replace

clear

exit
