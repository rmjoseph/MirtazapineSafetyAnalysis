** CREATED 06-10-2020 by RMJ at the University of Nottingham
*************************************
* Name: TimeVaryingAntidepExposure
* Creator:	RMJ
* Date:	20201006
* Desc:	Clean antidepressant exposure history with start stop and dose vars
* Requires: Stata 16 for frames functionality; tvc_split; tvc_merge
* Version History:
*	Date	Reference	Update
*	20201006	TimeVaryingAntidepExposure	Create file
*	20201007	TimeVaryingAntidepExposure	Add loop for tvc_split
*	20201007	TimeVaryingAntidepExposure	Only include eligible patients
*	20200108	TimeVaryingAntidepExposure	Also sum for all antideps
*	20200108	TimeVaryingAntidepExposure	Add section working out averages
*	20201012	TimeVaryingAntidepExposure	Fill in missing values for stop date
*	20201012	TimeVaryingAntidepExposure	Add small increment if start==stop
*************************************
** Note: guided by tvc_merge user guide 

** LOG
capture log close tvad
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/timevaryingantideps_`date'.txt", text append name(tvad)

**
set more off
frames reset

** Load patient list
frame create patlist
frame change patlist
use patid keep* using data/clean/final_combined.dta
egen keep = rowtotal(keep*)
keep if keep>0 & keep<.
count
keep patid

** Load drug data
frame change default
use data/clean/antidepsubsetfortimevaryingexp.dta

** Only keep patient subset
frlink m:1 patid, frame(patlist)
count
keep if patlist<.
count

** want to work with antidep names so decode
decode antidepdrug, gen(drug)

** get defined daily doses
frame create ddd
frame change ddd

import delimited using data/codelists/DefinedDailyDose_20200220.csv
keep adcode ddd
rename adcode antidepdrug
rename ddd defdd

frame change default
frlink m:1 antidepdrug, frame(ddd)
frget defdd, from(ddd)
drop ddd
gen ddd = cleandose/defdd


** Create a 'dates' dataset, with eligstart date and exit date
** (using eligstart so can calculate ALL the antidep exposure)
frame create dates
frame change dates
clear

use patid eligstart eligstop using data/clean/combinedpatinfo.dta
keep if eligstart<.
order patid eligstart eligstop


** Deal with each antidepressant in turn. This will include converting to ddd.
frame change default
capture frame drop tvc
frame create tvc

capture frame drop drugframe

*local drugs "agomelatin amitriptyline amoxapine butriptyline citalopram clomipramine desipramine dosulepin doxepin duloxetine escitalopram fluoxetine flupentixol fluvoxamine imipramine iprindole isocarboxazid lofepramine mianserin mirtazapine moclobemide nefazodone nortriptiline paroxetine phenelzine protriptyline reboxetine sertraline tranylcypromine trazodone trimipramine tryptophan venlafaxine viloxazine vortioxetine"

levelsof drug, local(drugs)
*local drugs "agomelatin amitriptyline"
*local drugs "duloxetine"

foreach X of local drugs { 
	di "`X'"

	// First, strip down the dataset
	frame change default
	capture frame drop drugframe
	frame put if drug=="`X'", into(drugframe)
	frame change drugframe

	keep patid start real_stop ddd
	rename ddd `X'
	rename real_stop stop
	sort patid start stop

	** ADDED RMJ 2020-10-12
	** Make missing stop date the earliest of: the next start date for that dose, or start+median duration
	** where median duration is by patid dose, patid, dose, or overall

	// calculate the time between starting consecutive prescs
	bys patid `X' (start stop): gen next = start[_n+1] - start

	// calculate medians
	bys patid `X': egen med1 = median(stop-start)
	bys patid : egen med2 = median(stop-start)
	bys `X': egen med3 = median(stop-start)
	egen med4 = median(stop-start)

	egen maxmed = rowmax(med1 med2 med3 med4)

	// replace stop with start of next if gap to next is shorter than any of the medians
	gen newstop=stop
	format newstop %dD/N/CY
	bys patid `X' (start stop): replace newstop=start+next if newstop==. & next<maxmed
	// otherwise replace with median in sequence
	replace newstop = start + med1 if newstop==.
	replace newstop = start + med2 if newstop==.
	replace newstop = start + med3 if newstop==.
	replace newstop = start + med4 if newstop==.

	replace stop=newstop if stop==.
	count if stop==.
	drop newstop med1 med2 med3 med4 maxmed next
	
	// if stop==start
	replace stop=stop+0.1 if stop==start
	**

	// if patients have overlapping records (>1 dose):
	
	** Split patients into groups of (1000) by creating a new index variable then
	** using this to create a group variable
	
	** New patient index: label first record per patient then use replace
	** to sequentially sum
	bys patid: gen newindex = 1 if _n==1
	replace newindex = sum(newindex)
	replace newindex = ceil(newindex/1000) // groups of (1000) patients
	
	** Loop the tvc_split over the groups of patients created in previous step,
	** as it struggles with large datasets
	capture frame drop newframe
	frame create newframe

	qui sum newindex
	di r(max)
	
	** open forvalues loop X
	forvalues Z = 1/`r(max)' {
		
		display "$S_TIME  $S_DATE"
		di `Z'

		frame change drugframe

		// For each of the patient subgroups, copy into a new frame
		capture frame drop tempframe	
		frame put if newindex==`Z', into(tempframe)
		drop if newindex==`Z' // to reduce amount of memory used
		frame change tempframe
		
		** split the data 
		count
		tvc_split start stop, common(patid)
		format stop %dD/N/CY
		sort patid start stop
		count

		** sum the doses
		bys patid start stop: egen sum=sum(`X')
		replace `X' = sum
		drop sum

		** keep one record
		bys patid start stop: keep if _n==1 
		
		// save temporary file and append into the newframe
		tempfile patsplit
		save `patsplit', replace
		frame change newframe
		append using `patsplit'
		
		// reset the loop
		frame change drugframe
		frame drop tempframe
		
		} 
	
	// Copy the newly created split dataset from newframe into the default frame
	frame change newframe
	frame drop drugframe
	frame rename newframe drugframe	
	

	// Where patients have multiple continuous prescriptions for the same strength, collapse
	bys patid `X' (start): replace start=start[_n-1] if start<=stop[_n-1] & _n!=1
	bys patid `X' start (stop): keep if _n==_N

	sort patid start stop

	// merge with the dates data
	frame change dates
	tempfile dates
	save "`dates'", replace

	frame change drugframe
	merge m:1 patid using "`dates'", keep(3) nogen

	// drop records end before or start after eligstart and eligstop (shouldn't really be any)
	drop if stop<eligstart
	drop if start>=eligstop

	// Fill in gaps between prescriptions with dose = 0
	sort patid start
	by patid: gen to_expand = (stop < start[_n+1] & _n!=_N)
	replace to_expand = to_expand+1
	expand to_exp

	sort patid start
	bys patid start: gen new_rec = (_n==2)

	replace `X' = 0 if new_rec==1
	replace stop = start[_n+1] if new_rec==1
	replace start = stop[_n-1] if new_rec==1

	drop to_expand new_rec

	// If last prescription ends after eligstop, change stop date
	replace stop = eligstop if start<eligstop & stop>eligstop

	// No changes to records starting before eligstart (these patients should be excluded anyway)

	// Fill in gap between last prescription and eligstop
	bys patid (start): gen to_expand = (_n==_N & stop<eligstop)
	replace to_expand = to_expand+1
	expand to_expand

	sort patid start
	bys patid start: gen new_rec=_n==2

	replace `X' = 0 if new_rec==1
	replace stop = eligstop if new_rec==1
	replace start = stop[_n-1] if new_rec==1

	drop to_expand new_rec

	// Fill in gap between elig start and first prescription
	bys patid (start): gen to_expand=(_n==1 & start>eligstart)
	replace to_expand = to_expand+1
	expand to_expand
	sort patid start

	bys patid start: gen new_record = (_n==2)

	replace `X' = 0 if new_rec==1
	replace start = eligstart if new_rec==1
	sort patid start stop
	replace stop = start[_n+1] if new_rec==1

	drop to_expand new_rec

	// records where start==stop
	count if start==stop
	replace stop = stop+0.1 if start==stop
	
	// save for merging
	drop eligstart eligstop
	tempfile tomerge
	save "`tomerge'", replace

	// Merge with the rest of the antideps
	frame change tvc
	if "`X'"== "agomelatin" {
		use "`tomerge'", clear
		} 
	else {
		tvc_merge start stop using "`tomerge'", id(patid)
		format stop %dD/N/CY
		}

	drop newindex
	
	// save as go in case of crashes	
	save data/clean/preparedtimevaringads.dta, replace
		
	}
	
