* Created 2021-03-12 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sh30_cohortsummary_selfharm
* Creator:	RMJ
* Date:	20210312
* Desc:	Basic summary of numbers, outcomes, follow-up for self harm analysis (using enddate30)
* Version History:
*	Date	Reference	Update
*	20210312	cohortsummary_selfharm	Create file
*************************************

frames reset
macro drop _all

** Open the dataset starting with the eligible patients for main analysis
use if keep1==1 & cohort<=4 & indexdate<enddate30 using data/clean/final_combined.dta
count

** End date and outcome accounting for serious self harm
egen newend = rowmin(serioussh_int enddate30)
format newend %dD/N/CY

gen outcome = serioussh_int<=enddate30
replace outcome = 2 if deathdate<=enddate30 & deathdate<serioussh_int
label def outcome 0 "no outcome" 1 "serious self-harm" 2 "death"
label values outcome outcome

** New follow-up time
gen time = (newend-indexdate)*12/365.25

** New reasons for stopping follow-up
replace endreason30 = 5 if newend==serioussh_int
label define endreason 5 "serious self harm", modify

** Distinguishing between self-harm and suicide
gen suicide = outcome==1 & serioussh_int==deathdate & cod_L4==5


** Output in form of log file
log using "outputs/sh30_selfharmcohortinfo.txt", text replace name(cohortlog30)

*** Numbers in this cohort:
count
drop if newend<=indexdate
count
tab cohort

*** Reasons for stopping follow-up
tab endreason30, m
tab endreason30 cohort, m co chi2

*** number of outcomes overall and by cohort
tab outcome,m
tab outcome cohort,m co chi2

*** average follow-up time
tabstat time, by(cohort) stat(N median p25 p75 mean sd)

*** suicide
tab suicide,m
*tab suicide cohort, m co chi2

*** close log
log close cohortlog30


** END
frames reset
exit
