** Created 2019-12-19 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	categorise_icd10.do
* Creator:	RMJ
* Date:	20191219
* Desc:	Categorises cause of death to match ONS short list
* Version History:
*	Date	Reference	Update
*	20191219	masterfile_preparation	Create file
*	20191220	categorise_icd10	Add missing code (U50.9) at start of script
*	20200423	categorise_icd10	Add missing infection codes (A and B)
*	20200423	categorise_icd10	Add headings to improve layout
*	20200423	categorise_icd10	Fix code errors in Chapters IX and XX
*************************************

frames reset
clear
import delim using data/raw/ICD10_Edition5_20160401/Content/ICD10_Edition5_CodesAndTitlesAndMetadata_GB_20160401.txt // downloaded from TRUD 2019-12-19
keep code alt_code description

set obs 17935
replace code = "U50.9" in 17935
replace alt_code = "U509" in 17935
replace description = "Event awaiting determination of event" in 17935

gen all_cause=.
gen death_group=""
gen death_group2=""
gen death_group3=""
gen death_group4=""

gen chapter = substr(code,1,1)
gen subchapt = substr(code,2,.)
destring(subchapt), replace force
replace subchapt = floor(subchapt)
replace subchapt = 45 if subchapt==.

order code death_group chapter subchapt

sort code

replace all_cause = 1 if chapter!="S" & chapter!="T" & chapter!="Z"
replace all_cause = . if chapter=="Y" & subchapt>89

// Top-level
replace death_group = "I Certain infectious and parasitic diseases" if (chapter=="A" | chapter=="B")
replace death_group = "II Neoplasms" if (chapter=="C") | (chapter=="D" & subchapt<=48)
replace death_group = "III Diseases of the blood and blood-forming organs and certain disorders involving the immune mechanism " if (chapter=="D" & subchapt>=50 & subchapt<=89)
replace death_group = "IV Endocrine, nutritional and metabolic diseases" if (chapter=="E" & subchapt<=90)
replace death_group = "V Mental and behavioural disorders" if (chapter=="F")
replace death_group = "VI Diseases of the nervous system" if (chapter=="G")
replace death_group = "VII Diseases of the eye and adnexa" if (chapter=="H" & subchapt<=59)
replace death_group = "VIII Diseases of the ear and mastoid process" if (chapter=="H" & subchapt>=60 & subchapt<=95)
replace death_group = "IX Diseases of the circulatory system" if (chapter=="I")
replace death_group = "X Diseases of the respiratory system" if (chapter=="J")
replace death_group = "XI Diseases of the digestive system" if (chapter=="K" & subchapt<94)
replace death_group = "XII Diseases of the skin and subcutaneous tissue" if (chapter=="L" )
replace death_group = "XIII Diseases of the musculoskeletal system and connective tissue" if (chapter=="M" )
replace death_group = "XIV Diseases of the genitourinary system" if (chapter=="N" )
replace death_group = "XIX Injury, poisoning and certain other consequences of external causes" if chapter=="S" | (chapter=="T" & subchapt<99)
replace death_group = "XV Pregnancy, childbirth and the puerperium" if (chapter=="O" )
replace death_group = "XVI Certain conditions originating in the perinatal period" if (chapter=="P" & subchapt<97 )
replace death_group = "XVII Congenital malformations, deformations and chromosomal abnormalities" if (chapter=="Q")
replace death_group = "XVIII Symptoms, signs and abnormal clinical and laboratory findings, not elsewhere classified" if (chapter=="R")
replace death_group = "XX External causes of morbidity and mortality" if (chapter=="V") | (chapter=="W") | (chapter=="X") | (chapter=="Y" & subchapt<51) | (code=="U50.9")

// A00-B99 I Certain infectious and parasitic diseases (was missing - added 23/04/2020)
replace death_group2 = "Intestinal infectious diseases" if chapter=="A" & subchapt<10
replace death_group2 = "Respiratory tuberculosis" if chapter=="A" & subchapt>=15 & subchapt<17
replace death_group2 = "Other tuberculosis" if chapter=="A" & subchapt>=17 & subchapt<20
replace death_group2 = "Meningococcal infection" if chapter=="A" & subchapt==39
replace death_group2 = "Sepsis" if chapter=="A" & subchapt>=40 & subchapt<42
replace death_group2 = "Viral hepatitis" if chapter=="B" & subchapt>=15 & subchapt<19
replace death_group2 = "Human immunodeficiency virus [HIV] disease" if chapter=="B" & subchapt>=20 & subchapt<25
replace death_group2 = "Sequelae of tuberculosis" if chapter=="B" & subchapt==90