recode vortioxetine-agomelatin (.=0)

save data/clean/preparedtimevaringads.dta, replace



** PREPARE AND MERGE ADVERSE EVENTS DATA 
**** mortality
frame create mort
frame change mort

** Get death info and limit to eligible
use patid deathdate cod_*  using data/clean/final_combined.dta, clear
frlink m:1 patid, frame(patlist)
count
keep if patlist<.
drop patlist

** keep only if died
keep if deathdate<.

** get dates
frlink m:1 patid, frame(dates)
frget *, from(dates)
drop dates

** define outcome var
rename deathdate stop
gen died = stop<.

gen causeofdeath = 0
replace causeofdeath = 1 if died==1 & cod_L1==5	// cardiovasc
replace causeofdeath = 2 if died==1 & cod_L1==2	// cancer
replace causeofdeath = 3 if died==1 & cod_L1==9	// respiratory
replace causeofdeath = 4 if died==1 & cod_L3==9	// suicide (intentional/undetermined) // changed from cod_L2==30
replace causeofdeath = 5 if died==1 & causeofdeath == 0	// other death

drop cod_*

** start var
gen start = eligstart
replace stop = start+0.1 if stop<=start
order patid start stop
format start stop %dD/N/CY

** merge with exposure vars
keep patid stop start causeofdeath
tempfile temp
save "`temp'", replace

