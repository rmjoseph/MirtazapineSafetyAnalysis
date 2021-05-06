* CREATED BY RMJ AT THE UNIVERSITY OF NOTTINGHAM 2021-03-02
*************************************
* Name:	CountNumbersStartingMirtazapine.do
* Creator:	RMJ
* Date:	20210302
* Desc:	Allows comparison of numbers starting mirtazapine to those 'switching' to mirtazapine. 
*		uses only a subset of the antidep information - is from an earlier 'define' dataset so
*		numbers will not match the final analysis.
* Requires: 
* Version History:
*	Date	Reference	Update
*	20210302	CountNumbersStartingMirtazapine	Create file
*************************************

** LOG
capture log close startmirt
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/CountStartEachAntidep_`date'.txt", text append name(startmirt)
**

frames reset

** Get dates from PATIENT and PRACTICE files
*** load all acceptable patients file
import delim using data/raw/Denominators_2019_11/acceptable_pats_from_utspracts_2019_11.txt

*** link to all practices file
**** generate pracid from patid	
tostring patid, gen(patstr) format(%12.1g)
gen pracid=substr(patstr,-3,3)
drop patstr
destring pracid, replace	

**** load the practice dataset
frame create practice
frame practice {
	import delim using data/raw/Denominators_2019_11/allpractices_NOV2019.txt
	}

**** link and merge fields across
frlink m:1 pracid, frame(practice)
frget *, from(practice)
	
*** convert dates from strings
foreach X of varlist frd crd tod deathdate lcd uts {
	rename `X' temp
	gen `X' = date(temp,"DMY")
	format `X' %dD/N/CY
	drop temp
	}

*** CPRD follow-up start plus one year
egen fupstart = rowmax(uts frd crd) 
replace fupstart = floor(fupstart + 365.25)

*** CPRD follow-up end (includes cprd deathdate)
egen fupend = rowmin(tod deathdate lcd)
format fupstart fupend %dD/N/CY
	
*** study start and stop date
gen studystart = date("01/01/2005","DMY")
gen studystop = date("30/11/2018","DMY")
format studystart studystop %dD/N/CY

*** keep required variables
keep patid fupstart fupend uts studystart studystop yob 




** Get linkage info
frame create linkage
frame linkage {
	import delim using "data/raw/set_17_Source_GOLD/linkage_eligibility.txt"
	keep patid hes_e death_e
	}
frlink 1:1 patid, frame(linkage)
frget *, from(linkage)
drop linkage




** Process the drug data from the define datasets
*** load and append each dataset
frame create drugs
frame change drugs
import delim using "data/raw/Define3_20191010/mirtaz3a_Define_Inc1_Therapy_001.txt"

#delimit ;
local datasets mirtaz3a_Define_Inc1_Therapy_001
mirtaz3a_Define_Inc1_Therapy_002
mirtaz3a_Define_Inc1_Therapy_003
mirtaz3a_Define_Inc1_Therapy_004
mirtaz3b_Define_Inc2_Therapy_001
mirtaz3c_Define_Inc3_Therapy_001
mirtaz3d1_Define_Inc1_Therapy_001
mirtaz3d2_Define_Inc1_Therapy_001 ;
#delimit cr

foreach X of local datasets {
	capture frame drop drugs2
	frame create drugs2
	frame drugs2 {
		import delim using "data/raw/Define3_20191010/`X'.txt"
		tempfile temp
		save "`temp'", replace
		}
	append using "`temp'"
	}

*** drop records before uts
**** make eventdate a date
rename eventdate temp
gen eventdate=date(temp,"DMY")
format eventdate %dD/N/CY
drop temp

drop if eventdate==.

**** merge across uts
frlink m:1 patid, frame(default)
frget uts, from(default)
drop default
	
**** drop records
drop if eventdate<uts

*** merge with the antideps code list
merge m:1 prodcode using data/clean/drugcodes.dta
keep if _merge==3
drop analgesics-_merge


*** find first record of each antidep type
**** variable categorising by type
keep if antidep==1
drop antidep