// C00-D48 II Neoplasms
replace death_group2 = "Malignant neoplasms" if chapter=="C" & subchapt<98
replace death_group3 = "Malignant neoplasms of lip, oral cavity and pharynx" if chapter=="C" & subchapt<15
replace death_group3 = "Malignant neoplasm of oesophagus"	if chapter=="C" & subchapt==15
replace death_group3 = "Malignant neoplasm of stomach"	if chapter=="C" & subchapt==16
replace death_group3 = "Malignant neoplasm of colon"	if chapter=="C" & subchapt==18
replace death_group3 = "Malignant neoplasm of rectosigmoid junction, rectum and anus"	if chapter=="C" & subchapt>=19 & subchapt<22
replace death_group3 = "Malignant neoplasm of liver and intrahepatic bile ducts"	if chapter=="C" & subchapt==22
replace death_group3 = "Malignant neoplasm of gallbladder and biliary tract"	if chapter=="C" & subchapt>=23 & subchapt<25
replace death_group3 = "Malignant neoplasm of pancreas"	if chapter=="C" & subchapt==25
replace death_group3 = "Malignant neoplasm of larynx"	if chapter=="C" & subchapt==32
replace death_group3 = "Malignant neoplasm of trachea, bronchus and lung"	if chapter=="C" & subchapt>=33 & subchapt<35
replace death_group3 = "Malignant melanoma of skin"	if chapter=="C" & subchapt==43
replace death_group3 = "Other malignant neoplasms of skin"	if chapter=="C" & subchapt==44
replace death_group3 = "Mesothelioma"	if chapter=="C" & subchapt==45
replace death_group3 = "Kaposi sarcoma"	if chapter=="C" & subchapt==46
replace death_group3 = "Malignant neoplasm of breast"	if chapter=="C" & subchapt==50
replace death_group3 = "Malignant neoplasm of cervix uteri"	if chapter=="C" & subchapt==53
replace death_group3 = "Malignant neoplasm of other and unspecified parts of uterus"	if chapter=="C" & subchapt>=54& subchapt<56
replace death_group3 = "Malignant neoplasm of ovary"	if chapter=="C" & subchapt==56
replace death_group3 = "Malignant neoplasm of prostate"	if chapter=="C" & subchapt==61
replace death_group3 = "Malignant neoplasm of testis"	if chapter=="C" & subchapt==62
replace death_group3 = "Malignant neoplasm of kidney, except renal pelvis"	if chapter=="C" & subchapt==64
replace death_group3 = "Malignant neoplasm of bladder"	if chapter=="C" & subchapt==67
replace death_group3 = "Malignant neoplasm of brain"	if chapter=="C" & subchapt==71
replace death_group3 = "Hodgkin lymphoma"	if chapter=="C" & subchapt==81
replace death_group3 = "Non-Hodgkin lymphoma"	if chapter=="C" & subchapt>=82 & subchapt<86
replace death_group3 = "Multiple myeloma and malignant plasma cell neoplasms"	if chapter=="C" & subchapt==90
replace death_group3 = "Leukaemia" 	if chapter=="C" & subchapt>=91 & subchapt<96
replace death_group3 = "Malignant neoplasms of independent (primary) multiple sites"	if chapter=="C" & subchapt==97

replace death_group2 = "In situ and benign neoplasms, and neoplasms of uncertain or unknown behaviour" if chapter=="D" & subchapt<49

// D50-D89 III Diseases of the blood and blood-forming organs
replace death_group2 = "Anaemias" if chapter=="D" & subchapt>=50 & subchapt<65

// E00 - E90 IV Endocrine, nutritional and metabolic diseases
replace death_group2 = "Diabetes mellitus" if chapter=="E" & subchapt>=10 & subchapt<15

// F00-F99 V Mental and behavioural disorders
replace death_group2 = "Vascular and unspecified dementia" if chapter=="F" & (subchapt==1 | subchapt==3)
replace death_group2 = "Mental and behavioural disorders due to psychoactive substance use"	if chapter=="F" & subchapt>=10 & subchapt<20

