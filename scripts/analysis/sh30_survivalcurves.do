* Created 2021-03-15 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sh30_survivalcurves
* Creator:	RMJ
* Date:	20210315
* Desc:	Draws survival curve for self-harm analysis (30 day version)
* Version History:
*	Date	Reference	Update
*	20210315	New file	Create file
*	20210520	sh30_survivalcurves	Update plot options (range, yaxis label, line width)
*	20210622	sh30_survivalcurves	Add risk table and format legend
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

sts graph, by(cohort) plotopts(lwidth(thin)) tmax(5) ///
	ylabel(.5(.05)1) ytitle("Serious self-harm" "Event-free survival probability") ///
	xtitle("Time, years") ///
	name(survival_unadj, replace) ///
	title("") ///
	legend(label(1 "Mirtazapine") label(2 "SSRI") label(3 "Amitriptyline") label(4 "Venlafaxine") region( lstyle(none)) ) ///
	risktable(0/5, order(1 "Mirtazapine" 2 "SSRI" 3 "Amitriptyline" 4 "Venlafaxine") ///
			rowtitle(, justification(left)) ///
			format(%9.0gc) size(small) title(,size(small)) ///
			) 

graph export outputs/SH30_KMplot_unadj.pdf, name(survival_unadj) replace

*******
frames reset
exit
