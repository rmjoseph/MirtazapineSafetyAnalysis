** CREATED 23-jan-2020 by RMJ at the University of Nottingham
*************************************
* Name:	define_conditiondates_v2
* Creator:	RMJ
* Date: 20200123
* Desc:	Combines codelists with medical history to find onset dates
*		or multiple record dates
* Requires: Stata 16 for frames function
* Version History:
*	Date	Reference	Update
*	20191206	define_conditiondates	Create file
*	20191212	define_conditiondates	Find first record of each type of event
*	20191216	define_conditiondates	Add loops for female data
*	20191217	define_conditiondates	Drop duplicates after combining files
*	20200124	define_conditiondates	Add codes for cat vars & save as separate files
*	20200204	define_conditiondates_v2	Add depressionsympt
*	20200218	define_conditiondates_v2	Replace vte with weightloss in varlists
*	20200316	define_conditiondates_v2	Also extract all cancer records
*	20200723	define_conditiondates_v2	Update varlist with new conditions
*	20200723	define_conditiondates_v2	Extract all mentalhealthservices records
*	20200805	define_conditiondates_v2	Account for duplicate depressionsympt
*	20200805	define_conditiondates_v2	Add 'capture' before rm for first run
*	20210218	define_conditiondates_v2	BUG: fix incorrect frame change (to mentalhealthservices)
*	20210218	define_conditiondates_v2	BUG: add rm depressionsymptrecords dataset
*************************************

/* NOTES
* Depression is different to all other conditions as the timing relative to
* other events is important - need a record of all instances.
* 
* Need all the medical info files (clinical, referral, test, immunisation), the
* codelist file, and the practice file (for uts)
* Create a single combined file of all the codelists
* Load each sub file in turn and link this codelist
* 
*/

