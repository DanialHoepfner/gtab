*! Verion 2.0 written by Danial Hoepfner danial.hoepfner@gmail.com
cap program drop gtab
program def gtab, nclass 
	local anything `0'
	*********************************Command Sorter*********************************
	*********************************Command Sorter*********************************
	*********************************Command Sorter*********************************
	tokenize `"`anything'"'
	local tnum
	local pos 1 
	if regexm(`"`1'"',`"^[0-9]+$"') {
		local tnum=regexs(0)
		local pos 2 
	}
	*!DH Note 9/28/2020: Column names for initialize
	if `"`tnum'"'=="" local pass_on=subinstr(`"`0'"',"`1'","",1)
	if `"`tnum'"'!="" local pass_on=subinstr(`"`0'"',"`1' `2'","",1)

	*!DH Note 9/28/2020: Initialize
	if inlist(`"``pos''"',`"init"',`"initialize"') gtab_init `pass_on', pos(`pos') tnum(`tnum')
	*!DH Note 9/28/2020: Add
	if !inlist(`"``pos''"',"init","initialize","export","exp","pre","preview",`"imp"',`"import"', `"fill"')  gtab_add `anything' 
	*!DH Note 9/28/2020: Fill
	if `"``pos''"' == `"fill"' gtab_fill, pos(``pos'') tnum(`tnum') 
	*!DH Note 9/28/2020:preview
	if inlist(`"``pos''"',"pre","preview") gtab_pre, tnum(`tnum')
	*!DH Note 9/28/2020: import
	if inlist(`"``pos''"',"imp","import") gtab_imp, pos(``pos'') tnum(`tnum')
	*!DH Note 9/28/2020: export
	if inlist(`"``pos''"',"exp","export") {
	    *!DH Note 9/28/2020: split file name from options
		qui tokenize `"`pass_on'"', p(`","')
		gtab_exp `1', pos(exp) tnum(`tnum') `3'
	}	
	*******************************End Command Sorter*******************************
	*******************************End Command Sorter*******************************
	*******************************End Command Sorter*******************************
end 


**************************Initialize columns for table***************************
**************************Initialize columns for table***************************
**************************Initialize columns for table***************************
cap program drop gtab_init
program def gtab_init, nclass 
syntax anything, [ ///
	pos(string) /// Position of subcommand
	tnum(string)] //Table number
	global dhtbl`tnum'_cols ""
	local columns`tnum'=trim(itrim(`"`anything'"'))
	local badcol = 0 
	local badcollist ""
	*!DH Note 9/18/2020: Checking for columns named with words reserved for sub-functions
	foreach c in `columns`tnum''{
		foreach no in init initialize export exp pre preview import imp fill {
			if `"`c'"' == `"`no'"' {
				local ++badcol
				local badcollist `badcollist' `c' 
			}
		}
	}
	if `badcol' > 0 {
		local plural
		local plural2 an
		if `badcol' > 1 {
			local plural s
			local plural2 
		} 
		di as error `"`badcol' specified column`plural' reserved for sub-commands (`badcollist'). Please choose `plural2'other name`plural'."'
		di as error `"initialize, init, export, exp, preview, pre, import, imp, and fill are reserved"'
		error 198
	}
	*!DH Note 9/18/2020: Duplicated column names
	local uniquecs
	if `"`columns`tnum''"' != `"`:list uniq columns`tnum''"' {
		di as error `"All column names must be unique, the following are repeated: `:list dups columns`tnum''."'
		error 198
	}
	di as result `"table initialized with columns `columns`tnum''"'
	global dhtbl`tnum'_cols `"`columns`tnum''"'
	global dhtbl`tnum'_cols2 ""
	tokenize `columns`tnum''
	local cct=0
	while `"`*'"'!="" {
		local ++cct
		global dhtbl`tnum'_`cct' `"`1'"'
		global dhtbl`tnum'_ct_`cct'=0
		global dhtbl`tnum'_cols2 "${dhtbl`tnum'_cols2} dhtbl`tnum'_`cct'"
		di `"`=itrim(`"gtab `tnum' ${dhtbl`tnum'_`cct'}"')'"'
		macro shift
	}
