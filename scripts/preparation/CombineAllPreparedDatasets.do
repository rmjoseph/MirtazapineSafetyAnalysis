** CREATED 20-01-2020 by RMJ at the University of Nottingham
*************************************
* Name:	CombineAllPreparedDatasets
* Creator:	RMJ
* Date:	20200120
* Desc:	Combine all the cleaned data into one file for analysis
* Requires: 
* Version History:
*	Date	Reference	Update
*	20192020	CombineAllPreparedDatasets	Create file
*	20200205	CombineAllPreparedDatasets	Change depression window to before first ad
*	20200210	CombineAllPreparedDatasets	Revise definition of cohort selection vars
*	20200218	CombineAllPreparedDatasets	Replace vte with weightloss in varlist
*	20200219	CombineAllPreparedDatasets	Update references to secondadtype so ssri = 1
*	20200220	CombineAllPreparedDatasets	Link with DDD data file to convert doses to DDDs
*	20200220	CombineAllPreparedDatasets	Calculate calendar year of index and time to switching
*	20200227	CombineAllPreparedDatasets	Add in newly created hes and cprd ethnicity vars
*	20200309	CombineAllPreparedDatasets	Incorporate test results depression sev
*	20200318	CombineAllPreparedDatasets	Add in recent cancer
*	20200327	CombineAllPreparedDatasets	Add in intentional self harm baseline
*	20200423	CombineAllPreparedDatasets	Add inc_thirdad variable
*	20200514	CombineAllPreparedDatasets	Recode 'other' sex as missing so auto-drop from analyses
*	20200522	CombineAllPreparedDatasets	Add in cancer from HES
*	20200723	CombineAllPreparedDatasets	Change varlist from weightloss-af to weightloss-abdompain
*	20200723	CombineAllPreparedDatasets	Add labels for analgesics
*	20210225	CombineAllPreparedDatasets	BUG FIX: definition of self-harm outcome
*	20210521	CombineAllPreparedDatasets	Add primary care self harm outcome
*************************************

set more off
frames reset
clear

