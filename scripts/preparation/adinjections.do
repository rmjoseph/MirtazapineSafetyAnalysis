* CREATED BY RMJ AT THE UNIVERSITY OF NOTTINGHAM 2020-01-30
*************************************
* Name:	adinjections.do
* Creator:	RMJ
* Date:	20200130
* Desc: Tidies injection data (start/stop and strength)
* Requires: Stata 16 (Frames function)
* Version History:
*	Date	Reference	Update
*	20200130	adinjections	Create file
*	20200203	adinjections	Convert addrug and adtype to numeric
*************************************

set more off
frames reset
clear


**** LOAD AND TIDY ANTIDEP DATASET
frame create antideps
frame change antideps
use data/raw/stata/antidep_records
drop if prodcode==.
drop if eventdate==.
drop if prodcode == 1

** Recode values of 0 to missing
recode qty 0=.
recode numdays 0=.
recode numpacks 0=.
recode packtype 0=.




**** KEEP ONLY INJECTION RECORDS
** Load clean antideps strengths file
frame create strengths
frame  change strengths
use data/clean/drugstrengths
keep if type=="injection"
*levelsof prodcode if type=="injection", local(injections)

** Merge back into the antideps file and keep only injections
*gen inject = .
frame change antideps
frlink m:1 prodcode, frame(strengths)
frget *, from(strengths)
keep if strengths<.
drop strengths

*foreach X of local injections {
*	replace inject = 1 if prodcode==`X'
*	}

*keep if inject==1

	
	

**** MERGE WITH THE COMMON_DOSAGES LOOKUP
merge m:1 dosageid using data/raw/stata/common_dosages
drop if _merge==2
drop _merge
drop choice_of_dose dose_max_average change_dose

** Rename daily_dose ndd (just for familiarity)
rename daily_dose ndd

** recode values
recode ndd 0=.
recode dose_number 0=.
recode dose_frequency 0=.
recode dose_interval 0=.
recode dose_duration 0=.

** cleaning based on dosage_text
recode ndd dose_number dose_freq dose_int dose_dur (1=.) if dosage_text=="I.M."

replace dose_unit = "ML" if dose_number==0.5 & dose_unit==""	
replace dose_unit = "ML" if dosage_text=="THREE" 

local textlist "10 100 150 20 200 25 40 60 75 80 FIVE X10 40MGM/2WK"
foreach X of local textlist {
	replace dose_unit = "MG" if dosage_text=="`X'" 
	}

replace dose_num = 2 if dosage_text=="TWICE A DAY"
replace dose_freq = 1 if dosage_text=="TWICE A DAY"	
	
local textlist `" "WEEK" "WEEKLY" "USE ONE EVERY WEEK" "TO BE INJECTED WEEKLY" "ONE WEEKLY" "ONE INJECTION WEEKLY" "ONE EVERY WEEK" "ONE A WEEK" "ONCE WKLY" "ONCE WEEKLY" "ONCE EACH WEEK" "ONCE A WEEK" "EVERY WEEK" "1 WEEKLY" "1 EVERY WEEK" "1 EACH WEEK" "1 A WEEK" "'
foreach X of local textlist {
	replace ndd=1/7 if dosage_text=="`X'"
	replace dose_number=1 if dosage_text=="`X'"
	replace dose_frequency=1 if dosage_text=="`X'"
	replace dose_interval=7 if dosage_text=="`X'"
	}

local textlist `" "2 A WEEK" "2 WEEKLY" "2WEEKLY" "2WKLY" "TAKE TWO WEEKLY" "TWO EVERY WEEK" "TWO WEEKLY" "TWICE WEEKL" "TWICE WEEKLY" "ONE TWICE WEEK" "'
foreach X of local textlist {
	replace ndd=2/7 if dosage_text=="`X'"
	replace dose_number=2 if dosage_text=="`X'"
	replace dose_frequency=1 if dosage_text=="`X'"
	replace dose_interval=7 if dosage_text=="`X'"
	}

	
local textlist `" "TWO WEEK" "/2WK" "1 FORTNIGHT" "EVERY 2 WEEKS" "EVERY 2/52" "EVERY 2WKS" "EVERY FORTNIGHT" "EVERY TWO WEEK" "EVERY TWO WEEKS" "FORTNIGHTLY" "ONE EVERY 2 WEEKS" "ONE EVERY FORTNIGHT" "ONE EVERY TWO WEEK" "ONE EVERY TWO WEEKS" "TO BE INJECTED EVERY 2 WEEKS" "IM EVERY 2 WEEKS" "'
foreach X of local textlist {
	replace ndd=1/14. if dosage_text=="`X'"
	replace dose_number=1 if dosage_text=="`X'"
	replace dose_frequency=1 if dosage_text=="`X'"
	replace dose_interval=14 if dosage_text=="`X'"
	}
	
local textlist `" "3 WEEKLY" "3WKLY" "THREE WEEKLY" "3WEEKLY" "EVERY 3 WEEKS" "EVERY 3 WKS" "EVERY THREE WEEK" "EVERY THREE WEEKS" "EVERY3WEEKS" "ONE EVERY 3 WEEKS" "ONE EVERY THREE WEEK"  "'
foreach X of local textlist {
	
	replace ndd=1/21 if dosage_text=="`X'"
	replace dose_number=1 if dosage_text=="`X'"	
	replace dose_frequency=1 if dosage_text=="`X'"
	replace dose_interval=21 if dosage_text=="`X'"
	}

	
