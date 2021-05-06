* CREATED BY RMJ AT THE UNIVERSITY OF NOTTINGHAM 2019-11-27
*************************************
* Name:	linkage_eligibility.do
* Creator:	RMJ
* Date:	20191125
* Desc:	Outputs txt file to send to CPRD to request linked files
* Requires: Stata 16 (Frames function); uses data from Define
* Version History:
*	Date	Reference	Update
*	20191125	linkage_eligibility	Create file
*	20191125	linkage_eligibility	Change to allpractice file
*	20191204	linkage_eligibility	Rewrite to use the denominator files
*	20191204	linkage_eligibility	Remove requirement of linkage w/deprivation
*************************************

/* INFO
* The study protocol defines the steps needed to determine eligibility. Multiple
* data files are needed for this initial step. The current script uses a reduced 
* list of criteria - the linkage request may include some ineligible patients but
* should not falsely exclude anyone. This is because the less detailed define dataset 
* (which contains event dates for all SSRI prescriptions) was used to determine 
* eligibility, along with the linkage eligibility file and the Nov 2019 denominator files.
* The following criteria were applied:
*	- Permanently registered acceptable patients
*	- Eligibile for linkage with HES, ONS, (// note - deprivation can be imputed so less imp)
*	- Eligibility start <= eligibility end, where start = latest of date18, 
*		uts+1y, crd+1y, frd+1y, 01 Jan 2005 and end = earliest of TOD, LCD, 30 Nov 2018
*	- Excluding any events recorded prior to UTS date, first SSRI prescribed:
*		- after turning 18
*		- after 01 Jan 2005
*		- after UTS + 1 year
*		- after FRD/CRD + 1 year
*		- before TOD
*		- before LCD
*		- before 30 Nov 2018
* Criteria relating to different types of antidepressants, timing of index date, 
* and records of depression, bipolar, or schizophrenia were not applied.
*/


*** PREPARE TO START
frames reset
clear

frame create patient
frame create linkage
frame create practice
frame create ssri


** LOG
capture log close linkagelog
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/LinkageEligibility_`date'.txt", text append name(linkagelog)


**** CRITERIA 1: 
*	- Permanently registered acceptable patients

*** LOAD PATIENT FILE
frame change patient
clear
use patid yob frd crd regstat tod accept using "data/raw/stata/allpatients.dta"

** Convert date variables from strings to dates
foreach X of varlist frd crd tod {
	rename `X' temp
	gen `X' = date(temp,"DMY")
	format `X' %dD/N/CY
	drop temp
	}

*** Keep permanently registered acceptable patients
gen permanent = (regstat==0)
drop regstat 
count
keep if perm==1 & accept==1
count



**** CRITERIA 2: 
*	- Eligibile for linkage with HES, ONS

** Get patid and linkdate for those in hes, death //, and lsoa data CRITERIA REMOVED
frame change linkage
use "data/raw/stata/linkageeligibility.dta", clear

count
keep if hes_e==1 & death_e==1 // & lsoa_e==1
count
keep patid linkdate hes_e death_e lsoa_e

** Convert linkdate from string to date
foreach X of varlist linkdate {
	rename `X' temp
	gen `X' = date(temp,"DMY")
	format `X' %dD/N/CY
	drop temp
	}


*** Merge linkage file into patient file and keep only patients who
**	are eligible for linkage
frame change patient
frlink 1:1 patid, frame(linkage)
count
drop if linkage==.
count

** ALSO, only keep patients who join practice before linkdate
* "patients registered for the FIRST TIME in a practice after the
*  linkdate will not be in the source file"
frget *, from(linkage)
drop linkage
frame drop linkage
count
drop if linkdate < frd 
count



**** CRITERIA 3: 
*	- Eligibility start <= eligibility end, where start = latest of date18, 
*		uts+1y, crd+1y, frd+1y, 01 Jan 2005 and end = earliest of TOD, LCD, 30 Nov 2018

** Load practice data for uts and lcd
frame change practice
clear
use "data/raw/stata/allpractices.dta"

** Convert date variables from strings to dates
foreach X of varlist lcd uts {
	rename `X' temp
	gen `X' = date(temp,"DMY")
	format `X' %dD/N/CY
	drop temp
	}