** LOG
capture log close medicallog
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/MedicalConditions_`date'.txt", text append name(medicallog)
**


** Set up
set more off
frames reset
clear

frame create practice
frame create codes
frame create medevents


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



** Load the code dataset
frame change codes
clear

use data/clean/conditionscodes.dta, replace
drop readcode desc

// add in the category variables code lists
append using data/clean/categorycodes.dta

// may be overlap between the codes (for depression/depsev and alcohol misuse/alcohol intake) - remove duplicates, keeping all info
sort medcode
bys medcode (depression): replace depression = depression[1]
bys medcode (depressionsympt): replace depressionsympt = depressionsympt[1] // added 2020-08-05
bys medcode (alcoholmisuse): replace alcoholmisuse = alcoholmisuse[1]

sort medcode alcoholintake depsev
bys medcode (alcoholintake depsev): keep if _n==1



********** PART 1: use code list to find first record in INDIVIDUAL datasets, and combine results

*** Keep any medical events with any of the codes of interest
frame change medevents
clear

** Process: load each individual file, replace missing eventdate with sysdate,
** drop records prior to uts, 
** mege with code lists, keep records matching on medcodes,
** replace condition indicators with event dates, copy all depression records
** into a new frame, in original frame set the earliest record of each condition
** as that condition's onset date, keep one record per patient, merge the 
** multiple depression records back into file.
** NOTE: THIS SECTION WORKS OUT FIRST DATE IN *INDIVIDUAL* FILE

** Define a program so not re-writing
capture program drop LOADCOMBINE
program LOADCOMBINE

	// Need to specify the file path and the file name
	syntax , PATH(string) FILEName(string) 

	// Load file, keeping variables of interest
	import delim using "`path'`filename'.txt"
	keep patid eventdate sysdate medcode

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

	// Merge with the code master file and keep if linked
	frlink m:1 medcode, frame(codes)
	keep if codes <.

	// Merge in the new fields
	frget *, from(codes)
	drop codes

	// Replace the different condition variables with dates
	foreach X of varlist weightloss-abdompain {	// changed from vte-af 20200723
		di "`X'"
		replace `X' = eventdate if `X'==1
		format `X' %dD/N/CY
		}

	// Copy depression, smoking, alcohol, ethnicity into own frames (also cancer, mentalhealthservices)
	capture frame drop depressionev
	frame put if depression<., into(depressionev)
	frame change depressionev
	keep patid medcode depression depsev eventdate
	rename depression depev

	frame change medevents	
	capture frame drop depsymp
	frame put if depressionsympt<., into(depsymp)
	frame change depsymp
	keep patid medcode depressionsympt eventdate

	frame change medevents	
	capture frame drop smoking
	frame put if smokingstatus<., into(smoking)
	frame change smoking
	keep patid medcode smoking eventdate

	frame change medevents	
	capture frame drop alcohol
	frame put if alcoholintake<., into(alcohol)
	frame change alcohol
	keep patid medcode alcoholintake eventdate	
	
	frame change medevents	
	capture frame drop ethnicity
	frame put if ethnicity<., into(ethnicity)
	frame change ethnicity
	keep patid medcode ethnicity eventdate

	frame change medevents	
	capture frame drop cancer
	frame put if cancer<., into(cancer)
	frame change cancer
	keep patid medcode cancer eventdate
	
	frame change medevents	
	capture frame drop mentalhealthservices
	frame put if mentalhealthservices<., into(mentalhealthservices)
	frame change mentalhealthservices
	keep patid medcode mentalhealthservices eventdate
	
	
	// save each of these as separate files
	frame change depressionev
	capture append using "data/raw/stata/depressionrecords.dta"
	saveold "data/raw/stata/depressionrecords.dta", replace

	frame change depsymp
	capture append using "data/raw/stata/depressionsymptrecords.dta"
	saveold "data/raw/stata/depressionsymptrecords.dta", replace
	
	frame change smoking
	capture append using "data/raw/stata/smokingrecords.dta"
	saveold "data/raw/stata/smokingrecords.dta", replace

	frame change alcohol
	capture append using "data/raw/stata/alcoholrecords.dta"
	saveold "data/raw/stata/alcoholrecords.dta", replace

	frame change ethnicity
	capture append using "data/raw/stata/ethnicityrecords.dta"
	saveold "data/raw/stata/ethnicityrecords.dta", replace

	frame change cancer
	capture append using "data/raw/stata/cancerrecords.dta"
	saveold "data/raw/stata/cancerrecords.dta", replace
	
	*frame change cancer	// BUG FIX 2021-02-18
	frame change mentalhealthservices
	capture append using "data/raw/stata/mentalhealthservicesrecords.dta"
	saveold "data/raw/stata/mentalhealthservicesrecords.dta", replace
	
	// Find the onset date for each condition and then keep one record per pat
	frame change medevents

	drop smokingstatus alcoholintake ethnicity depsev
	
	foreach X of varlist weightloss-abdompain {	// changed from weightloss-af 20200723
		bys patid (`X'): replace `X' = `X'[1]
		}

	bys patid (eventdate): keep if _n==1 
	drop pracid medcode eventdate uts 
	
	sort patid 
	
end


** Use the program defined above to identify onset dates and depression records
** in individual files, and combine all files using append.


***** IMPORTANT - THIS REQUIRES THAT THE FILES FOR DEPRESSION, SMOKING ,
***** ALCOHOL, AND ETHNICITY ARE NOT ALREADY GENERATED (as append is used)
*** The following code will delete them:
capture rm "data/raw/stata/depressionrecords.dta"
capture rm "data/raw/stata/depressionsymptrecords.dta"	// added 2021-02-18
capture rm "data/raw/stata/smokingrecords.dta"
capture rm "data/raw/stata/alcoholrecords.dta"
capture rm "data/raw/stata/ethnicityrecords.dta"
capture rm "data/raw/stata/cancerrecords.dta"
capture rm "data/raw/stata/mentalhealthservicesrecords.dta"


display "$S_TIME  $S_DATE"
// MALE DATASET
frame change medevents
// referral is one file
clear
LOADCOMBINE, path("data/raw/Mirt1m/") filen("Mirt1m_Extract_Referral_001")
save data/clean/combinedmedevents.dta, replace

// immunisation is 1 file
clear
LOADCOMBINE, path("data/raw/Mirt1m/") filen("Mirt1m_Extract_Immunisation_001")
append using data/clean/combinedmedevents.dta
save data/clean/combinedmedevents.dta, replace

display "$S_TIME  $S_DATE"
// clinical is 20 files so loop the process
foreach X of numlist 1/20 {

	// this code creates the file number in format 001 / 020
	scalar def sc1 = "00" + string(`X')
	local num = substr(sc1,-3,3)
	di `num'
	di "`num'"

	clear
	LOADCOMBINE, path("data/raw/Mirt1m/") filen("Mirt1m_Extract_Clinical_`num'")
	append using data/clean/combinedmedevents.dta	
	save data/clean/combinedmedevents.dta, replace
	
	scalar drop sc1
	}
	
