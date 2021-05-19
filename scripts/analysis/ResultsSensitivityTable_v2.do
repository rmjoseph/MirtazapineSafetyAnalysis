* Created 2020-12_08 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	ResultsSensitivityTable_v2
* Creator:	RMJ
* Date:	20201208
* Desc:	Automates the tables for reporting sensitivity analyses
* Version History:
*	Date	Reference	Update
*	20201208	ResultsSensitivityTable	 New version allowing for new var names and interactions
*	20201208	ResultsSensitivityTable_v2	Expand to work on results files without interactions too
*	20210223	ResultsSensitivityTable_v2	Update self-harm info
*	20210312	ResultsSensitivityTable_v2	Add code for sh30 analysis results
*	20210518	ResultsSensitivityTable_v2	Add SH analysis including primary care var 
*	20210519	ResultsSensitivityTable_v2	Add line for weighted SH analysis with broader outcome
*************************************

set more off

**** INSTALL REQUIRED PACKAGE 
ssc install sxpose

**** DEFINE PROGRAM
capture program drop TABLE
program def TABLE

	syntax, FILEname(string) KEEPmod(integer) ANname(string)
	
	// Create frame and change to it
	frame create temp
	frame pwf
	local framename `r(currentframe)'
	frame change temp

	// Import file
	import delim using "outputs/`filename'.csv"

	// for iptw results change cohort to var and create model variable
	if `keepmod' == 4 | `keepmod' == 8 {
		rename cohort var
		gen model = "4"
		drop if coeff==0 & se==0 // 1b.cohort#1o.split
		}
	
	// keep rows of interest
	keep if regexm(var,"ssri") | regexm(var,"amitriptyline") |regexm(var,"venlafaxine") |regexm(var,"cohort")==1

	if `keepmod'==1 |`keepmod'==5 {
		drop if model=="unadj" | model=="agesex"
		}
	if `keepmod'==2 | `keepmod'==6 {
		drop if model=="unadj"
		}

	**** for those with interaction terms, reshape so that both results for each
	**** drug are on one line
	// create variables to allow reshaping
	gen var2 = substr(var,-4,4)
	replace var2 = var if regexm(var,"cohort")==1 // not all results are labelled
	
	replace model = "fulladj1" if model=="fulladj2"
	bys model var2: gen i = 1 if _n==1
	sort model var2 i
	replace i = sum(i)
	bys i (var): gen j = _n
	keep model hr2 var2 i j

	// reshape (if interaction, puts both results on one line per cohort and model)
	reshape wide hr2, i(i) j(j)
	rename var2 var
	drop i
	
	// rename the rows
	replace var = "1" if var=="ssri" | regexm(var,"2.cohort")==1
	replace var = "2" if var=="line" | regexm(var,"3.cohort")==1
	replace var = "3" if var=="xine" | regexm(var,"4.cohort")==1

	// Convert model to number so order is kept
	replace model = "1" if model=="unadj"
	replace model = "2" if model=="agesex"
	replace model = "3" if regexm(model,"fulladj")==1
	destring model, replace
	sort model var
	
	// Rename results vars
	rename hr21 HR0
	capture rename hr22 HR2
	
	// Reshape (if multiple models, puts results on one line per cohort)
	if `keepmod' < 5 {
		reshape wide HR0 HR2, i(var) j(model)
		} 
	else {
		reshape wide HR0, i(var) j(model)
		}

	replace var="ssri" if var=="1"
	replace var="amitrip" if var=="2"
	replace var="venlafax" if var=="3"

	// Transpose (so that cohorts are across and results are down)
	sxpose, clear firstnames

	// Label the model used
	gen model = ""
	order model, first
	
	if `keepmod'==1 {
		replace model = "fulladj"
		}		
	if `keepmod'==2 {
		replace model = "agesex" if _n<=2 & model==""
		replace model = "fulladj" if _n<=4 & model==""
		}
	if `keepmod'==3 {
		replace model = "unadj" if _n<=2
		replace model = "agesex" if _n<=4 & model==""
		replace model = "fulladj" if _n<=6 & model==""
		}
	if `keepmod'==4 | `keepmod'==8 {
		replace model = "weighted"
		}
	if `keepmod'==5 {
		replace model = "fulladj" if _n==1
		}
	if `keepmod'==6 {
		replace model = "agesex" if _n==1
		replace model = "fulladj" if _n==2
		}	
	if `keepmod'==7 {
		replace model = "unadj" if _n==1
		replace model = "agesex" if _n==2
		replace model = "fulladj" if _n==3
		}

		
	// reshape again (if +int) so the results from the 2 time points are in one row
	if `keepmod' < 5 {
		gen time = 0
		order time, after(model)
		gen index = _n
		bys model (index): replace time = 2 if _n==_N
		sort index
		drop index
		
		reshape wide ssri amitrip venlafax, i(model) j(time)
		gen order = 1 if model=="unadj"
		replace order = 2 if model=="agesex"
		sort order
		drop order
		}
	else {
		rename ssri ssri0
		rename amitrip amitrip0
		rename venlafax venlafax0
		}
	
	// Label the analysis
	gen analysis = "`anname'"
	order model analysis, first
	
	// Temp save
	tempfile temp
	save "`temp'", replace

	// Go back to original frame, append the file
	frame change `framename'
	append using "`temp'"

	// Drop the frame
	frame drop temp

