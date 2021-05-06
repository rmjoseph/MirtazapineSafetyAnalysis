* CREATED BY RMJ AT THE UNIVERSITY OF NOTTINGHAM 2019-12-12
*************************************
* Name:	EligibleDrugHistory.do
* Creator:	RMJ
* Date:	20191212
* Desc: Uses output of DrugPrep to determine who switches antideps
* Requires: Stata 16 (Frames function)
* Version History:
*	Date	Reference	Update
*	20191212	EligibleDrugHistory	Save file before looking at drug exp and conditions
*	20191217	EligibleDrugHistory	Don't drop patients who never change drug 
*	20200109	EligibleDrugHistory	Load and append multiple drug files; reduce memory by encoding
*	20200109	EligibleDrugHistory	Change secondantidep sections to treat type and drug as numeric
*	20200109	EligibleDrugHistory	Collapse into courses before working out changes
*	20200129	EligibleDrugHistory	Use frames to define first second third drug history
*	20200129	EligibleDrugHistory	Define end of exposure to the switch drug (3 vars)
*	20200129	EligibleDrugHistory	Use tidy strength dataset to calculate dose
*	20200130	EligibleDrugHistory	Create variable showing end date of first drug wrt switch
*	20200205	EligibleDrugHistory	Modify antideptype ssri to 1 so comes first in sort
*	20200205	EligibleDrugHistory	Remove section appending all drugprep files - new dofile
*	20200205	EligibleDrugHistory	Update dose section as first calculated in drugprep now
*	20201006	EligibleDrugHistory	Save a subset of the data for working out time varying exp
*************************************