// test is 21 files
foreach X of numlist 1/21 {

	scalar def sc1 = "00" + string(`X')
	local num = substr(sc1,-3,3)
	di `num'

	clear
	LOADCOMBINE, path("data/raw/Mirt1m/") filen("Mirt1m_Extract_Test_`num'")
	append using data/clean/combinedmedevents.dta	
	save data/clean/combinedmedevents.dta, replace
	
	scalar drop sc1
	}
	
display "$S_TIME  $S_DATE"


// REPEAT FOR FEMALES
// referral is 2 files
clear
foreach X of numlist 1/2 {

	scalar def sc1 = "00" + string(`X')
	local num = substr(sc1,-3,3)
	di `num'
	di "`num'"

	clear
	LOADCOMBINE, path("data/raw/Mirt1f/") filen("Mirt1f_Extract_Referral_`num'")
	append using data/clean/combinedmedevents.dta	
	save data/clean/combinedmedevents.dta, replace
	
	scalar drop sc1
	}


// immunisation is 2 files
clear
foreach X of numlist 1/2 {

	scalar def sc1 = "00" + string(`X')
	local num = substr(sc1,-3,3)
	di `num'
	di "`num'"

	clear
	LOADCOMBINE, path("data/raw/Mirt1f/") filen("Mirt1f_Extract_Immunisation_`num'")
	append using data/clean/combinedmedevents.dta	
	save data/clean/combinedmedevents.dta, replace
	
	scalar drop sc1
	}


display "$S_TIME  $S_DATE"
// clinical is 45 files
foreach X of numlist 1/45 {

	scalar def sc1 = "00" + string(`X')
	local num = substr(sc1,-3,3)
	di `num'
	di "`num'"

	clear
	LOADCOMBINE, path("data/raw/Mirt1f/") filen("Mirt1f_Extract_Clinical_`num'")
	append using data/clean/combinedmedevents.dta	
	save data/clean/combinedmedevents.dta, replace
	
	scalar drop sc1
	}
	
// test is 48 files
foreach X of numlist 1/48 {

	scalar def sc1 = "00" + string(`X')
	local num = substr(sc1,-3,3)
	di `num'

	clear
	LOADCOMBINE, path("data/raw/Mirt1f/") filen("Mirt1f_Extract_Test_`num'")
	append using data/clean/combinedmedevents.dta	
	save data/clean/combinedmedevents.dta, replace
	
	scalar drop sc1
	}
	
display "$S_TIME  $S_DATE"




********** PART 2: within the results, find onset dates for each patient
// Find the onset date for each condition
foreach X of varlist weightloss-abdompain {	// changed from weightloss-af 20200723
	bys patid (`X'): replace `X' = `X'[1]
	}


// May be duplicates if patient was in multiple files for reasons other than depression
*duplicates drop if depression >= .

// If patients were in more than one file, and at least one did not involve depression codes,
// may be superfluous records with no depression event date. Drop these. (If patients 
// have a depression onset date they must have at least one depression record).
** Verified last statement with following code:
*gen nmiss = 1 if depression<. & depev==.
*bys patid: gen count=_N
*tab count if nmiss==1 // all > 2
*drop nmiss count
*drop if depression < . & depev >= .

// 23-01-2020 any duplicates - can ignore depression now
bys patid: keep if _n==1

// Save and exit
save data/clean/combinedmedevents.dta, replace
	
clear
frames reset
capture log close medicallog
exit