end


*************** Run to generate tables

** TABLE syntax: 
*	filename is name of the file to import (minus extension)
*	keepmod is which models to show, with the following options;
*		1 fulladj (+int)	5 fulladj(-int)
*		2 fulladj,agesex (+int)	6 fulladj,agesex (-int)
*		3 all (+int)	7 all (-int)
*		4 iptw (+int)	8 iptw (-int)
*	anname is a label for the row
// All-cause mort
frames reset

TABLE, file(adjsurvival_allcausemort_interaction) keep(3) anname("Main analysis")
TABLE, file(iptw_results_allcausemort_s) keep(4) anname("Main analysis")
TABLE, file(adjsurvival_allcausemort_allvars_interaction) keep(1) anname("Use all variables")
TABLE, file(iptw_results_allcausemort_allvars_s) keep(4) anname("Use all variables")
TABLE, file(iptw_results_allcausemort_common_s) keep(4) anname("Restrict to common support")
TABLE, file(adjsurvival_allcausemort_nosplit) keep(7) anname("No time interaction")
TABLE, file(iptw_results_allcausemort_nosplit) keep(8) anname("No time interaction")
TABLE, file(adjsurvival_sensitivity_allcausestartcita) keep(2) anname("All start citalopram")
TABLE, file(adjsurvival_sensitivity_allcauseswitchsert) keep(2) anname("SSRI is sertraline")
TABLE, file(adjsurvival_sensitivity_allcauseswitchcita) keep(2) anname("SSRI is citalopram")
TABLE, file(adjsurvival_sensitivity_allcausecancer) keep(2) anname("No prior cancer")
TABLE, file(adjsurvival_sensitivity_allcausenoselfharm) keep(2) anname("No prior self-harm")
TABLE, file(adjsurvival_sensitivity_allcauseage18to64) keep(2) anname("Aged 18-64")
TABLE, file(adjsurvival_sensitivity_allcauseage65to99) keep(2) anname("Aged 65-99")
TABLE, file(adjsurvival_sensitivity_allcausemax5years) keep(6) anname("Max 5 years followup")
TABLE, file(adjsurvival_sensitivity_allcausemax1year) keep(6) anname("Max 1 year followup")
TABLE, file(adjsurvival_sensitivity_allcausestop0) keep(2) anname("No carry-over window")
TABLE, file(adjsurvival_sensitivity_allcausestop30) keep(2) anname("30 day carry-over window")
TABLE, file(adjsurvival_sensitivity_allcausenostop) keep(2) anname("Follow-up to end")
TABLE, file(adjsurvival_sensitivity_allcausethirdad) keep(2) anname("Ignore 3rd antidepressant")
TABLE, file(adjsurvival_sensitivity_broadelig_allcause) keep(2) anname("Widen eligibily criteria")


** Merge in the info about follow-up
frame create new
frame change new

use data/clean/sensitivitycounts.dta
drop datetime

frame change default
frlink m:1 analysis, frame(new)
frget *, from(new)

drop new
frame drop new
order model analysis obs events totfup
**

export delim using outputs/FullSensitivityAllCause_202104.csv, replace // updated from 202010 2021-03-02


// Circulatory system
frames reset
TABLE, file(adjsurvival_circulatory_cr_202010) keep(7) anname("Main analysis competing risk")
TABLE, file(iptw_results_circulatory_cr_202010) keep(8) anname("Main analysis competing risk")
TABLE, file(adjsurvival_circulatory_cox_202010) keep(7) anname("Main analysis Cox")
TABLE, file(iptw_results_circulatory_cox_202010) keep(8) anname("Main analysis Cox")
TABLE, file(adjsurvival_allvars_circulatory_cox) keep(5) anname("Main analysis all variables COX")
TABLE, file(iptw_results_allvars_circulatory_cox) keep(8) anname("Main analysis all variables COX")

