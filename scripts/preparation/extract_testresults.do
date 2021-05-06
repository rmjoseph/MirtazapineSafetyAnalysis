** CREATED 2020-03-09 by RMJ at the University of Nottingham
*************************************
* Name:	extract_testresults.do
* Creator:	RMJ
* Date:	20200309
* Desc:	Extract results from test data (originally depression scales)
* Requires: Stata 16 for frames function
* Version History:
*	Date	Reference	Update
*	20200309	extract_testresults.do	Create file
*************************************

************ Define program extracting data of interest from test files
*** For each test dataset: load, keep if record of interest, get description, get/format eventdate, drop if before uts, append to one file

capture program drop EXTRACT
program EXTRACT 

	// Need to specify the file path and the file name
	syntax , PATH(string) FILEName(string) 

	// Load next file
	frame change import
	clear
	import delim using "`path'`filename'.txt"

	// Keep relevant records
	frlink m:1 medcode, frame(codes)
	keep if codes!=.
	drop codes

	// Merge across the Read code descripion
	frlink m:1 medcode, frame(medical)
	frget desc, from(medical)
	drop medical

	// Fill in missing eventdate with sysdate; convert to date format
	replace eventdate = sysdate if eventdate==""
	rename eventdate eventdate1
	gen eventdate = date(eventdate1, "DMY")
	format eventdate %dD/N/CY
	drop eventdate1 sysdate

	// Gen pracid then link to practice file to get uts
	tostring patid, gen(pracid)
	replace pracid = substr(pracid,-3,3)
	destring pracid, replace

	frlink m:1 pracid, frame(practice)
	keep if practice<.
	frget uts, from(practice)
	drop practice

	// Drop records prior to uts
	drop if eventdate < uts

	// Append to the main file
	tempfile tosave
	save "`tosave'", replace

	frame change combine
	append using "`tosave'", force

end



***************************************************
*** RUN THE PROGRAM TO EXTRACT DATA FROM TEST FILES

frames reset
clear

frame create codes
frame create import
frame create combine
frame create medical
frame create practice


*** Load code list (depression scales)
frame change codes
use data/clean/conditionscodes.dta

keep medcode depscale
keep if depscale==1


*** Load medical dictionary to get description
frame change medical
use data/raw/stata/medical.dta

frlink 1:1 medcode, frame(codes)
keep if codes!=.
drop codes


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

frame change combine
clear

** Male dataset: 21 files
display "$S_TIME  $S_DATE"

foreach X of numlist 1/21 {

	scalar def sc1 = "00" + string(`X')
	local num = substr(sc1,-3,3)
	di `num'

	EXTRACT, path("data/raw/Mirt1m/") filen("Mirt1m_Extract_Test_`num'")
	
	scalar drop sc1
	}

** Female dataset: 48 files
display "$S_TIME  $S_DATE"

foreach X of numlist 1/48 {

	scalar def sc1 = "00" + string(`X')
	local num = substr(sc1,-3,3)
	di `num'

	EXTRACT, path("data/raw/Mirt1f/") filen("Mirt1f_Extract_Test_`num'")
	
	scalar drop sc1
	}
	
display "$S_TIME  $S_DATE"




save data/raw/stata/depressionscales, replace

frames reset
exit