// G00-G99 VI Diseases of the nervous system
replace death_group2 = "Meningitis (excluding meningococcal)" if chapter=="G" & subchapt<4
replace death_group2 = "Motor neuron disease" if code=="G12.2"
replace death_group2 = "Parkinson disease"	if chapter=="G" & subchapt==20
replace death_group2 = "Alzheimer disease"	if chapter=="G" & subchapt==30
replace death_group2 = "Multiple sclerosis"	if chapter=="G" & subchapt==35
replace death_group2 = "Epilepsy"	if chapter=="G" & subchapt==40

// I00-I00 IX Diseases of the circulatory system
replace death_group2 = "Chronic rheumatic heart diseases"	if chapter=="I" & subchapt>=5 & subchapt<10
replace death_group2 = "Hypertensive diseases"	if chapter=="I" & subchapt>=10 & subchapt<16

replace death_group2 = "Ischaemic heart diseases"	if chapter=="I" & subchapt>=20 & subchapt<=25
replace death_group3 = "Acute myocardial infarction"	if chapter=="I" & subchapt>=21 & subchapt<=22 // Edit (to group3) 23 apr 2020

replace death_group2 = "Other heart diseases"	if chapter=="I" & subchapt>=26 & subchapt<=51
replace death_group3 = "Intracranial haemorrhage"	if chapter=="I" & subchapt>=60 & subchapt<=62
replace death_group3 = "Cerebral infarction"	if chapter=="I" & subchapt==63
replace death_group3 = "Stroke, not specified as haemorrhage or infarction"	if chapter=="I" & subchapt==64

replace death_group2 = "Cerebrovascular diseases"	if chapter=="I" & subchapt>=60 & subchapt<=69
replace death_group2 = "Atherosclerosis"	if chapter=="I" & subchapt==70
replace death_group2 = "Aortic aneurysm and dissection"	if chapter=="I" & subchapt==71

// J00-J99 X Diseases of the respiratory system
replace death_group2 = "Influenza due to certain identified influenza virus"	if chapter=="J" & subchapt==09
replace death_group2 = "Influenza"	if chapter=="J" & subchapt>=10 & subchapt<=11
replace death_group2 = "Pneumonia"	if chapter=="J" & subchapt>=12 & subchapt<=18
replace death_group2 = "Bronchitis, emphysema and other chronic obstructive pulmonary disease" if chapter=="J" & subchapt>=40 & subchapt<=44
replace death_group2 = "Asthma"	if chapter=="J" & subchapt>=45 & subchapt<=46

// K00-K93 XI Diseases of the digestive system
replace death_group2 = "Gastric and duodenal ulcer"	if chapter=="K" & subchapt>=25 & subchapt<=27
replace death_group2 = "Hernia"	if chapter=="K" & subchapt>=40 & subchapt<=46
replace death_group2 = "Diverticular disease of intestine" if chapter=="K" & subchapt==57
replace death_group2 = "Diseases of the liver" if chapter=="K" & subchapt>=70 & subchapt<=77

// M00-M99 XIII Diseases of the musculoskeletal system and connective tissue
replace death_group2 = "Rheumatoid arthritis and juvenile arthritis" if chapter=="M" & (subchapt>=05 & subchapt<=06 | subchapt==08)
replace death_group2 = "Osteoporosis" if chapter=="M" & subchapt>=80 & subchapt<=81

// N00-N99 XIV Diseases of the genitourinary system
replace death_group2 = "Glomerular and renal tubulo-interstitial diseases" if chapter=="N" & subchapt<=15
replace death_group2 = "Renal failure" if chapter=="N" & subchapt>=17 & subchapt<=19
replace death_group2 = "Hyperplasia of prostate" if chapter=="N" & subchapt==40

// Q00-Q99 XVI Congenital malformations, deformations and chromosomal abnormalities
replace death_group2 = "Congenital malformations of the circulatory system" if chapter=="Q" & subchapt>=20 & subchapt<=28

// R00-R99 XVIII Symptoms, signs and abnormal clinical and lab findings NEC
replace death_group2 = "Senility" if chapter=="R" & subchapt==54
replace death_group2 = "Sudden infant death syndrome" if chapter=="R" & subchapt==95
replace death_group2 = "Other ill-defined and unspecified causes of mortality" if chapter=="R" & subchapt==99

