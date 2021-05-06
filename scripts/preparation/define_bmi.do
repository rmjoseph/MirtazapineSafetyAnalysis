** CREATED 2020-01-27 by RMJ at the University of Nottingham
*************************************
* Name:	define_bmi.do
* Creator:	RMJ
* Date:	20200127
* Desc:	Defines BMI using additional data
* Requires: Stata 16 for frames function; index date
* Version History:
*	Date	Reference	Update
*	20200127	define_bmi	Create file
*************************************

/* DEFINITION - MOST RECENT BMI ON OR BEFORE BASELINE
* Calculate using weight and height records
* Data cleaning steps:
*	- drop any records prior to age 18
*	- drop any height and weight records smaller than normal baby measurements and larger than largest known measurement (2.5-635kg and 0.45-2.75m)
*	- weight range 35 to 400
*	- height range 1.2 to 2.72
*	- drop patients with more than 10cm difference in their min and max height measurements
*	- use median height as a measure of patient height
*	- bmi lower limit 11
*/


set more off
frames reset
clear


*** LOAD ADDITIONAL FILE, KEEP ENTTYPES FOR HEIGHT AND WEIGHT
frame change default
use data/raw/stata/additional_extract
keep if enttype==13 | enttype==14
sort patid eventdate
drop data2 data4


*** LOAD COHORT FILE TO GET DATE OF BIRTH; merge back into default
frame create patient
frame change patient
use patid dob using data/clean/combinedpatinfo.dta

frame change default
frlink m:1 patid, frame(patient)
frget *, from(patient)
keep if patient < .
drop patient
frame drop patient

** Drop records prior to age 18
keep if year(eventdate) - year(dob) >= 18
count

*** SEND HEIGHT AND WEIGHT DATA INTO THEIR OWN FRAMES
frame put if enttype==13, into(weight) // put weight data in new frame
frame put if enttype==14, into(height) // put height data in new frame



*** IN NEW FRAME, CLEAN WEIGHT
frame change weight
keep patid data1 eventdate
rename data1 weightrec

drop if weightrec<=0 // drop if 0 or negative (assume error)
sum weightrec,d
di r(mean) + 3*r(sd)
di r(mean) - 3*r(sd)

drop if weightrec > 635 // drop if weight > heaviest person
drop if weightrec < 2.5	// normal baby weight

sum weightrec,d
di r(mean) + 3*r(sd)
di r(mean) - 3*r(sd)
*drop if weightrec > r(mean) + 3*r(sd) // drop if weight is more than mean plus 3 sd
*drop if weightrec < r(mean) - 3*r(sd) // drop if weight is more than mean minus 3 sd 

*sum weightrec,d

**  Reasons for low weight:
**	- stone entered instead of kg (maybe reasonable for range ~6-30?)
**	- ?

* Inspecting histogram, approaches 0 at approx 29/30. BMI charts go down to 40kg.
* Possible overlap with stone up to 30-40 kg.
* Setting at 30 would be more liberal, but may contain more error.
* At other end, bariatric hospital beds go up to 400kg

drop if weight < 35
drop if weight > 400



*** IN NEW FRAME, CLEAN HEIGHT
** NOTE: BMI tailored to 'normal' range of weights and heights. Reasonable to drop low heights. Use 4 foot (1.2m).
frame change height

keep patid eventdate data1
rename data1 heightrec

drop if heightrec<=0 // drop if 0 or negative (assume error)
sum heightrec,d
di r(mean) + 3*r(sd)
di r(mean) - 3*r(sd)

drop if heightrec > 2.72 // drop if height > tallest person ever
drop if heightrec < 0.45	// normal baby height

sum heightrec,d
di r(mean) + 3*r(sd)
di r(mean) - 3*r(sd)


** Reasons for low height:
** inputting as feet, e.g. 5'1'' as 0.51? so up to say 0.7 would be this error?
** Extreme short stature considered to be 3 foot, or 0.91m
** 2.5 foot just over 0.75, would be between both these considerations
** Extreme tall values remaining, unclear why these may be
drop if height < 1.2


*** Calculate average height per patient
bys patid: egen maxheight = max(heightrec)
bys patid: egen minheight = min(heightrec)
bys patid: gen heightdif = maxheight - minheight

bys patid: egen medianheight = median(heightrec)
bys patid: egen meanheight = mean(heightrec)

bys patid (eventdate): keep if _n==_N

drop if heightdif >= 0.10 // drop if change in height more than 10cm
keep patid medianheight // use median height as measure




*** COMBINE WEIGHT AND HEIGHT, AND CALCULATE BMI
frame change weight
frlink m:1 patid, frame(height)
frget *,from(height)

keep if height<.
drop height

gen bmi = weight / (medianheight*medianheight)


sum bmi,d
di r(mean) + 3*r(sd)
di r(mean) - 3*r(sd)

*** VERY LOW BMI is now almost entirely due to low weight tall height. 11 is reasonable cut-off.
drop if bmi < 11

*** Very high BMI is related to heigh weight rather than extremely small height. No change.





*** NOW KEEP MOST RECENT UP TO OR INCLUDING THE INDEX DATE
frame create index
frame change index
use patid secondaddate using data/clean/finalcohort.dta
rename secondaddate indexdate

frame change weight
frlink m:1 patid, frame(index)
keep if index<.
frget *, from(index)
drop index

count
keep if eventdate <= indexdate
count

bys patid (eventdate): keep if _n==_N
count


*** BMI category
gen bmicat = 1 if bmi <18.5
replace bmicat = 2 if bmi>=18.5 & bmi<25
replace bmicat = 3 if bmi>=25 & bmi<30
replace bmicat = 4 if bmi>=30 & bmi<35
replace bmicat = 5 if bmi>=35 & bmi<40
replace bmicat = 6 if bmi>=40

label define bmi	1 "underweight" ///
					2 "healthy" ///
					3 "overweight" ///
					4 "obese class 1" ///
					5 "obese class 2" ///
					6 "obese class 3+"
					
label values bmicat bmi

*** TIDY AND SAVE
keep patid bmi bmicat
*duplicates report patid
saveold data/clean/baselinebmi.dta, replace

frames reset
clear
exit






