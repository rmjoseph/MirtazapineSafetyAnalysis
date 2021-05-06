** CREATED 09-Dec-2019 by RMJ at the University of Nottingham
*************************************
* Name:	define_prescriptionevents
* Creator:	RMJ
* Date:	20191209
* Desc:	Uses drug codes to extract drug info for each drug of interest and 
*		saves as separate files
* Requires: Stata 16 for frames function
* Version History:
*	Date	Reference	Update
*	20191209	define_conditiondates	Create file
*	20191216	define_prescriptionevents	Modify loop to also include data from females
*	20200124	define_prescriptionevents	Add smoking therapies
*	20200713	define_prescriptionevents	Add analgesics
*************************************

** LOG
capture log close druglog
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/DrugEvents_`date'.txt", text append name(druglog)
**

** SET UP
set more off
frames reset
clear

frame create practice
frame create codes
frame create drugevents



** Load practice file for uts
frame change practice
clear

use data/raw/stata/allpractices.dta
keep pracid uts

rename uts temp
gen uts = date(temp,"DMY")
format uts %dD/N/CY
drop temp

frame change default




** Load the code dataset
frame change codes
clear

use data/clean/drugcodes.dta, replace





** Keep any prescription events with any of the codes of interest
** Loop over each of the separate therapy files and drugs, creating individual
** Drug files
frame change drugevents
clear

*** Store file names in a macro to loop over (first build as a scalar)
// Blank scalar
scalar def scM = ""
// male dataset, 59 therapy files
forvalues N = 1/59 {
	
	// file number as string, format 001
	scalar def sc1 = "00" + string(`N')
	local num = substr(sc1,-3,3)
	
	// full file path as string
	scalar def sc2 = "Mirt1m/Mirt1m_Extract_Therapy_`num'.txt"
	
	// append this to the existing scalar
	scalar def sc3 = scM + " " + sc2
	scalar drop scM
	scalar def scM = sc3
}
// female dataset, 121 therapy files
forvalues N = 1/121 {

	scalar def sc1 = "00" + string(`N')
	local num = substr(sc1,-3,3)
	
	scalar def sc2 = "Mirt1f/Mirt1f_Extract_Therapy_`num'.txt"
	scalar def sc3 = scM + " " + sc2
	
	scalar drop scM
	scalar def scM = sc3
}
// Use scalar to create a local var to loop over
local filename = scM

*di "`filename'"

*** PROCESS: open file, replace missing event date, drop events happening
**	before UTS, link with codes file and keep if linked, then for each drug
**	of interest: merge across vars of interest for that drug, keep only records
**	of that drug, save as new dataset for that drug/append results if not first
**	pass. End up with dataset for each drug containing all prescribing records
**	for that drug extracted from the invididual therapy files.

**** Start loop to merge therapy files with drug codes
display "$S_TIME  $S_DATE"

local i = 0 // loop count indicator
// Open loop X for each filename
foreach X of local filename {
	display "$S_TIME  $S_DATE"
	// clear memory
	clear
	
	// increment counter
	local i = `i'+1
	
	// Load file, keeping all variables
	di "data/raw/`X'"
	import delim using "data/raw/`X'"

	// Replace missing values of eventdate
	replace eventdate = sysdate if eventdate==""
	drop sysdate

	// Convert eventdate to a date
	rename eventdate temp
	gen eventdate=date(temp,"DMY")
	format eventdate %dD/N/CY
	drop temp

	// Link to practice file to get uts; gen pracid then link
	tostring patid, gen(pracid)
	replace pracid = substr(pracid,-3,3)
	destring pracid, replace

	frlink m:1 pracid, frame(practice)
	keep if practice<.
	frget uts, from(practice)
	drop practice

	// Drop records prior to uts
	drop if eventdate < uts
	drop uts
	
	// Merge with the code master file and keep if linked
	frlink m:1 prodcode, frame(codes)
	keep if codes <.
	
	
	// THEN loop over each of the drugs of interest
	// open loop drugname
	foreach drugname of newlist antidep antipsychotics anxiolytics gc hypnotics nsaids opioids statins smokingtherapies analgesics {
		
		di "`drugname'"
		
		// preserve in memory
		preserve
		
		// Merge in the new fields for that drug (* allows the multiple antideps fields to be copied)
		frget `drugname'*, from(codes)
		drop codes

		// Drop if not a record of drug of interest
		drop if `drugname' !=1
		
		// Either save as a new file for that drug (if first filename), or append the previous results
		if `i' == 1 {
			save "data/raw/stata/`drugname'_records.dta", replace
			}
		else {
			append using "data/raw/stata/`drugname'_records.dta"
			save "data/raw/stata/`drugname'_records.dta", replace
			}
			
		// Restore
		restore
		
		// Close loop drugname
		}
	
	// Close loop filename
	}
	
	
	
display "$S_TIME  $S_DATE"


** Exit	
clear
frames reset
capture log close druglog
exit


