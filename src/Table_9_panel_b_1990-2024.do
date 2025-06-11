/*******************************************************************************
* Replication of table 9 Ang et al. (2006)
* NB! in order to replicate the table it is necessary to change the control_filter
* and the dataset that controls the filter.
* To replicate our out of sample analysis/extension it is necessary to change 
* the time period.
*******************************************************************************/
clear all
set more off
cd "/Users/eirik/master-v25/STATA/data"

local sample_start = mofd(mdy(1,1,1990))
local sample_end = mofd(mdy(1,1,2025))

/**************************************************************
* Create a data set with the portfolio assignment of the stocks
**************************************************************/
use CRSP_monthly_1926_2024.dta, clear

* lower case vaiable names
rename PERMNO permno
rename SHRCD shrcd
rename EXCHCD exchcd
rename DLRET dlret
rename PRC prc
rename RET ret
rename SHROUT shrout

generate month_id=mofd(date)
label var month_id "numerical date variables; increases each month by 1; Stata mofd() function. Human readable: format month_id %tm"

* Ordinary U.S. stocks on NYSE, NASDAQ and NYSE American
keep if shrcd==10 | shrcd==11
keep if exchcd==1 | exchcd==2 | exchcd==3 
* vol less than 17

* Panel data
sort permno month_id
xtset permno month_id

merge 1:1 permno month_id using DATA_b_delta_vix_monthly_stocks_1990-2024.dta
keep if _merge==3 
drop _merge

* control filter
local control_filter="b_d_vix"
keep if `control_filter' !=.

* Portfolio formation
forvalues i=20(20)80 {
  by month_id, sort: egen control_quintile_`i'=pctile(`control_filter'), p(`i')
}
generate control_quintile=.
replace control_quintile=1 if `control_filter'<control_quintile_20 & `control_filter'!=. & control_quintile_20!=.
replace control_quintile=2 if `control_filter'>=control_quintile_20 & `control_filter'<control_quintile_40 & `control_filter'!=. & control_quintile_20!=.
replace control_quintile=3 if `control_filter'>=control_quintile_40 & `control_filter'<control_quintile_60 & `control_filter'!=. & control_quintile_40!=.
replace control_quintile=4 if `control_filter'>=control_quintile_60 & `control_filter'<control_quintile_80 & `control_filter'!=. & control_quintile_60!=.
replace control_quintile=5 if `control_filter'>=control_quintile_80 & `control_filter'!=. & control_quintile_80!=.

label variable control_quintile "Quintiles filtered based on control parameter"

drop control_quintile_*

* Merge with volatility data
merge 1:1 permno month_id using DATA_IV_monthly_stocks_1926-2024.dta
keep if _merge==3 
drop _merge

* Sort quintile on: "iv" or "vol"
local ivol_measure="iv"
keep if `ivol_measure' !=.

keep permno month_id `ivol_measure' `control_filter' control_quintile

* Portfolio formation
forvalues i=20(20)80 {
  by month_id control_quintile, sort: egen ivol_percentile_`i'=pctile(`ivol_measure'), p(`i')
}
generate ivol_quintile=.
replace ivol_quintile=1 if `ivol_measure'<ivol_percentile_20 & `ivol_measure'!=. & ivol_percentile_20!=.
replace ivol_quintile=2 if `ivol_measure'>=ivol_percentile_20 & `ivol_measure'<ivol_percentile_40 & `ivol_measure'!=. & ivol_percentile_20!=.
replace ivol_quintile=3 if `ivol_measure'>=ivol_percentile_40 & `ivol_measure'<ivol_percentile_60 & `ivol_measure'!=. & ivol_percentile_40!=.
replace ivol_quintile=4 if `ivol_measure'>=ivol_percentile_60 & `ivol_measure'<ivol_percentile_80 & `ivol_measure'!=. & ivol_percentile_60!=.
replace ivol_quintile=5 if `ivol_measure'>=ivol_percentile_80 & `ivol_measure'!=. & ivol_percentile_80!=.

