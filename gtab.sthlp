{smcl}
{hline}
help for {cmd:gtab} {right:v2.0  March 2020}
{hline}

{title:Title}

{pstd}{hi:gtab} {hline 2} Completely customizable table tool

{marker syntax}{...}
{title:Syntax}
{hline}

{pstd}
    {cmd:gtab [number] {ul:init}alize} column_names {hline 2} Initialize gtab with columns defined by column names. Number (Optional) may be specified to build multiple tables at the same time.

{pstd}
    {cmd:gtab [number] column_name} {hline 2} Add text to column_name, creating new row

{pstd}
    {cmd:gtab [number] fill} {hline 2} Equalize number of rows for all columns, useful if including header rows.

{pstd}
    {cmd:gtab [number] {ul:pre}view}} {hline 2} Preview table in results window 

{pstd}
    {cmd:gtab [number] {ul:exp}ort}} "file_name", [export options] {hline 2} Export table to excel file. 

{pstd}
    {cmd:gtab [number] {ul:imp}ort}} {hline 2} Import table into current data frame. 

{hline}
{synoptset 25 tabbed}{...}
{marker expopts}{col 5}{help gtab##expoptions:{it:export_options}}{col 32}Description
{synoptline}
{synopt:{opth sheet:(strings:string)}}Name of sheet to modify or replace, `"Sheet1"' is used if not specified
    {p_end}
{synopt:{opt replace:}}Replace excel file if it exists
    {p_end}
{synopt:{opt sheetreplace:}}Replace excel sheet if it exists
    {p_end}
{synopt:{opt sheetmodify:}}Modify excel file or sheet
    {p_end}
{synopt:{opth cell:(strings:string)}}Cell in which table should start, using excel conventsions (for example C5).
    {p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gtab} provides a tool to create entirely custom tables. It uses mata string matricies and allows you to define table columns row by row. It is best used looping over variables or other items of interest.
While it is more effortful than other table .ados, {cmd:gtab} makes custom tables easier to write and export.


{marker initdesc}{...}
{title:gtab initialize}
{pstd}
{cmd:gtab [number] {ul:init}alize} column_names {hline 2} Initialize gtab with the column names desired, and in the order the columns will appear in the table. 
gtab will then helpfully print commands to fill each column, which can be pasted into your .do file.
[number] can be specified to create multiple tables at once. 
Intialize each table with a number between gtab and the intialize command, and then place that number between gtab and each subsequent command.

{marker maindesc}{...}
{title:gtab}
{pstd}
{cmd:gtab [number] column_name} {hline 2} After intitalizing the table the command {cmd:gtab column_name} will add another row to column_name. 
You can fill the columns in whatever order, but empty cells must be defined (for example if you have header rows where only one column is filled, you must "fill" the remaining columns by calling that column and adding no text.
The {cmd:gtab fill} command will equalize the length of all columns.

{marker filldesc}{...}
{title:gtab fill}
{pstd}
{cmd:gtab [number] fill} {hline 2} Since {cmd:gtab} works by defining a set of mata string vectors, if empty cells aren't specified, table columns can get misaligned. Empty cells can be specified with -gtab column_name-.
Alternatively, {cmd: gtab fill} will equalize all column lengths so that the next gtab commands build on the same row.

{marker predesc}{...}
{title:gtab preview}
{pstd}
{cmd:gtab [number] {ul:pre}view} {hline 2} Previews table in results window. Some tables may be too wide to display properly in the results window. 

{marker impdesc}{...}
{title:gtab import}
{pstd}
{cmd:gtab [number] {ul:imp}ort} {hline 2} Imports table into the current Stata dataset or frame. Table information is cleared after importing and so can't be added to. 

{marker expdesc}{...}
{title:gtab export}
{pstd}
{cmd:gtab [number] {ul:exp}ort `"file_path"'}  {hline 2} Exports table to excel file with the specified path. Table information is cleared after exporting and so can't be added to.

{phang}
{opth sheet:(strings:string)} Specify the sheet in the excel file. Note that there are character limits on sheet names, avoid special characters and keep sheet names shorter than 32 characters. 

{phang}
{opt replace:} Replace the excel file if it already exists.

{phang}
{opt sheetreplace:} Replace the sheet if it already exists.

{phang}
{opt sheetmodify:} Modify the sheet if it already exists

{phang}
{opth cell:(strings:string)} Specify the cell that the table should start at using excel notation (for example B15). The upper-left cell of the table will be placed at that location.  

{marker basicexamples}{...}
{title:Simple example}
This simple table would be more easily made with another table export command, but it demonstrates the basic usage. In this case I'll use a table number, this allows one to build multiple tables at the same time.
Some data to use:
    sysuse auto, clear
Initalize gtab with the columns desired in the order desired
   gtab 1 init var mean min max

Title row for each column, there is no reason there can't be more than one, or title rows in the middle of tables.
    gtab 1 var Variable
    gtab 1 mean Mean 
    gtab 1 min Min 
    gtab 1 max Max

Loop over all of the non-string variables and output summary statistics
    ds * 
    foreach v in `r(varlist)' { 
        if !regexm(`"`:type `v''"',`"str"') {
            gtab 1 var `:variable label `v''
            sum `v'
            gtab 1 mean `:di %3.1f `r(mean)''
    	    gtab 1 min `:di %3.0f `r(min)'' 
	    gtab 1 max `:di %3.0f `r(max)''
        }	
    }
    
Add a legend or notes in the last row
    gtab 1 mean Legend: Data from auto.dta
Gtab will warn you if the columns are not the same length on import or export. Since this is the last row, it won't cause other columns to be off, but it'll prevent that warning from being printed.
    gtab 1 fill 
Preview, then export the table to excel.    
    gtab 1 pre
    gtab 1 export "C:/users/dhoepfner/results/example.xlsx", replace sheet("descriptives")

{marker advancedexamples}{...}
{title:Advanced example}

This more advanced example shows how you can get tables you couldn't otherwise. It also uses extended macro functions for variables/values to produce a tight fit between the labels and data so things aren't mis-aligned.
    sysuse auto, clear
Here I am going to use the levels of foreign to help define the columns, this will make tables extensible to addition levels added to a variable. I'll define and add to a local called gtab that defines the columns. 
When filling the table, you can make use of the same loops for the table.
    local gtab var
    levelsof foreign 
    foreach l in `r(levels)' {
        local gtab `gtab' m`l'
    }
