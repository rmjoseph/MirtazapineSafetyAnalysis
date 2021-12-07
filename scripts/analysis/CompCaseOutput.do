* Created 2021-11-26 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	CompCaseOutput
* Creator:	RMJ
* Date:	20211126
* Desc:	Creates formatted output for complete case analysis, all outcomes
* Version History:
*	Date	Reference	Update
*	20211126	CompCaseOutput	Create file
*************************************
set more off
frames reset

**# Get counts for time and events
use data/clean/imputed_outcome2, clear

egen complete = rownonmiss(bmi townsend smokestat alcoholintake ethnicity)
replace complete = (complete==5)
keep if complete==1

forval COD=1/3 {
	local countsrowname "Complete case: `COD'"
	gen outcome=(died_cause==`COD')
	include scripts/analysis/TabulateCounts.do
	drop outcome
	}

local countsrowname "Complete case: all cause"
gen outcome=(died==1)
include scripts/analysis/TabulateCounts.do
*****



frames reset
frame create counts
frame counts {
	use data/clean/sensitivitycounts.dta
	keep if regexm(analysis,"Complete case|Main analysis cause-specific mort")==1 | analysis=="Main analysis"
	drop datetime	
}

** All-cause
clear
import delim using outputs/mortality_completecasesensit.csv, varnames(1)

keep if version=="Complete case" | version=="Complete variables"
drop if var=="1.split"

sort version var
replace var = substr(var,3,.)

by version: gen J=_n
drop var

rename out HR

reshape wide HR, i(version) j(J)

gen analysis = "Complete case: all cause" if version == "Complete case"
replace analysis = "Main analysis" if version == "Complete variables"

frlink 1:1 analysis, frame(counts)
frget *, from(counts)
drop counts
order version obs events totfup


frame create cod
frame cod {
	import delim using outputs/mortality_completecasesensit_cod.csv, varnames(1)
	drop if regexm(var,"mirtazapine")
	drop if regexm(var,"split")
	bys model (var): gen J=_n
	drop var
	rename out HR
	reshape wide HR, i(model) j(J)

	gen analysis = "Complete case: 2" if model == "Cancer complete case"
	replace analysis = "Complete case: 1" if model == "Circulatory syst complete case"
	replace analysis = "Complete case: 3" if model == "Respiratory syst complete case"
	
	replace analysis = "Main analysis cause-specific mort: 1" if model == "Circulatory syst complete vars"
	replace analysis = "Main analysis cause-specific mort: 2" if model == "Cancer complete vars"
	replace analysis = "Main analysis cause-specific mort: 3" if model == "Respiratory syst complete vars"
	
	frlink 1:1 analysis, frame(counts)
	frget *, from(counts)
	drop counts
	order model obs events totfup
	rename model version
}

frameappend cod

drop analysis

export delim using outputs/CompleteCaseOutput.csv, replace 


frames reset
exit