label variable ivol_quintile "Quintiles filtered based on iv or vol"
table ivol_quintile control_quintile, statistic(mean `ivol_measure' `control_filter')

keep permno month_id ivol_quintile control_quintile

* 1/0/1 strategy, increment month_id and save to file
replace month_id=month_id+1
save `ivol_measure'_portfolio_assignment.dta, replace


/**************************************************************
* Create a data set with the returns using the CRSP monthly data
**************************************************************/
use CRSP_monthly_1926_2024.dta, clear

rename PERMNO permno
rename SHRCD shrcd
rename EXCHCD exchcd
rename DLRET dlret
rename PRC prc
rename RET ret
rename SHROUT shrout

replace ret = . if ret > .
replace dlret = . if dlret > .
replace prc = . if prc > .
replace shrout = . if shrout > .

replace ret=(1+ret)*(1+dlret)-1 if dlret!=.
replace ret=dlret if ret==. & dlret!=.

generate year=year(date)
generate month_id=mofd(date)
label var month_id "numerical date variables; increases each month by 1; Stata mofd() function"

* Panel data
sort permno month_id
xtset permno month_id

generate market_cap=abs(prc)*shrout/1000
label var market_cap "Market cap [million USD] at end of current month"

* Lag the market cap by one month, i.e. end of previous month
generate market_cap_l1=l1.market_cap
label var market_cap_l1 "Market cap [million USD] at end of previous month"

keep permno month_id ret market_cap_l1 year
save `ivol_measure'_return_data.dta, replace


/*******************************
Value Weighted Portfolio Returns
*******************************/
use `ivol_measure'_return_data.dta, clear

* merge returns with portfolio assignment from end of previous month
merge 1:1 permno month_id using `ivol_measure'_portfolio_assignment.dta
keep if _merge==3
drop _merge

drop if ivol_quintile==.
drop if control_quintile==.

* Compute value-weighted portfolio returns
quietly generate return_mcap=ret*market_cap_l1
quietly generate mcap_adjusted=market_cap_l1 if return_mcap!=.

by ivol_quintile control_quintile month_id, sort: egen sum_return_mcap=total(return_mcap), missing
by ivol_quintile control_quintile month_id, sort: egen sum_mcap=total(mcap_adjusted), missing
generate portfolio_return=sum_return_mcap/sum_mcap

save `ivol_measure'_mcap_data.dta, replace


drop permno ret market_cap_l1 return_mcap mcap_adjusted sum_return_mcap sum_mcap
duplicates drop

save `ivol_measure'_value_weighted_returns.dta, replace

/*********************************************
Compute average portfolio 25 returns and alphas
*********************************************/
local sample_start = mofd(mdy(1,1,1990))
local sample_end = mofd(mdy(1,1,2025))
local ivol_measure="iv"
use `ivol_measure'_value_weighted_returns.dta, clear

merge m:1 month_id using FF3_monthly_1926_2024.dta
drop if _merge==2
drop _merge


merge m:1 month_id using DATA_fvix_monthly_1990-2024.dta
drop if _merge==2
drop _merge

* goupby ivol_quintile
gen port_id = 10 * control_quintile + ivol_quintile

drop ivol_quintile control_quintile

* Now gather together the ivol quintiles. Want to do further analysis on the ivolquintiles not control.
reshape wide portfolio_return, i(month_id year) j(port_id)

foreach var of varlist portfolio_return* {
    replace `var' = 0 if `var'==.
}

generate return_difference1=portfolio_return15-portfolio_return11
generate return_difference2=portfolio_return25-portfolio_return21
generate return_difference3=portfolio_return35-portfolio_return31
generate return_difference4=portfolio_return45-portfolio_return41
generate return_difference5=portfolio_return55-portfolio_return51

/****************************************************************
* Replication of the main result
****************************************************************/
* Use excess return
forvalues ctrl_p = 1/5 {
    forvalues iv_p = 1/5 {
		gen portfolio_exreturn`ctrl_p'`iv_p' = portfolio_return`ctrl_p'`iv_p' - rf
		replace portfolio_exreturn`ctrl_p'`iv_p' = 0 if portfolio_exreturn`ctrl_p'`iv_p' == . 
	}
}
drop portfolio_return*

* Time-series
sort month_id
tsset month_id

local portfolios 11 12 13 14 15 /*
    */21 22 23 24 25 /*
    */31 32 33 34 35 /*
    */41 42 44 44 45 /*
    */51 52 53 54 55
matrix results = J(25, 2, .)  // Expanded to 6 columns
local row = 1

tsset month_id, delta(1)

foreach ctrl_port of local portfolios {
	* Post formation fvix loading
	quietly newey portfolio_exreturn`ctrl_port' mktrf smb hml fvix if month_id>=`sample_start' & month_id<`sample_end', lag(1)
	if _rc == 0 {
		matrix results[`row', 1] = _b[fvix]
		matrix results[`row', 2] = _b[fvix] / _se[fvix]
	}

	local row = `row' + 1

}

matrix colnames results = fvix_loading fvix_loading_tstat 
matrix rownames results = 11 12 13 14 15 21 22 23 24 25 ///
                          31 32 33 34 35 41 42 43 44 45 ///
                          51 52 53 54 55
matrix list results
svmat results, names(col)

gen quintile_ctrl_iv = .
local portfolios "11 12 13 14 15 21 22 23 24 25 31 32 33 34 35 41 42 43 44 45 51 52 53 54 55"
local i = 1
foreach p of local portfolios {
    replace quintile_ctrl_iv = `p' in `i'
    local ++i
}

order quintile_ctrl_iv fvix_loading fvix_loading_tstat
save table_9_alpha_results.dta, replace

drop fvix_loading fvix_loading_tstat quintile_ctrl_iv portfolio_exreturn*


use table_9_alpha_results.dta, clear
* FF3 regressions for return differences
eststo diff1: quietly newey return_difference1 mktrf smb hml fvix if month_id >= `sample_start' & month_id < `sample_end', lag(1)
eststo diff2: quietly newey return_difference2 mktrf smb hml fvix if month_id >= `sample_start' & month_id < `sample_end', lag(1)
eststo diff3: quietly newey return_difference3 mktrf smb hml fvix if month_id >= `sample_start' & month_id < `sample_end', lag(1)
eststo diff4: quietly newey return_difference4 mktrf smb hml fvix if month_id >= `sample_start' & month_id < `sample_end', lag(1)
eststo diff5: quietly newey return_difference5 mktrf smb hml fvix if month_id >= `sample_start' & month_id < `sample_end', lag(1)

* Export only FVIX beta and its t-stat
estout using table_9_differences_1990-2024.txt, ///
    keep(fvix) ///
    cells(b(fmt(2) star) t(fmt(2))) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    varlabels(fvix "FVIX Beta, need multiply by 100") ///
    label stats(N, fmt(0) labels("Observations")) ///
    replace


eststo clear


/****************************************
* Save results to text file
****************************************/
use table_9_alpha_results.dta, clear
keep quintile_ctrl_iv fvix_loading fvix_loading_tstat
keep if quintile_ctrl_iv < 56

* get right unit
replace fvix_loading = fvix_loading * 100

* Optional: format numbers
format fvix_loading fvix_loading_tstat %6.2f

order fvix_loading fvix_loading_tstat

outsheet using table_9_1990-2024.txt, replace
