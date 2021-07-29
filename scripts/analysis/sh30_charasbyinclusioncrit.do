* Created 20210629 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sh30_charasbyinclusioncrit
* Creator:	RMJ
* Date:	20210629
* Desc:	summarises characteristics of people after applying different inclusion criteria
* Version History:
*	Date	Reference	Update
*	20210629	new file	Create file
*************************************
** what can be summarised for those without second ad?
** firstadtype, firstaddrug, sex, region, *ageatfirstad*, townsend


frames reset
set more off
use data/clean/final_combined.dta


** Start with people eligible for linkage (box 2)
keep if inc_extracted==1
keep if inc_perm==1
keep if inc_followup==1
keep if inc_ssri==1
keep if inc_linked==1



** Also need vars to show if the first ad (if it isn't an SSRI) is in the approptime window
gen firstmeetstimecrit = (eligstart<=firstaddate & firstaddate<eligstop)



** Vars to use to group people by inclusion criteria
*** All at this stage
gen crit0 = 1

*** Ever prescribed second antidep (whatever first AD was) (also apply followup crit)
gen critX = (inc_everswitch==1 & firstmeetstimecrit==1)

*** Prescribed second antidep in window of interest (whatever first AD was) (also apply followup crit)
gen critY = (inc_everswitch==1 & inc_switchafter==1 & inc_switch90==1 & firstmeetstimecrit==1)

*** First AD was SSRI (box 3)
gen crit3 = (inc_firstisssri==1)

*** Second ad was drug of interst (box 4)
gen crit4 = (crit3==1 & inc_everswitch==1 & inc_switchofinterest==1 & cohort<5)

*** Second ad was drug of interest and in time window of interest (box 5)
gen crit5 = (crit4==1 & inc_switchafter==1 & inc_switch90==1)

*** Depression record in specified window (box 6)
gen crit6 = (crit5==1 & depression==1 & depress_12==1)

*** Study cohort (box 7)
gen crit7 = (crit6==1 & inc_thirdad==1 & inc_under100==1 & bipolar!=1 & schizophrenia!=1 & bl_intselfharm!=1)


order crit0 crit3 crit4 crit5 crit6 crit7 critX critY




******************* DEFINE PROGRAMS TO DISPLAY RESULTS AS WANTED
*** Continuous variables
capture program drop CONTINUOUS
program define CONTINUOUS
	
	// Need to specify the file path and the file name
	syntax varlist(max=1), ROWname(string) 
	
	file write outputfile "`rowname'"  _tab 
	
	foreach Y of varlist crit* {
		qui sum `varlist' if `Y'==1, d
		file write outputfile (round(`r(p50)',.1)) " ("  (round(`r(p25)',.1))  "-"  (round(`r(p75)',.1))  ")" 
		if "`Y'"!="critY" file write outputfile _tab
		}

	file write outputfile _n
	
	** row for missing values
	count if `varlist'== .
	local num `r(N)'
	count
	
	if `num'!=0 {
		file write outputfile "Missing" _tab 
				
		foreach Y of varlist crit* {
			count if `varlist'== . & `Y'==1
			local num `r(N)'
			count if `Y'==1
			file write outputfile (string(`num',"%9.0gc")) " (" (string(100*`num'/`r(N)',"%9.1fc")) "%)"
			if "`Y'"!="critY" file write outputfile _tab
		}
			
		file write outputfile  _n
	}
	
end	



*** Categorical variables
capture program drop CATEG
program define CATEG
	
	*set trace on
	// Need to specify the file path and the file name
	syntax varlist(max=1), ROWname(string) LABel(string)
	
	file write outputfile "`rowname'"  _n 

	qui levelsof `varlist', local(varcat)
	local numlev `r(r)'
	
	gen i = 0
	foreach X of local label {
		file write outputfile "`X'" _tab 		
		replace i = i + 1
		
		foreach Y of varlist crit* {
			count if `varlist'== i & `Y'==1
			local num `r(N)'
			count if  `Y'==1 & `varlist'<. // for percentages without the missing	
			file write outputfile (string(`num',"%9.0gc")) " (" (string(100*`num'/`r(N)',"%9.1fc")) "%)" 
			if "`Y'"!="critY" file write outputfile _tab
			}
		file write outputfile _n
	}
	drop i
	
	
	** row for missing values
	count if `varlist'== .
	local num `r(N)'
	count
	
	if `num'!=0 {
		file write outputfile "Missing" _tab 
		
		foreach Y of varlist crit* {
			count if `varlist'== . & `Y'==1
			local num `r(N)'
			count if `Y'==1
			file write outputfile (string(`num',"%9.0gc")) " (" (string(100*`num'/`r(N)',"%9.1fc")) "%)"
			if "`Y'"!="critY" file write outputfile _tab
		}
		
		file write outputfile  _n
	}