** Merge in the info about follow-up
frame create new
frame change new
clear

use data/clean/sensitivitycounts.dta
drop datetime
keep if regexm(analysis,"cause-specific mort: 1")==1
gen link=1 if regexm(analysis,"Main analysis")==1
replace link=2 if regexm(analysis,"ALL VARS")==1
drop analysis

frame change default
gen link=1 if regexm(analysis,"Main analysis")==1
replace link=2 if regexm(analysis,"all variables")==1
frlink m:1 link, frame(new)
frget obs events totfup, from(new)

drop new link
frame drop new
order model analysis obs events totfup
**
export delim using outputs/FullSensitivityCirculatory_202012.csv, replace



// Cancer 
frames reset
TABLE, file(adjsurvival_cancer_cr_202012_interaction) keep(3) anname("Main analysis competing risk")
TABLE, file(iptw_results_cancer_cr_202010_s) keep(4) anname("Main analysis competing risk")
TABLE, file(adjsurvival_cancer_cox_202010_interaction) keep(3) anname("Main analysis Cox")
TABLE, file(iptw_results_cancer_cox_202010_s) keep(4) anname("Main analysis Cox")
TABLE, file(adjsurvival_allvars_cancer_cox_interaction) keep(1) anname("Main analysis all variables COX")
TABLE, file(iptw_results_allvars_cancer_cox_interaction) keep(4) anname("Main analysis all variables COX")
TABLE, file(adjsurvival_cancer_cox_202010_nosplit) keep(7) anname("No time interaction")
TABLE, file(iptw_results_cancer_cox_202010_nosplit) keep(8) anname("No time interaction")
TABLE, file(adjsurvival_sensitivity_cancercancer) keep(2) anname("No prior cancer: cancer mort")


** Merge in the info about follow-up
frame create new
frame change new
clear

use data/clean/sensitivitycounts.dta
drop datetime
keep if regexm(analysis,"cause-specific mort: 2")==1 | ///
	analysis=="No prior cancer: cancer mort" | analysis=="No time interaction cancer"
gen link=1 if regexm(analysis,"Main analysis")==1
replace link=2 if analysis=="No prior cancer: cancer mort"
replace link=3 if regexm(analysis,"ALL VARS")==1
replace link=4 if analysis=="No time interaction cancer"
drop analysis

frame change default
gen link=1 if regexm(analysis,"Main analysis")==1
replace link=2 if analysis=="No prior cancer: cancer mort"
replace link=3 if regexm(analysis,"all variables")==1
replace link=4 if regexm(analysis,"No time interaction")==1
frlink m:1 link, frame(new)
frget obs events totfup, from(new)

drop new link
frame drop new
order model analysis obs events totfup

replace analysis="No prior cancer Cox" if analysis=="No prior cancer: cancer mort"
**
export delim using outputs/FullSensitivityCancer_202012.csv, replace




// Respiratory system
frames reset
TABLE, file(adjsurvival_respiratory_cr_202010) keep(7) anname("Main analysis competing risk")
TABLE, file(iptw_results_respiratory_cr_202010) keep(8) anname("Main analysis competing risk")
TABLE, file(adjsurvival_respiratory_cox_202010) keep(7) anname("Main analysis Cox")
TABLE, file(iptw_results_respiratory_cox_202010) keep(8) anname("Main analysis Cox")
TABLE, file(adjsurvival_allvars_respiratory_cox) keep(5) anname("Main analysis all variables COX")
TABLE, file(iptw_results_allvars_respiratory_cox) keep(8) anname("Main analysis all variables COX")

** Merge in the info about follow-up
frame create new
frame change new
clear

use data/clean/sensitivitycounts.dta
drop datetime
keep if regexm(analysis,"cause-specific mort: 3")==1 
gen link=1 if regexm(analysis,"Main analysis")==1
replace link=2 if regexm(analysis,"ALL VARS")==1
drop analysis

frame change default
gen link=1 if regexm(analysis,"Main analysis")==1
replace link=2 if regexm(analysis,"all variables")==1
frlink m:1 link, frame(new)
frget obs events totfup, from(new)

drop new link
frame drop new
order model analysis obs events totfup
**
export delim using outputs/FullSensitivityRespiratory_202012.csv, replace



