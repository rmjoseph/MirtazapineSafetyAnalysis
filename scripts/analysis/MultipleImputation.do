* Created 2020-04-17 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	MultipleImputation
* Creator:	RMJ
* Date:	20200417
* Desc:	Runs multiple imp with rules specified elsewhere
* Version History:
*	Date	Reference	Update
*	20200417	Regression_Outcome1	Create file
*	20200428	MultipleImputation	Add some of the generic steps
*	20200428	MultipleImputation	Change global $model to local
*	20200429	MultipleImputation	Keep some of the ad desriptor variables
*	20200430	MultipleImputation	Keep some of the time variables
*	20200514	MultipleImputation	Drop section recoding sex
*	20201009	MultipleImputation	Add local extravars to include vars not in PS
*************************************


********** MULTIPLE IMPUTATION
** Include all variables that go into the propensity score plus
*  variables related to follow-up time and outcome, and any
*  further covariates added to the final regression model.

** Keep key variables
drop secondaddate inc_* eligible firstaddate firstadtype  ///
 stopad1 lastdosead1 currentdosead1 ///
 firstdosead2 lastdepdate depression ///
 depress_12 lastdepsympt depressionsympt icd10_cod keep* cod_*
drop bipolar schizophrenia 
order enddate* endreason*, first


** generate variables to fill in
foreach var of varlist townsend ethnicity bmi smokestat alcoholintake  {
	gen `var'_i = `var'
	}
order townsend* ethnicity* bmi* smokestat* alcoholintake*, last

** recode firstaddrug to combine fluvoxamine with citalopram (small n fluvox) // added 2020-04-28
replace firstaddrug = 5 if firstaddrug==14

** mi set (wide is best if few variables with lots of missing)
mi set wide

** Register variables to impute data into and which not to
mi register imputed townsend_i ethnicity_i bmi_i smokestat_i alcoholintake_i 

** set seed
set seed 871508752


** Impute data
mi impute chained	"`imputation'"   = ///
					i.cohort time firstad2_ddd ///
					`outcomes' `model' `extravars', add(20) noisily augment
*NOTE - without augment option gives error "mi impute mlogit: perfect predictor(s) detected"

save data/clean/imputed_`tag', replace

****
frames reset
clear
exit



