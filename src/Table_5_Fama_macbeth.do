/*******************************************************************************
* Replication of table 5 Ang et al. (2006)
* not included in thesis
*******************************************************************************/
clear all
set more off
cd "/Users/eirik/master-v25/STATA/data"

local sample_start = mofd(mdy(1,1,1986))
local sample_end = mofd(mdy(1,1,2001))

/**************************************************************
* Create a data set with the portfolio assignment of the stocks
**************************************************************/
use DATA_CRSP_monthly_1926_2024.dta, clear

merge 1:1 permno month_id using DATA_b_delta_vxo_monthly_stocks_1986-2020.dta
*merge 1:1 permno month_id using DATA_b_delta_vix_monthly_stocks_1990-2024.dta
keep if _merge==3 
drop _merge

local control_filter="b_mkt"
keep if `control_filter' !=.


forvalues i=20(20)80 {
  by month_id, sort: egen control_quintile_`i'=pctile(`control_filter'), p(`i')
}
generate control_quintile=.
replace control_quintile=1 if `control_filter'<control_quintile_20 & `control_filter'!=. & control_quintile_20!=.
replace control_quintile=2 if `control_filter'>=control_quintile_20 & `control_filter'<control_quintile_40 & `control_filter'!=. & control_quintile_20!=.
replace control_quintile=3 if `control_filter'>=control_quintile_40 & `control_filter'<control_quintile_60 & `control_filter'!=. & control_quintile_40!=.
replace control_quintile=4 if `control_filter'>=control_quintile_60 & `control_filter'<control_quintile_80 & `control_filter'!=. & control_quintile_60!=.
replace control_quintile=5 if `control_filter'>=control_quintile_80 & `control_filter'!=. & control_quintile_80!=.

label variable control_quintile "Quintiles filtered on b_mkt"
drop control_quintile_*


local ivol_measure="b_d_vxo"
keep if `ivol_measure' !=.


forvalues i=20(20)80 {
  by month_id control_quintile, sort: egen ivol_percentile_`i'=pctile(`ivol_measure'), p(`i')
}
generate ivol_quintile=.
replace ivol_quintile=1 if `ivol_measure'<ivol_percentile_20 & `ivol_measure'!=. & ivol_percentile_20!=.
replace ivol_quintile=2 if `ivol_measure'>=ivol_percentile_20 & `ivol_measure'<ivol_percentile_40 & `ivol_measure'!=. & ivol_percentile_20!=.
replace ivol_quintile=3 if `ivol_measure'>=ivol_percentile_40 & `ivol_measure'<ivol_percentile_60 & `ivol_measure'!=. & ivol_percentile_40!=.
replace ivol_quintile=4 if `ivol_measure'>=ivol_percentile_60 & `ivol_measure'<ivol_percentile_80 & `ivol_measure'!=. & ivol_percentile_60!=.
replace ivol_quintile=5 if `ivol_measure'>=ivol_percentile_80 & `ivol_measure'!=. & ivol_percentile_80!=.

label variable ivol_quintile "Quintiles filtered on b_d_vxo"
drop ivol_percentile_*

drop if ivol_quintile==.
replace month_id=month_id+1

keep permno month_id ivol_quintile control_quintile

rename ivol_quintile q_b_dvix
rename control_quintile q_b_mkt

save fmb_portfolio_assignment_table_5.dta, replace



/*****************************************************/
* DAILY
/****************************************************
use DATA_CRSP_daily_1926-01_2024-12.dta, clear

* potensielt bare market cap ikke l1
keep permno year month_id date ret market_cap_l1  

merge m:1 permno month_id using fmb_portfolio_assignment_table_5.dta
keep if _merge==3
drop _merge

quietly generate return_mcap=ret*market_cap_l1
quietly generate mcap_adjusted=market_cap_l1 if return_mcap!=.

* daglig 25 portføljer?
by q_b_mkt q_b_dvix date, sort: egen sum_return_mcap=total(return_mcap), missing
by q_b_mkt q_b_dvix date, sort: egen sum_mcap=total(mcap_adjusted), missing
generate portfolio_return=sum_return_mcap/sum_mcap

*gen pid = "q" + string(q_b_mkt) + "_" + string(q_b_dvix)
*keep month_id date portfolio_return pid
keep month_id date portfolio_return q_b_mkt q_b_dvix
duplicates drop

*reshape wide portfolio_return, i(date month_id) j(pid) string
save fmb_returns_daily_table_5.dta, replace

*****************************************************/
* MONTHLY valueweighted return
/*****************************************************/
use DATA_CRSP_monthly_1926_2024.dta, clear
keep permno month_id ret market_cap_l1 year

merge 1:1 permno month_id using fmb_portfolio_assignment_table_5.dta
keep if _merge==3
drop _merge

quietly generate return_mcap=ret*market_cap_l1
quietly generate mcap_adjusted=market_cap_l1 if return_mcap!=.

by q_b_mkt q_b_dvix month_id, sort: egen sum_return_mcap=total(return_mcap), missing
by q_b_mkt q_b_dvix month_id, sort: egen sum_mcap=total(mcap_adjusted), missing
generate portfolio_return=sum_return_mcap/sum_mcap

keep portfolio_return month_id year q_b_mkt q_b_dvix
duplicates drop

*reshape wide portfolio_return, i(month_id year) j(ivol_quintile control_quintile)
save fmb_returns_monthly_table_5.dta, replace


/*****************************************************/
use fmb_returns_monthly_table_5.dta, clear

merge m:m month_id using FF3_monthly_1926_2024
keep if _merge!=2 
drop _merge


merge m:m month_id using LIQ_1962-08_2024-12.dta
keep if _merge!=2 
drop _merge
sort date

merge m:1 month_id using DATA_fvix_monthly_1986-2000.dta
keep if _merge==3
drop _merge


gen str_q = string(q_b_mkt, "%1.0f") + string(q_b_dvix, "%1.0f")
gen q = real(str_q)
drop q_b_dvix q_b_mkt str_q

gen ex_ret = portfolio_return - rf

xtset q month_id

* FMB Analysis
bys q: asreg ex_ret mkt fvix smb hml  umd liq
drop _R2 _adjR2
asreg ex_ret _b_mktrf _b_fvix _b_smb _b_hml _b_umd _b_liq, fmb
drop _Nobs 

keep 
duplicates drop