end	

************************End Initialize columns for table*************************
************************End Initialize columns for table*************************
************************End Initialize columns for table*************************	

******************************Add text to columns*******************************
******************************Add text to columns*******************************
******************************Add text to columns*******************************

cap program drop gtab_add
program def gtab_add, nclass 
	*!DH Note 9/28/2020: I can't use syntax to pass more information because stata will assume any , in table text indicates options, so I need to manually re-parse the command for this one
	local anything `"`0'"'
	tokenize `"`anything'"'
	local tnum
	local pos 1 
	if regexm(`"`1'"',`"^[0-9]+$"') {
		local tnum=regexs(0)
		local pos 2 
	}
	if `"`tnum'"'=="" local coln `"`1'"'
	if `"`tnum'"'!="" local coln `"`2'"'
	local nonm=0	
	local cct=0
	foreach c of global dhtbl`tnum'_cols {
		local ++cct
		if `"`c'"' == `"`coln'"' {
			local nonm=1
			if `"`tnum'"'=="" local text=trim(itrim(subinstr(`"`anything'"',"`1'","",1)))
			if `"`tnum'"'!="" local text=trim(itrim(subinstr(`"`anything'"',"`1' `2'","",1)))
			if ${dhtbl`tnum'_ct_`cct'} > 0  {
				mata: dhtbl`tnum'_`cct'=dhtbl`tnum'_`cct'\(`"`text'"')
				global dhtbl`tnum'_ct_`cct'= ${dhtbl`tnum'_ct_`cct'}+1
			}

			if ${dhtbl`tnum'_ct_`cct'} == 0  {
				mata: dhtbl`tnum'_`cct'=(`"`text'"')
				global dhtbl`tnum'_ct_`cct'= ${dhtbl`tnum'_ct_`cct'}+1
			}
			continue, break
		}
	}
	if `nonm' == 0 {
	    if `"`tnum'"'=="" di as error `"`1' is not an initialized column"'
		if `"`tnum'"'!="" di as error `"`2' is not an initialized column for table `tnum'"'
		error 198
	}	
end	
****************************End Add text to columns*****************************
****************************End Add text to columns*****************************
****************************End Add text to columns*****************************



*******************************Fill partial rows********************************
*******************************Fill partial rows********************************
*******************************Fill partial rows********************************
cap program drop gtab_fill
program def gtab_fill, nclass 
syntax, [ ///
	pos(string) /// subcommand
	tnum(string)] //Table number
	gtab_check, tnum(`tnum') pos(fill)
end
*****************************End Fill partial rows******************************
*****************************End Fill partial rows******************************
*****************************End Fill partial rows******************************

	
*********************************Preview Table**********************************
*********************************Preview Table**********************************
*********************************Preview Table**********************************
cap program drop gtab_pre
program def gtab_pre, nclass 
syntax, [ ///
	tnum(string)] //Table number
	gtab_check, tnum(`tnum') pos(pre)
	local mct = 0 
	foreach c of global dhtblO`tnum'_cols2 {
		local ++mct
		if `mct' == 1 mata: dhbtlresult`tnum' = (`c')
		if `mct' > 1  mata: dhbtlresult`tnum' = dhbtlresult`tnum',(`c')
	}
	mata:dhbtlresult`tnum'
	mata: mata drop dhbtlresult`tnum'
	foreach c of global dhtblO`tnum'_cols2 {
		mata: mata drop `c'
	}
	global dhtblO`tnum'_cols2

end	
*******************************End Preview Table********************************
*******************************End Preview Table********************************
*******************************End Preview Table********************************


************************Import Table into Stata Dataset*************************
************************Import Table into Stata Dataset*************************
************************Import Table into Stata Dataset*************************
cap program drop gtab_imp
program def gtab_imp, nclass 
syntax, [ ///
	pos(string) ///subcommand
	tnum(string)] //Table number
	gtab_check, tnum(`tnum') pos(imp)
	clear
	foreach c of global dhtbl`tnum'_cols2 {
		getmata (`c') = `c'
	}
	local ct=0
	qui ds dhtbl* 
	foreach v in `r(varlist)' { 
		local ++ct
		rename `v' column_`ct' 
	}
	foreach c of global dhtbl`tnum'_cols2 {
		mata: mata drop `c'
	}
	macro drop dhtbl`tnum'_*
end	
**********************End Import Table into Stata Dataset***********************
**********************End Import Table into Stata Dataset***********************
**********************End Import Table into Stata Dataset***********************


*****************************Export Table to Excel******************************
*****************************Export Table to Excel******************************
*****************************Export Table to Excel******************************
cap program drop gtab_exp
program def gtab_exp, nclass 
syntax anything, [ ///
	pos(string) ///subcommand
	tnum(string) ///Table number
	replace /// replace excel file
	sheetreplace /// replace sheet
	sheetmodify /// Modify sheet
	sheet(string) ///Which Sheet
	cell(string)] //Which cell to start in 
	if `"`sheet'"' == "" local sheet `"Sheet1"'
	*!DH Note 9/29/2020: Making sure only one of these is specified
	local sheetops = 0 
	foreach op in replace sheetreplace sheetmodify {
	    if `"``op''"' != "" local ++sheetops
	}
	if `sheetops'>1 {
	    di as error`" May only specify one of replace, sheetreplace, and sheetmodify"'
		error 198
	}
	gtab_check, tnum(`tnum') pos(exp)
	local mct = 0 
	foreach c of global dhtbl`tnum'_cols2 {
		local ++mct
		if `mct' == 1 mata: dhbtlresult`tnum' = (`c')
		if `mct' > 1  mata: dhbtlresult`tnum' = dhbtlresult`tnum',(`c')
	}
	local fname = subinstr(`"`anything'"',".xlsx","",1)
	local fname = subinstr(`"`fname'"',".xls","",1)
	if `"`cell'"' == "" local ex_cell `"1,1"'
	if `"`cell'"' != "" {
	    local ex_cell `"`=upper(`"`cell'"')'"'
		if !regexm(`"`ex_cell'"',`"^([A-Z]+)([1-9]+)$"') {
		    di as error `"Please specify cell as [A-Z]+[1-9]+ format"'
			error 198
		}	
		if regexm(`"`ex_cell'"',`"^([A-Z]+)([1-9]+)$"') {
			local lets = regexs(1)
			local numbs = regexs(2)
			*!DH Note 9/29/2020: letter list that follow A-Z AA-ZZ, AAA-ZZZ
			local letlist `c(ALPHA)'
			if `=length(`"`lets'"')' > 1 {
				foreach f in `c(ALPHA)' {
					foreach s in `c(ALPHA)' {
						local letlist `letlist' `f'`s'
					}
				}
			}	
			*!DH Note 10/2/2020: This adds a ton of time, only add these if the selected column uses 3 letters
			if `=length(`"`lets'"')' > 2 {
				foreach f in `c(ALPHA)' {
					foreach s in `c(ALPHA)' {
						foreach th in `c(ALPHA)' {
							local letlist `letlist' `f'`s'`th'
						}	
					}
				}
			}	
			local lct=0
			foreach l in `letlist' {
			    local ++lct
				if `"`lets'"' == `"`l'"' {
				    local let_num = `lct'
					continue, break
				}
			}
			local ex_cell `"`numbs',`let_num'"'
		}	
	}
	*!DH Note 11/11/2020: Determining if the file/sheet exists
	cap confirm file `"`fname'.xlsx"'
	if _rc == 0 local f_exists 1 
	if _rc != 0 local f_exists 0 

	local s_exists 0
	local onesheet 0 
	if `f_exists' == 1 {
		qui import excel `"`fname'.xlsx"', desc
		if `r(N_worksheet)' == 1 local onesheet 1 
		forvalues i = 1/`r(N_worksheet)' {
			if `"`r(worksheet_`i')'"' == `"`sheet'"' local s_exists 1
		}
	}
	if (`"`replace'"' != `""' | `"`sheetreplace'"' != `""' | `"`sheetmodify'"' != `""') & `f_exists' == 0 di as smcl `"Note: `fname'.xlsx not found"'
	*!DH Note 9/29/2020: If no replace/modify option passed
	if (`"`replace'"' == `""' & `"`sheetreplace'"' == `""' & `"`sheetmodify'"' == `""') | `f_exists' == 0 {
	   	mata: gtabb=xl()
		mata: gtabb.create_book(`"`fname'"',`"`sheet'"')
		mata: gtabb.put_string(`ex_cell',dhbtlresult`tnum')	    
		di as smcl `"CLICK TO OPEN: {browse `"`fname'.xlsx"'}"'
	}
	if (`"`replace'"' == `"replace"'|(`"`sheetreplace'"' == `"sheetreplace"' & `onesheet' == 1 & `s_exists' == 1)) & `f_exists' == 1 {
		cap rm `"`fname'.xlsx"'
		if _rc != 0 {
			di as error `"Unable to remove existing file, may be open or otherwise locked"'
		}
 	   	mata: gtabb=xl()
		mata: gtabb.create_book(`"`fname'"',`"`sheet'"')
		mata: gtabb.put_string(`ex_cell',dhbtlresult`tnum')
		di as smcl `"CLICK TO OPEN: {browse `"`fname'.xlsx"'}"'
	}
	if `"`sheetreplace'"' == `"sheetreplace"' & `f_exists' == 1 & (`onesheet' == 0 | (`onesheet' == 1 & `s_exists' == 0))  {
		if `s_exists' == 1 {
			mata:repex(`"`fname'"',`"`sheet'"',`ex_cell',dhbtlresult`tnum')
		}	
		if `s_exists' == 0 {
			mata:repnew(`"`fname'"',`"`sheet'"',`ex_cell',dhbtlresult`tnum')
			di as smcl `"Note `sheet' did not exist in excel file"'
		}	
		di as smcl `"CLICK TO OPEN: {browse `"`fname'.xlsx"'}"'

	}
	if `"`sheetmodify'"' == `"sheetmodify"' & `f_exists' == 1 {
		if `s_exists' == 0 {
			mata:repnew(`"`fname'"',`"`sheet'"',`ex_cell',dhbtlresult`tnum')
			di as smcl `"Note: Sheet `sheet' did not exist in excel file"'
		}
		if `s_exists' == 1 {
			mata:modex(`"`fname'"',`"`sheet'"',`ex_cell',dhbtlresult`tnum')
		}
		di as smcl `"CLICK TO OPEN: {browse `"`fname'.xlsx"'}"'

	}
	
	macro drop dhtbl`tnum'_*
	
end	
***************************End Export Table to Excel****************************
***************************End Export Table to Excel****************************
***************************End Export Table to Excel****************************

*******************Mata Functions used for exporting to excel*******************
*******************Mata Functions used for exporting to excel*******************
*******************Mata Functions used for exporting to excel*******************


mata:
	/*Sheet replace when that sheet does not exist*/
	void repnew(string scalar fname,string scalar sheet, real scalar rown, real scalar coln, string matrix tablen)
	{
		class xl scalar gtabb
		gtabb=xl()
		gtabb.load_book(fname)
		gtabb.add_sheet(sheet)
		gtabb.set_sheet(sheet)
		gtabb.put_string(rown,coln,tablen)
	}	
	/*Sheet replace when that sheet does exist*/
	void repex(string scalar fname,string scalar sheet, real scalar rown, real scalar coln, string matrix tablen)
	{
		class xl scalar gtabb
		gtabb=xl()
		gtabb.load_book(fname)
		gtabb.delete_sheet(sheet)
		gtabb.add_sheet(sheet)
		gtabb.set_sheet(sheet)
		gtabb.put_string(rown,coln,tablen)
	}
	/*Sheet modify when that sheet does exist*/
	void modex(string scalar fname,string scalar sheet, real scalar rown, real scalar coln, string matrix tablen)
	{
		class xl scalar gtabb
		gtabb=xl()
		gtabb.load_book(fname)
		gtabb.set_sheet(sheet)
		gtabb.put_string(rown, coln, tablen)
	}

end 

*****************End Mata Functions used for exporting to excel*****************
*****************End Mata Functions used for exporting to excel*****************
*****************End Mata Functions used for exporting to excel*****************

********************Checks/Prepares vectors	for imp pre exp*********************
********************Checks/Prepares vectors	for imp pre exp*********************
********************Checks/Prepares vectors	for imp pre exp*********************
cap program drop gtab_check
program def gtab_check, nclass 
syntax, [ ///
	pos(string) /// subcommand using this function
	tnum(string)] //Table number
	
	*!DH Note 7/30/2020: Stop if already imported or exported
	if `"${dhtbl`tnum'_cols}"' == "" {
		di as error `"gtab `tnum' not initialized (or already imported or exported)"'
		error 198
	}
	local ok=1
	local rowmax=0
	local cols `:word count ${dhtbl`tnum'_cols2}'
	forvalues j=1/`cols' {
		if `rowmax'< ${dhtbl`tnum'_ct_`j'} local rowmax= ${dhtbl`tnum'_ct_`j'}
	}
	forvalues j=1/`cols' { 
		if ${dhtbl`tnum'_ct_`j'} != `rowmax' local ok=0
	}
	*!DH Note 9/28/2020: if import or export, modify main matrix for table
	*!DH Note 9/28/2020: if preview, generate new vectors whose lengths are equalized so that you can preview without equalizing main table vectors
	if `"`pos'"' == `"pre"' {
		global dhtblO`tnum'_cols2
		forvalues i=1/`cols' {
			mata: dhtblO`tnum'_`i'=dhtbl`tnum'_`i'
			global dhtblO`tnum'_cols2 ${dhtblO`tnum'_cols2} dhtblO`tnum'_`i' 
		}

		if `ok'!=1 {
			di as error `"Table columns do not have same number of rows!"'
			di as error `"Table may be mis-aligned!"'
			forvalues i=1/`cols' {
				di as result `"${dhtbl`tnum'_`i'}:${dhtbl`tnum'_ct_`i'} Rows"'	
				if ${dhtbl`tnum'_ct_`i'} < `rowmax' {
					local reps=`rowmax'-${dhtbl`tnum'_ct_`i'}
					if `reps'> 0 {
						forvalues r=1/`reps' {
							if ${dhtbl`tnum'_ct_`i'} > 0 mata: dhtblO`tnum'_`i'=dhtblO`tnum'_`i'\(`""')
							if ${dhtbl`tnum'_ct_`i'} == 0 mata: dhtblO`tnum'_`i'=(`""')
						}	
					}	
				}	
			}
		}
	}
		
	if inlist(`"`pos'"',`"imp"',`"exp"',`"fill"') {
		if `ok'!=1 {
			if inlist(`"`pos'"',`"imp"',`"exp"') {
				di as error `"Table columns do not have same number of rows!"'
				di as error `"Table may be mis-aligned!"'
			}	
			forvalues i=1/`cols' {
				if inlist(`"`pos'"',`"imp"',`"exp"') di as result `"${dhtbl`tnum'_`i'}:${dhtbl`tnum'_ct_`i'} Rows"'	
				if ${dhtbl`tnum'_ct_`i'} < `rowmax' {
					local reps=`rowmax'-${dhtbl`tnum'_ct_`i'}
					if `reps'> 0 {
						forvalues r=1/`reps' {
							if ${dhtbl`tnum'_ct_`i'} > 0 mata: dhtbl`tnum'_`i'=dhtbl`tnum'_`i'\(`""')
							if ${dhtbl`tnum'_ct_`i'} == 0 mata: dhtbl`tnum'_`i'=(`""')
							global dhtbl`tnum'_ct_`i'= ${dhtbl`tnum'_ct_`i'}+1
						}	
					}	
				}	
			}
		}
	}	
end	
******************End Checks/Prepares vectors for imp pre exp*******************
******************End Checks/Prepares vectors for imp pre exp*******************
******************End Checks/Prepares vectors for imp pre exp*******************
	

