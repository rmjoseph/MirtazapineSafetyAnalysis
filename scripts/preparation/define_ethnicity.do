** CREATED 2020-01-27 by RMJ at the University of Nottingham
*************************************
* Name:	define_ethnicity
* Creator:	RMJ
* Date:	20200127
* Desc:	Finds most recent ethnicity recorded prior to index
* Requires: Stata 16 for frames function; index date
* Version History:
*	Date	Reference	Update
*	20200121	define_alcoholuse	Create file
*	20200228	define_ethnicity	Add HES ethnicity data
*************************************

/* DEFINITION: Most recent ethnicity record prior to index date. 
*  DATA CLEANING APPLIED:
*		- if >1 category on a single day, drop records for that day
*/

set more off
frames reset
clear

*** LOAD AND TIDY ETHNICITY RECORDS FROM CPRD
frame create ethnicity
frame change ethnicity
use data/raw/stata/ethnicityrecords.dta

*** DROP TRUE DUPLICATES
drop medcode
bys patid eventdate ethnicity: keep if _n==1

*** MORE THAN ONE RECORD PER DAY: drop that day
bys patid eventdate: keep if _N==1



*** LOAD AND TIDY ETHNICITY RECORDS FROM HES
frame create hes
frame change hes

clear
import delim using data/raw/19_241_Delivery/GOLD_linked/hes_episodes_19_241.txt, stringc(3)
codebook patid

// convert epistart into date var
replace epistart = admidate if epistart==""
gen date = date(epistart,"DMY")
format date %dD/N/CY
drop if date==.
codebook patid

// any duplicates ethnicity within episode?
duplicates report patid epikey ethnos // no

// remove duplicates on episode date (more than one episode on one date - sort by episode order)
sort patid date eorder
bys patid date (eorder): keep if _n==_N
codebook patid

// Make ethnos categorical variable
encode ethnos, gen(hes_eth)

// keep subset of variables
keep patid date hes_eth




*** MERGE WITH INDEX DATE
frame create index
frame change index
use patid secondaddate using data/clean/finalcohort.dta
rename secondaddate indexdate

** CPRD:
** link
frame change ethnicity
frlink m:1 patid, frame(index)
keep if index<.
frget *, from(index)
drop index
** keep records on or before index
keep if indexdate<.
keep if eventdate<=indexdate
** keep most recent
bys patid (eventdate): keep if _n==_N

rename ethnicity cprd_eth


* HES:
** link
frame change hes
frlink m:1 patid, frame(index)
keep if index<.
frget *, from(index)
drop index
** keep records on or before index
keep if indexdate<.
keep if date<=indexdate
** keep most recent
bys patid (date): keep if _n==_N



*** Combine all
frame change index

frlink 1:1 patid, frame(ethnicity)
frget cprd_eth, from(ethnicity)
drop ethnicity

frlink 1:1 patid, frame(hes)
frget hes_eth, from(hes)
drop hes

*** Recode the hes ethnicity
label list

gen hes2 = hes_eth
recode hes2 (3=2) (4=2) (5=4) (6=1) (7=3) (8=1) (9=4) (10=1) (11=.) (12=5)
label val hes2 ethnicity


*** Replace missing CPRD ethnicity with HES ethnicity
*tab cprd_eth hes2
gen ethnicity = cprd_eth
replace ethnicity = hes2 if ethnicity==.
count if ethnicity==.

*** TIDY AND SAVE
keep patid ethnicity cprd_eth hes2
rename hes2 hes_eth
*duplicates report patid
saveold data/clean/baselineethnicity.dta, replace

frames reset
clear
exit

