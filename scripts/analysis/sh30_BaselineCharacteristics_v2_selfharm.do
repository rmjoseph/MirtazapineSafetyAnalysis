* Created 2021-03-12 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sh30_BaselineCharacteristics_v2_selfharm
* Creator:	RMJ
* Date:	20210223
* Desc:	Outputs a baseline characteristics table (using enddate30)
* Version History:
*	Date	Reference	Update
*	20210312	BaselineCharacteristics_v2_selfharm	Create file
*	20210709	BaselineCharacteristics_v2_selfharm	Bug fix: outcome <enddate30 not 6
*************************************

set more off
frames reset
clear


*** Date macro
local date: display %dCYND date("`c(current_date)'", "DMY")
local time: display %tcCCYYNNDD-HHMM clock("`c(current_date)' `c(current_time)'", "DMY hms")
*** Open log file
capture log close baselinecharas30
log using "logs/results_baselinecharas_sh30_`date'.txt", text append name(baselinecharas30)

*** Open file to write to
capture file close outputfile
file open outputfile using "outputs/sh30_BaselineCharacteristics_selfharm_`time'.txt", write replace




******************* DEFINE PROGRAMS TO DISPLAY RESULTS AS WANTED
*** Continuous variables
capture program drop CONTINUOUS
program define CONTINUOUS
	
	// Need to specify the file path and the file name
	syntax varlist(max=1), ROWname(string) 
	
	file write outputfile "`rowname'"  _tab 
	qui sum `varlist', d
	file write outputfile (round(`r(p50)',.1)) " ("  (round(`r(p25)',.1))  "-"  (round(`r(p75)',.1))  ")" _tab
	
	qui levelsof cohort, local(cohort)
	foreach Y of local cohort {
		qui sum `varlist' if cohort==`Y', d
		file write outputfile (round(`r(p50)',.1)) " ("  (round(`r(p25)',.1))  "-"  (round(`r(p75)',.1))  ")" _tab
		}

	
	kwallis `varlist', by(cohort)
	file write outputfile "KW chi2(`r(df)')=" (string(`r(chi2)',"%9.1fc")) ", p=" 
	local pval: di chi2tail(r(df), r(chi2))
	file write outputfile (string(`pval',"%9.3fc")) _n
	
		** row for missing values
	count if `varlist'== .
	local num `r(N)'
	count
	
	if `num'!=0 {
		file write outputfile "Missing" _tab (string(`num',"%9.0gc")) " (" (string(100*`num'/`r(N)',"%9.1fc")) "%)" _tab
		
		gen missing_`varlist' = (`varlist'==.)
		
		foreach Y of local cohort {
			count if `varlist'== . & cohort==`Y'
			local num `r(N)'
			count if  cohort==`Y'	
			file write outputfile (string(`num',"%9.0gc")) " (" (string(100*`num'/`r(N)',"%9.1fc")) "%)" _tab
			}
		
		tab missing_`varlist' cohort, chi2
		
		file write outputfile  "chi2(" ((`r(r)'-1)*(`r(c)'-1)) ")=" (string(`r(chi2)',"%9.1fc")) ", p=" (string(`r(p)',"%9.3fc")) _n
		drop missing_`varlist'
		}
	
	
end	

*** Categorical variables
capture program drop CATEG
program define CATEG
	
	// Need to specify the file path and the file name
	syntax varlist(max=1), ROWname(string) LABel(string)
	
	file write outputfile "`rowname'"  _n 

	qui levelsof cohort, local(cohort)
	qui levelsof `varlist', local(varcat)
	local numlev `r(r)'
	
	gen i = 0
	foreach X of local label {
		
		replace i = i + 1
		
		count if `varlist'== i
		local num `r(N)'
		
		count if `varlist' <. // for percentages without the missing		
		
		file write outputfile "`X'" _tab (string(`num',"%9.0gc")) " (" (string(100*`num'/`r(N)',"%9.1fc")) "%)" _tab
		
		foreach Y of local cohort {
			count if `varlist'== i & cohort==`Y'
			local num `r(N)'
			count if  cohort==`Y' & `varlist'<. // for percentages without the missing	
			file write outputfile (string(`num',"%9.0gc")) " (" (string(100*`num'/`r(N)',"%9.1fc")) "%)" _tab
			}
			
			if i!=`numlev' file write outputfile _n
		}
	drop i
	tab `varlist' cohort, chi2

	file write outputfile  "chi2(" ((`r(r)'-1)*(`r(c)'-1)) ")=" (string(`r(chi2)',"%9.1fc")) ", p=" (string(`r(p)',"%9.3fc")) _n
	
	
	
	** row for missing values
	count if `varlist'== .
	local num `r(N)'
	count
	
	if `num'!=0 {
		file write outputfile "Missing" _tab (string(`num',"%9.0gc")) " (" (string(100*`num'/`r(N)',"%9.1fc")) "%)" _tab
		
		gen missing_`varlist' = (`varlist'==.)
		
		foreach Y of local cohort {
			count if `varlist'== . & cohort==`Y'
			local num `r(N)'
			count if  cohort==`Y'	
			file write outputfile (string(`num',"%9.0gc")) " (" (string(100*`num'/`r(N)',"%9.1fc")) "%)" _tab
			}
		
		tab missing_`varlist' cohort, chi2
		
		file write outputfile  "chi2(" ((`r(r)'-1)*(`r(c)'-1)) ")=" (string(`r(chi2)',"%9.1fc")) ", p=" (string(`r(p)',"%9.3fc")) _n
		drop missing_`varlist'
		}
end	



capture program drop BINARY
program define BINARY
	syntax varlist(max=1), ROWname(string)
	
	count if `varlist'==1
	local num `r(N)'	// number overall with that exposure
	count	// number overall
	
	file write outputfile "`rowname'" _tab (string(`num',"%9.0gc")) " (" (string(100*`num'/`r(N)',"%9.1fc")) "%)" _tab	// row1 cell1 cell2

	qui levelsof cohort, local(cohort)
	
	foreach Y of local cohort {
		count if `varlist'==1 & cohort==`Y'
		local num `r(N)'	// number in each cohort with that exposure
		count if  cohort==`Y'	// number in each cohort
		file write outputfile (string(`num',"%9.0gc")) " (" (string(100*`num'/`r(N)',"%9.1fc")) "%)" _tab	// row1 cell3 - cell5
		}	
	tab `varlist' cohort, chi2 // cross-tab of exposure and cohort
	file write outputfile  "chi2(" ((`r(r)'-1)*(`r(c)'-1)) ")=" (string(`r(chi2)',"%9.1fc")) ", p=" (string(`r(p)',"%9.3fc")) _n	// row1 cell6 _n
	
end



*** Open data file
use data/clean/final_combined.dta
order bipolar schizophrenia depsev , last // lithium removed
keep if cohort<5
keep if inc_thirdad==1 // for this analysis drop patients who start two antideps on index

*** Keep patients of interest (copy into new frame)
frame change default
capture frame drop resultsframe
frame put if keep1==1, into(resultsframe)
frame change resultsframe

**** restrict to self harm dataset
gen outcome = serioussh_int <= enddate30
gen died = endreason30==1
replace outcome = 2 if outcome!=1 & died==1
egen newstop = rowmin(enddate30 serioussh_int)
gen time = (newstop - index)*12/365.25
drop if time<0
drop if serioussh_int==index


*** Label each table
file write outputfile _n
file write outputfile "-----------------------------------------" _n
file write outputfile "Table generated using keep1 - self-harm subset"  _n

file write outputfile "Inclusion critera: switch 90d; depression 12m; depression only" _n

file write outputfile _n
file write outputfile _n

*** Start writing table
** HEADER ROW
file write outputfile ""  _tab "All"  _tab "Mirtazapine"  _tab "SSRI"  _tab "Amitriptyline"  _tab "Venlafaxine"  _tab  "Statistic" _n

** Counts Row
file write outputfile "Count" _tab

count
local num `r(N)'	// overall count
file write outputfile (string(`num',"%9.0gc")) _tab

qui levelsof cohort, local(cohort)	
foreach Y of local cohort {
	count if cohort==`Y'
	local num `r(N)'	// number in each cohort with that exposure
	file write outputfile (string(`num',"%9.0gc")) _tab	// row1 cell3 - cell5
	}	
file write outputfile _n

** Remaining variables
CONTINUOUS ageindex, row("Age, median (IQR)")
CATEG sex, row("Sex, n(%)") label(Male Female)
CATEG ethnicity, row("Ethnicity, n(%)") label(Asian Black Mixed Other White)
CATEG townsend, row("SES, n(%)") label(1(least) 2 3 4 5(most))
CATEG region, row("Region, n(%)") label(NorthEast NorthWest YorkshireHumber EastMidlands WestMidlands EastOfEngland SouthWest SouthCentral London SouthEastCoast)
CONTINUOUS bmi, row("BMI, median (IQR)") 
CATEG smokestat, row("Smoking status, n(%)") label(Never Former Current)
CATEG alcoholintake, row("Alcohol intake, n(%)")  label(Non- Former Occasional Moderate Heavy)
*CATEG depsev, row("Depression severity, n(%)") label(Mild moderate Severe)

foreach Z of varlist severe depscale alcoholmisuse anxiety mentalhealthservices eatingdis insomnia intellectualdisab personalitydis selfharm substmisuse {	// take out bl_intselfharm
	BINARY `Z', row("`Z', n(%)")
	}	
	
foreach Z of varlist opioids gc nsaids analgesics statins anxiolytics antipsychotics hypnotics {
	BINARY `Z', row("`Z', n(%)")
	}

foreach Z of varlist abdompain ibd indigestion liverdis_mild liverdis_mod obesity pancreatitis pud renal anaemia af angina cerebrovas chf diabetes diab_comp hypertension mi pvd vte {
	BINARY `Z', row("`Z', n(%)")
	}

foreach Z of varlist appetiteloss carehome hemiplegia legulcer palliative mobility weightloss hospitaladmi asthma copd dyspnoea sleepapnoea aids cancer cancer1year metastatictumour dementia epilepsy fibromyalgia huntingtons migraine ms neuropathicpain parkinsons rheumatological {
	BINARY `Z', row("`Z', n(%)")
	}
	

gen firstdrug2 = 1 if firstaddrug==5
replace firstdrug2 = 1 if firstaddrug==14 // recoding fluvoxamine due to small numbers
replace firstdrug2 = 2 if firstaddrug==11
replace firstdrug2 = 3 if firstaddrug==12
replace firstdrug2 = 4 if firstaddrug==24
replace firstdrug2 = 5 if firstaddrug==28

CATEG firstdrug2, row("First SSRI, n(%)") label(Citalopram Escitalopram Fluoxetine Paroxetine Sertraline)
CONTINUOUS yearindex, row("Index year, median (IQR)") 
CONTINUOUS lastad1_ddd, row("Most recent antidepressant dose at index (DDD), median (IQR)") 
CONTINUOUS currentad1_ddd, row("Current antidepressant dose at index (DDD), median (IQR)")
gen time2 = timetoswitch/7
CONTINUOUS time2, row("Time (weeks) between starting first and second antidepressant (DDD), median (IQR)") 
BINARY ad1active, row("First antidepressant still active at index, n(%)")
	
*** ADD ROWS FOR FOLLOWUP TIME
CONTINUOUS time, row("Follow-up time (months), median (IQR)") 
CATEG outcome, row("Outcomes, n(%)") label(SeriousSelfHarm Death)

	
*** close file
file close outputfile

*** Show labels for quick ref
label list

*** END
clear
frames reset
log close baselinecharas30	
exit


