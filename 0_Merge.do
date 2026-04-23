********************************************************************************
** 	TITLE	: 0_merge.do
**
**	PURPOSE	: Instructions for the Merge, Time Variables 
**				
**	AUTHOR	: Ananya 
**
**	DATE	: 08.12.2025 
********************************************************************************
************************************* RUN BEFORE MASTER ********************************
// set cd to whatever you need 
*--------------------------------------READ ME--------------------------------------------*
*** !!!: All survey datasets should be in cwd before running this file !!! *** 
******************************** Reshaping the Rosters *************************************

*** Program Reshape_roster_wide ***
clear all 
cap program drop reshape_roster_wide
program define reshape_roster_wide

    * Syntax expects required options: file, id, and suffix.
    syntax, file(string) id(string) suffix(string)
    
    local file "`file'"
    local roster_id "`id'"
    local suffix "`suffix'"
    
    * Define the composite key for the check
    local composite_key "interview__key interview__id `roster_id'"

    display as text "{hline 70}"
    display as text "Starting reshape diagnostic for: `file'.dta"
    display as text "  - Composite Key Check: `composite_key'"
    display as text "{hline 70}"

    * 1. Load the roster file (assumes it's in the current directory)
    local input_file `"`file'.dta"'
    use `"`input_file'"', clear
    
    * --- New: Unique Identifier Check (isid) ---
    
    * 2. Check if the composite key uniquely identifies all observations
    cap isid `composite_key'
    
    if _rc {
        display as error "!!! FAILURE: `file' is a Problem File !!!"
        display as error "!!! isid failed (Code: `_rc'): Composite Key is NOT Unique !!!"
        exit 111  // Exits the program to indicate failure
    }
    
    display as result "CHECK PASSED: Composite Key is unique. Proceeding to reshape."

    * 3. Identify all variables to reshape
    ds `composite_key', not
    local varlist_to_reshape `r(varlist)'
    
    * 4. Execute the reshape from long to wide
    capture reshape wide `varlist_to_reshape', i(interview__id) j(`roster_id')
    
    if _rc {
        display as error "!!! FAILURE: Reshape command failed for unknown reason (Code: `_rc') !!!"
        display as error "This is often a data type or variable limit error."
        exit 112  
    }

    * 5. Save the new wide file (if successful)
    local output_file `"`file'`suffix'.dta"'
    save `"`output_file'"', replace
    display as result "SUCCESS: `file' reshaped and saved as: `output_file'"

end

*------------------------------------------------------------------------------------------*

** Input Call for the Program 
reshape_roster_wide, file("livestock") id("livestock__id") suffix("_wide") 
reshape_roster_wide, file("activity") id("activity__id") suffix("_wide") 
reshape_roster_wide, file("plot") id("plot__id") suffix("_wide") 
reshape_roster_wide, file("yieldfac") id("yieldfac__id") suffix("_wide")
reshape_roster_wide, file("influencer") id("influencer__id") suffix("_wide")
reshape_roster_wide, file("reasbadsoil") id("reasbadsoil__id") suffix("_wide")
reshape_roster_wide, file("extension") id("extension__id") suffix("_wide")
reshape_roster_wide, file("trainings") id("trainings__id") suffix("_wide")
reshape_roster_wide, file("incsour") id("incsour__id") suffix("_wide")
reshape_roster_wide, file("maizepic") id("maizepic__id") suffix("_wide")
reshape_roster_wide, file("landuse_targetplot") id("landuse_targetplot__id") suffix("_wide")
reshape_roster_wide, file("yieldsrost1") id("yieldsrost1__id") suffix("_wide")
reshape_roster_wide, file("yieldsrost2") id("yieldsrost2__id") suffix("_wide")
reshape_roster_wide, file("yieldsrost3") id("yieldsrost3__id") suffix("_wide")
reshape_roster_wide, file("input") id("input__id") suffix("_wide")
reshape_roster_wide, file("efficacy") id("efficacy__id") suffix("_wide") 
reshape_roster_wide, file("coop") id("coop__id") suffix("_wide")
reshape_roster_wide, file("coop2") id("coop2__id") suffix("_wide")

** manual reshape farmstr // ask what to do about this one?? 

*****************************  Merge Instructions ***************************************
use SurOv.dta, clear 
merge 1:1 interview__id interview__key using "livestock_wide.dta"
drop _merge
merge 1:1 interview__id interview__key using "activity_wide.dta"
drop _merge
merge 1:1 interview__id interview__key using "yieldfac_wide.dta"
drop _merge
merge 1:1 interview__id interview__key using "plot_wide.dta"
drop _merge
merge 1:1 interview__id interview__key using "influencer_wide.dta"
drop _merge
merge 1:1 interview__id interview__key using "reasbadsoil_wide.dta"
drop _merge
merge 1:1 interview__id interview__key using "extension_wide.dta"
drop _merge
merge 1:1 interview__id interview__key using "incsour_wide.dta"
drop _merge 
merge 1:1 interview__id interview__key using "trainings_wide.dta" 
drop _merge 
merge 1:1 interview__id interview__key using "maizepic_wide.dta"
drop _merge 
merge 1:1 interview__id interview__key using "landuse_targetplot_wide.dta"
drop _merge 
merge 1:1 interview__id interview__key using "yieldsrost1_wide.dta"
drop _merge 
merge 1:1 interview__id interview__key using "yieldsrost2_wide.dta"
drop _merge 
merge 1:1 interview__id interview__key using "yieldsrost3_wide.dta" 
drop _merge
merge 1:1 interview__id interview__key using "input_wide.dta" 
drop _merge 
merge 1:1 interview__id interview__key using "efficacy_wide.dta" 
drop _merge 
merge 1:1 interview__id interview__key using "coop_wide.dta" 
drop _merge 
merge 1:1 interview__id interview__key using "coop2_wide.dta"
save "Raw_Survey.dta", replace 
 
