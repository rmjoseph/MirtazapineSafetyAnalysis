* Created 2021-03-12 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sh30_TabulateCounts
* Creator:	RMJ
* Date:	20210312
* Desc:	Utility to summarise overall followup for individual analyses (sep file for sh30 analysis)
* Version History:
*	Date	Reference	Update
*	20210312	TabulateCounts	Create file
*************************************

** Remember original frame
frame pwf
local origframe `r(currentframe)'

** Change to new frame, remove mi set, keep patients and vars of interest
frame put *, into(NEW)
frame change NEW
mi extract 0, clear
keep if time>0
keep time outcome

** Create scalars for number of people, number of events, total followup
count if time>0
scalar def sc_obs = string(`r(N)', "%9.0fc")
count if outcome==1 & time>0
scalar def sc_events = string(`r(N)')
sum time if time>0, d
scalar def sc_time = string(`r(sum)'/365.25, "%9.0fc")

** Create dataset that only contains this info
clear
set obs 1
gen analysis = "`countsrowname'"
gen obs = sc_obs
gen events = sc_events
gen totfup = sc_time

** Multiple records may be generated if analysis is re-run: create a time stamp
*	so that the most recent record can be identified and retained
gen temp = c(current_date) + " " + c(current_time)
gen datetime = clock(temp, "DMY hms")
format datetime %tc
drop temp

** Add the new record to the output dataset, keep most recent, and save
capture append using data/clean/sh30_sensitivitycounts.dta
sort analysis datetime
by analysis: keep if _n==_N
save data/clean/sh30_sensitivitycounts.dta, replace

** Go back to original frame and drop the new one
frame change `origframe'
frame drop NEW

*****
exit
