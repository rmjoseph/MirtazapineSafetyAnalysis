* Created 2021-03-15 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sh30_survivalcurves
* Creator:	RMJ
* Date:	20210315
* Desc:	Draws survival curve for self-harm analysis (30 day version)
* Version History:
*	Date	Reference	Update
*	20210315	New file	Create file
*************************************

ssc install grstyle, replace
ssc install palettes, replace

frames reset
clear

use data/clean/imputed_sh30_outcome3

mi stset time, fail(outcome==1) scale(365.25)

set scheme s2mono 
grstyle init
grstyle set plain, horizontal

sts graph, by(cohort) ylabel(.95(.05)1) ytitle("Survival probability") xtitle("Time") tmax(5) name(survival_unadj, replace) title("")


*******
frames reset
exit