********************************************************************************************
****************************  Creating Datetime Variable *********************************
// Full datetime in Stata format
use Raw_Survey.dta, clear 

// Intiating Datetime 
gen time_1_clean = subinstr(time_1, "T", " ", .)
gen double datetime_var = clock(time_1_clean, "YMD hms")
format datetime_var %tc
label variable datetime_var "Interview datetime"

// Initiating Endtime 
gen time_2_clean =subinstr(endtime, "T", " ", .)
gen double endtime_var = clock(time_2_clean, "YMD hms")
format endtime_var %tc
label variable endtime_var "Interview endtime" 

// Survey duration
gen time_duration = endtime_var - datetime_var 
gen double survey_duration = (time_duration)/(1000*60)
label variable survey_duration "Interview Duration Minutes"

// creating Survey Duration per section 

** Section A
//Initiating Datetime Variables 
local varlist a_starttime b_starttime c_starttime d_starttime e_starttime f_starttime g_starttime h_starttime i_starttime j_starttime k_starttime l_starttime m_starttime
foreach var in `varlist' {
	gen `var'_start_clean =subinstr(`var', "T", " ", .)
	gen double datetime_`var' = clock(`var'_start_clean, "YMD hms")
	format datetime_`var' %tc
label variable datetime_`var' "`Var' Datetime" 	
}

* --- SECTION A ---
gen a_time_duration = datetime_b_starttime - datetime_a_starttime
gen double a_duration = a_time_duration / 60000
label variable a_duration "Section A Duration Minutes"

* --- SECTION B ---
gen b_time_duration = datetime_c_starttime - datetime_b_starttime
gen double b_duration = b_time_duration / 60000
label variable b_duration "Section B Duration Minutes"

* --- SECTION C ---
gen c_time_duration = datetime_d_starttime - datetime_c_starttime
gen double c_duration = c_time_duration / 60000
label variable c_duration "Section C Duration Minutes"

* --- SECTION D ---
gen d_time_duration = datetime_e_starttime - datetime_d_starttime
gen double d_duration = d_time_duration / 60000
label variable d_duration "Section D Duration Minutes"

* --- SECTION E ---
gen e_time_duration = datetime_f_starttime - datetime_e_starttime
gen double e_duration = e_time_duration / 60000
label variable e_duration "Section E Duration Minutes"

* --- SECTION F ---
gen f_time_duration = datetime_g_starttime - datetime_f_starttime
gen double f_duration = f_time_duration / 60000
label variable f_duration "Section F Duration Minutes"

* --- SECTION G ---
gen g_time_duration = datetime_h_starttime - datetime_g_starttime
gen double g_duration = g_time_duration / 60000
label variable g_duration "Section G Duration Minutes"

* --- SECTION H ---
gen h_time_duration = datetime_i_starttime - datetime_h_starttime
gen double h_duration = h_time_duration / 60000
label variable h_duration "Section H Duration Minutes"

* --- SECTION I ---
gen i_time_duration = datetime_j_starttime - datetime_i_starttime
gen double i_duration = i_time_duration / 60000
label variable i_duration "Section I Duration Minutes"

* --- SECTION J ---
gen j_time_duration = datetime_k_starttime - datetime_j_starttime
gen double j_duration = j_time_duration / 60000
label variable j_duration "Section J Duration Minutes"

* --- SECTION K ---
gen k_time_duration = datetime_l_starttime - datetime_k_starttime
gen double k_duration = k_time_duration / 60000
label variable k_duration "Section K Duration Minutes"

* --- SECTION L ---
gen l_time_duration = datetime_m_starttime - datetime_l_starttime
gen double l_duration = l_time_duration / 60000
label variable l_duration "Section L Duration Minutes"

* --- SECTION M (Special Case: Uses endtime_var) ---
gen m_time_duration = endtime_var - datetime_m_starttime
gen double m_duration = m_time_duration / 60000
label variable m_duration "Section M Duration Minutes"


* Optional: Clean up the intermediate variables (e.g., a_time_duration)
drop *_time_duration


******************************************************************************************
****************************  Creating Form_version Variable *****************************
gen form_version = 42

save "Raw_Survey.dta", replace //for the next do.file, please move Raw_Survey to the folder system created by ipacheck (more instructions in the ReadMe.txt)


********************************************************************************************
****************************** Setting up Data Management System **************************

*Installing ipacheck for the first time ------------------------------------------------

//net install ipacheck, all replace from("https://raw.githubusercontent.com/PovertyAction/high-frequency-checks/master")
//ipacheck update

* after initial installation ipacheck can be updated at any time via
//ipacheck update

*---------------------------------------------------------------------------------------*

ipacheck new, surveys(Benin_Baseline)  // make sure the cd is set to your current project day 

*--------------------------------------- END -------------------------------------------* 





