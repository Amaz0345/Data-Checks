***********************************************************************************
** 	TITLE	: 7_enumerator_stats.do
**
**	PURPOSE	: Running Enumerator Checks on Dataset
**				
**	AUTHOR	: Ananya 
**
**	DATE	: 10.12.2025 
********************************************************************************
*** THIS IS A DO FILE THAT IS DESIGNED TO RUN EXCLUSIVELY WITH THE CONFIDENTIAL DATASET BENIN.RAW.dta ***
** Dataset is not publicly available ** 
** This is only meant to be sample piece of code, must be adapted ** 
   *========================= Creating Enum_Stats Workbook =========================* 

use "$rawsurvey", clear 
local vars_to_check tgt_plot_7 tgt_plot_11 tgt_plot_12 tgt_plot_24 trust_1 trust_2 trust_3 trust_4 trust_5 assets_2 assets_11 assets_12 assets_13 coop_0 training_3 inc_food_insec_1 plot_71 plot_74 ext_25 tr_10 tr_11 tr_12 tgt_plot_hist_12016 tgt_plot_hist_12017 tgt_plot_hist_12018 tgt_plot_hist_12019 tgt_plot_hist_12020 tgt_plot_hist_12021 tgt_plot_hist_12022 tgt_plot_hist_12023 

foreach var of local vars_to_check {
    gen byte dk_`var' = (`var' == 89)
    gen byte ref_`var' = (`var' == 79)
}

preserve

collapse (mean) dk_* ref_* (min) int_id, by(cov_2b)
foreach var of varlist dk_* ref_* {
    replace `var' = `var' * 100
}

reshape long dk_ ref_, i(int_id cov_2b) j(variable) string

rename dk_ dont_know_pct
rename ref_ refusal_pct
rename cov_2b enumerator

sort variable enumerator

export excel using "enum_analysis.xlsx", firstrow(variables) replace

list variable enumerator dont_know_pct refusal_pct, sepby(variable)

restore

foreach var of local vars_to_check {
    di "--- Results for variable: `var' ---"
    tabulate `var' if `var' == 89 | `var' == 79
    di ""
}


if $run_enumdb {
    
    * Import the list of variables to check from the input file
    import excel using "${inputfile}", sheet("enumstats") firstrow clear
    
    * Store variable names to check in a local
    quietly count
    local nvars = r(N)
    
    local vars_to_check ""
    forvalues i = 1/`nvars' {
        local varname = variable[`i']
        if !missing("`varname'") {
            local vars_to_check "`vars_to_check' `varname'"
        }
    }
    
    * Now load the actual survey data
    use "${rawsurvey}", clear
    
    * Create output Excel file
    putexcel set "${enumdb_output}", sheet("enumstats") replace
    
    * Set up headers
    putexcel A1 = "Enumerator" B1 = "Total Surveys" C1 = "Avg Duration (min)" ///
             D1 = "Don't Know Count" E1 = "Don't Know %" ///
             F1 = "Refuse Count" G1 = "Refuse %" ///
             H1 = "First Survey Date" I1 = "Last Survey Date" ///
             J1 = "Form Version(s)"
    
    * Get list of enumerators (numeric)
    quietly levelsof ${enum}, local(enumerators)
    
    local row = 2
    foreach enum_id in `enumerators' {
        
        * Count total surveys
        quietly count if ${enum} == `enum_id'
        local total_surveys = r(N)
        
        * Calculate average duration
        quietly summarize ${duration} if ${enum} == `enum_id', meanonly
        local avg_duration = r(mean)
        if missing(`avg_duration') local avg_duration = .
        
        * Count Don't Know and Refuse responses
        local dk_count = 0
        local ref_count = 0
        local total_responses = 0
        
        * Loop through only the specified variables
        foreach var of local vars_to_check {
            
            * Check if variable exists in dataset
            capture confirm variable `var'
            if _rc continue
            
            * Check if numeric or string
            capture confirm numeric variable `var'
            if !_rc {
                * Numeric variable - check for coded values 89 and 79
                quietly count if ${enum} == `enum_id' & !missing(`var')
                local total_responses = `total_responses' + r(N)
                
                * Check for don't know (89)
                quietly count if ${enum} == `enum_id' & `var' == 89
                local dk_count = `dk_count' + r(N)
                
                * Check for refuse (79)
                quietly count if ${enum} == `enum_id' & `var' == 79
                local ref_count = `ref_count' + r(N)
            }
            else {
                * String variable - check for text patterns
                quietly count if ${enum} == `enum_id' & !missing(`var')
                local total_responses = `total_responses' + r(N)
                
                * Check for "don't know" patterns
                quietly count if ${enum} == `enum_id' & ///
                    (lower(`var') == "don't know" | ///
                     lower(`var') == "dont know" | ///
                     lower(`var') == "dk" | ///
                     lower(`var') == "don't know" | ///
                     lower(`var') == "89")
                local dk_count = `dk_count' + r(N)
                
                * Check for "refuse" patterns
                quietly count if ${enum} == `enum_id' & ///
                    (lower(`var') == "refuse" | ///
                     lower(`var') == "refuse to answer" | ///
                     lower(`var') == "refused" | ///
                     lower(`var') == "79")
                local ref_count = `ref_count' + r(N)
            }
        }
        
        * Calculate percentages
        if `total_responses' > 0 {
            local dk_pct = (`dk_count' / `total_responses') * 100
            local ref_pct = (`ref_count' / `total_responses') * 100
        }
        else {
            local dk_pct = 0
            local ref_pct = 0
        }
        
        * Get first and last survey dates
        quietly summarize ${date} if ${enum} == `enum_id', meanonly
        local first_date = r(min)
        local last_date = r(max)
        
        * Format dates
        if !missing(`first_date') {
            local first_date_str = string(`first_date', "%tc")
        }
        else {
            local first_date_str = ""
        }
        
        if !missing(`last_date') {
            local last_date_str = string(`last_date', "%tc")
        }
        else {
            local last_date_str = ""
        }
        
        * Get form versions
        capture confirm string variable ${formversion}
        if !_rc {
            quietly levelsof ${formversion} if ${enum} == `enum_id', local(versions) clean
        }
        else {
            quietly levelsof ${formversion} if ${enum} == `enum_id', local(versions)
        }
        local version_list = "`versions'"
        
        * Write to Excel
        putexcel A`row' = `enum_id' ///
                 B`row' = `total_surveys' ///
                 C`row' = `avg_duration' ///
                 D`row' = `dk_count' ///
                 E`row' = `dk_pct' ///
                 F`row' = `ref_count' ///
                 G`row' = `ref_pct' ///
                 H`row' = "`first_date_str'" ///
                 I`row' = "`last_date_str'" ///
                 J`row' = "`version_list'"
        
        local row = `row' + 1
    }
    
    display "Enumerator statistics exported to ${enumdb_output}"
}
























