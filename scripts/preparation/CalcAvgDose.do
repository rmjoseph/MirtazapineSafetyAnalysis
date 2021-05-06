** CREATED 08-10-2020 by RMJ at the University of Nottingham
*************************************
* Name: TimeVaryingAntidepExposure
* Creator:	RMJ
* Date:	20201008
* Desc:	Stata program calculating range of dose vars for multiple-row drug exposure
* Requires: Stata 16 for frames functionality
* Version History:
*	Date	Reference	Update
*	20201008	TimeVaryingAntidepExposure	Create file
*************************************

capture program drop CALCDOSE
program define CALCDOSE

	syntax, ORIGFrame(string) ENTER(varlist max=1) EXIT(varlist max=1) DRUG(varlist max=1)

	** Put variables into new frame
    frame change `origframe'
	capture frame drop hadfdbfbd	// random frame name
	frame put patid start stop `exit' `enter' `drug', into(hadfdbfbd)
	frame change hadfdbfbd
	
	** Drop variables outside specified window and edit the start stop dates
	** for first and last record if needed
	drop if stop<=`enter'
	drop if start>=`exit'
	*replace start=`enter' if start<`enter' // shouldn't be any if index; shouldn't be if eligstart (pats should have been excluded)
	replace stop=`exit' if stop>`exit'
	
	** Want to be able to exclude time when not prescribed - create indicator
	gen nozero = (`drug'>0) 
		
	** Work out number of days for each record, setting to 0 if no drug
	gen rowdays = round(stop-start)
	gen rowdaysnozero = rowdays
	replace rowdaysnozero = 0 if nozero==0
		
	** Work out total dose per record (dose * number of days)
	gen rowdose = `drug'*rowdays
	gen rowdosenozero = `drug'*rowdaysnozero
	
	** Running total of number of days
	bys patid (start): gen runningtotdays = sum(rowdays)
	bys patid (start): gen runningtotdaysnozero = sum(rowdaysnozero)
	
	** Running total of dose
	bys patid (start): gen runDose_`drug' = sum(rowdose)
	bys patid: gen runDoseOn_`drug' = sum(rowdosenozero)	
	
	** Total number of days
	bys patid: egen alldays = sum(rowdays)
	bys patid: egen alldaysnozero = sum(rowdaysnozero)
	
	** Total dose
	bys patid (start): egen totDose_`drug' = sum(rowdose)	
	
	** Running mean: running dose divided by running days
	bys patid (start): gen runMean_`drug' = sum(rowdose)
	replace runMean_ = runMean_ / runningtotdays
		// and ignoring periods of no exposure
	bys patid (start): gen runMeanOn_`drug' = sum(rowdosenozero)
	replace runMeanOn_ = runMeanOn_ / runningtotdaysnozero
	replace runMeanOn_ = 0 if runMeanOn_==.

	** Overall mean:
	bys patid: egen totMean_`drug' = sum(rowdose)
	replace totMean_ = totMean_/alldays
		// and ignoring periods of no exposure
	bys patid: egen totMeanOn_`drug' = sum(rowdosenozero)
	replace totMeanOn_ = totMeanOn_/alldaysnozero
	replace totMeanOn_ = 0 if totMeanOn_==.
	
	** Overall median: 
	**	sort by drug dose then work out new running count of days
	**	work out the number of days that is half of the total follow-up
	**	median is the dose at this number of days (when sorted by dose)
	gen meddays = alldays/2
	bys patid (`drug'): gen runningdaysmed = sum(rowdays)
	bys patid (`drug'): gen medrec = 1 if runningdaysmed>meddays
	replace medrec = medrec*`drug'
	bys patid (start): egen totMed_`drug' = min(medrec)
		// ignore periods of no exposure
	gen meddaysnozero = alldaysnozero/2
	bys patid (`drug'): gen runningdaysmednozero = sum(rowdaysnozero)
	bys patid (`drug'): gen medrecnozero = 1 if runningdaysmednozero>meddaysnozero 
	replace medrecnozero = medrecnozero*`drug'
	bys patid (start): egen totMedOn_`drug' = min(medrecnozero)
	replace totMedOn_=0 if totMedOn_==.

	** Tidy
	keep patid start totDose_ runMean* totMean* totMed* runDose*

	***
	frame change `origframe'
	frlink 1:1 patid start, frame(hadfdbfbd)
	count if hadfdbfbd<.
	frget *, from(hadfdbfbd)
	drop hadfdbfbd
	frame drop hadfdbfbd

end