use data/clean/preparedtimevaringads.dta, clear
tvc_merge start stop using "`temp'", id(patid) failure(causeofdeath)
format start stop %dD/N/CY

recode vortiox-agomelatin (.=0)

gen died=(causeofdeath>0 & causeofdeath<.)
order patid start stop died causeofdeath

** check when records were recorded
frlink m:1 patid, frame(dates)
frget *, from(dates)
drop dates
order patid eligstart start stop eligstop
// shouldn't be any before eligstart: these pats should already be excluded
count if start<eligstart // have already set start=eligstart
count if stop<=eligstart
// records could happen after eligstop but don't need them
count if stop>eligstop
count if start>=eligstop
drop if start>=eligstop

** tidy
order patid start stop died causeofdeath
drop eligstop eligstart
tab died causeofdeath,m

** add variables for the four AD types
egen ssri = rowtotal(citalopram escitalopram fluoxetine fluvoxamine paroxetine sertraline)
egen tca = rowtotal(amitriptyline clomipramine dosulepin doxepin imipramine lofepramine mianserin nortriptiline trazodone trimipramine) // no amoxapine desipramine protriptyline viloxazine
egen maoi = rowtotal(moclobemide phenelzine ) // no isocarboxazid tranylcypromine
egen other = rowtotal(agomelatin duloxetine flupentixol mirtazapine  reboxetine tryptophan venlafaxine vortioxetine) // no nefazodone
egen allantidep = rowtotal(vortiox-agomelatin)

** save
saveold data/clean/antidepexp_mortality.dta, replace



**** self harm
frame create selfharm
frame change selfharm

** get self harm info and limit to eligible patients
use patid serioussh_int using data/clean/final_combined.dta, clear
frlink m:1 patid, frame(patlist)
count
keep if patlist<.
drop patlist

** get dates
frlink m:1 patid, frame(dates)
frget *, from(dates)
drop dates

** rename vars and make outcome var
rename serioussh_int stop
gen shevent = 1 if stop<.
tab shevent

** keep only if have event
keep if shevent==1

** start is date of previous event
sort patid stop
by patid: gen start=stop[_n-1] if _n>1
bys patid: replace start = eligstart if _n==1 // all pats have single record

** if event is before eligstart, should be dropped in the analysis. Fix start date.
replace start = stop if stop<start

** add small increment in case start and stop are same date
replace stop=stop+0.1 if start==stop 

** merge with exposures
keep patid start stop shevent
tempfile sh
save "`sh'", replace

use data/clean/preparedtimevaringads.dta, clear
tvc_merge start stop using "`sh'", id(patid) failure(shevent)

recode vortiox-agomelatin (.=0)
format start stop %dD/N/CY

** check when records were recorded
frlink m:1 patid, frame(dates)
frget *, from(dates)
drop dates
order patid eligstart start stop eligstop
// events can happen before eligstart, but the patients should be excluded
count if start<eligstart 
count if stop<=eligstart
// records could happen after eligstop but don't need them
count if stop>eligstop
count if start>=eligstop
drop if start>=eligstop

** tidy
order patid start stop shevent
drop eligstop eligstart
tab shevent,m

