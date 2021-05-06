** Created 2020-04-02 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	SummariseDeaths
* Creator:	RMJ
* Date:	20200402
* Desc:	Combine all the cleaned data into one file for analysis
* Requires: 
* Version History:
*	Date	Reference	Update
*	20200402	SummariseDeaths	Create file
*	20200423	SummariseDeaths	Refine file
*	20200506	SummariseDeaths	Don't include patients who start a third ad on index date
*************************************

set more off
frames reset
clear

** Open dataset and restrict to eligible patients
use if keep1==1 & cohort<=4 using data/clean/final_combined.dta
keep if inc_thirdad==1 // for this analysis drop patients who start two antideps on index

** Keep minimal variables
keep cohort index enddate6 endreason6 cod_L*

** Checks
count if enddate6 < index
count if enddate6 == index
tab endreason6 if enddate6==index // no deaths in patients not contributing time

** Restrict to those who died during follow-up
keep if endreason6==1

** For each cause of death variable, put data into a new frame
frame put cohort cod_L1, into(cause1)
frame put cohort cod_L1 cod_L2, into(cause2)
frame put cohort cod_L1 cod_L3, into(cause3)
frame put cohort cod_L1 cod_L4, into(cause4)

** Loop over each of the four cause of death fields
forval X=1/4 {
	// Change to relevant frame
	frame change cause`X'

	// Count how many patients have each cause of death, overall and by cohort
	bys cod_L`X': gen total=_N
	bys cohort cod_L`X': gen grtot=_N

	// Keep one record per cause
	bys cohort cod_L`X': keep if _n==1
	
	// Drop if there is no listed cause of death (except for the highest level - 
	//	missing counted then)
	if `X'!=1 {
		drop if cod_L`X'==.
		}

	// Reshape so each cohort has its own variable
	reshape wide grtot, i(cod_L`X') j(cohort)

	// Convert coded fields into text fields (always record highest level field)
	decode cod_L1, gen(causeA)
	decode cod_L`X', gen(causeB)
	
	// Tidy
	order causeA causeB grtot* total
	keep causeA causeB grtot* total

	// Create marker of which cause of death level is represented
	gen level=`X'
	}
	
** Append each of the tidied datasets to the original
frame change cause2
tempfile temp
save "`temp'"
frame change cause1
append using "`temp'"

frame change cause3
tempfile temp
save "`temp'"
frame change cause1
append using "`temp'"

** For the individual cohort totals, round down to the nearest 5
gen m = floor(grtot1/5) * 5
gen s = floor(grtot2/5) * 5
gen a = floor(grtot3/5) * 5
gen v = floor(grtot4/5) * 5

recode m s a v (.=0)

** Mask if overall total is less than 10
replace total=0 if total==. | total<10

** Sort 
gsort causeA -total

** Convert fields to strings & indicate where masked
foreach Y of varlist m s a v {
	tostring `Y', replace
	replace `Y'="<5" if `Y'=="0"
	}

tostring total, replace
replace total = "<10" if total=="0"	

** Tidy
order causeA causeB m s a v level
drop grtot*

** Export
export delim using outputs/summarisedcauseofdeath.csv, replace

** End
frames reset
clear
