** CREATED 24-jan-2020 by RMJ at the University of Nottingham
*************************************
* Name:	extract_additionaldata.do
* Creator:	RMJ
* Date: 20200124
* Desc:	Extracts info to use to define BMI and smoking status from additional file
* Requires: Stata 16 for frames function
* Version History:
*	Date	Reference	Update
*	20202124	extract_additionaldata	Create file
*************************************


** LOG
capture log close additional
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/AdditionalDataExtract_`date'.txt", text append name(additional)
**


** Set up
set more off
frames reset
clear

frame create practice
frame create additional
frame create clinical


*** Load practice file for uts
frame change practice
clear
use data/raw/stata/allpractices.dta
keep pracid uts

// convert UTS to date
rename uts temp
gen uts = date(temp,"DMY")
format uts %dD/N/CY
drop temp

frame change default



*** Load all additional files, extract records of interest, and save
frame change additional
clear

*** Store file names in a macro to loop over (first build as a scalar)
// Blank scalar
scalar def scM = ""
// male dataset, 3 Additional files
forvalues N = 1/3 {
	
	// file number as string, format 001
	scalar def sc1 = "00" + string(`N')
	local num = substr(sc1,-3,3)
	
	// full file path as string
	scalar def sc2 = "Mirt1m/Mirt1m_Extract_Additional_`num'.txt"
	
	// append this to the existing scalar
	scalar def sc3 = scM + " " + sc2
	scalar drop scM
	scalar def scM = sc3
}
// female dataset, 7 Additional files
forvalues N = 1/7 {

	scalar def sc1 = "00" + string(`N')
	local num = substr(sc1,-3,3)
	
	scalar def sc2 = "Mirt1f/Mirt1f_Extract_Additional_`num'.txt"
	scalar def sc3 = scM + " " + sc2
	
	scalar drop scM
	scalar def scM = sc3
}

// Use scalar to create a local var to loop over
local filename = scM

** Process: open file, keep if enttype==4,23,13,14, save file if first run, otherwise append
local i = 0 // loop count indicator
// Open loop X for each filename
foreach X of local filename {
	
	// clear memory
	clear
	
	// increment counter
	local i = `i'+1
	
	// Load file, keeping all variables
	di "data/raw/`X'"
	import delim using "data/raw/`X'"

	// Keep if enttype is one of the ones of interest
	keep if enttype==4 | enttype==13 | enttype==14 | enttype==23
	
	// Reduce memory used
	drop data5-data7
	destring data1,replace
	destring data2,replace
	destring data3,replace
	destring data4,replace
	compress
	
	// save if first in loop, if not append then save
	if `i' == 1 {
		save "data/raw/stata/additional_extract.dta", replace
		}
	else {
		append using "data/raw/stata/additional_extract.dta"
		save "data/raw/stata/additional_extract.dta", replace
		}
	
	}
	

	
** Keep additional in frame, load each clinical in turn and use frlink and get to copy the variables across

** frget doesn't work like merge in the sense it won't fill in values if the variable already exists. Need to create a new variable to update.
frame change additional
gen neweventdate=.
format neweventdate %dD/N/CY

*** Store file names in a macro to loop over (first build as a scalar)
// Blank scalar
scalar def scM = ""
// male dataset, 20 Clinical files
forvalues N = 1/20 {
	
	// file number as string, format 001
	scalar def sc1 = "00" + string(`N')
	local num = substr(sc1,-3,3)
	
	// full file path as string
	scalar def sc2 = "Mirt1m/Mirt1m_Extract_Clinical_`num'.txt"
	
	// append this to the existing scalar
	scalar def sc3 = scM + " " + sc2
	scalar drop scM
	scalar def scM = sc3
}
// female dataset, 45 clinical files
forvalues N = 1/45 {

	scalar def sc1 = "00" + string(`N')
	local num = substr(sc1,-3,3)
	
	scalar def sc2 = "Mirt1f/Mirt1f_Extract_Clinical_`num'.txt"
	scalar def sc3 = scM + " " + sc2
	
	scalar drop scM
	scalar def scM = sc3
}

// Use scalar to create a local var to loop over
local filename = scM

foreach X of local filename {
	
	frame change clinical
	clear
	import delim using "data/raw/`X'"
	keep patid eventdate sysdate adid

	// Replace missing values of eventdate
	replace eventdate = sysdate if eventdate==""
	drop sysdate

	// Convert eventdate to a date
	rename eventdate temp
	gen eventdate=date(temp,"DMY")
	format eventdate %dD/N/CY
	drop temp

	// duplicates
	drop if adid==0
	duplicates drop
	
	// link
	frame change additional
	capture drop clinical
	frlink 1:1 patid adid, frame(clinical)	
	frget *, from(clinical)
	replace neweventdate = eventdate if neweventdate==.
	drop clinical eventdate

	}

** Drop prior to uts
frame change additional
frame drop clinical

rename neweventdate eventdate

// Link to practice file to get uts; gen pracid then link
tostring patid, gen(pracid)
replace pracid = substr(pracid,-3,3)
destring pracid, replace

frlink m:1 pracid, frame(practice)
keep if practice<.
frget uts, from(practice)
drop practice

drop if eventdate < uts
drop uts

** Save
compress
save "data/raw/stata/additional_extract.dta", replace

*** Clear and exit
capture log close additional
frames reset
exit


