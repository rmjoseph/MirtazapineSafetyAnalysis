* Created 2021-02-24 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	cohortsummary_selfharm
* Creator:	RMJ
* Date:	20210224
* Desc:	Basic summary of numbers, outcomes, follow-up for self harm analysis
* Version History:
*	Date	Reference	Update
*	20210224	cohortsummary_selfharm	Create file
*************************************

frames reset
macro drop _all

** Open the dataset starting with the eligible patients for main analysis
use if keep1==1 & cohort<=4 & indexdate<enddate6 using data/clean/final_combined.dta
count

** End date and outcome accounting for serious self harm
egen newend = rowmin(serioussh_int enddate6)
format newend %dD/N/CY

gen outcome = serioussh_int<=enddate6
replace outcome = 2 if deathdate<=enddate6 & deathdate<serioussh_int
label def outcome 0 "no outcome" 1 "serious self-harm" 2 "death"
label values outcome outcome

** New follow-up time
gen time = (newend-indexdate)*12/365.25

** New reasons for stopping follow-up
replace endreason6 = 5 if newend==serioussh_int
label define endreason 5 "serious self harm", modify

** Distinguishing between self-harm and suicide
gen suicide = outcome==1 & serioussh_int==deathdate & cod_L4==5


** Output in form of log file
log using "outputs/selfharmcohortinfo.txt", text replace name(cohortlog)

*** Numbers in this cohort:
count
drop if newend<=indexdate
count
tab cohort

*** Reasons for stopping follow-up
tab endreason6, m
tab endreason6 cohort, m co chi2

*** number of outcomes overall and by cohort
tab outcome,m
tab outcome cohort,m co chi2

*** average follow-up time
tabstat time, by(cohort) stat(N median p25 p75 mean sd)

*** suicide
tab suicide,m

*** close log
log close cohortlog


** END
frames reset
exit