** LOG
capture log close combinelog
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/combine_all_`date'.txt", text append name(combinelog)

**** Set up a frame to contain the combined data; keep saving
frame create combined

**** Set up a frame to merge data in from
frame create tolink

**** Follow-up
** Inclusion/exclusion criteria
frame change combined
use data/clean/finalcohort.dta

label variable patid "unique patient identifier"

label variable inc_extracted "1 if in original GOLD data extract"
label variable inc_perm "1 if permanently registered and acceptable"
label variable inc_linked "1 if available for linkage in HES and ONS"
label variable inc_followup "1 if at least 0 days of eligible followup"
label variable inc_ssri "1 if first SSRI recorded within eligibility window"
label variable inc_switchofinterest "1 if first switch is to a study drug and is within eligibility window"
label variable inc_switchafter "1 if switch is not the same day as first antidep"
label variable inc_switch90d "1 if switch is during/less than 90d after end of a course of the first ad"
label variable inc_switch6m "1 if switch is during/less than 6m after end of a course of the first ad"
label variable inc_under100 "1 if switch date is before age 100"
label variable inc_firstisssri "1 if first ever antidep is an SSRI"
label variable inc_everswitch "1 if ever start a second antidepressant"
label variable inc_thirdad "1 if they do NOT start a third ad on the same day as second"
label variable eligible "1 if meet all inclusion criteria except for switch90"


** Index date, drug history and follow-up end
merge 1:1 patid using data/clean/eligibledrughistory.dta
drop _merge

gen indexdate = secondaddate
format indexdate %dD/N/CY
label variable indexdate "date of first starting the second antidepressant"

label variable firstaddate "date of first antidepressant after uts"
label variable firstadtype "class of first prescribed antidep"
label variable firstaddrug "drug substance, first prescribed antidep"
label variable secondaddate "date of first starting a second antidepressant"
label variable secondadtype "class of second antidep prescribed"
label variable secondaddrug "drug substance, second antidep prescribed"
label variable thirdaddate "date of first starting a third antidepressant"
label variable thirdadtype "class of third antidep prescribed"
label variable thirdaddrug "drug substance, third antidep prescribed"

label variable ad1active "whether the original drug was still active on index"
label variable stopad1 "end date of last ad1 course started before index"
label variable lastdosead1 "most recent dose of first drug by index"
label variable currentdosead1 "current dose of first drug if still active on index"
label variable firstdosead2 "first ever dose of antidep of interest"
label variable switchenddate "end of first course of antidep 2, no washout"
label variable switchenddate30d "end of first course of antidep 2 inc 30day washout"
label variable switchenddate6m "end of first course of antidep 2 inc 6month washout"


** Eligibility dates
merge 1:1 patid using data/clean/combinedpatinfo.dta, keepusing(eligstart eligstop) keep(3) nogen
label variable eligstart "latest of date 18, uts/frd/crd +1y, or study start date"
label variable eligstop "earliest of lcd, tod, death, or study end date" 

** Eligibility
* depression
merge 1:1 patid using data/clean/baselinedepression.dta
drop _merge
label variable depression "1 Diagnosis of depression on or before index"
label variable lastdepdate "Date of most recent depression record on or bef index"

gen depress_12 = (firstaddate - lastdepdate) <= 365.25
label variable depress_12 "1 Diagnosis of depression on or < 12m before first ad"

* depression symptoms
merge 1:1 patid using data/clean/baselinedepressionsympt.dta
drop _merge
label variable depressionsympt "1 depression or symptom code on or before index"
label variable lastdepsympt "Date of most recent depression/symptom record on or bef index"

gen depresssympt_12 = (firstaddate - lastdepsympt) <= 365.25
label variable depresssympt_12 "1 depression diagnoses/symptom code on or < 12m before first ad"




**** Exposure
** Cohort membership
gen cohort = 1 if secondaddrug == 20
replace cohort = 2 if secondadtype == 1	// RMJ updated 20200219
replace cohort = 3 if secondaddrug == 2
replace cohort = 4 if secondaddrug == 33
replace cohort = 5 if secondaddrug == 10

label def cohort 1 "mirtazapine" 2 "ssri" 3 "amitriptyline" 4 "venlafaxine" 5 "duloxetine" 
label values cohort cohort
label variable cohort "Which cohort the patient belongs to"

** Antidep dose
// Import the defined daily dose codebook and match to first and second adtype
// Convert the variables to ddd
frame change tolink
clear

import delimited using data/codelists/DefinedDailyDose_20200220.csv
keep adcode ddd
rename adcode firstaddrug
gen secondaddrug = firstaddrug

frame change combined
frlink m:1 firstaddrug, frame(tolink)
frget ddd, from(tolink)
rename ddd firstddd
drop tolink

frlink m:1 secondaddrug, frame(tolink)
frget ddd, from(tolink)
rename ddd secondddd
drop tolink

gen lastad1_ddd = lastdosead1/firstddd
gen currentad1_ddd = currentdosead1/firstddd
gen firstad2_ddd = firstdosead2/secondddd

drop firstddd secondddd

label var lastad1_ddd "Most recent dose first ad divided by defined daily dose"
label var currentad1_ddd "Current dose first ad divided by defined daily dose"
label var firstad2_ddd "First dose second ad divided by defined daily dose"






**** Outcome
** Date of death
frame change tolink
clear

use patid onsdeath using data/clean/combinedpatinfo.dta

// drop patients not in extracted file
frlink 1:1 patid, frame(combined)
drop if combined==.
drop combined

// link death date back to combined frame
frame change combined
frlink 1:1 patid, frame(tolink)
frget *, from(tolink)
drop tolink

// label
rename onsdeath deathdate
label variable deathdate "death date from ONS filled in with CPRD date if missing or incomplete"

** Cause of death
frame change tolink
clear

use data/clean/causeofdeath.dta
drop if unknowncause==1
drop description all_c unkno

rename icd10 icd10_cod
rename cause_chapt cod_L1
rename cause_sub1 cod_L2
rename cause_sub2 cod_L3
rename cause_sub3 cod_L4

label var icd10_cod "icd10 code for underlying cause of death"
label var cod_L1 "Cause of death, chapter level"
label var cod_L2 "Cause of death, subcategory level 1"
label var cod_L3 "Cause of death, subcategory level 2"
label var cod_L4 "Cause of death, subcategory level 3"

// link back to combined frame
frame change combined
frlink 1:1 patid, frame(tolink)
frget *, from(tolink)
drop tolink



** near-fatal deliberate self harm / suicide
// combine mortality and HES data for this outcome; create two variables (intentional/all)
frame change tolink
clear
use data/clean/hes_selfharm.dta

// link back to combined frame
frame change combined
frlink 1:1 patid, frame(tolink)
frget *, from(tolink)
drop tolink

** intentional self-harm / event of undetermined intent; use death date if this is
** cause of death; if self harm record in HES use that date (checking is prior to death date)
*gen serioussh_any = deathdate if cod_L2== 30
gen serioussh_any = deathdate if cod_L3== 9	// rmj 2021-02-25 error fix
replace serioussh_any = selfharm if selfharm<. & selfharm<deathdate

** intentional self-harm use death date if this is
** cause of death; if self harm record in HES use that date (checking is prior to death date)
*gen serioussh_int = deathdate if cod_L3== 8
gen serioussh_int = deathdate if cod_L3== 9 & cod_L4==5 // rmj 2021-02-25 error fix
replace serioussh_int = intentionalselfharm if intentionalselfharm<. & intentionalselfharm<deathdate

format serioussh* %dD/N/CY
label var serioussh_any "Date of serious self harm/suicide (inc undetermined intent)"
label var serioussh_int "Date of serious self harm/suicide (intentional only)"

gen bl_intselfharm = intentionalselfharm<=index
label var bl_intselfharm "Indicator of hospital record of intentional self harm on or before index"

rename selfharm sh_any
rename intentionalsel sh_int
replace sh_any = (sh_any<.)
replace sh_int = (sh_int<.)
format sh_any sh_int %9.0g
label var sh_any "Indicator of record of self harm (+undetermined intent) at ANY time"
label var sh_int "Indicator of record of self harm (intentional only) at ANY time"

**** SELF-HARM primary care (added 6 May 2021)
frame change tolink
clear

use patid selfharm using data/clean/combinedmedevents.dta
rename selfharm SHdate
label var SHdate "Date of first primary care self-harm record"

frame change combined
frlink 1:1 patid, frame(tolink)
frget SHdate, from(tolink)
drop tolink



**** Demographics
** Age at index, Sex, Practice region
frame change tolink
clear

//use patid gender dob region using data/clean/combinedpatinfo.dta
use patid dob region gender using data/clean/combinedpatinfo.dta

frame change combined
frlink 1:1 patid, frame(tolink)
frget *, from(tolink)
drop tolink

gen ageindex = year(indexdate) - year(dob)
drop dob
label variable ageindex "Age (years) at index date"

label variable region "Practice region"
label def prg	1	"North East" ///
				2	"North West" /// 
				3	"Yorkshire & The Humber" ///
				4	"East Midlands" ///
				5	"West Midlands" ///
				6	"East of England" ///
				7	"South West" ///
				8	"South Central" ///
				9	"London" ///
				10	"South East Coast" ///
				11	"Northern Ireland" ///
				12	"Scotland" ///
				13	"Wales"
label val region prg

rename gender sex
recode sex (0 = 3) (3 = 3)
label variable sex "Sex 1 male 2 female 3 other"
label def sex 1 "male" 2 "female" 3 "other"
label values sex sex

gen sex_orig = sex
label values sex_orig sex
replace sex=. if sex==3
label variable sex_orig "Sex variable before recoding -other- as missing"


** SES
frame change tolink
clear
import delim "data/raw/19_241_Delivery/GOLD_linked/patient_townsend2001_19_241.txt"
rename townsend townsend

frame change combined
frlink 1:1 patid, frame(tolink)
frget townsend, from(tolink)
drop tolink

label var townsend "Patient-level townsend quintile, 1 is high"

** Ethnicity
frame change tolink
clear

use data/clean/baselineethnicity.dta

frame change combined
frlink 1:1 patid, frame(tolink)
frget *, from(tolink)
drop tolink

label values ethnicity ethnicity
label var ethnicity "Ethnicity from CPRD data if available, otherwise HES data"
label var cprd_eth "Ethnicity from CPRD data only"
label var hes_eth "Ethnicity from HES data only"



**** Lifestyle characteristics
** BMI
frame change tolink
clear

use data/clean/baselinebmi.dta

frame change combined
frlink 1:1 patid, frame(tolink)
frget bmi bmicat, from(tolink)
drop tolink

label var bmi "BMI at baseline"
label var bmicat "BMI at baseline, categorised"


** Smoking status
frame change tolink
clear

use data/clean/baselinesmoking.dta

frame change combined
frlink 1:1 patid, frame(tolink)
frget smokestat, from(tolink)
drop tolink

label var smokestat "Smoking status at baseline"


** Alcohol use
frame change tolink
clear

use data/clean/baselinealcohol.dta

frame change combined
frlink 1:1 patid, frame(tolink)
frget alcoholintake, from(tolink)
drop tolink

label var alcoholintake "Alcohol intake at baseline"




**** Medication use
** opioids, gluococorticoids, nsaids, statins, antipsychotics, anxiolytics, hypnotic agents, analgesics, 
frame change combined
merge 1:1 patid using data/clean/baselinemeds.dta
drop _merge

label variable antipsychotics "prescription for antipsychotics in 6m on/bef index"
label variable anxiolytics "prescription for anxiolytics in 6m on/bef index"
label variable gc "prescription for glucocorticoids in 6m on/bef index"
label variable hypnotics "prescription for hypnotic meds in 6m on/bef index"
label variable nsaids "prescription for NSAIDs in 6m on/bef index"
label variable opioids "prescription for opioids in 6m on/bef index"
label variable statins "prescription for statins in 6m on/bef index"

label variable analgesics "prescription for analgesics in 6m on/bef index"



**** Comorbidities
** Depression severity
frame change tolink
clear

use data/clean/baselinedepressionseverity.dta

frame change combined
frlink 1:1 patid, frame(tolink)
frget depsev testsev, from(tolink)
drop tolink

label var depsev "Maximum depression severity on or before baseline"
label var testsev "Severe/not severe on or before baseline using test results"

label def testsev 0 "Not severe" 1 "Severe"
label values testsev testsev

gen severe = (depsev==3 | testsev==1)
label var severe "Have Read code or score result of severe on or before index"

** RECENT cancer
frame change tolink
clear

use data/clean/baselinecancer.dta

frame change combined
frlink 1:1 patid, frame(tolink)
frget *, from(tolink)
drop tolink

label var cancer1year "Record of cancer in the year prior to index"
label var hescancer1year "HES record of cancer in the year prior to index"
label var hesmalig1year "Hes record of malignant neop in the year prior to index"
label var hescancerev "HES record of cancer ever prior to index"
label var hesmaligev "HES record of malignant neoplasm ever prior to index"


** Alcohol misuse
** self-harm
** insomnia, appetite loss, weight losss, epilepsy, anxiety, personality disorer, eating disorder, Huntington's, Parkinson's, MS, hypertension, mi, chf, pvd, cerebrovascular disease, angina, af, vte, hemiplegia, dementia, copd, asthma, dyspnoea, rheumatologic disease, pud, diabetes mellitus (with without complications), renal disease, cancer, metasatic solid tumour, liver disease (mild moderate), AIDS, lec ulcer, pancreatitis, poor mobility, anaemia, intellectual disability, unplanned hospital admission, living in a care home
// 
frame change combined
merge 1:1 patid using data/clean/baselinecomorbidities.dta
drop _merge

unab conditions: weightloss - abdompain
di "`conditions'"

