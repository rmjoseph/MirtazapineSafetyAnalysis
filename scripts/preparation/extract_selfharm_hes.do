** CREATED 27-01-2020 by RMJ at the University of Nottingham
*************************************
* Name:	extract_selfharm_hes.do
* Creator:	RMJ
* Date:	20200127
* Desc:	Finds date first selfharm record in hes - both intentional self harm and any recorded self harm
* Requires: Stata 16 for frames function
* Version History:
*	Date	Reference	Update
*	20210622	extract_selfharm_hes	Bug fix? death_group2->3 and death_group3->4 (!no dif in output)
*************************************

set more off
frames reset
clear

*** Open cause of death code list and prepare for linking
frame create icd10codes
frame change icd10codes
clear

import excel data/codelists/Appendix1_mirtaz_codelists.xlsx, sheet(death_expanded) firstrow case(lower)

rename code icd10
replace all_cause=0 if all_cause==.

gen selfharm = regexm(death_group3,"Intentional self-harm")==1
keep if selfharm==1
gen intentionalselfharm=1 if death_group4=="Intentional self-harm"
drop death_group* all_cause


*** Open the HES dataset - all diagnosis codes during a spell
frame change default
import delim "data/raw/19_241_Delivery/GOLD_linked/hes_diagnosis_hosp_19_241.txt"

** Narrow down to icd codes of interest for speed
gen keep = regex(icd,"^X")==1 | regex(icd,"^Y")==1 
keep if keep==1
drop keep

** Merge in the self harm code lists
rename icd icd10
frlink m:1 icd10, frame(icd10codes)
frget *, from(icd10codes)

** Keep only those with self harm code
keep if icd10codes<.
drop icd10codes

** Event date is the date of admission for that hospitalisation
gen eventdate = date(admidate,"DMY")
format eventdate %dD/N/CY


**** Find first records for self harm (any) and for intentional self harm
** - use separate frames then recombine by merging with the patids
keep patid icd10 desc eventdate selfharm intentional

** put records into own frame according to code type
frame put if selfharm==1, into(sh)
frame put if intentionalselfharm==1, into(ish)
keep patid
bys patid: keep if _n==1

** keep first record of self harm per patient
frame change sh
bys patid (eventdate): keep if _n==1
replace selfharm = eventdate
keep patid selfharm

** keep first record of intentional self harm per patient
frame change ish
bys patid (eventdate): keep if _n==1
replace intentionalselfharm = eventdate
keep patid intentionalselfharm

** Merge the two new datasets back with the patid list
frame change default

frlink 1:1 patid, frame(sh)
frget *, from(sh)

frlink 1:1 patid, frame(ish)
frget *, from(ish)

** Tidy and save
keep patid selfharm intentionalselfharm

sort patid
saveold data/clean/hes_selfharm.dta, replace

frames reset
clear
exit








