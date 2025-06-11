/**************************************************************
* Calculate monthly b_vix
**************************************************************/
clear all
set more off
cd "/Users/eirik/master-v25/STATA/data"

/**************************************************************
* Preprosess CRSP daily data
**************************************************************/
*ssc install asreg, replace
*ssc install gtools, replace
* --------------------------------------
// DATA LOAD
* turnover size dol_vol
local control_filter = "ba_spread"
use b_d_vxo_value_weighted_returns_daily.dta, clear

merge m:1 date using FF3_daily_1926_2024.dta
keep if _merge==3
drop _merge

merge m:1 date using VIX_daily_1986-01-02_2024-12-31.dta
keep if _merge==3
drop _merge

merge m:1 date using MKT_FACTOR_Daily_1925-12_2024-12.dta
keep if _merge==3
drop _merge

sort ivol_quintile month_id

gen ret = portfolio_return - rf
drop rf 

keep if month_id>=mofd(mdy(1,1,1986)) & month_id < mofd(mdy(1,1,2001))
sort ivol_quintile month_id

by ivol_quintile month_id: asreg ret vwretd smb hml delta_vxo, fit save(betas)

rename _b_vwretd b_mkt
rename _b_delta_vxo b_d_vxo

label var b_mkt "Monthly calculated from: asreg ret vwretd delta_vxo"
label var b_d_vxo "Post formation b_d_vxo Monthly delta vxo calculated from: asreg ret vwretd delta_vxo"

keep b_mkt b_d_vxo month_id ivol_quintile
duplicates drop 
keep if b_d_vxo != .
duplicates list month_id ivol_quintile
save DATA_portfolio_postformation_dvxo_`control_filter'_monthly_stocks_1986-2001.dta, replace

/********************************
beta post formation factors
*********************************/
use DATA_portfolio_postformation_dvxo_`control_filter'_monthly_stocks_1986-2001.dta, clear
collapse (mean) b_d_vxo, by(ivol_quintile)
rename b_d_vxo b_d_vxo_avg_beta_post_formation

save b_d_vxo_`control_filter'_avg_beta_post_formation.dta, replace
replace b_d_vxo_avg_beta_post_formation = b_d_vxo_avg_beta_post_formation*100
