/*********************************
1986-2000 vxo correlations
*********************************/
clear all
set more off
cd "/Users/eirik/master-v25/STATA/data"

/* Panel B: monthly correlation*/
use DATA_fvix_monthly_1986-2000.dta, clear

merge 1:1 month_id using FF3_monthly_1926_2024.dta
keep if _merge==3 
drop _merge

merge 1:1 month_id using LIQ_1962-08_2024-12.dta
keep if _merge==3 
drop _merge

merge 1:1 month_id using VIX_monthly_1986-01-02_2024-12-31.dta
keep if _merge==3 
drop _merge

keep if month_id >= mofd(mdy(1,1,1986)) & month_id <= mofd(mdy(1,1,2001))

correlate fvix delta_vxo_m mkt smb hml umd liq

matrix C = r(C)
matlist C, format(%5.2f)

save correlation_1986-2000.dta,replace

/*********************************
1990 -2024 vix correlations
*********************************/
* Panel A: daily correlation
use DATA_fvix_1990-2024.dta, clear

merge 1:1 date using VIX_daily_1986-01-02_2024-12-31
keep if _merge==3 
drop _merge

correlate fvix delta_vix

* Panel B: monthly correlation
collapse (mean) fvix delta_vix, by(month_id)
rename fvix fvix_m
rename delta_vix delta_vix_m

merge 1:1 month_id using FF3_monthly_1926_2024.dta
keep if _merge==3 
drop _merge

merge 1:1 month_id using LIQ_1962-08_2024-12.dta
keep if _merge==3 
drop _merge

keep if month_id >= mofd(mdy(1,1,1990)) & month_id <= mofd(mdy(1,1,2025))

correlate fvix_m delta_vix_m mkt smb hml umd liq

matrix C = r(C)
matlist C, format(%5.2f)

save correlation_1990-2024.dta