** TABLE syntax: 
*	filename is name of the file to import (minus extension)
*	keepmod is which models to show, with the following options;
*		1 fulladj (+int)	5 fulladj(-int)
*		2 fulladj,agesex (+int)	6 fulladj,agesex (-int)
*		3 all (+int)	7 all (-int)
*		4 iptw (+int)	8 iptw (-int)
*	anname is a label for the row
// Self-harm
frames reset
TABLE, file(adjsurvival_selfharm_cr_202010) keep(7) anname("Main analysis competing risk")
TABLE, file(iptw_results_selfharm_cr_202010) keep(8) anname("Main analysis competing risk")
TABLE, file(adjsurvival_selfharm_cox_202010) keep(7) anname("Main analysis Cox")
TABLE, file(iptw_results_selfharm_cox_202010) keep(8) anname("Main analysis Cox")
TABLE, file(adjsurvival_allvars_selfharm_cox) keep(5) anname("Main analysis all variables Cox")
TABLE, file(iptw_results_allvars_selfharm_cox) keep(8) anname("Main analysis all variables Cox")
TABLE, file(adjsurvival_sensitivity_selfharmnoselfharm) keep(6) anname("No prior self-harm (primary care) Cox")
TABLE, file(adjsurvival_sensitivity_selfharmage18to64_cox) keep(6) anname("Aged 18-64 Cox")
TABLE, file(adjsurvival_sensitivity_selfharmage65to99_cox) keep(6) anname("Aged 65-99 Cox")
TABLE, file(adjsurvival_sensitivity_selfharmthirdad) keep(6) anname("Ignore third antidep, Cox")
TABLE, file(adjsurvival_sensitivity_selfharmstop0) keep(6) anname("No risk carry-over, window Cox")
TABLE, file(adjsurvival_sensitivity_selfharmstop30) keep(6) anname("30 day risk carry-over window, Cox")
TABLE, file(adjsurvival_sensitivity_selfharmnostop) keep(6) anname("Ignore end of exposure period, Cox")


** Merge in the info about follow-up
frame create new
frame change new
clear

use data/clean/sensitivitycounts.dta
drop datetime
keep if  regexm(analysis,"selfharm")==1 | regexm(analysis,"SH:")==1 
gen link=1 if analysis=="Main analysis selfharm"
replace link=2 if analysis=="No prior self harm: selfharm"
replace link=3 if analysis=="Aged 18-64 selfharm"
replace link=4 if analysis=="Aged 65-99 selfharm"
replace link=5 if analysis=="Use all variables selfharm"
replace link=6 if analysis=="Main analysis ALL VARS selfharm"
replace link=7 if analysis=="SH: No carry-over window"
replace link=8 if analysis=="SH: 30 day carry-over window"
replace link=9 if analysis=="SH: Follow-up to end"
replace link=10 if analysis=="SH: Ignore 3rd antidepressant"

*drop analysis

frame change default
gen link=1 if regexm(analysis,"Main analysis")==1
replace link=2 if analysis=="No prior self-harm (primary care) Cox"
replace link=3 if analysis=="Aged 18-64 Cox"
replace link=4 if analysis=="Aged 65-99 Cox"
replace link=5 if analysis=="Main analysis all variables Cox"
replace link=6 if analysis=="Main analysis all variables Cox"
replace link=7 if analysis=="No risk carry-over, window Cox"
replace link=8 if analysis=="30 day risk carry-over window, Cox"
replace link=9 if analysis=="Ignore end of exposure period, Cox"
replace link=10 if analysis=="Ignore third antidep, Cox"


frlink m:1 link, frame(new)
frget obs events totfup, from(new)

drop new link
frame drop new
order ssri amit venlaf, last
**
export delim using outputs/FullSensitivitySelfHarm_202102.csv, replace