foreach X of local conditions {
	label variable `X' "Diagnosis for `X' on or before index"
	}

label variable rheumatological "Diagnosis for rheumatological conditions on or before index"
label variable diabetes "Diagnosis for diabetes without complications on or before index"
label variable diab_comp "Diagnosis for diabetes with complications on or before index"








**** FINAL COHORT ELIGIBILITY VARIABLES 
// NOTE - dont account for inc_thirdad as one sensitivity analysis needs it; survival analysis drops these pats anyway
gen keep1 = (eligible==1 & bipolar!=1 & schizophrenia!=1 & inc_switch90==1 & depress_12==1)
gen keep2 = (eligible==1 & bipolar!=1 & schizophrenia!=1 & inc_switch90==1 & depression==1)
gen keep3 = (eligible==1 & bipolar!=1 & schizophrenia!=1 & inc_switch90==1 & depresssympt_12==1)
gen keep4 = (eligible==1 & bipolar!=1 & schizophrenia!=1 & inc_switch90==1 & depressionsympt==1)
gen keep5 = (eligible==1 & bipolar!=1 & schizophrenia!=1 & inc_switch6==1 & depress_12==1)
gen keep6 = (eligible==1 & bipolar!=1 & schizophrenia!=1 & inc_switch6==1 & depression==1)
gen keep7 = (eligible==1 & bipolar!=1 & schizophrenia!=1 & inc_switch6==1 & depresssympt_12==1)
gen keep8 = (eligible==1 & bipolar!=1 & schizophrenia!=1 & inc_switch6==1 & depressionsympt==1)