gen antidep = 1 if antidepdrug=="mirtazapine"
replace antidep = 2 if antideptype=="ssri"
replace antidep = 3 if antidepdrug=="amitriptyline"
replace antidep = 4 if antidepdrug=="venlafaxine"

codebook patid if antidep==2

**** there are records of nefazodone - drop
drop if antidepdrug=="nefazodone"

**** first record of each drug
bys patid antidepdrug (eventdate): keep if _n==1

**** first of each of the classes of interest
bys patid antidep (eventdate): gen firstmirtaz = eventdate if antidep==1
bys patid antidep (eventdate): gen firstssri = eventdate if antidep==2
bys patid antidep (eventdate): gen firstamitrip = eventdate if antidep==3
bys patid antidep (eventdate): gen firstvenlaf = eventdate if antidep==4

foreach X of varlist firstmirtaz firstssri firstami firstven {
	bys patid (`X'): replace `X'=`X'[1]
	format `X' %dD/N/CY
	}

**** also need second ssri prescn if switching ssris
bys patid antidep (eventdate): gen secondssri = eventdate[2] if antidep==2 // still allows 2nd to be same day as 1st
bys patid (secondssri): replace secondssri=secondssri[1]
format secondssri %dD/N/CY
sort patid eventdate antidepdrug	
	
	
	
*** determine the first two antidepressant prescription dates (ignoring multiple prescn same day)
**** first two antidep records (what if >2 on a day??)
bys patid (eventdate): gen firstdate = eventdate[1]
format firstdate %dD/N/CY

gen prescdonfirst = (eventdate==firstdate)

bys patid prescdonfirst (eventdate): gen seconddate = eventdate[1] if prescdonfirst==0
bys patid (seconddate): replace seconddate=seconddate[1]
format seconddate %dD/N/CY

sort patid eventdate antidepdrug

keep if eventdate==firstdate | eventdate==seconddate	
	
	
*** Find the first and second antidepressants, with sep indicator for >1 on the same day
bys patid eventdate: gen count = _N
	
**** First antidep
egen firstcat = rowmin(firstmirtaz firstssri firstami firstven)
gen firstad = "mirt" if firstmirtaz==firstdate
replace firstad = "ssri" if firstssri==firstdate
replace firstad = "amit" if firstami==firstdate
replace firstad = "venl" if firstvenl==firstdate
bys patid (eventdate): replace firstad = ">1" if count[1]>1

**** second ad
gen secondad = "mirt" if firstmirtaz==seconddate & seconddate!=.
replace secondad = "ssri" if firstssri==seconddate & seconddate!=.
replace secondad = "ssri" if secondssri==seconddate & seconddate!=.
replace secondad = "amit" if firstami==seconddate & seconddate!=.
replace secondad = "venl" if firstven==seconddate & seconddate!=.
replace secondad = ">1" if firstad == ">1"
replace secondad = ">1" if eventdate==seconddate & count>1 
bys patid (secondad): replace secondad=secondad[1]

sort patid eventdate antidepdrug
	
*** keep one record per patient
keep patid firstdate seconddate firstm firsts firstami firstv seconds firstad secondad
duplicates drop



** combine with the follow-up dates
frlink 1:1 patid, frame(default)
frget *, from(default)


** eligibility
gen eligible = 1 if firstdate>=fupstart & firstdate>=studystart & firstdate<fupend & firstdate<studystop
replace eligible = . if hes_e!=1 | death_e!=1
replace eligible = . if year(firstdate) - yob <18
replace eligible = . if year(firstdate) - yob >=100
replace eligible = . if fupend<fupstart | fupend<studystart | fupstart>=studystop

** save copy of dataset
drop default yob uts fupstart fupend studystart studystop hes_e death_e
save data/clean/firstdrugsfromdefineonly.dta, replace

** RESULTS
count
count if seconddate<.
tab firstad,m
tab secondad,m
tab firstad secondad,m

keep if eligible==1
count
count if seconddate<.
tab firstad,m
tab secondad,m
tab firstad secondad,m

** end
frames reset
capture log close startmirt
exit
