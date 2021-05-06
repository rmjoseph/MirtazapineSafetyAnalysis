** Created by: Rebecca Joseph, University of Nottingham, 20190911
** Defines program stringsearch which was created to help generate codelists
** by searching for specified terms within string fields

** Start by defining program to search for specified terms in specified fields
capture program drop stringsearch 
program define stringsearch

//	set trace on
	
	* Name each of the arguments
	args IDVAR NEWVAR SEARCHNAME FIELDS TERMS
	
	* Preserve current dataset
	preserve
	
	* Keep only minimum required fields
	keep `IDVAR' `FIELDS'
	
	* Create the variable to hold the search results
	gen TEMPVAR = ""
	
	* Send the list of fields to be searched and the list of search terms to macros
	local fields "`FIELDS'"
	local terms "`TERMS'"
	
	* Loop over each of the fields to be searched
	foreach X of local fields {
	
	* replace the contents of each field with a lowercase version
		gen lowercase = lower(`X')
		
	* Loop over each of the search terms
		foreach Y of local terms {
	
	* Replace the search term with a lowercase version
			gen sc_1 = lower("`Y'")
			
	* Search the field for the search term and update variable with search results
			replace TEMPVAR = "`SEARCHNAME'" if regexm(lowercase,sc_1)==1
	
	* Drop the generated scalar holding the search term
			drop sc_1
	
	* Close the search term loop
			}
	
	* Drop the variable containing lowercase version of field searched
		drop lowercase
		
	* Close the field loop	
		}
	
	* Keep minimal dataset containing search results and save as temp file
	keep `IDVAR' TEMPVAR
	keep if TEMPVAR != ""
	tempfile tomerge
	save "`tomerge'", replace
	
	* Restore original dataset and merge in the search results
	restore
//	set trace off
	merge 1:1 `IDVAR' using "`tomerge'", nogen keepusing(TEMPVAR) 
//	set trace on

	* Setting the new variable name to that requested: avoid crash if variable already exists
	* by using capture. If variable already exists, will generate an error code.
	tab TEMPVAR
	capture noisily rename TEMPVAR `NEWVAR'
	
	* If variable already exists, then update it with the new results.
	if _rc!=0 {
		tab `NEWVAR'
		replace `NEWVAR' = TEMPVAR if TEMPVAR!="" & `NEWVAR'==""
		replace `NEWVAR' = TEMPVAR if TEMPVAR!=""   // use to highlight any overlaps
		drop TEMPVAR
		}
	
	* Tab to show final results
	tab `NEWVAR'

end


** EXAMPLE OF USE:
* stringsearch prodcode drug fluoxetine "productname drugsubst" "fluoxetine prozac serafem"

/*  needs the following args in this order: 
	id variable (e.g. prodcode - used to merge results with orig data)
	new variable name (e.g. drug - the variable holding the search results)
	a label for items in search (e.g. fluoxetine - a string to label the results)
	"list of fields to search" (e.g. "productname drugsubst" - list of existing variables)
	"list of search terms" (e.g. "fluoxetine prozac serafem" - will all be treated as lowercase)
*/
