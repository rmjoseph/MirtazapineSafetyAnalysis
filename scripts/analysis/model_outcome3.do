* Created 2020-05-06 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	model_outcome3.do
* Creator:	RMJ
* Date:	20200506
* Desc:	Specifies the vars to include in multiple imp and regression models
*			for serious self-harm/suicide
* Version History:
*	Date	Reference	Update
*	20200506	model_outcome3	Create file
*	20201005	model_outcome3	Update the propensity score model
*************************************

**** MACROS FOR THE MODELS 
local model i.sex ageindex age2  i.(antipsychotics anxiolytics hypnotics statins substmisuse selfharm pud pancreatitis mentalhealthservices liverdis_mild intellectualdisab insomnia indigestion hypertension diabetes cancer anxiety asthma appetiteloss alcoholmisuse)
// Also specify the imputed vars to include in regression
local imputedvars bmi_i i.(smokestat_i alcoholintake_i) 


exit

