***********************************************************************************
** 	TITLE	: 6_descriptives.do
**
**	PURPOSE	: Run Descriptives on Dataset
**				
**	AUTHOR	: Ananya 
**
**	DATE	: 08.12.2025 
********************************************************************************

   *========================= Creating Descriptives Workbook =========================* 
	
use Raw_Survey.dta, clear

// Sheet 1: Continuous Variables ----------------------------------------------------------
local varlist age hh_1 hh_2 hh_3 hh_4 hh_5 hh_7 land_1 land_2 tgt_size plot_0 tgt_plot_3 tgt_plot_24b tgt_plot_27 tgt_plot_28__1 tgt_plot_28__2 tgt_plot_28__3 tgt_plot_28__4 tgt_plot_28__5 tgt_plot_28__89 tgt_plot_28__99 tgt_plot_29 tgt_plot_31 tgt_plot_35 tgt_plot_35a tgt_plot_35b tgt_plot_49 tgt_plot_51 tgt_plot_52 tgt_plot_53 tgt_plot_54 tgt_plot_50 soil_perc_beans1 soil_perc_beans2 soil_perc_beans3 soil_perc_beans4 soil_perc_beans5 training_1 maize_beans1 maize_beans2 maize_beans3 maize_beans4 maize_beans5 plot_20 plot_21 plot_22 plot_23

foreach var of local varlist {
    quietly summarize `var', detail
    matrix stats = (r(N), r(mean), r(sd), r(min), r(max), r(p50))
    matrix rownames stats = `var'
    matrix colnames stats = N Mean SD Min Max Median 

    if "`var'" == "age" {
        matrix all_stats = stats
    }
    else {
        matrix all_stats = all_stats \ stats
    }
}
putexcel set "Descriptives.xlsx", sheet("Continuous") modify
putexcel A1 = matrix(all_stats), names 

// Sheet 2: Categorical descriptives ------------------------------------------------------


local varlist2 gender land_0__1 land_0__2 land_0__3 land_0__4 land_3__1 land_3__2 land_3__3 land_3__4 land_3__5 land_3__6 land_3__7 land_3__8 land_3__9 land_3__10 land_3__11 land_3__12 land_3__13 land_3__14 min_fert_any org_fert_any che_pest_any org_pest_any tgt_plot_21 agency_1 agency_3 agency_4 agency_5 agency_6 agency_7 soil_perc_5__1 soil_perc_5__2 soil_perc_5__3 soil_perc_5__4 soil_perc_5__5 respect_1 coop_1

putexcel set "Descriptives.xlsx", sheet("Categorical") modify
putexcel A1 = "Variable" B1 = "Variable Label" C1 = "Value" D1 = "Frequency" E1 = "Percent"

local row = 2
foreach var of local varlist2 {
    local varlabel : variable label `var'
    if "`varlabel'" == "" {
        local varlabel "`var'"
    }
    
    quietly tab `var', matcell(freq) matrow(cats)
    local total = r(N)
    local nrows = rowsof(freq)
    
    forvalues i = 1/`nrows' {
        local val = cats[`i',1]
        local frq = freq[`i',1]
        local pct = `frq'/`total'*100
        
        putexcel A`row' = "`var'" B`row' = "`varlabel'" C`row' = `val' D`row' = `frq' E`row' = `pct'
        local row = `row' + 1
    }
}

//Folder: Categorical Visualisations 
* Define the list of categorical variables
cap mkdir Charts
local varlist2 gender land_0__1 land_0__2 land_0__3 land_0__4 land_3__1 land_3__2 land_3__3 land_3__4 land_3__5 land_3__6 land_3__7 land_3__8 land_3__9 land_3__10 land_3__11 land_3__12 land_3__13 land_3__14 min_fert_any org_fert_any che_pest_any org_pest_any tgt_plot_21 agency_1 agency_3 agency_4 agency_5 agency_6 agency_7 soil_perc_5__1 soil_perc_5__2 soil_perc_5__3 soil_perc_5__4 soil_perc_5__5 respect_1 coop_1


foreach var of local varlist2 {
    
    graph hbar (count), over(`var') ///
        title("Frequency Distribution: `: variable label `var''") 															///
        ytitle("Frequency") ///
        blabel(bar, format(%5.1f)) ///
    
    graph export "Charts/`var'_frequency.png", replace
}

// Category 3: Reporting Survey Duration Out of Orders -------------------------------------------------------------------------------------------

gen bad_time = 0