*** Merge uts and lcd from practice into patient
frame change patient

* Generate patid
tostring patid, gen(patstr)
gen pracid=substr(patstr,-3,3)
drop patstr
destring pracid, replace

* Link patient and practice frames and get variables
frlink m:1 pracid, frame(practice)
frget *, from(practice)
drop practice
frame drop practice

* Generate variable showing date 18
gen plus18 = yob + 18
tostring plus18, replace
gen date18=date(plus18,"Y")
format date18  %dD/N/CY
drop yob plus18 

* Create variable which is the maximum value of uts+1y, crd+1y, frd+1y
egen plus1 = rowmax(uts crd frd)
format plus1 %dD/N/CY
replace plus1 = plus1+365.25
label variable plus1 "Latest of uts crd or frd plus 1 year"

* Create variables for the study start and end date
gen studystart=date("01/01/2005","DMY")
gen studyend=date("30/11/2018","DMY")
format studystart studyend %dD/N/CY

* Create eligibility start and stop variables
egen eligstart = rowmax(plus1 date18 studystart)
egen eligstop = rowmin(lcd tod studyend)
format eligstart eligstop %dD/N/CY

** KEEP if eligstart is before or on eligstop
count
keep if eligstart <= eligstop
count


**** CRITERIA 4: 
*	- Excluding any events recorded prior to UTS date, first SSRI prescribed:
*		- after turning 18
*		- after 01 Jan 2005
*		- after UTS + 1 year
*		- after FRD/CRD + 1 year
*		- before TOD
*		- before LCD
*		- before 30 Nov 2018

** Load the SSRI data and find the date of the first prescription AFTER uts
* NOTE: the extracted define therapy files contain data for both males and females
* so don't have to worry about combining them.
frame change ssri
clear

* Import and combine the four define therapy files
import delimited using "data/raw/Mirt1m/Mirt1m_Define_Inc1_Therapy_001.txt"

foreach X of numlist 2/4 {
	frame create import
	frame change import
	import delim using "data/raw/Mirt1m/Mirt1m_Define_Inc1_Therapy_00`X'.txt"
	tempfile file
	save "`file'", replace
	frame change ssri
	append using "`file'"
	frame drop import
	}

* Convert eventdate from string to date
foreach X of varlist eventdate {
	rename `X' temp
	gen `X' = date(temp,"DMY")
	format `X' %dD/N/CY
	drop temp
	}

* Merge in the uts from the patient frame to the ssri frame
frame change ssri
frlink m:1 patid, frame(patient)
drop if patient==.
frget uts, from(patient)
drop patient

* Keep only events recorded on or after the uts; also drop if no eventdate
keep if uts <= eventdate
keep if eventdate != .

* Keep the first record per patient
sort patid eventdate
bys patid (eventdate): keep if _n==1

** Go back to patient file and merge in the first SSRI prescription dates
frame change patient
frlink 1:1 patid, frame(ssri)
frget eventdate, from(ssri)
frame drop ssri

* Keep patients who have an SSRI recorded:
*		- after their uts date
count
keep if ssri!=.
count
drop ssri

*		- after turning 18
keep if date18<=eventdate
count

*		- after 01 Jan 2005
keep if studystart<=eventdate
count

*		- after UTS + 1 year
*		- after FRD/CRD + 1 year
keep if plus1<=eventdate
count

*		- before TOD
keep if eventdate<=tod
count

*		- before LCD
keep if eventdate<=lcd
count

*		- before 30 Nov 2018
keep if eventdate<=studyend
count


* Keep variables needed
keep patid hes_e death_e lsoa_e

* Export as txt file following requested naming convention
export delimited using "data/clean/19_241_UniNottingham_patientlist.txt", delim(tab) replace

* End
log close linkagelog
exit





