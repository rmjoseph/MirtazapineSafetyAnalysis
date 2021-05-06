* Created 2020-07-30 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	ReasonStopFollowup
* Creator:	RMJ
* Date:	20200730
* Desc:	Outputs percentages of patients per cohort according to reasons for follow-up end
* Version History:
*	Date	Reference	Update
*	20200730	ReasonStopFollowup	Create file
*	20210104	ReasonStopFollowup	Drop those with 0 followup
*************************************

*** Log
capture log close stopfup
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/stopfollowup`date'.txt", text append name(stopfup)
*******

frames reset
clear

use if keep1==1 & cohort<=4 using data/clean/final_combined.dta
drop if enddate6==index 

*** Recreate tabulation "tab endreason6 cohort,m chi2 co"
frame put cohort endreason6, into(results)
frame change results

** Work out totals by reason for stopping followup and cohort
bys cohort endreason6: gen grouptot=_N
bys cohort endreason6: keep if _n==1

** Change dataset layout to wide to match table
reshape wide grouptot , i(endreason6) j(cohort)

** Create a column containing totals according to reason for stopping followup
egen total = rowtotal(grouptot1 grouptot2 grouptot3 grouptot4)

** Create a 5th row which will contain the cohort totals
set obs 5
decode endreason6, gen(reason)
replace reason = "TOTAL" if _n==5
drop endreason6
order reason, first

** Fill in this 5th row with totals, then convert all other cells to column percentages
foreach X of varlist grouptot* total {
	egen sum = sum(`X')	// temp var with column total
	replace `X' = (`X'/sum)*100	// use temp var to work out cell percentage
	replace `X'=sum if _n==5	// temp var becomes the TOTAL row
	tostring `X', replace force format(%9.1fc)	// convert cells to strings in tidy display format
	replace `X' = `X' + "%" if _n<5	// Add percentage symbol
	replace `X' = subinstr(`X',".0","",1) if _n==5	// Remove superfluous decimal point from TOTAL
	drop sum
}

** Rename variables
rename grouptot1 mirtazapine
rename grouptot2 ssri
rename grouptot3 amitriptyline
rename grouptot4 venlafaxine

** Save as csv output
export delim using outputs/ReasonForEndOfFollowup.csv, replace


** Exit
frames reset
capture log close stopfup
exit
