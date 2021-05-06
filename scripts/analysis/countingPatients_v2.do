** CREATED 08-04-2020 by RMJ at the University of Nottingham
*************************************
* Name:	countingPatients_v2
* Creator:	RMJ
* Date:	20200408
* Desc:	Outputs the number of patients meeting sequential inclusion criteria
* Requires: 
* Version History:
*	Date	Reference	Update
*	20200408	countingPatients	Change order, drop duloxetine, only report most and least restrictive
*	20200423	countingPatients_v2	Change order, incorp new criteria
*************************************
set more off
frames reset
clear

*** Date macro
local date: display %dCYND date("`c(current_date)'", "DMY")

*** Open log file
capture log close countingpatients
log using "logs/results_countingpatients_`date'.txt", ///
	text append name(countingpatients)

*** Open file to write to
capture file close outputfile
file open outputfile using "outputs/NumbersInCohort`date'.txt", write replace

*** Open data file
use depress* inc* bipolar schizophrenia eligible cohort ///
	using data/clean/final_combined.dta


*** Most restrictive: depression code 12 months, switch 90 days
capture frame drop newframe
frame put *, into(newframe)
frame change newframe

file write outputfile "Most restrictive criteria:"  _n _n

file write outputfile "Criterion" _tab "Keep" _tab "Dropping" _n

count
file write outputfile "Extracted" _tab "`r(N)'" _tab _n

// Count how many meet criteria, work out how many are dropped, keep those
// meeting criteria, report how many kept and how many dropped
count if inc_extracted==1 & inc_perm==1 & inc_followup==1 & inc_ssri==1
scalar exc = _N - `r(N)'
keep if inc_extracted==1 & inc_perm==1 & inc_followup==1 & inc_ssri==1
count
file write outputfile "Elig follow-up, first SSRI in window" _tab ///
	"`r(N)'" _tab (exc) _n

// Repeat
count if inc_linked==1
scalar exc = _N - `r(N)'
keep if inc_linked==1
count
file write outputfile "Linked" _tab "`r(N)'" _tab (exc) _n

// Repeat
count if inc_firstisssri==1
scalar exc = _N - `r(N)'
keep if inc_firstisssri==1
count
file write outputfile "First ever ad is SSRI" _tab "`r(N)'" _tab (exc) _n

// Repeat
count if inc_switchofinterest==1 & inc_switchafter==1 & ///
	inc_everswitch==1 & cohort<5
scalar exc = _N - `r(N)'
keep if inc_switchofinterest==1 & inc_switchafter==1 & ///
	inc_everswitch==1 & cohort<5
count
file write outputfile "Switch to a study drug AFTER first" ///
	_tab "`r(N)'" _tab (exc) _n


// Repeat
count if inc_switch90==1 
scalar exc = _N - `r(N)'
keep if inc_switch90==1
count
file write outputfile "Switch within 90 days of original" _tab ///
	"`r(N)'" _tab (exc) _n


// Repeat
count if depress_12==1
scalar exc = _N - `r(N)'
keep if depress_12==1
count
file write outputfile "Prior depression, <12 months before original presc" _tab "`r(N)'" _tab (exc) _n


// Repeat
count if inc_under100==1 & inc_thirdad==1 & bipolar!=1 & schizophrenia!=1
scalar exc = _N - `r(N)'
keep if inc_under100==1 & inc_thirdad==1 & bipolar!=1 & schizophrenia!=1
count
file write outputfile "No exclusions (age, 3rd ad, bipolar, schizophrenia)" _tab "`r(N)'" _tab (exc) _n



count if cohort==1
file write outputfile "Mirtazapine" _tab "`r(N)'" _tab _n			
count if cohort==2
file write outputfile "SSRI" _tab "`r(N)'" _tab _n	
count if cohort==3
file write outputfile "Amitriptyline" _tab "`r(N)'" _tab _n	
count if cohort==4
file write outputfile "Venlafaxine" _tab "`r(N)'" _tab _n	

file write outputfile _n

frame change default



*** Least restrictive: depression SYMPTOM code ever, switch 6m
capture frame drop newframe
frame put *, into(newframe)
frame change newframe

file write outputfile "Least restrictive criteria:"  _n _n

file write outputfile "Criterion" _tab "Keep" _tab "Dropping" _n

count
file write outputfile "Extracted" _tab "`r(N)'" _tab _n

// Count how many meet criteria, work out how many are dropped, keep those
// meeting criteria, report how many kept and how many dropped
count if inc_extracted==1 & inc_perm==1 & inc_followup==1 & inc_ssri==1
scalar exc = _N - `r(N)'
keep if inc_extracted==1 & inc_perm==1 & inc_followup==1 & inc_ssri==1
count
file write outputfile "Elig follow-up, first SSRI in window" _tab ///
	"`r(N)'" _tab (exc) _n

// Repeat
count if inc_linked==1
scalar exc = _N - `r(N)'
keep if inc_linked==1
count
file write outputfile "Linked" _tab "`r(N)'" _tab (exc) _n

// Repeat
count if inc_firstisssri==1
scalar exc = _N - `r(N)'
keep if inc_firstisssri==1
count
file write outputfile "First ever ad is SSRI" _tab "`r(N)'" _tab (exc) _n

// Repeat
count if inc_switchofinterest==1 & inc_switchafter==1 & ///
	inc_everswitch==1 & cohort<5
scalar exc = _N - `r(N)'
keep if inc_switchofinterest==1 & inc_switchafter==1 & ///
	inc_everswitch==1 & cohort<5
count
file write outputfile "Switch to a study drug AFTER first" ///
	_tab "`r(N)'" _tab (exc) _n


// Repeat
count if inc_switch6==1 
scalar exc = _N - `r(N)'
keep if inc_switch6==1
count
file write outputfile "Switch within 6 months of original" _tab ///
	"`r(N)'" _tab (exc) _n


// Repeat
count if depressionsympt==1
scalar exc = _N - `r(N)'
keep if depressionsympt==1
count
file write outputfile "Prior depression, ever" _tab "`r(N)'" _tab (exc) _n


// Repeat
count if inc_under100==1 & inc_thirdad==1 & bipolar!=1 & schizophrenia!=1
scalar exc = _N - `r(N)'
keep if inc_under100==1 & inc_thirdad==1 & bipolar!=1 & schizophrenia!=1
count
file write outputfile "No exclusions (age, 3rd ad, bipolar, schizophrenia)" _tab "`r(N)'" _tab (exc) _n



count if cohort==1
file write outputfile "Mirtazapine" _tab "`r(N)'" _tab _n			
count if cohort==2
file write outputfile "SSRI" _tab "`r(N)'" _tab _n	
count if cohort==3
file write outputfile "Amitriptyline" _tab "`r(N)'" _tab _n	
count if cohort==4
file write outputfile "Venlafaxine" _tab "`r(N)'" _tab _n	

file write outputfile _n
*****





*** Close output file
file close outputfile

*** Close script
capture log close countingpatients
frames reset
exit

