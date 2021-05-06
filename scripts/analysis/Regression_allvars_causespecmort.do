* Created 2020-10-21 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	Regression_allvars_causespecmort
* Creator:	RMJ
* Date:	20201021
* Desc:	Runs main analysis for cause-specific mortality using all vars
* Version History:
*	Date	Reference	Update
*	20201021	Regression_allvars_mortality	Create file
*	20201022	Regression_allvars_causespecmort	Bug: add blank macros to stop them carrying over
*	20201207	Regression_allvars_causespecmort	Update specn of interactions, cancer
*************************************

*** Log
capture log close allvarscod
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/regression_allvarscod_`date'.txt", text append name(allvarscod)
*******

frames reset
clear

******** SPECIFY MODEL FOR PROPENSITY SCORE ANALYSIS 
// Also specifies the imputed variables for the models
include scripts/analysis/model_allvars.do


********** ANALYSIS
***** Loop over the different causes of death
forval COD = 1/3 {

	******** MAIN ANALYSIS - IPTW-adjusted regression
	********* first time = competing risk
	** REMOVED **
	
	********* second time = cox 
	frames reset
	use data/clean/imputed_allvars

	*** Specify macros
	include scripts/analysis/model_allvars.do 
	local outcome died_cause
	local stset "stset time [pw=sw], fail(died_cause==`COD') scale(365.25) id(patid)"
	local regression "stcox i.cohort"
	local options
	local savetag
	local split
	local splitvar
		
	if `COD'==1 {
	local savetag allvars_circulatory_cox
	}
	if `COD'==2 {
	local savetag allvars_cancer_cox_interaction
	local split "stsplit split, at(2)"
	local splitvar "replace split=(split==2)"
	local regression "stcox i.cohort#i.split i.split"	// bug fix: change from stcrreg
	}
	if `COD'==3 {
	local savetag allvars_respiratory_cox
	}

	***** Extract counts info
	local countsrowname "Main analysis ALL VARS cause-specific mort: `COD'"
	drop outcome
	gen outcome=(died_cause==`COD')
	include scripts/analysis/TabulateCounts.do
	drop outcome
	*****	
	
	*** Run the do-file
	include scripts/analysis/WeightedAnalysis.do
}	
	
forval COD = 1/3 {
	********* STANDARD (UNWEIGHTED) SURVIVAL ANALYSIS
	********* Cox
	frames reset
	macro drop savetag options regression stset imputedvars model
	use data/clean/imputed_allvars

	*** Specify macros
	include scripts/analysis/model_allvars.do 
	local stset "stset time, fail(died_cause==`COD') scale(365.25) id(patid)" // the full stset command
	local regression stcox // type of regression
	local options  // fill in if using stcrreg
	local savetag
	local split
	local splitvar
	local addsplitvar
	
	if `COD'==1 {
	local savetag allvars_circulatory_cox
	}
	if `COD'==2 {
	local savetag allvars_cancer_cox_interaction
	}
	if `COD'==3 {
	local savetag allvars_respiratory_cox
	}

	*** Run the do-file
	if `COD'==2 {
		include scripts/analysis/AdjustedSurvivalWithInteraction.do    
		}
	else {
		include scripts/analysis/AdjustedSurvival.do
		}

	}


*********** END
log close allvarscod
frames reset
exit
