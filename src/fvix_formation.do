clear all
set more off
cd "/Users/eirik/master-v25/STATA/data"

/**************************************************************
* Preprosess CRSP daily data
**************************************************************/
 // DATA LOAD
use b_d_vix_value_weighted_returns_daily.dta,clear
*use b_d_vxo_value_weighted_returns_daily.dta,clear

reshape wide portfolio_return, i(date) j(ivol_quintile)

merge m:1 date using FF3_daily_1926_2024.dta
keep if _merge==3
drop _merge

merge m:1 date using VIX_daily_1986-01-02_2024-12-31.dta
keep if _merge==3
drop _merge

merge m:1 date using MKT_FACTOR_Daily_1925-12_2024-12.dta
keep if _merge==3
drop _merge

sort month_id

/**************************************************************
* Excess return
* NB! In Ang et Als (2006) Table I they scale the FVIX by 100.
* It is not clear to us why this is done, but we replicate it by
* Using returns as percentages in their regression, ie a return 
* with value 0.5 = 0.5% not 50%. 
* Hence we multiply portfolio_return by 100. 
**************************************************************/
replace portfolio_return1 = portfolio_return1*100 - rf*100
replace portfolio_return2 = portfolio_return2*100 - rf*100
replace portfolio_return3 = portfolio_return3*100 - rf*100
replace portfolio_return4 = portfolio_return4*100 - rf*100
replace portfolio_return5 = portfolio_return5*100 - rf*100
drop rf smb hml umd vix	vxo vwretd

/**************************************************************
* Regression daily fvix
**************************************************************/
keep if month_id>=mofd(mdy(1,1,1990)) & month_id < mofd(mdy(1,1,2025))
by month_id: asreg delta_vxo portfolio_return1 portfolio_return2 portfolio_return3 portfolio_return4 portfolio_return5

save DATA_fvix_betas_1990-2024.dta, replace

gen fvix = _b_portfolio_return1 * portfolio_return1 + ///
           _b_portfolio_return2 * portfolio_return2 + ///
           _b_portfolio_return3 * portfolio_return3 + ///
           _b_portfolio_return4 * portfolio_return4 + ///
           _b_portfolio_return5 * portfolio_return5

sum fvix if month_id>400 & month_id <412
sum fvix delta_vix
save DATA_fvix_daily_1990-2024.dta,replace

/**************************************************************
* Aggregate to monthly
**************************************************************/
collapse (mean) fvix (mean) delta_vix, by(month_id)
sum fvix 
save DATA_fvix_monthly_1990-2024.dta,replace



/**************************************************************
* Another Aggregation method used
* Here the returns are aggregated per portfolio
* Preprosess CRSP monthly data

// DATA LOAD
use DATA_fvix_betas_1986-2000.dta,clear
*use DATA_fvix_daily_1990-2020.dta, clear

keep _b_portfolio_return* month_id
duplicates drop
drop if _b_portfolio_return1==.

merge 1:1 month_id using b_d_vix_value_weighted_returns_monthly.dta
keep if _merge==3
drop _merge

merge 1:1 month_id using FF3_monthly_1926_2024.dta
keep if _merge==3
drop _merge

*excess return
replace portfolio_return1 = portfolio_return1*100 - rf*100
replace portfolio_return2 = portfolio_return2*100 - rf*100
replace portfolio_return3 = portfolio_return3*100 - rf*100
replace portfolio_return4 = portfolio_return4*100 - rf*100
replace portfolio_return5 = portfolio_return5*100 - rf*100

gen fvix = _b_portfolio_return1 * portfolio_return1 + ///
           _b_portfolio_return2 * portfolio_return2 + ///
           _b_portfolio_return3 * portfolio_return3 + ///
           _b_portfolio_return4 * portfolio_return4 + ///
           _b_portfolio_return5 * portfolio_return5


keep month_id fvix
save DATA_fvix_monthly_1986-2000.dta,replace
sum fvix
**************************************************************/