** add variables for the four AD types
egen ssri = rowtotal(citalopram escitalopram fluoxetine fluvoxamine paroxetine sertraline)
egen tca = rowtotal(amitriptyline clomipramine dosulepin doxepin imipramine lofepramine mianserin nortriptiline trazodone trimipramine) // no amoxapine desipramine protriptyline viloxazine
egen maoi = rowtotal(moclobemide phenelzine ) // no isocarboxazid tranylcypromine
egen other = rowtotal(agomelatin duloxetine flupentixol mirtazapine  reboxetine tryptophan venlafaxine vortioxetine) // no nefazodone
egen allantidep = rowtotal(vortiox-agomelatin)

** save
saveold data/clean/antidepexp_selfharm.dta, replace




** CALCULATE AVERAGE DOSES OVER SPECIFIED TIMES
** Run the utility to calculate average dose
include scripts/preparation/CalcAvgDose.do

**** Mortality
** Load data and get/make follow-up variables (core analysis)
frame change mort
use data/clean/antidepexp_mortality.dta, clear

merge m:1 patid using data/clean/final_combined.dta, keepusing(ageindex sex cohort index enddate6 keep1 eligstart eligstop) keep(3) nogen
order patid cohort sex ageindex eligstart eligstop index start stop

gen time = stop if died==1
replace time = enddate6 if time==.
bys patid: egen exit = min(time)
format exit enddate6 %dD/N/CY
drop time


** Loop the utility over variables of interest
**	syntax, ORIGFrame(string) ENTER(varlist max=1) EXIT(varlist max=1) DRUG(varlist max=1)
frame change mort
foreach X of varlist mirtazapine ssri amitriptyline venlafaxine allantidep citalopram escitalopram fluoxetine fluvoxamine paroxetine sertraline {
	CALCDOSE, origf(mort) enter(index) exit(exit) drug(`X')
}

** Restrict dataset
keep if keep1==1
keep if cohort<5
drop if stop<=index
drop if start>=exit
misstable sum

** Keep first record per patient
codebook patid
keep if start==index
count

** Keep vars of interest
keep patid mirtazapine ssri amitriptyline venlafaxine allantidep totMed* citalopram escitalopram fluoxetine fluvoxamine paroxetine sertraline

** Rename vars 
foreach X of varlist mirtazapine ssri amitriptyline venlafaxine allantidep citalopram escitalopram fluoxetine fluvoxamine paroxetine sertraline {
	rename `X' firstDose_`X'
	label var firstDose_`X' "Dose (ddd) of drug `X' on index date"
}

foreach X of varlist totMed_* {
	label var `X' "Median dose (ddd) over followup (including when off drug)"
}

foreach X of varlist totMedOn_* {
	label var `X' "Median dose (ddd) over followup (only when on drug)"
}

** Save
saveold data/clean/avgdose_mortality.dta, replace



**** Self harm
** Load data and get/make follow-up variables (core analysis)
frame change selfharm
use data/clean/antidepexp_selfharm.dta, clear

merge m:1 patid using data/clean/final_combined.dta, keepusing(ageindex sex cohort index enddate6 keep1 eligstart eligstop) keep(3) nogen
order patid cohort sex ageindex eligstart eligstop index start stop

gen time = stop if shevent==1
replace time = enddate6 if time==.
bys patid: egen exit = min(time)
format exit enddate6 %dD/N/CY
drop time

** Loop the utility over variables of interest
**	syntax, ORIGFrame(string) ENTER(varlist max=1) EXIT(varlist max=1) DRUG(varlist max=1)
frame change selfharm
foreach X of varlist mirtazapine ssri amitriptyline venlafaxine allantidep citalopram escitalopram fluoxetine fluvoxamine paroxetine sertraline {
	CALCDOSE, origf(selfharm) enter(index) exit(exit) drug(`X')
}

** Restrict dataset
keep if keep1==1
keep if cohort<5
drop if stop<=index
drop if start>=exit
misstable sum

** Keep first record per patient
codebook patid
keep if start==index
count

** Keep vars of interest
keep patid mirtazapine ssri amitriptyline venlafaxine citalopram escitalopram fluoxetine fluvoxamine paroxetine sertraline allantidep totMed*

** Rename vars 
foreach X of varlist mirtazapine ssri amitriptyline venlafaxine citalopram escitalopram fluoxetine fluvoxamine paroxetine sertraline allantidep {
	rename `X' firstDose_`X'
	label var firstDose_`X' "Dose (ddd) of drug `X' on index date"
}

foreach X of varlist totMed_* {
	label var `X' "Median dose (ddd) over followup (including when off drug)"
}

foreach X of varlist totMedOn_* {
	label var `X' "Median dose (ddd) over followup (only when on drug)"
}

** Save
saveold data/clean/avgdose_selfharm.dta, replace



*****
frames reset
capture log close tvad
exit