*~~~ SELF HARM WITH ENDDATE 30 ~~~* 2021/03/12
** TABLE syntax: 
*	filename is name of the file to import (minus extension)
*	keepmod is which models to show, with the following options;
*		1 fulladj (+int)	5 fulladj(-int)
*		2 fulladj,agesex (+int)	6 fulladj,agesex (-int)
*		3 all (+int)	7 all (-int)
*		4 iptw (+int)	8 iptw (-int)
*	anname is a label for the row
// Self-harm
frames reset
TABLE, file(adjsurvival_sh30_cr) keep(7) anname("Main analysis competing risk")
TABLE, file(iptw_results_sh30_cr) keep(8) anname("Main analysis competing risk")
TABLE, file(adjsurvival_sh30_cox) keep(7) anname("Main analysis Cox")
TABLE, file(iptw_results_sh30_cox) keep(8) anname("Main analysis Cox")
TABLE, file(adjsurvival_sh30_allvars_cox) keep(5) anname("Main analysis all variables Cox")
TABLE, file(iptw_results_sh30_allvars_cox) keep(8) anname("Main analysis all variables Cox")
TABLE, file(adjsurvival_sh30_sensitivity_noselfharm) keep(6) anname("No prior self-harm (primary care) Cox")
TABLE, file(adjsurvival_sh30_sensitivity_age18to64_cox) keep(6) anname("Aged 18-64 Cox")
TABLE, file(adjsurvival_sh30_sensitivity_age65to99_cox) keep(6) anname("Aged 65-99 Cox")
TABLE, file(adjsurvival_sh30_sensitivity_thirdad) keep(6) anname("Ignore third antidep, Cox")
TABLE, file(adjsurvival_sh30_sensitivity_stop0) keep(6) anname("No risk carry-over, window Cox")
TABLE, file(adjsurvival_sh30_sensitivity_stop6) keep(6) anname("6 month risk carry-over window, Cox")
TABLE, file(adjsurvival_sh30_sensitivity_nostop) keep(6) anname("Ignore end of exposure period, Cox")
TABLE, file(adjsurvival_sh30_sensitivity_max5years) keep(6) anname("Max 5 years followup")
TABLE, file(adjsurvival_sh30_sensitivity_max1year) keep(6) anname("Max 1 year followup")
TABLE, file(adjsurvival_sh30_sensitivity_startcital) keep(6) anname("First ad is citalopram")
TABLE, file(adjsurvival_sh30_sensitivity_switchcital) keep(6) anname("Second ad is citalopram")
TABLE, file(adjsurvival_sh30_sensitivity_switchfluox) keep(6) anname("Second ad is fluoxetine")
TABLE, file(iptw_results_sh30_sensitivity_PCselfharm) keep(8) anname("Outcome includes primary care self-harm")
TABLE, file(adjsurvival_sh30_sensitivity_PCselfharm) keep(6) anname("Outcome includes primary care self-harm")

** Merge in the info about follow-up
frame create new
frame change new
clear

use data/clean/sh30_sensitivitycounts.dta
drop datetime

gen link=.
replace link=1 if analysis=="6 month carry-over window"
replace link=2 if analysis=="Aged 18-64"
replace link=3 if analysis=="Aged 65-99"
replace link=4 if analysis=="Follow-up to end"
replace link=5 if analysis=="Ignore 3rd antidepressant"
replace link=6 if analysis=="Main analysis selfharm"
replace link=7 if analysis=="No carry-over window"
replace link=8 if analysis=="No prior self harm"
replace link=9 if analysis=="Max 5 years followup"
replace link=10 if analysis=="Max 1 year followup"
replace link=11 if analysis=="First ad is citalopram"
replace link=12 if analysis=="Second ad is citalopram"
replace link=13 if analysis=="Second ad is fluoxetine"
replace link=14 if analysis=="Outcome includes primary care self-harm"
drop if analysis=="Use all variables"

frame change default
gen link=.
replace link=1 if regexm(analysis,"6 month risk carry-over window")==1
replace link=2 if regexm(analysis,"Aged 18-64") ==1
replace link=3 if regexm(analysis,"Aged 65-99") ==1
replace link=4 if regexm(analysis,"Ignore end of exposure period")==1
replace link=5 if regexm(analysis,"Ignore third antidep")==1
replace link=6 if regexm(analysis,"Main analysis") ==1
replace link=8 if regexm(analysis,"No prior self-harm") ==1
replace link=7 if regexm(analysis,"No risk carry-over, window")==1
replace link=9 if analysis=="Max 5 years followup"
replace link=10 if analysis=="Max 1 year followup"
replace link=11 if analysis=="First ad is citalopram"
replace link=12 if analysis=="Second ad is citalopram"
replace link=13 if analysis=="Second ad is fluoxetine"
replace link=14 if analysis=="Outcome includes primary care self-harm"

frlink m:1 link, frame(new)
frget obs events totfup, from(new)

drop new link
frame drop new
order ssri amit venlaf, last
**
export delim using outputs/sh30_FullSensitivity.csv, replace





***** 
frames reset
exit