end	






capture program drop BINARY
program define BINARY
	syntax varlist(max=1), ROWname(string)
	
	file write outputfile "`rowname'" _tab
	
	foreach Y of varlist crit* {
		count if `varlist'==1 & `Y'==1
		local num `r(N)'	// number in each group with that exposure
		count if  `Y'==1	// number in each group
		file write outputfile (string(`num',"%9.0gc")) " (" (string(100*`num'/`r(N)',"%9.1fc")) "%)" 
		if "'Y'"!="critY" file write outputfile _tab	
		}
	file write outputfile _n
	
end



***************** Summarise results
** dataset edits:
replace sex=2 if sex==.
gen time2 = timetoswitch/7
merge 1:1 patid using data/raw/stata/allpatients.dta, keep(3) nogen keepusing(yob)
gen ageatfirstad = year(firstaddate) - yob

*** Open file to write to
capture file close outputfile
file open outputfile using "outputs/sh30_charasbyinclusioncrit.txt", write replace

file write outputfile "NOTE - some vars have already been set to missing if total N<100" _n

** HEADER ROW
file write outputfile ""  _tab "Everyone linked" _tab "First was SSRI"  _tab "+ ever second"  _tab  "+ second with timing" _tab "+ depression" _tab "Study cohort" _tab "Ever second ad"  _tab "Second AD with timing"  _n

** Counts Row
file write outputfile "Count" _tab
foreach Y of varlist crit* {
	count if `Y'==1
	local num `r(N)'	// number in each cohort with that exposure
	file write outputfile (string(`num',"%9.0gc")) 
	if "'Y'"!="critY" file write outputfile _tab	
	}	
file write outputfile _n

** Common rows
CONTINUOUS ageatfirstad, row("Age at first AD, median (IQR)")
CATEG sex, row("Sex, n(%)") label(Male Female)
CATEG townsend, row("SES, n(%)") label(1(least) 2 3 4 5(most))
CATEG region, row("Region, n(%)") label(NorthEast NorthWest YorkshireHumber EastMidlands WestMidlands EastOfEngland SouthWest SouthCentral London SouthEastCoast)
CATEG firstadtype, row("First antidepressant type, n(%)") label (SSRI Other MAOI TCA)

** Rows only if have an index date
CONTINUOUS ageindex, row("Age at index, median (IQR)")
CATEG ethnicity, row("Ethnicity, n(%)") label(Asian Black Mixed Other White)
CONTINUOUS bmi, row("BMI, median (IQR)") 
CATEG smokestat, row("Smoking status, n(%)") label(Never Former Current)
CATEG alcoholintake, row("Alcohol intake, n(%)")  label(Non- Former Occasional Moderate Heavy)
CONTINUOUS yearindex, row("Index year, median (IQR)") 
CONTINUOUS lastad1_ddd, row("Most recent antidepressant dose at index (DDD), median (IQR)") 
CONTINUOUS currentad1_ddd, row("Current antidepressant dose at index (DDD), median (IQR)")
CONTINUOUS time2, row("Time (weeks) between starting first and second antidepressant (DDD), median (IQR)") 
BINARY ad1active, row("First antidepressant still active at index, n(%)")

foreach Z of varlist severe depscale alcoholmisuse anxiety mentalhealthservices eatingdis insomnia intellectualdisab personalitydis selfharm substmisuse {	// take out bl_intselfharm
	count if `Z'==1
	replace `Z'=. if `r(N)'<100
	BINARY `Z', row("`Z', n(%)")
	}	
	
foreach Z of varlist opioids gc nsaids analgesics statins anxiolytics antipsychotics hypnotics {
	count if `Z'==1
	replace `Z'=. if `r(N)'<100
	BINARY `Z', row("`Z', n(%)")
	}

foreach Z of varlist abdompain ibd indigestion liverdis_mild liverdis_mod obesity pancreatitis pud renal anaemia af angina cerebrovas chf diabetes diab_comp hypertension mi pvd vte {
	count if `Z'==1
	replace `Z'=. if `r(N)'<100
	BINARY `Z', row("`Z', n(%)")
	}

foreach Z of varlist appetiteloss carehome hemiplegia legulcer palliative mobility weightloss hospitaladmi asthma copd dyspnoea sleepapnoea aids cancer cancer1year metastatictumour dementia epilepsy fibromyalgia huntingtons migraine ms neuropathicpain parkinsons rheumatological {
	count if `Z'==1
	replace `Z'=. if `r(N)'<100
	BINARY `Z', row("`Z', n(%)")
	}
	


file close outputfile
frames reset
exit
