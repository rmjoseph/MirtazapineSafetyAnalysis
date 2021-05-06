* Created 2020-05-06 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	model_outcome2.do
* Creator:	RMJ
* Date:	20200506
* Desc:	Specifies the vars to include in multiple imp and regression models
*			for cause-specific mortality (originally same as all-cause)
* Version History:
*	Date	Reference	Update
*	20200506	model_outcome2	Create file
*	20201006	model_outcome2	Update propensity score model
*************************************

**** MACROS FOR THE MODELS (cause-specific mort) 
local model age2 agesex invdose	///
	i.sex ageindex ///
	lastad1_ddd yearindex /// 
	i.(firstaddrug bl_intselfharm antipsychotics anxiolytics gc hypnotics opioids statins analgesics severe cancer1year weightloss vte substmisuse selfharm rheumatological renal pvd pud parkinsons pancreatitis palliative neuropathicpain mobility migraine mi metastatictumour legulcer insomnia indigestion hypertension hospitaladmi hemiplegia epilepsy dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas carehome cancer asthma anxiety appetiteloss angina anaemia alcoholmisuse af)

// Also specify the imputed vars to include in regression
local imputedvars i.(townsend_i smokestat_i alcoholintake_i) ib5.ethnicity_i bmi_i 

exit

