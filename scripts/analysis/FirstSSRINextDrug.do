* Created 2021-01-19 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	FirstSSRINextDrug
* Creator:	RMJ
* Date:	20210119
* Desc:	Outputs percentages of patients according to their first SSRI and the next drug
* Version History:
*	Date	Reference	Update
*	20210119	ReasonStopFollowup	Create file
*	20210119	FirstSSRINextDrug	Include (rounded) counts in the table.
*************************************

*** Log
capture log close whichssri
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/FirstSSRI`date'.txt", text append name(whichssri)
*******

frames reset
clear

*** Open data file
use if cohort<5 & inc_thirdad==1 & keep1==1 using data/clean/final_combined.dta
count

*** Remove the small number of patients who start or stop fluvoxamine 
drop if firstaddrug==14
drop if secondaddrug==14
tab firstaddrug secondaddrug, co 

*** Recreate tabulation "tab firstaddrug secondaddrug,m chi2 co"
frame put firstaddrug secondaddrug, into(results)
frame change results

** Work out totals by reason for stopping followup and cohort
bys firstaddrug secondaddrug: gen N_=_N
bys firstaddrug secondaddrug: keep if _n==1

** Change drug names to strings to simplify reshape
decode firstaddrug, gen(first)
drop firstaddrug
decode secondaddrug, gen(second)
drop secondaddrug

** Change dataset layout to wide to match table
reshape wide N_ , i(first) j(second) string

** Create a column containing totals according to reason for stopping followup
egen total = rowtotal(N_*)

** Create a 6th row which will contain the column totals // 6 if drop fluvoxamine at start
set obs 6
replace first = "TOTAL" if _n==6

** Fill in this 7th row with totals, then convert all other cells to column percentages
foreach X of varlist N_* total {
	egen sum = sum(`X')	// temp var with column total
	replace `X'=sum if _n==6	// temp var becomes the TOTAL row
	
	gen p_`X' = (`X'/sum)*100	// use temp var to work out cell percentage
	tostring p_`X', replace force format(%9.1fc)	// convert cells to strings in tidy display format
	
	replace `X' = floor(`X'/5) * 5 // round down to nearest 5
	tostring `X', replace // convert number to string
	
	replace `X' = `X' + " (" + p_`X' + "%)" // concetenate
	
	replace `X' = " " if `X'==". (.%)"
	drop sum p_`X'
}


** Tidy
order N_mirtaz N_amitrip N_venlaf total, last

** Save as csv output
export delim using outputs/FirstSSRISecondDrug.csv, replace

** Exit
frames reset
capture log close whichssri
exit