// S00-T98 XIX Injury, poisoning and certain other consequences of external causes
replace death_group2 = "Injuries to the head and the neck" if chapter=="S" & subchapt<=19
replace death_group2 = "Injuries to the thorax" if chapter=="S" & subchapt>=20 & subchapt<=29
replace death_group2 = "Injuries to the abdomen, lower back, lumbar spine and pelvis" if chapter=="S" & subchapt>=30 & subchapt<=39
replace death_group2 = "Fracture of femur" if chapter=="S" & subchapt==72
replace death_group2 = "Burns and corrosions" if chapter=="T" & subchapt>=20 & subchapt<=32
replace death_group2 = "Poisoning by 4-Aminophenol derivatives"	 if code=="T39.1"
replace death_group2 = "Poisoning by narcotics and psychodysleptics [hallucinogens]" if chapter=="T" & subchapt==40
replace death_group2 = "Poisoning by antiepileptic, sedative-hypnotic and antiparkinsonism drugs" if chapter=="T" & subchapt==42
replace death_group2 = "Poisoning by psychotropic drugs, not elsewhere classified" if chapter=="T" & subchapt==43
replace death_group2 = "Poisoning by other and unspecified drugs, medicaments and biological substances" if code=="T50.9"

replace death_group2 = "Toxic effects of substances chiefly nonmedicinal as to source" if chapter=="T" & subchapt>=51 & subchapt<=65
replace death_group3 = "Toxic effect of carbon monoxide" if chapter=="T" & subchapt==58

replace death_group2 = "Asphyxiation" if chapter=="T" & subchapt==71
replace death_group2 = "Drowning and nonfatal submersion" if code=="T75.1"


// V01-Y89, U50.9 XX External causes of morbidity and mortality (GROUPING UPDATED 23 Apr 2020)
replace death_group2 = "Accidents"	if chapter=="V" | (chapter=="X" & subchapt<=59)

replace death_group3 = "Transport accidents" if chapter=="V" | (chapter=="Y" & subchapt==85)
replace death_group4 = "Land transport accidents" if chapter=="V" & subchapt<=89

replace death_group3 = "Falls" if chapter=="W" & subchapt<=19
replace death_group3 = "Accidental drowning and submersion"	if chapter=="W" & subchapt>=65 & subchapt<=74
replace death_group3 = "Exposure to smoke, fire and flames" if chapter=="X" & subchapt<=09

replace death_group3 = "Accidental poisoning by and exposure to noxious substances"	if chapter=="X" & subchapt>=40 & subchapt<=49
replace death_group4 = "Accidental poisoning by and exposure to antiepileptic, sedative-hypnotic, antiparkinsonism and psychotropic drugs, not elsewhere classified" if chapter=="X" & subchapt==41
replace death_group4 = "Accidental poisoning by and exposure to narcotics and psychodysleptics [hallucinogens], not elsewhere classified" if chapter=="X" & subchapt==42
replace death_group4 = "Accidental poisoning by and exposure to other and unspecified drugs, medicaments and biological substances" if chapter=="X" & subchapt==44

replace death_group2 = "Accidental exposure to unspecified factor" if chapter=="X" & subchapt==59

replace death_group2 = "Assault; death from injury or poisoning, event awaiting determination of intent (inquest adjourned)" if (chapter=="X" & subchapt>=85) |  (chapter=="Y" & subchapt<=9) | code=="U50.9"

replace death_group3 = "Intentional self-harm; and event of undetermined intent" if (chapter=="X" & subchapt>=60 & subchapt<=84) |  (chapter=="Y" & subchapt>=10 & subchapt<=34)
replace death_group4 = "Intentional self-harm" if (chapter=="X" & subchapt>=60 & subchapt<=84)
replace death_group4 = "Event of undetermined intent" if (chapter=="Y" & subchapt>=10 & subchapt<=34)

replace death_group3 = "Assault" if (chapter=="X" & subchapt>=85) |  (chapter=="Y" & subchapt<=9)


*****
keep code death* alt_code desc all_cause
order code alt_code desc all_cause death*
replace death_group2="" if death_group2=="."
replace death_group3="" if death_group3=="."
	
	
	
