* Created 2020-02-10 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	masterfile_analysis
* Creator:	RMJ
* Date:	20200210
* Desc:	Sets working directory and runs analysis files
* Version History:
*	Date	Reference	Update
*	20200210	masterfile_preparation	Create file
*	20200427	masterfile_analysis	Update with current files
*	20201009	masterfile_analysis	Add multiple imputation as separate scripts
*	20201209	masterfile_analysis	Use ResultsSensitivityTable_v2
*	20201209	masterfile_analysis	Add self harm sensitivity analyses & baseline charas
*	20210224	masterfile_analysis	Add the dose scripts
*	20210224	masterfile_analysis	Separate out the self-harm scripts
*	20210629	masterfile_analysis	Add additional self harm scripts
*	20211126	masterfile_analysis	Add sensitivity analysis with complete cases scripts
*	20211201	masterfile_analysis	Add extra SH sensitivity analyses
*************************************

** Working directory must have the following structure:
*	data/clean
*	data/codelists
*	data/raw/stata
*	data/raw/*FURTHER DIRECTORIES AS REQUIRED*
*	scripts/preparation
*	scripts/analysis
*	scripts/quicktools


clear
set more off
frames reset

** Set working directory
capture cd "R:/QResearch/CPRD/mirtazapine"
capture cd "R:/Research/QResearch/CPRD/mirtazapine"

pwd

** LOG
capture log close analysislog
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/master_analysis_`date'.txt", text append name(analysislog)

** SCRIPTS
/* model checking scripts
** FIRST SPEC OF PS, USING MEAN-FILLED MISSING VALUES
scripts/analysis/PropScore_mortality1.do
scripts/analysis/PropScore_SH1.do
scripts/analysis/PropScore_allvars1.do
** TESTING THE PROPORTIONAL HAZARDS ASSUMPTION WITH ABOVE MODELS
scripts/analysis/PH_mortality.do
scripts/analysis/PH_SH.do
scripts/analysis/PH_SH30.do
** RE-TESTING PS AFTER MI
scripts/analysis/PropScore_mortality2.do
scripts/analysis/PropScore_SH2.do
scripts/analysis/PropScore_allvars2.do
*/

// NOTE - the following scripts are needed for the
// regression & sensitivity analyses to run:
*scripts/analysis/MultipleImputation.do
*scripts/analysis/WeightedAnalysis.do
*scripts/analysis/AdjustedSurvival.do
*scripts/analysis/AdjustedSurvivalWithInteraction.do
*scripts/analysis/model_outcome1.do
*scripts/analysis/model_outcome2.do
*scripts/analysis/model_outcome3.do
*scripts/analysis/TabulateCounts.do
*scripts/analysis/sh30_TabulateCounts.do // separate file for self-harm analysis with enddate30



*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
** MORTALITY
*** Descriptives
do scripts/analysis/countingPatients_v2.do	//	counts of people in the cohorts
do scripts/analysis/BaselineCharacteristics_v2.do	//	Tidier baseline characteristics file (note added "_v2" 22 feb 2021)
do scripts/analysis/SummariseDeaths.do // outputs frequent causes of death
do scripts/analysis/ReasonStopFollowup.do	// Tabulation of why pats left cohort
do scripts/analysis/FirstSSRINextDrug.do	// Tabulation of first SSRI and second antidep
do scripts/analysis/StandardisedRates_v2.do // age-sex standardised rates
do scripts/analysis/StandardisedRates_v3.do // age-sex standardised rates (with inverted attrib risks)

*** MULTIPLE IMPUTATION
do scripts/analysis/MI_outcome1.do // all-cause mort
do scripts/analysis/MI_outcome2.do // cause-specific mort
do scripts/analysis/MI_broadelig.do // for sensitivity broadelig, uses keep4==1
do scripts/analysis/MI_allvars.do // model with all variables in

*** REGRESSION SCRIPTS
do scripts/analysis/Regression_Outcome1_v2.do // all-cause mortality
do scripts/analysis/Regression_Outcome2_v2.do // cause-specific mortality

*** DOSE
do scripts/analysis/DoseAdjustedIPTWRegression_AllCause.do // dose dataset, iptw, all-cause mort
do scripts/analysis/DoseAdjustedAdjRegression_AllCause.do // dose dataset, adjusted reg, all-cause mort


