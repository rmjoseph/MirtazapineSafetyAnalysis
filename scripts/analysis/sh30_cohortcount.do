* Created 20210629 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sh30_cohortcount
* Creator:	RMJ
* Date:	20210629
* Desc:	Summarises number of people dropped when defining the cohort
* Version History:
*	Date	Reference	Update
*	20210629	new file	Create file
*************************************

frames reset
set more off

use data/clean/final_combined.dta

capture log close cohortcount
log using "outputs/sh30_cohortcount.txt", text replace name(cohortcount)



count
*** BOX 1 (SSRI users prescribed an SSRI in specified window, plus follow-up rules)
count if inc_extracted!=1 | inc_perm!=1 | inc_followup!=1 | inc_ssri!=1
keep if inc_extracted==1
keep if inc_perm==1
keep if inc_followup==1
keep if inc_ssri==1
count

*** BOX 2 (linked)
keep if inc_linked==1
count

*** BOX 3 (first AD is ssri)
keep if inc_firstisssri==1
count

*** BOX 4 (second AD is study drug)
count if inc_everswitch!=1 | inc_switchofinterest!=1 | cohort>=5
keep if inc_everswitch==1
keep if inc_switchofinterest==1 & cohort<5
count

*** BOX 5 (second AD within specified window)
count if inc_switchafter!=1 | inc_switch90d!=1
keep if inc_switchafter==1
keep if inc_switch90d==1
count

*** BOX 6 (depression within specified window)
count if depression!=1 | depress_12!=1
keep if depression==1
keep if depress_12==1
count

*** BOX 7 (after applying exclusions: no thirdad, under100, no bipolar or schizophrenia, no hosp self harm)
count if inc_thirdad!=1 | inc_under100!=1 | bipolar==1 | schizophrenia==1 | bl_intselfharm==1
keep if inc_thirdad==1
keep if inc_under100==1 & bipolar!=1 & schizophrenia!=1
keep if bl_intselfharm!=1
count

log close cohortcount

clear
exit
