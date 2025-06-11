*********************************************
* FORMAT Vix data
*********************************************
clear all
set more off
cd "/Users/eirik/master-v25/STATA/data"

*********************************************
* VIX Daily data
*********************************************
use VIX_daily_1986-01-02_2024-12-31.dta,clear
*rename Date date

tsset date
gen delta_vix = vix - vix[_n-1]
gen delta_vxo = vxo - vxo[_n-1]

label var delta_vix "S&P500 change in vix per day"
label var delta_vxo "S&P100 change in vxo per day"
save VIX_daily_1986-01-02_2024-12-31.dta

*********************************************
* VIX Monthly data
*********************************************
use VIX_daily_1986-01-02_2024-12-31.dta,clear
gen month_id = mofd(date)
gen byte first_in_month = 0
bysort month_id (date): replace first_in_month = 1 if _n == _N
keep if first_in_month==1

gen delta_vix_m = vix - vix[_n-1]
gen delta_vxo_m = vxo - vxo[_n-1]
replace month_id = month_id

keep date month_id vix delta_vix_m delta_vxo_m
order date month_id vix delta_vix_m delta_vxo_m 

save VIX_monthly_1986-01-02_2024-12-31.dta,replace