replace bad_time = 1 if datetime_a_starttime > datetime_b_starttime | ///
                     datetime_b_starttime > datetime_c_starttime | ///
                     datetime_c_starttime > datetime_d_starttime | ///
                     datetime_d_starttime > datetime_e_starttime | ///
                     datetime_e_starttime > datetime_f_starttime | ///
                     datetime_f_starttime > datetime_g_starttime | ///
                     datetime_g_starttime > datetime_h_starttime | ///
                     datetime_h_starttime > datetime_i_starttime | ///
                     datetime_i_starttime > datetime_j_starttime | ///
                     datetime_j_starttime > datetime_k_starttime | ///
                     datetime_k_starttime > datetime_l_starttime | ///
                     datetime_l_starttime > datetime_m_starttime | ///
                     datetime_m_starttime > endtime_var

export excel int_id cov_2b interview__id datetime_*_starttime endtime_var bad_time if bad_time == 1 using "Descriptives.xlsx",sheet("Duration Out-of-Order", modify) cell(A1) firstrow(varlabels) keepcellfmt 

// Category 4: Survey Duration Summary --------------------------------------------------------------------------------------------

putexcel set "Descriptives.xlsx", sheet("SurveyDuration") modify
local varlist3 a_duration b_duration c_duration d_duration e_duration f_duration g_duration h_duration i_duration j_duration k_duration l_duration m_duration
putexcel A1 = "Variable" B1 = "Variable Label" C1 = "Mean" D1 = "Median" E1 = "Max" F1 = "Min" 
local row = 2
foreach var of local varlist3 {
    local varlabel : variable label `var'
    if "`varlabel'" == "" {
        local varlabel "`var'"
    }
    
    quietly summarize `var' if bad_time != 1, detail
    
    putexcel A`row' = "`var'" B`row' = "`varlabel'" C`row' = `r(mean)' D`row' = `r(p50)' E`row' = `r(max)' F`row' = `r(min)'
    local row = `row' + 1
}

// Rushed Check? 
local duration_vars survey_duration

local threshold = 45

putexcel set "Descriptives.xlsx", sheet("Survey_Duration_Check") modify
putexcel A1 = "Variable" B1 = "interview__id" C1 = "Respondent ID (int_id)" D1 = "Group (cov_2b)" E1 = "Duration_Value" F1 = "Check_Condition"

local row = 2 // Initialize starting row for data output

foreach var of local duration_vars {
    
    preserve // Save the current state of the dataset
    
    keep if `var' < `threshold' & bad_time != 1
    
    count
    local N_rushed = r(N)
    
    if `N_rushed' > 0 {
        
        gen str20 check_flag = "Rushed: < `threshold'"
        
        forvalues i = 1/`N_rushed' {
            
            putexcel A`row' = "`var'"             ///
                     B`row' = interview__id[`i']  ///
                     C`row' = int_id[`i']         ///
                     D`row' = cov_2b[`i']          ///
                     E`row' = `var'[`i']          ///
                     F`row' = check_flag[`i']
            
            local row = `row' + 1
        }
    }
    
    restore // Return to the full dataset for the next variable
}
di "Rushed check analysis complete. Check Duration_Rushed_Check.xlsx, sheet Rushed_Checks."

// Interview starttime 
*Interview starttime is less than 10min of the interview end time of the previous questionnaire?
preserve 



// 1. Define the variables to display
// Assuming your start time variables end with '_starttime'
local start_vars a_starttime b_starttime c_starttime d_starttime e_starttime f_starttime g_starttime h_starttime i_starttime j_starttime k_starttime l_starttime m_starttime endtime 
//Add all relevant start time variables here

// 2. Sort the data by Enumerator (cov_2b) and then by the primary interview start time
// This ensures all interviews by one enumerator are grouped together and chronologically ordered.
sort cov_2b time_1

// 3. List the variables
// The 'by(cov_2b)' prefix groups the output visually by enumerator.
list cov_2b interview__id int_id time_1 `start_vars' if !mi(cov_2b), sepby(cov_2b)

// Cleanly define all start time variables
local all_start_times a_starttime b_starttime c_starttime d_starttime e_starttime f_starttime g_starttime h_starttime i_starttime j_starttime k_starttime l_starttime m_starttime endtime 

// Define the main start time variable for sorting and include all others
local start_vars time_1 `all_start_times'

// Combine ID, Grouping, and Start Time variables for the export list
local export_vars cov_2b interview__id int_id `start_vars'

// --- DEBUGGING STEP ---
di "Contents of local macro 'export_vars':"
di "`export_vars'"
di "--------------------------------------------------------"

// 2. Sort the data
sort cov_2b time_1 

// 3. Export the relevant variables to an Excel file
// The local macro `export_vars' should contain only the list displayed above.
export excel `export_vars' using "Enumerator_StartTimes_Check.xlsx", ///
    sheet("StartTimes_by_Enumerator") replace ///
    cell(A1) firstrow(varlabels)

	
	di "Export complete. Check the Stata Results window for the exact list of variables exported."







