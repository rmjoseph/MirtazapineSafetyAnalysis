* Created 2021-06-24 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sh30_powercalc
* Creator:	RMJ
* Date:	20210624
* Desc:	Generating values for and running post-hoc power calculations
* Version History:
*	Date	Reference	Update
*	20210624	new file	create file
*************************************

frames reset
macro drop _all
use data/clean/imputed_sh30_outcome3

mi extract 0

gen mvs = 1 if cohort==1
replace mvs = 0 if cohort==2

gen mva = 1 if cohort==1
replace mva = 0 if cohort==3

gen mvv = 1 if cohort==1
replace mvv = 0 if cohort==4

include scripts/analysis/model_outcome3.do
logistic mvs ageindex i.sex
logistic mvs `model'
logistic mva ageindex i.sex
logistic mva `model'
logistic mvv ageindex i.sex
logistic mvv `model'


stset time, fail(outcome==1) scale(365.25)
stcox i.cohort
stcox i.cohort ageindex i.sex
stcox i.cohort `model'


*** Log
capture log close power
log using "outputs/sh30_powercalculations.txt", text append name(power)
*******

** power calcs
*** power for the estimated hrs (unadj / agesex / adjusted)
// SSRI 
 power cox, n(19205) sd(0.215594) eventprob(0.010414) hr(0.7259858)
 power cox, n(19205) sd(0.215594) eventprob(0.010414) r2(0.0236) hr(0.6586298)
 power cox, n(19205) sd(0.215594) eventprob(0.010414) r2(0.0501) hr(0.8915671)

// amtriptypine
 power cox, n(8578) sd(0.370702) eventprob(0.007578) hr(0.1960266)
 power cox, n(8578) sd(0.370702) eventprob(0.007578) r2(0.0263) hr(0.23032)
 power cox, n(8578) sd(0.370702) eventprob(0.007578) r2(0.0763) hr(0.3025597)

// venlafaxine
 power cox, n(6287) sd(0.372373) eventprob(0.013361) hr(1.168716)
 power cox, n(6287) sd(0.372373) eventprob(0.013361) r2(0.0124) hr(1.061897)
 power cox, n(6287) sd(0.372373) eventprob(0.013361) r2(0.0345) hr(1.19774)


*** power to detect hr of 1.2
// SSRI
power cox, n(19205) sd(0.215594) eventprob(0.010414) hr(1.2)
power cox, n(19205) sd(0.215594) eventprob(0.010414) r2(0.0501) hr(1.2)
// amitriptyline
power cox, n(8578) sd(0.370702) eventprob(0.007578) hr(1.2)
power cox, n(8578) sd(0.370702) eventprob(0.007578) r2(0.0763) hr(1.2)
// venlafaxine
power cox, n(6287) sd(0.372373) eventprob(0.013361) hr(1.2)
power cox, n(6287) sd(0.372373) eventprob(0.013361) r2(0.0345) hr(1.2)

*** minimum hr for power 0.8
// ssri
power cox, n(19205) sd(0.215594) eventprob(0.010414) r2(0.0501) power(0.8) effect(hr) direction(upper)
power cox, n(19205) sd(0.215594) eventprob(0.010414) r2(0.0501) power(0.8) effect(hr) direction(lower)
// amitriptyline
power cox, n(8578) sd(0.370702) eventprob(0.007578) r2(0.0763) power(0.8) effect(hr) direction(upper)
power cox, n(8578) sd(0.370702) eventprob(0.007578) r2(0.0763) power(0.8) effect(hr) direction(lower)
// venlafaxine
power cox, n(6287) sd(0.372373) eventprob(0.013361) r2(0.0345) power(0.8) effect(hr) direction(upper)
power cox, n(6287) sd(0.372373) eventprob(0.013361) r2(0.0345) power(0.8) effect(hr) direction(lower)

*** Log close
log close power
*******
frames reset