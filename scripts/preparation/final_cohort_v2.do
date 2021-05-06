* CREATED BY RMJ AT THE UNIVERSITY OF NOTTINGHAM 2020-01-20
*************************************
* Name:	final_cohort_v2.do
* Creator:	RMJ
* Date:	20200120
* Desc: Combines all data needed to work out eligibility
* Requires: Stata 16 (Frames function)
* Version History:
*	Date	Reference	Update
*	20200120	final_cohort	Keep patients but create tags for why people dropped
*	20200218	final_cohort_v2	Keep secondaddate
*	20200218	final_cohort_v2	Update ssris as adtype==1 after changes in other scripts
*	20200422	final_cohort_v2	Change eligibility window def to drop same dates
*	20200423	final_cohort_v3	Change SSRI in elig window to exlude eligstop
*	20200423	final_cohort_v3	Add step - exclude if third ad starts same day
*	20200506	final_cohort_v3	Change indexdate on/before end to before end
*************************************

** LOG
capture log close finalelig
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/finaleligibility_`date'.txt", text append name(finalelig)


** Set up
set more off
frames reset
clear

** Files to combine: combinedpatinfo, eligibledrughistory, antidep_records
frame create patient
frame change patient
use data/clean/combinedpatinfo.dta


** Antidepressant history - 1:1, load and merge
frame create antidep
frame change antidep
clear
use data/clean/eligibledrughistory.dta, clear

frame change patient
frlink 1:1 patid, frame(antidep)
frget *, from(antidep)
replace antidep = (antidep <.)

frame drop antidep


** First uts SSRI
frame create ssri
frame change ssri

use patid eventdate antideptype using data/raw/stata/antidep_records.dta
keep if antideptype=="ssri"
bys patid (eventdate): keep if _n==1
rename eventdate firstssri

keep patid firstssri

frame change patient
frlink 1:1 patid, frame(ssri)
frget *, from(ssri)
replace ssri = (ssri <.)

rename ssri extracted

frame drop ssri


*** CREATE INDICATOR VARIABLES FOR INCLUSION EXCLUSION CRITERIA
* SSRI prescription within study window, first after age 18 & uts+1
gen inc_extracted = (extracted==1)

* Permanently registered acceptable
gen inc_perm = (perm==1 & accept==1)

* Linkage with ONS and HES; joined practice before linkage made
gen inc_linked = (hes_e==1 & death_e==1 & frd <= linkdate)

* Eligibility start on/before eligibility end
gen inc_followup = (eligstart < eligstop)	// 2020-04-22 CHANGED FROM <=

* First SSRI on or after eligibility start & on or before eligibility end 
gen inc_ssri = (eligstart <= firstssri & firstssri < eligstop) // 2020-04-23 CHANGED FROM <= eligstop

* At least one prescription for one of comparator drugs within eligiblity window
// actually, at least one switch to drug of interest within eligibility window
gen inc_switchofinterest = ((secondadtype==1 | secondaddrug==20 | secondaddrug==2 | secondaddrug==33 | secondaddrug==10) & ///
	(eligstart <= secondaddate & secondaddate < eligstop)) // 2020-05-06 CHANGED FROM <= eligstop

* First switch to one of comparator drugs is AFTER first SSRI and within (90 days/6 months) of prev SSRI ending
gen inc_switchafter = (firstaddate<secondaddate)
gen inc_switch90d = (secondaddate - stopad1) <= 90
gen inc_switch6m = (secondaddate - stopad1) <= (365.25/2)

* (depression code <12 months before first ad up to index presc - ignore for now)
// ignore at this point


** EXCLUSION CRITERIA, BUT CODED IN REVERSE AS INCLUSIONS TO AVOID MISUNDERSTANDINGS LATER
* Age 100 or over at index date
gen inc_under100 = (secondaddate < date100)

* First ever antidep is not an SSRI
gen inc_firstisssri = (firstadtype==1)

* First ever ad switch is not to drug of interest
// incorporated into inclusion above

* (record of bipolar or schizophrenia before index - ignore for now)
// ignore at this point

* Third antidep on same day as second // aded 23/04/2020
gen inc_thirdad = (secondaddate < thirdaddate & secondaddate<. )


** ADDITIONAL CRITERIA FOR COUNTING LATER
gen inc_everswitch = (secondaddate < .)



*** Indicate those meeting all above criteria (EXCEPT inc_switch90d and inc_thirdad)
gen eligible = (inc_extracted==1 & ///
				inc_perm==1 & ///
				inc_linked==1 & ///
				inc_followup==1 & ///
				inc_ssri==1 & ///
				inc_switchofinterest==1 & ///
				inc_switchafter==1 & ///
				inc_switch6m==1 & ///
				inc_under100==1 & ///
				inc_firstisssri==1 & ///
				inc_everswitch==1)


*** KEEP ONLY PATIENTS WHO MEET THE HIGHEST-LEVEL CRITERIA, i.e. those extracted
keep if inc_extracted==1



*** Keep variables of interest
keep patid inc_* eligible secondaddate

saveold data/clean/finalcohort.dta, replace


log close finalelig
clear
exit



