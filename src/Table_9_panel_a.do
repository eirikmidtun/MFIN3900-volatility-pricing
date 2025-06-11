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

*merge 1:1 permno month_id using DATA_b_delta_vxo_monthly_stocks_1986-2001.dta
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
* Plausibility check
tab ivol_quintile control_quintile
table ivol_quintile control_quintile, statistic(mean `ivol_measure' `control_filter')

drop ivol_percentile_*

* Keep the relevant variables
*keep permno month_id ivol_quintile control_quintile
keep permno month_id ivol_quintile 

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

* Compute value-weighted portfolio returns
quietly generate return_mcap=ret*market_cap_l1
quietly generate mcap_adjusted=market_cap_l1 if return_mcap!=.

by ivol_quintile month_id, sort: egen sum_return_mcap=total(return_mcap), missing
by ivol_quintile month_id, sort: egen sum_mcap=total(mcap_adjusted), missing
generate portfolio_return=sum_return_mcap/sum_mcap

save `ivol_measure'_mcap_data.dta, replace


drop permno ret market_cap_l1 return_mcap mcap_adjusted sum_return_mcap sum_mcap
duplicates drop
duplicates list ivol_quintile month_id

* Get the portfolio returns in five separate variables
reshape wide portfolio_return, i(month_id year) j(ivol_quintile)

save `ivol_measure'_value_weighted_returns.dta, replace

/*********************************************
Compute average portfolio returns and alphas
*********************************************/
use `ivol_measure'_value_weighted_returns.dta, clear

* Merge the data with the monthly Fama and French factors
merge 1:1 month_id using FF3_monthly_1926_2024.dta
drop if _merge==2
drop _merge

* Time-series
sort month_id
tsset month_id


* Q5 - Q1
generate return_difference=portfolio_return5-portfolio_return1

/****************************************************************
* Replication of the main result
****************************************************************/
local portfolios portfolio_return1 portfolio_return2 portfolio_return3 portfolio_return4 portfolio_return5 return_difference
* avg portfolio returns and volatility
sum portfolio_return* if month_id>=`sample_start' & month_id<`sample_end'

* Use excess return
gen portfolio_exreturn1 = portfolio_return1 - rf
gen portfolio_exreturn2 = portfolio_return2 - rf
gen portfolio_exreturn3 = portfolio_return3 - rf
gen portfolio_exreturn4 = portfolio_return4 - rf
gen portfolio_exreturn5 = portfolio_return5 - rf
label variable portfolio_exreturn1   "Portfolio return 1 - riskfree rate"
label variable portfolio_exreturn2   "Portfolio return 2 - riskfree rate"
label variable portfolio_exreturn3   "Portfolio return 3 - riskfree rate"
label variable portfolio_exreturn4   "Portfolio return 4 - riskfree rate"
label variable portfolio_exreturn5   "Portfolio return 5 - riskfree rate"


local portfolios 1 2 3 4 5
matrix results = J(5, 6, .)  // Expanded to 6 columns
local row = 1

tsset month_id, delta(1)

foreach port of local portfolios {
    * CAPM regression of ex-return
    quietly newey portfolio_exreturn`port' mktrf if month_id>=`sample_start' & month_id<`sample_end', lag(1)
    if _rc == 0 {
        matrix results[`row', 1] = _b[_cons]
        matrix results[`row', 2] = _b[_cons] / _se[_cons]
    }

    * FF3 regression of ex-return
    quietly newey portfolio_exreturn`port' mktrf smb hml if month_id>=`sample_start' & month_id<`sample_end', lag(1)
    if _rc == 0 {
        matrix results[`row', 3] = _b[_cons]
        matrix results[`row', 4] = _b[_cons] / _se[_cons]
    }

    * Mean and Std Dev of total return
    quietly summarize portfolio_return`port' if month_id>=`sample_start' & month_id<`sample_end'
    matrix results[`row', 5] = r(mean)
    matrix results[`row', 6] = r(sd)

    local row = `row' + 1
}

matrix rownames results = Port1 Port2 Port3 Port4 Port5
matrix colnames results = CAPM_Alpha CAPM_tstat FF3_Alpha FF3_tstat Mean_tot_ret SD_tot_ret
matrix list results
svmat results, names(col)

gen ivol_quintile = _n
order ivol_quintile Mean_tot_ret SD_tot_ret CAPM_Alpha CAPM_tstat FF3_Alpha FF3_tstat
label variable CAPM_Alpha   "CAPM Alpha (Excess Return)"
label variable CAPM_tstat   "CAPM t-stat (Excess Return)"
label variable FF3_Alpha    "FF3 Alpha (Excess Return)"
label variable FF3_tstat    "FF3 t-stat (Excess Return)"
label variable Mean_tot_ret "Mean tot Return"
label variable SD_tot_ret   "Std. Dev. tot Return"

save `ivol_measure'_alpha_results.dta, replace

drop CAPM_Alpha CAPM_tstat FF3_Alpha FF3_tstat portfolio_exreturn*


* Raw return
eststo alpha_0F: quietly newey return_difference if month_id>=`sample_start' & month_id<`sample_end', lag(1)

* CAPM alpha
eststo alpha_1F: quietly newey return_difference mktrf if month_id>=`sample_start' & month_id<`sample_end', lag(1)
 
* FF3 Alpha
eststo alpha_3F: quietly newey return_difference mktrf smb hml if month_id>=`sample_start' & month_id<`sample_end', lag(1)

estout using table_9_Ang_Table_VI_1990-2025_`control_filter'_alphas.txt, cells(b(fmt(4) star) t(fmt(2))) /*
*/ starlevels(* 0.10 ** 0.05 *** 0.01) varlabels(_cons Alpha) label stats(r2 N, fmt(3 0) /*
*/ labels("\$R^2\$" "Observations")) replace
eststo clear

/*********************************
* Control parameters
// bm
// mkt_share
// size
*********************************/
use `ivol_measure'_portfolio_assignment, clear
merge 1:1 permno month_id using COMPUSTAT_bm_1970-01-31_2024-12-31.dta
keep if _merge==3
drop _merge

keep if month_id>=`sample_start' & month_id<`sample_end'

collapse (mean) bm, by(ivol_quintile)
label variable bm "Average Book-to-Market Ratio per portfolio"
save `ivol_measure'_control_bm.dta, replace

// mkt_share
use `ivol_measure'_mcap_data.dta, clear
keep if month_id>=`sample_start' & month_id<`sample_end'

collapse (sum) mcap_adjusted, by(ivol_quintile)
quietly summarize mcap_adjusted
gen mcap_weight = mcap_adjusted / r(sum)

label variable mcap_weight "Market share: Portfolios average percentage of total Market Cap"
save `ivol_measure'_control_mktshare.dta, replace

//size
use `ivol_measure'_mcap_data.dta, clear
keep if month_id>=`sample_start' & month_id<`sample_end'

gen log_mcap = log(mcap_adjusted)

collapse (mean) log_mcap, by(ivol_quintile)
label variable log_mcap "Portfolio size: Portfolios average log market cap"
save `ivol_measure'_control_size.dta, replace

* Merge all controls
use `ivol_measure'_control_bm.dta, clear
merge 1:1 ivol_quintile using `ivol_measure'_control_mktshare.dta, nogen
merge 1:1 ivol_quintile using `ivol_measure'_control_size.dta, nogen
drop mcap_adjusted
save `ivol_measure'_controls_combined.dta, replace

/****************************************
* Save results to text file
****************************************/
*local ivol_measure="vol"
use `ivol_measure'_alpha_results.dta, clear
keep ivol_quintile Mean_tot_ret SD_tot_ret CAPM_Alpha CAPM_tstat FF3_Alpha FF3_tstat
keep if ivol_quintile < 6

merge 1:1 ivol_quintile using `ivol_measure'_controls_combined.dta
keep if _merge==3
drop _merge

* get right unit
replace mcap_weight =  	mcap_weight * 100
replace CAPM_Alpha 	=	CAPM_Alpha 	* 100
replace FF3_Alpha 	=  	FF3_Alpha   * 100
replace Mean_tot_ret= 	Mean_tot_ret* 100 
replace SD_tot_ret	= 	SD_tot_ret  * 100

* Optional: format numbers
format Mean_tot_ret SD_tot_ret log_mcap bm CAPM_Alpha CAPM_tstat FF3_Alpha FF3_tstat %6.2f
format mcap_weight %6.1f

order ivol_quintile Mean_tot_ret SD_tot_ret mcap_weight log_mcap bm CAPM_Alpha CAPM_tstat FF3_Alpha FF3_tstat

outsheet using table_9_Ang_Table_VI_1990-2025_`control_filter'.txt, replace