*** SENSITIVITY ANALYSES
do scripts/analysis/StandardisedRates_v2_sensitivity.do // 3 sensitivity analyses with different entry crit
do scripts/analysis/StandardisedRates_v3_sensitivity.do // inverted attrib risks
do scripts/analysis/StandardisedRates_v3_timesplit.do // all-cause and cancer by time period
do scripts/analysis/sensitivity_cancer.do	// NOTE: includes full model spec
do scripts/analysis/sensitivity_noselfharm.do	// NOTE: includes full model spec
do scripts/analysis/sensitivity_ssri.do	// NOTE: includes full model spec (start citalopram)
do scripts/analysis/sensitivity_maxfollowup.do
do scripts/analysis/sensitivity_stopdate.do
do scripts/analysis/sensitivity_agebands.do
do scripts/analysis/sensitivity_broadeligibility_allcause.do
do scripts/analysis/sensitivity_nosplit_allcausemort_cancer.do // no time interaction, all cause mort & cancer
do scripts/analysis/sensitivity_commonsupport.do // restricts to within common support (all cause)

*** repeating analyses using allvars models/imputed dataset (no stcrreg models)
do scripts/analysis/Regression_allvars_mortality.do	
do scripts/analysis/Regression_allvars_causespecmort.do



*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
** SELF-HARM
*** Descriptives
do scripts/analysis/cohortsummary_selfharm.do	//	info about numbers, outcomes, follow-up
do scripts/analysis/BaselineCharacteristics_v2_selfharm.do	//	Baseline charas for selfharm dataset

*** MULTIPLE IMPUTATION
do scripts/analysis/MI_outcome3.do // serious self-harm/suicide

*** REGRESSION SCRIPTS
do scripts/analysis/Regression_Outcome3_v2.do // serious self-harm/suicide

*** DOSE
do scripts/analysis/DoseAdjustedIPTWRegression_SelfHarm.do // dose dataset, iptw, self-harm
do scripts/analysis/DoseAdjustedAdjRegression_SelfHarm.do // dose dataset, adjusted reg, self-harm

*** SENSITIVITY ANALYSES
do scripts/analysis/sensitivity_ALLselfharm.do // all the self-harm sensitivity regression analyses

**** repeating analyses using allvars models/imputed dataset (no stcrreg models)
do scripts/analysis/Regression_allvars_selfharm.do



*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
** Repeating self-harm with 30 day risk carry-over (instead of 6m)
*** Descriptives
do scripts/analysis/sh30_StandardisedRates_v2.do // age-sex standardised rates
do scripts/analysis/sh30_StandardisedRates_v3.do // above with inverted attrib risks
do scripts/analysis/sh30_cohortsummary_selfharm.do	//	info about numbers, outcomes, follow-up
do scripts/analysis/sh30_BaselineCharacteristics_v2_selfharm.do	//	Baseline charas for selfharm dataset

*** Multiple imp
do scripts/analysis/sh30_MI_outcome3.do // serious self-harm/suicide
do scripts/analysis/sh30_MI_allvars.do // model with all variables in

*** REGRESSION SCRIPTS
do scripts/analysis/sh30_Regression_Outcome3_v2.do // serious self-harm/suicide
do scripts/analysis/sh30_survivalcurves.do	// draws a survival curve

*** DOSE
do scripts/analysis/sh30_DoseAdjustedIPTWRegression_SelfHarm.do // dose dataset, iptw, self-harm
do scripts/analysis/sh30_DoseAdjustedAdjRegression_SelfHarm.do // dose dataset, adjusted reg, self-harm

*** Sensitivity analyses
do scripts/analysis/sh30_StandardisedRates_v2_sensitivity.do // 3 sensitivity analyses with different entry crit
do scripts/analysis/sh30_StandardisedRates_v3_sensitivity.do // above with inverted attrib risks
do scripts/analysis/sh30_sensitivity_ALLselfharm.do // all the self-harm sensitivity regression analyses
do scripts/analysis/sh30_Regression_allvars_selfharm.do

*** Additional analyses
do scripts/analysis/sh30_cohortcount.do // person counts as applying criteria
do scripts/analysis/sh30_charasbyinclusion.do // summarises bl charas according to inclusion criteria
do scripts/analysis/sh30_Regression_SSRIasref_v2.do // main analysis but with SSRI as base group
do scripts/analysis/sh30_powercalc.do // power calculations



*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
** REPORTING:
do scripts/analysis/ResultsSensitivityTable_v2.do


** 2021-11-26 Complete case analysis (mortality)
do scripts/analysis/Sensit_CompleteCaseAnalyses.do
do scripts/analysis/Sensit_CompleteCaseAnalyses_cod.do
do scripts/analysis/CompCaseOutput.do

** 2021-12-01 Additional sensitivity self-harm
do scripts/analysis/sh30_Sensit_BroadElig.do
do scripts/analysis/sh30_Sensit_CompleteCaseAnalysis.do

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
** END
capture log close analysislog
frames reset
exit