label var keep1 "1 meet protocol criteria (switch 90d depression 12m)"
label var keep2 "1 meet revised criteria (switch 90d depression ever)"
label var keep3 "1 meet revised criteria (switch 90d depression/sympt 12m)"
label var keep4 "1 meet revised criteria (switch 90d depression/sympt ever)"
label var keep5 "1 meet revised criteria (switch 6m depression 12m)"
label var keep6 "1 meet revised criteria (switch 6m depression ever)"
label var keep7 "1 meet revised criteria (switch 6m depression/sympt 12m)"
label var keep8 "1 meet revised criteria (switch 6m depression/sympt ever)"


**** VARIABLES FOR SURVIVAL ANALYSIS / TIME AT RISK
egen enddate6 = rowmin(switchenddate6 deathdate thirdaddate eligstop)
gen endreason6 = 1 if enddate6==deathdate
replace endreason6 = 2 if enddate6==thirdaddate & endreason6==.
replace endreason6 = 3 if enddate6==eligstop & endreason6==.
replace endreason6 = 4 if enddate6==switchenddate6 & endreason6==.

egen enddate0 = rowmin(switchenddate deathdate thirdaddate eligstop)
gen endreason0 = 1 if enddate0==deathdate
replace endreason0 = 2 if enddate0==thirdaddate & endreason0==.
replace endreason0 = 3 if enddate0==eligstop & endreason0==.
replace endreason0 = 4 if enddate0==switchenddate & endreason0==.

