** CREATED 2020-01-21 by RMJ at the University of Nottingham
*************************************
* Name:	define_alcoholuse
* Creator:	RMJ
* Date:	20200121
* Desc:	Finds most recent alcohol status prior to index
* Requires: Stata 16 for frames function; index date
* Version History:
*	Date	Reference	Update
*	20200121	define_alcoholuse	Create file
*************************************

/* DEFINITION: Most recent status prior to index date. 
*  CLEANING APPLIED:
*		- If multiple records per day, pick one with highest alcohol use status
*		- Make non- former if there was a previous record of drinking
*/

set more off
frames reset
clear

*** LOAD AND TIDY ALCOHOL RECORDS
frame create alcohol
frame change alcohol
use data/raw/stata/alcoholrecords.dta

** More than one record per day: pick highest code
bys patid eventdate (alcoholintake): keep if _n==_N

** First record of drinking anything
bys patid (eventdate): gen drinkrec=(alcoholin>1)
bys patid drinkrec (eventdate): gen firstdrink=eventdate[1] if drinkrec==1
format firstdrink %dD/N/CY
bys patid (firstdrink): replace firstdrink=firstdrink[1]

** Replace nondrinkers (1) with former drinkers(2) if ever had a prior drinking rec
sort patid eventdate
replace alcoholintake=2 if alcoholintake==1 & eventdate>=firstdrink

** Tidy
drop medcode drinkrec firstdrink



*** MERGE WITH INDEX DATE
frame create index
frame change index
use patid secondaddate using data/clean/finalcohort.dta
rename secondaddate indexdate

frame change alcohol
frlink m:1 patid, frame(index)
keep if index<.
frget *, from(index)
drop index



*** KEEP RECORDS ON OR BEFORE INDEX
keep if indexdate<.
keep if eventdate<=indexdate

*** KEEP MOST RECENT RECORD
bys patid (eventdate): keep if _n==_N


*** TIDY AND SAVE
keep patid alcoholintake
*duplicates report
saveold data/clean/baselinealcohol.dta, replace

frames reset
clear
exit