local textlist `" "4 WEEKLY" "4WEEKLY" "EVERY 4 WEEKS" "EVERY FOUR WEEKS" "ONE EVERY 4 WEEKS" "ONE EVERY FOUR WEEK" "'
foreach X of local textlist {
	
	replace ndd=1/28 if dosage_text=="`X'"
	replace dose_number=1 if dosage_text=="`X'"	
	replace dose_frequency=1 if dosage_text=="`X'"
	replace dose_interval=28 if dosage_text=="`X'"
	}
	
	
local textlist `" "EVERY MONTH" "MTHLY" "ONCE A MONTH" "ONE EVERY MONTH" "ONE MONTHLY" "ONE PER MONTH" "TO BE INJECTED MONTHLY" "MONTHLY" "IM MONTHLY" "MONTHLY INJECTIONS" "PER MONTH" "MONTHLY INJECTION" "'
foreach X of local textlist {
	
	replace ndd=1/30 if dosage_text=="`X'"
	replace dose_number=1 if dosage_text=="`X'"	
	replace dose_frequency=1 if dosage_text=="`X'"
	replace dose_interval=30 if dosage_text=="`X'"
	}
	
	
replace ndd=1/35 if dosage_text=="5 WEEKLY"
replace dose_number=1 if dosage_text=="5 WEEKLY"
replace dose_frequency=1 if dosage_text=="5 WEEKLY"
replace dose_interval=35 if dosage_text=="5 WEEKLY"
	
replace ndd=1/84 if dosage_text== "12WEEKLY"
replace dose_number=1 if dosage_text== "12WEEKLY"
replace dose_frequency=1 if dosage_text== "12WEEKLY"
replace dose_interval=84 if dosage_text== "12WEEKLY"


replace ndd=1/90 if dosage_text=="3 MONTHLY"
replace dose_number=1 if dosage_text=="3 MONTHLY"
replace dose_frequency=1 if dosage_text=="3 MONTHLY"
replace dose_interval=90 if dosage_text=="3 MONTHLY"

replace dose_interval=14 if dosage_text=="40MGM/2WK"





**** MERGE WITH PACKTYPE LOOKUP FOR INFORMATION ABOUT HOW THE DRUG IS DISPENSED
frame create pack
frame change pack
import delim using "data/raw/Lookups_2019_06/packtype.txt", delim(tab)

frame change antideps
replace packtype = . if packtype==0

frlink m:1 packtype, frame(pack)
frget *, from(pack)
drop pack
order packtype_desc, after(packtype)


**** MERGE WITH PRODUCT FILE AND ANTIDEPS LIST TO GET PRODUCT NAME
** merge product file and antideps file
frame create codes
frame change codes
clear
use data/raw/stata/product.dta
merge 1:1 prodcode using data/clean/drugcodes.dta, keep(3) nogen
keep if antidep==1
drop smoking-statins
keep prodcode productname

** Link back in
frame change antideps
frlink m:1 prodcode, frame(codes)
frget *, from(codes)
drop codes
order productname, after(prodcode)


**** GET SINGLE DOSE INFO FROM PACKTYPE
gen singledose = .

replace singledose = 0.5 if packtype==269 | packtype==6026
replace singledose = 1 if packtype==49 | packtype==30222 | packtype==40957 | packtype==5141 | packtype==238 | packtype==4789 | packtype==4723 | packtype==2635 | packtype==2266 | packtype==2637 | packtype==13050
replace singledose = 2 if packtype==16 | packtype==447 | packtype==5000 | packtype==2677
replace singledose = 5 if packtype==25

replace singledose = 0.2 if packtype==44059 & prodcode==2155
replace singledose = 1 if singledose == .




**** VOLUME INJECTED MAY BE SPECIFIED IN DOSE_NUMBER FIELD; ALSO INFO IN PACKTYPE DESCS.
***	INFO FROM COMMON DOSAGES SHOULD TRUMP PACKTYPE INFO
gen unitvol = .

replace unitvol = singledose // missing values already filled in as 1

replace unitvol = dose_number if dose_unit=="ML"



**** DOSE INJECTED MAY BE SPECIFIED IN DOSE_NUMBER FIELD; STRENGTH ALSO FROM UNITVOL
*** MULTIPLIED BY PRODUCT STRENGTH (ALL MG/ML). DOSAGE_TEXT TRUMPS OTHERS.
gen unitstrength = .

replace unitstrength = newstrength * unitvol
replace unitstrength = dose_number if dose_unit=="MG"




**** DURATION: NUMDAYS AND DOSE_INTERVAL MOST USEFUL SOURCES OF INFO. ASSUME NONE OF INJECTIONS ARE TO BE REPEATED EVERY DAY.
gen duration = .

replace duration = dose_interval if dose_interval!=1 
replace duration = numdays if numdays!=1 & duration==.

*** FILL IN MISSINGS WITH MEDIAN VALUES
bys prodcode unitstrength: egen medint1 = median(duration)
bys antidepdrug unitstrength: egen medint2 = median(duration)
bys antidepdrug: egen medint3 = median(duration)

replace duration = medint1 if duration==.
replace duration = medint2 if duration==.
replace duration = medint3 if duration==.

*** FINALLY FILL IN SINGLE VALUE FOR LAST DRUG
replace duration = 20 if prodcode==30375



**** GEN START AND STOP DATES
gen start = eventdate
gen real_stop = eventdate + duration
format start real_stop %dD/N/CY



**** TIDY AND SAVE
replace antideptype = "2" if antideptype=="otherAntidep"
replace antideptype = "4" if antideptype=="tca"
replace antidepdrug = "6" if antidepdrug=="clomipramine"
replace antidepdrug = "13" if antidepdrug=="flupentixol"
destring antidepdrug,replace
destring antideptype,replace
keep patid prodcode antideptype antidepdrug unitstrength start real_stop type dosageid

saveold data/clean/antidepinjections.dta, replace

frames reset
clear
exit
