* Created 2021-06-30 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sh30_SummaryOfDose.do
* Creator:	RMJ
* Date:	20210630
* Desc:	Summarises median dose over follow-up, and how many people are still taking the first ad
* Version History:
*	Date	Reference	Update
*	20210630	New file	Create file
*************************************
frames reset
use data/clean/avgdose_selfharm30.dta
merge m:1 patid using data/clean/final_combined.dta, keepusing(cohort) keep(3) nogen

** Average doses (median of the medians)
capture log close dosesum
log using "outputs/sh30_summaryofdose.txt", text append name(dosesum)
// Average doses (median of medians) per cohort
tabstat totMed_mirtazapine, by(cohort) stat(mean sd p25 p50 p75)
tabstat totMed_ssri, by(cohort) stat(mean sd p50 p25 p75)
tabstat totMed_amit, by(cohort) stat(mean sd p50 p25 p75)
tabstat totMed_venlaf, by(cohort) stat(mean sd p50 p25 p75)
tabstat totMed_all, by(cohort) stat(mean sd p50 p25 p75)

tabstat totMedOn_mirtazapine, by(cohort) stat(mean sd p25 p50 p75)
tabstat totMedOn_ssri, by(cohort) stat(mean sd p50 p25 p75)
tabstat totMedOn_amit, by(cohort) stat(mean sd p50 p25 p75)
tabstat totMedOn_venlaf, by(cohort) stat(mean sd p50 p25 p75)
tabstat totMedOn_all, by(cohort) stat(mean sd p50 p25 p75)
log off dosesum

** Who are still taking first SSRI at 3 months?
clear
use data/clean/imputed_sh30_outcome3
gen newstart = index+(28*3)
format newstart enddate6 %dD/N/CY
count if newstop<=newstart
drop if newstop<=newstart
sort patid 
merge 1:m patid using data/clean/antidepexp_selfharm.dta,  keep(3) nogen

foreach X of varlist vortiox-agomelatin {
	replace `X' = (`X'!=0 & `X'<.)
	}
egen numantidep=rowtotal(vortiox-agomelatin)
drop if stop<=newstart
count
bys patid (start): keep if _n==1
count
log on dosesum
tab numantidep cohort, co
log off dosesum

capture log close dosesum
frames reset
exit

