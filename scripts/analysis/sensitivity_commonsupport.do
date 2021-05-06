* Created 2020-10-22 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	sensitivity_commonsupport
* Creator:	RMJ
* Date:	20201022
* Desc:	Restricts to patients with probabilities within common support for each cohort
* Version History:
*	Date	Reference	Update
*	20201022	Regression_Outcome1_v2	Create file
*	20201209	sensitivity_commonsupport	Update specification of interaction
*************************************

*** Log
capture log close comsup
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/regression_outcome1_commonsup_`date'.txt", text append name(comsup)
*******

frames reset
clear


******** SPECIFY MODEL FOR PROPENSITY SCORE ANALYSIS (ALSO USED FOR MULT IMP)
// Also specifies the imputed variables for the models
include scripts/analysis/model_outcome1.do

******** MAIN ANALYSIS - IPTW-adjusted regression
frames reset
macro drop _all
use data/clean/imputed_outcome1

*** Specify macros
include scripts/analysis/model_outcome1.do 
local stset "stset time [pw=sw], fail(died) scale(365.25) id(patid)"
local split "stsplit split, at(2)"
local splitvar "replace split=(split==2)"
local regression "stcox i.cohort#i.split i.split"
local outcome died
local savetag allcausemort_common_s
local commonsupport 1 	// 1 if want to restrict to common support

*** Run the do-file
include scripts/analysis/WeightedAnalysis.do

***** Extract counts info
frame change default
clear
use data/clean/imputed_outcome1

frlink 1:1 patid, frame(patsincommonsup)
keep if patsincommonsup<.

local countsrowname "Restrict to common support"
gen outcome=died
include scripts/analysis/TabulateCounts.do
drop outcome
*****

*********** END
log close comsup
frames reset
exit
