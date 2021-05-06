** CREATED 09-Dec-2019 by RMJ at the University of Nottingham
*************************************
* Name:	import_drugcodes.do
* Creator:	RMJ
* Date:	20191209
* Desc:	Imports codelists for medications
* Requires: Stata 16 for frames function
* Version History:
*	Date	Reference	Update
*	20191209	define_drugcodes	Create file
*	20191217	define_drugcodes	Change counter to local i
*	20191217	define_drugcodes	Bug fix: use append instead of save after antidep import
*	20200124	define_drugcodes	Add smoking therapies
*	20200713	define_drugcodes	Add lithium and analgesics (also updated opioid and nsaid codes)
*************************************

/* NOTES
* Create a single combined file of all the codelists
*/

set more off
frames reset
clear

** LOG
capture log close prodcodeimportlog
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/importdrugcodes`date'.txt", text append name(prodcodeimportlog)
**

frame create codes


** Import all the codes
frame change codes
clear

** Create macro containing the names of excel tabs for medication code lists
** NOTE - not including antidepressants in this step
local drugs "statins opioids nsaids hypnotics gc anxiolytics antipsychotics smokingtherapies lithium analgesics"
di "`drugs'"

** Use loop to import each code in turn and combine all lists into single file
local i = 0 // counter for if loop

// Open loop X
foreach X of local drugs {
	
	// clear data in memory
	clear
	
	// increment the counter
	local i=`i'+1
	
	// import the codes for drug X	
	import excel data/codelists/Appendix1_mirtaz_codelists.xlsx, sheet(`X') firstrow case(lower)
	
	// drop any blank rows that might have been imported 
	drop if prodcode==.
	
	// keep only the product code
	keep prodcode
	
	// create indicator variable for that drug
	gen `X' = 1

	// Save as a new dataset if first pass of loop, otherwise append the combined 
	// results from previous pass and save 
	if `i'==1 { 
		save data/clean/drugcodes.dta, replace
		}	
	else {
		append using data/clean/drugcodes.dta 
		save data/clean/drugcodes.dta, replace
		}
	
	// Close loop X
	}

	
** Import and append antidepressant info - treating separately as have more fields
clear
import excel data/codelists/Appendix1_mirtaz_codelists.xlsx, sheet(antidepressants) firstrow case(lower)
drop if prodcode==.

rename drug antidepdrug
gen antidep=1

append using data/clean/drugcodes.dta 	// addition RMJ


	
** Some products may be included in more than one list. Collapse into single record.
// Where prodcodes are in more than one list, change each drug indicator to 1 as appropriate
#delimit ;
local drugs "statins opioids nsaids hypnotics gc anxiolytics antipsychotics antidep smokingtherapies";
#delimit cr

sort prodcode
foreach X of local drugs {
	bys prodcode (`X'): replace `X'=`X'[1]
	}

// Keep single record of each prodcode
sort prodcode antidepdrug
bys prodcode (antidepdrug): keep if _n==_N	 // keep the antidep record to retain labels

// Save and clear
save data/clean/drugcodes.dta, replace

clear
frames reset
capture log close prodcodeimportlog
exit