Now adding a column for the difference 
    local gtab `gtab' d
Now adding columns for the Ns    
    levelsof foreign 
    foreach l in `r(levels)' {
        local gtab `gtab' n`l'
    }
Now initializing gtab     
    gtab init `gtab'
Now filling the title row
    gtab var Variable 
    levelsof foreign 
    foreach l in `r(levels)' { 
	gtab m`l' `:label (foreign) `l'' Mean
	gtab n`l' `:label (foreign) `l'' N
    }
    gtab  d Difference
Now we'll loop over each variable and level of foreign and extract and export the desired statistics. Notice that we can use stored results to define stars for significance, or whatever else we want.

     local vct=0
     ds foreign, not
     foreach v in `r(varlist)' {
         if !regexm(`"`:type `v''"',`"str"') {
             local ++vct
             gtab  var `:variable label `v'' 
             levelsof foreign 
             foreach l in `r(levels)' { 
	         sum `v' if foreign == `l'
	         local m`l' `r(mean)'
	         local n`l' `r(N)'
	         gtab m`l' `:di %7.1fc `m`l'''
	         gtab n`l' `:di %6.0fc `n`l'''
	     }
	     local stars
	     ranksum `v', by(foreign)
	     if `r(p_exact)' < .05 local stars `"*"'
	     if `r(p_exact)' < .01 local stars `"**"'
	     if `r(p_exact)' < .001 local stars `"***"'
	     if `vct' !=5  gtab  d `:di %3.2f  `=`m1'-`m0'''`stars'
	     if `vct' ==5  gtab  d `:di %3.2f  `=`m1'-`m0'''Custom Tables!
         }	
     }
Import the table into the current dataset/frame.
     gtab import

{marker author}{...}
{title:Author}
Danial Hoepfner, Gibson Consulting Group Inc., dhoepfner@gibsonconsult.com or danial.hoepfner@gmail.com

