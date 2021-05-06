** CREATED 22-05-2020 by RMJ at the University of Nottingham
*************************************
* Name:	extract_cancer_hes.do
* Creator:	RMJ
* Date:	20200522
* Desc:	Extracts most recent cancer/malig record from HES diagnosis dataset
* Requires: Stata 16 for frames function; index date
* Version History:
*	Date	Reference	Update
*	20200522	extract_selfharm_hes	Create file
*************************************

** NOTE - use ICD10 categories C00-D48 (neoplasms) & C00-C97 (malignant neop.)

set more off
frames reset
clear

*** Load the HES dataset - all diagnosis codes during a spell
import delim "data/raw/19_241_Delivery/GOLD_linked/hes_diagnosis_hosp_19_241.txt"

** Narrow down to icd codes of interest
gen keep = regex(icd,"^C")==1 | regex(icd,"^D[0-4]")==1 
keep if keep==1
drop if regexm(icd,"^D49")==1
drop keep
gen cancer=1

** Tag the malignant neoplasm codes
gen malignant = regex(icd,"^C")==1 
replace malignant = 1 if regexm(icd,"^C9[8-9]")==1

** Event date is the date of admission for that hospitalisation
gen eventdate = date(admidate,"DMY")
format eventdate %dD/N/CY
// <5 have no eventdate - use discharge date
replace eventdate = date(discharged,"DMY") if eventdate==.

** Merge in index date
merge m:1 patid using data/clean/finalcohort.dta, keepusing(secondaddate)
drop if _merge==2

** Drop events after index date
drop if eventdate>secondaddate


**** Most recent records for cancer (any) and for malignant neoplasms before index
** - use separate frames then recombine by merging with the patids
keep patid icd eventdate malignant cancer

** put records into own frame according to code type
frame put if cancer==1, into(can)
frame put if malignant==1, into(mal)
keep patid
bys patid: keep if _n==1

** keep first record of cancer per patient
frame change can
bys patid (eventdate): keep if _n==_N
replace cancer = eventdate
keep patid cancer

** keep first record of malignant neoplasms per patient
frame change mal
bys patid (eventdate): keep if _n==_N
replace malignant = eventdate
keep patid malignant

** Merge the two new datasets back with the patid list
frame change default

frlink 1:1 patid, frame(can)
frget *, from(can)

frlink 1:1 patid, frame(mal)
frget *, from(mal)

** Tidy and save
keep patid cancer malignant
format cancer malignant %dD/N/CY

sort patid
saveold data/clean/hes_cancer.dta, replace

frames reset
clear
exit