** LOG
capture log close adlog
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/EligibleDrugHistory_`date'.txt", text append name(adlog)

** Prepare
frames reset
clear
frame create antideps

** Load the output of DrugPrep for antidepressants
frame change antideps
clear

use data/clean/combinedcleanedantideps.dta


**** ESTIMATE DAILY DOSE FOR EACH PRESCRIPTION
** First, fill in any missing dose with medians, calculated according to the sequence below
* median for that patient for that prodcode
* median for that prodcode
* median for that patient for that particular drug substance and type
* median for that particular drug substance and type
* median for that particular drug substance 
bys patid prodcode: egen meddose1 = median(dose)
bys prodcode: egen meddose2 = median(dose)
bys patid antidepdrug type: egen meddose3 = median(dose)
bys antidepdrug type: egen meddose4 = median(dose)
bys antidepdrug: egen meddose5 = median(dose)

gen cleandose = dose
replace cleandose = meddose1 if cleandose == .
replace cleandose = meddose2 if cleandose == .
replace cleandose = meddose3 if cleandose == .
replace cleandose = meddose4 if cleandose == .

replace cleandose = . if type == "injection" | type==""

drop dose meddose*



**** WORK OUT START DATE OF EACH DRUG, KEEPING INFO FOR FIRST THREE
** Copy into a new frame
frame put patid start real_stop antideptype antidepdrug, into(drugdates)
frame change drugdates

** Keep only first record of each drug
// SORT
sort patid antidepdrug start real_stop
by patid antidepdrug: keep if _n==1

** Keep only the first three drugs
// SORT
sort patid start real_stop antideptype antidepdrug 
by patid: keep if _n<=3

** Generate variables for drug start dates, drugs, types
by patid: gen firstaddate = start[1]
by patid: gen firstadtype = antideptype[1]
by patid: gen firstaddrug = antidepdrug[1]
by patid: gen secondaddate = start[2]
by patid: gen secondadtype = antideptype[2]
by patid: gen secondaddrug = antidepdrug[2]
by patid: gen thirdaddate = start[3]
by patid: gen thirdadtype = antideptype[3]
by patid: gen thirdaddrug = antidepdrug[3]

format firstaddate secondaddate thirdaddate %dD/N/CY

** Keep one record per patient
by patid: keep if _n==1

** Merge back into original frame
keep patid first* second* third*
frame change antideps
frlink m:1 patid, frame(drugdates)
frget *, from(drugdates)
drop drugdates

frame drop drugdates

**** Save a file to use to calculate time varying AD exposure in another do-file
** keep only those who ever start a second ad, and whose first ad is an ssri
frame put if secondaddate<., into(subset)
frame change subset
count
keep if firstadtype==1
drop firstad* secondad* thirdad*
saveold data/clean/antidepsubsetfortimevaryingexp.dta, replace
frame change antideps
frame drop subset
****

******* WORKING OUT DOSE OF FIRST DRUG ON THE DATE OF SWITCHING
** KEEP ONLY RECORDS OF FIRST AND SECOND DRUG
keep if antidepdrug==firstaddrug | antidepdrug==secondaddrug

** KEEP RECORDS OF FIRST DRUG IF START BEFORE INDEX DATE (where index is secondaddate)
// SORT
sort patid antidepdrug start real_stop
by patid antidepdrug: drop if start > secondaddate & antidepdrug==firstaddrug


*** SAVE TO PROTECT FROM CRASHES
saveold data/clean/eligibledrughistory_p1.dta, replace
***


** multiple strengths same day
// SORT
sort patid antidepdrug start real_stop
by patid antidepdrug start: egen sumdose = sum(cleandose)

** KEEP THE MOST RECENT RECORD OF FIRST AD ON OR BEFORE INDEX
by patid antidepdrug: drop if _n!=_N & antidepdrug==firstaddrug

** INDICATOR VARIABLE SHOWING IF DRUG1 WAS STILL ACTIVE AT INDEX
sort patid start antidepdrug
by patid: gen ad1active=(start[1]<=start[2] & real_stop[1]>start[2])

** GENERATE VARIABLE SHOWING END DATE OF DRUG1 BEFORE SWITCHING
by patid: gen stopad1=real_stop[1]
format stopad1 %dD/N/CY

** LAST DOSE FIRST DRUG
sort patid start real_stop
by patid: gen lastdosead1 = sumdose[1]

** CURRENT DOSE FIRST DRUG
gen currentdosead1=lastdosead1*ad1active

** STARTING DOSE SWITCH DRUG
sort patid start antidepdrug real_stop
by patid: gen firstdosead2 = sumdose[2]



****** COLLAPSE COURSES TO GENERATE FOLLOW-UP END DATES
** WANT a variable allowing no gaps, a variable allowing for a 30 day gap, and 
** a variable allowing for a 6 month gap.

** NOTES: if no switch, have only one record. If switch have one record of first
** drug and multiple records of second drug. Use frames again.
frame put if antidepdrug == secondaddrug, into(followup)
frame change followup
keep patid start real_stop 

// If consecutive records overlap, make the start date the first in the sequence
sort patid start real_stop
by patid: replace start = start[_n-1] if _n!=1 & start<= real_stop[_n-1]

// Now all overlapping records have the same start date, keep the record with the latest stop date
// SORT
sort patid start real_stop
by patid start: keep if _n==_N

// gen follow up stop variable
by patid: gen switchenddate = real_stop[1]
format switchenddate %dD/N/CY

** NOW REPEAT, adding 30 days to stop date
replace real_stop = real_stop + 30

// If consecutive records overlap, make the start date the first in the sequence
// SORT
sort patid start real_stop
by patid: replace start = start[_n-1] if _n!=1 & start<= real_stop[_n-1]

// Now all overlapping records have the same start date, keep the record with the latest stop date
// SORT
sort patid start real_stop
by patid start: keep if _n==_N

// gen follow up stop 30 days variable
by patid: gen switchenddate30d = real_stop[1]
format switchenddate30d %dD/N/CY

** NOW REPEAT, adding 6 months (-30d) to stop date
replace real_stop = real_stop + (365.25/2) - 30

// If consecutive records overlap, make the start date the first in the sequence
// SORT
sort patid start real_stop
by patid: replace start = start[_n-1] if _n!=1 & start<= real_stop[_n-1]

// Now all overlapping records have the same start date, keep the record with the latest stop date
// SORT
sort patid start real_stop
by patid start: keep if _n==_N

// gen follow up stop 6 months variable
by patid: gen switchenddate6m = real_stop[1]
format switchenddate6m %dD/N/CY

** KEEP ONE RECORD PER PATIENT AND MERGE BACK IN
keep patid switch*
duplicates drop

frame change antideps
frlink m:1 patid, frame(followup)
frget *, from(followup)
drop followup
frame drop followup

**** TIDY: ONE REC PER PAT, KEEP VARS OF INTEREST
keep patid firstaddate firstadtype firstaddrug secondaddate secondadtype secondaddrug thirdaddate thirdadtype thirdaddrug ad1active stopad1 lastdosead1 currentdosead1 firstdosead2 switchenddate switchenddate30d switchenddate6m 

label values firstaddrug secondaddrug thirdaddrug drug
label values firstadtype secondadtype thirdadtype type

// sort
sort patid
by patid: keep if _n==1

**** save and exit
saveold data/clean/eligibledrughistory.dta, replace
frames reset
clear
log close adlog
exit