egen enddate30 = rowmin(switchenddate30 deathdate thirdaddate eligstop)
gen endreason30 = 1 if enddate30==deathdate
replace endreason30 = 2 if enddate30==thirdaddate & endreason30==.
replace endreason30 = 3 if enddate30==eligstop & endreason30==.
replace endreason30 = 4 if enddate30==switchenddate30 & endreason30==.

label define endreason 1 "death"
label define endreason 2 "new drug", modify
label define endreason 3 "follow-up window end", modify
label define endreason 4 "exposure window end", modify

label values endreason* endreason
label var enddate0 "End of risk period, no wash-out period"
label var enddate6 "End of risk period, 6 month wash-out period"
label var enddate30 "End of risk period, 30 day wash-out period"
label var endreason0 "Reason for end of risk period, no wash-out period"
label var endreason6 "Reason for end of risk period, 6 month wash-out period"
label var endreason30 "Reason for end of risk period, 30 day wash-out period"

**** Year of index date
gen yearindex = year(index)
label var yearindex "Year of first prescription"

**** Time to switching ad
gen timetoswitch = secondaddate - firstaddate
label var timetoswitch "Time (days) between starting first and second antidepressants"


**** SAVE
saveold data/clean/final_combined.dta, replace


**** CREATE DATASET DESCRIPTION AND CODEBOOK FILES
label save using data/clean/AllVariableLabels.do, replace //saves individual value labels to a do file.

describe, replace clear // creates a dataset describing the final dataset.
export delimited using data/clean/DatasetDescription.csv, delim(",") replace

clear
frames reset

capture log close combinelog
exit


