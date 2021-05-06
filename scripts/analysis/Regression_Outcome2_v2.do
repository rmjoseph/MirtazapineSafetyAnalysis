* Created 2020-04-29 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	Regression_Outcome2_v2
* Creator:	RMJ
* Date:	20200429
* Desc:	Runs main analysis for serious self-harm & suicide
* Version History:
*	Date	Reference	Update
*	20200429	Regression_Outcome3_v2	Create file
*	20200429	Regression_Outcome2_v2	Loop over the different causes of death
*	20200506	Regression_Outcome2_v2	Use do-files to specify vars for models
*	20200506	Regression_Outcome2_v2	Change def suicide to cod_L3 after update
*	20200507	Regression_Outcome2_v2	bug fix: change tag to outcome2
*	20200507	Regression_Outcome2_v2	bug fix: rename `outcome' `savetag' and make new `outcome'
*	20200507	Regression_Outcome2_v2	bug fix: update the imputation model
*	20200508	Regression_Outcome2_v2	bug fix: replace outcome with died_cause
*	20200513	Regression_Outcome2_v2	bug fix: drop macros between analyses
*	20200514	Regression_Outcome1_v2	Recode sex in this script
*	20200521	Regression_Outcome1_v2	Include script summarising followup
*	20201009	Regression_Outcome2_v2	MI: remove line dropping if t<0
*	20201009	Regression_Outcome2_v2	MI: merge in dose vars
*	20201009	Regression_Outcome2_v2	MI: create time interaction var
*	20201009	Regression_Outcome2_v2	MI: add extravars macro to add new vars to MI
*	20201009	Regression_Outcome2_v2	Removed MI section (new dofile)
*	20201014	Regression_Outcome2_v2	Add macro lines for stsplit
*	20201014	Regression_Outcome2_v2	Add split variable to model macro for cancer
*	20201014	Regression_Outcome2_v2	Add id(patid) to stset
*	20201016	Regression_Outcome2_v2	Bug fix cancer competing risk change from stcox
*	20201203	Regression_Outcome2_v2	Update specification of interaction, weighted cancer (both sections)
*	20201203	Regression_Outcome2_v2	Split first and second section so easier to run interactively
*	20201203	Regression_Outcome2_v2	Change how interaction specified (cancer): use new dofile
*************************************

*** Log
capture log close outcome2
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/regression_outcome2_`date'.txt", text append name(outcome2)
*******

frames reset
clear


******** SPECIFY MODEL FOR PROPENSITY SCORE ANALYSIS (ALSO USED FOR MULT IMP)
// Also specifies the imputed variables for the models
include scripts/analysis/model_outcome2.do



********** ANALYSIS
***** Loop over the different causes of death
forval COD = 1/3 {

	******** MAIN ANALYSIS - IPTW-adjusted regression
	********* first time = competing risk
	frames reset
	use data/clean/imputed_outcome2

	*** Specify macros
	include scripts/analysis/model_outcome2.do 
	local outcome died_cause
	local stset "stset time [pw=sw], fail(died_cause==`COD') scale(365.25) id(patid)"
	local regression "stcrreg i.cohort"
	
	if `COD'==1 {
	local options ", compete(died_cause== 2 3 4 5)"
	local savetag circulatory_cr_202010
	}
	if `COD'==2 {
	local options ", compete(died_cause== 1 3 4 5)"
	local savetag cancer_cr_202010_s
	local split "stsplit split, at(2)"
	local splitvar "replace split=(split==2)"
	local regression "stcrreg i.cohort#i.split i.split"	
	}
	if `COD'==3 {
	local options ", compete(died_cause== 1 2 4 5)"
	local savetag respiratory_cr_202010
	}

	
	***** Extract counts info
	local countsrowname "Main analysis cause-specific mort: `COD'"
	gen outcome=(died_cause==`COD')
	include scripts/analysis/TabulateCounts.do
	drop outcome
	*****
	
	*** Run the do-file
	include scripts/analysis/WeightedAnalysis.do


	********* second time = cox 
	frames reset
	use data/clean/imputed_outcome2

	*** Specify macros
	include scripts/analysis/model_outcome2.do 
	local outcome died_cause
	local stset "stset time [pw=sw], fail(died_cause==`COD') scale(365.25) id(patid)"
	local regression "stcox i.cohort"
	local options
	
	if `COD'==1 {
	local savetag circulatory_cox_202010
	}
	if `COD'==2 {
	local savetag cancer_cox_202010_s
	local split "stsplit split, at(2)"
	local splitvar "replace split=(split==2)"
	local regression "stcox i.cohort#i.split i.split"	
	}
	if `COD'==3 {
	local savetag respiratory_cox_202010
	}

	*** Run the do-file
	include scripts/analysis/WeightedAnalysis.do
	
}


forval COD = 1/3 {	
	********* STANDARD (UNWEIGHTED) SURVIVAL ANALYSIS
	********* first time = competing risk
	frames reset
	macro drop savetag options regression imputedvars model outcome
	use data/clean/imputed_outcome2

	*** Specify macros
	include scripts/analysis/model_outcome2.do 

	local stset "stset time, fail(died_cause==`COD') scale(365.25) id(patid)" // the full stset command
	local regression stcrreg // type of regression

	if `COD'==1 {
	local options ", compete(died_cause== 2 3 4 5)"
	local savetag circulatory_cr_202010
	}
	if `COD'==2 {
	local options ", compete(died_cause== 1 3 4 5)"
	local savetag cancer_cr_202010_interaction
	}
	if `COD'==3 {
	local options ", compete(died_cause== 1 2 4 5)"
	local savetag respiratory_cr_202010
	}

	*** Run the do-file
	if `COD'==2 {
		include scripts/analysis/AdjustedSurvivalWithInteraction.do
    	}
	else {
		include scripts/analysis/AdjustedSurvival.do
		}

	
	********* second time = cox
	frames reset
	macro drop savetag options regression stset imputedvars model
	use data/clean/imputed_outcome2

	*** Specify macros
	include scripts/analysis/model_outcome2.do 
	local stset "stset time, fail(died_cause==`COD') scale(365.25) id(patid)" // the full stset command
	local regression stcox // type of regression
	local options  // fill in if using stcrreg
	if `COD'==1 {
	local savetag circulatory_cox_202010
	}
	if `COD'==2 {
	local savetag cancer_cox_202010_interaction
	}
	if `COD'==3 {
	local savetag respiratory_cox_202010
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
capture log close outcome2
frames reset
exit
