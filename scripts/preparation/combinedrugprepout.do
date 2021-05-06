* Created 2020-02-05 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	combinedrugprepout
* Creator:	RMJ
* Date:	20200205
* Desc:	Combines all of the cleaned drug exposure data files from drugprep
* Version History:
*	Date	Reference	Update
*	20200205	EligibleDrugHistory	Create file based on start of reference file
*	20200205	combineddrugprepout	Use the new newdose variable created in drugprep
*	20200206	Drop records while appending to prevent over-large file
*************************************

set more off
frames reset
clear

** LOG
capture log close appending
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/combine_antideps_`date'.txt", text append name(appending)
*log using "combine_antideps_`date'.txt", text append name(appending)

** Load and append each of the cleaned datasets from drugprep (should be oral meds only)

display "$S_TIME  $S_DATE"
forvalues FILE = 1/35 {
	** Append each file
	append using data/clean/ad`FILE'_post_drugprep_out.dta, keep(patid prodcode start real_stop antideptype antidepdrug newdose drugcode)

	di "For " antideptype[_N] + " " + antidepdrug[_N]
	
	** Keep only the first record of the newly appended drug, unless it is one of the study drugs
	
	capture drop keep
	gen keep = (antideptype=="ssri" | drugcode==20 | drugcode==2 | drugcode==33 | drugcode==10)
	
	sort patid drugcode start
	by patid drugcode: drop if _n>1 & keep==0
	
	}
drop keep
display "$S_TIME  $S_DATE"	


** Format start and stop variables
format start real_stop %dD/N/CY


** Change string variables to categorical to reduce memory load
encode antideptype, gen(type)
encode antidepdrug, gen(drug)
drop antidep*
rename type antideptype
rename drug antidepdrug
compress

** Recode the antidep types so that SSRIs are always first in sort 
** (So, if on first ever ad day the patient has SSRI + a different ad, the SSRI will always be detected)
recode antideptype (3=1) (1=3) // added 2020-02-05
label define type 1 "ssri" 3 "maoi", modify // added 2020-02-05


**** Merge in the info about drug type and strength
merge m:1 prodcode using data/clean/drugstrengths
drop if _merge==2
drop _merge
compress strength

**** DROP DRUGS RECORDED AS CREAMS (Shouldn't be any)
drop if type=="cream"

**** DROP DRUG RECORDS FOR INJECTIONS, THEN APPEND THEM BACK IN
drop if type=="injection"
append using data/clean/antidepinjections.dta

*** TIDY AND SAVE
keep patid prodcode start real_stop antideptype antidepdrug strength newstrength units type newdose unitstrength
rename newdose dose

sort patid start antideptype antidepdrug
saveold data/clean/combinedcleanedantideps.dta, replace

frames reset

log close appending
exit
