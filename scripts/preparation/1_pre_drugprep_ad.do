* Copyright (c) Arthritis Research UK Centre for Epidemiology, University of Manchester (2016-2018)
* MODIFIED 09-Dec-2019 by RMJ at the University of Nottingham
*************************************
* Name:	1_pre_drugprep_ad.do
* Creator:	Based on file from UoM
* Date:	20191209
* Desc:	Modify antidepressant dataset to allow drugprep to run
* Requires: Stata 16 for frames function
* Version History:
*	Date	Reference	Update
*	20191209	1_pre_drugprep_ad	Create file
*	20191216	1_pre_drugprep_ad	Merge common_dosages rather than importing txt
*	20190108	1_pre_drugprep_ad	Save individual files for each drug substance
*	20200205	1_pre_drugprep_ad	Add section calculating dose
*	20200205	1_pre_drugprep_ad	Remove section cleaning numdays
*************************************

* VARS NEEDED: patid prodcode start qty ndd numdays dose_duration textid

** SET UP
set more off
frames reset
frame change default
clear


** Open the antidepressants file
use data/raw/stata/antidep_records.dta
keep patid prodcode eventdate qty numdays dosageid issueseq antideptype antidepdrug

** Drop records missing prodcode or eventdate, or with prodcode==1
drop if prodcode==.
drop if eventdate==.
drop if prodcode == 1

** Generate the variable 'start'
rename eventdate start

** Get dosage info by merging in the common_dosages file
merge m:1 dosageid using data/raw/stata/common_dosages.dta, keepusing(daily_dose dose_duration)
drop if _merge==2
drop _merge

** Rename daily_dose ndd to match name in the algorithm
rename daily_dose ndd

** Recode values of 0 to missing
recode qty 0=.
recode ndd 0=.
recode numdays 0=.
recode dose_duration 0=.

** Calculate dose before any changes to ndd // section added 2020-02-05
merge m:1 prodcode using data/clean/drugstrengths
drop if _merge==2
drop _merge
drop strength

drop if type=="cream" // only topical doxepin (licensed for eczema)
drop if type=="injection" // dealt with separately later

gen dose = ndd * newstrength

// replace high and low values of dose with upper and lower centiles (on visual exam
// seems these correspond to the recommendations in the bnf)
// Convert drug names into a numeric code
encode antidepdrug, gen(drugcode)

gen newdose = dose

forvalues X = 1/35 {

	qui sum dose if drugcode == `X', d

	replace newdose = r(p1) if newdose<r(p1) & drugcode==`X'
	replace newdose = r(p99) if newdose>r(p99) & newdose<. & drugcode==`X'

	}


** Generate presc_id variable needed later in algorithm
sort patid prodcode start qty ndd numdays dose_duration	// (sort is just to be reproducible - many duplicates present but this doesn't matter?)
gen presc_id = _n

** Tidy
order patid prodcode qty numdays ndd dose_duration start
compress
rename dosageid textid


****** LOOP ADDED 20200108
// Convert drug names into a numeric code
*encode antidepdrug, gen(drugcode) // already done

// Open loop to keep only those with a certain code to save as separate files
forvalues X = 1/35 {
	// copy data for each numeric code into a new frame and change to this frame
	frame put if drugcode == `X', into(saveframe)
	frame change saveframe
	
	** Display the total number of prescriptions
	local num_presc = _N
	notes: "Total prescriptions = `num_presc'"

	** Save file ready for use
	// saving a subset of the original data file
	saveold data/clean/ad`X'_pre_drugprep_out.dta, replace
	
	// change back to default and remove the new frame
	frame change default
	frame drop saveframe
	
	// if drop data as go may run faster?
	drop if drugcode == `X'
}

exit
