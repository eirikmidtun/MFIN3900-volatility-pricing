*********************************************
* FORMAT VOL data
*********************************************
clear all
set more off
cd "/Users/eirik/master-v25/STATA/data"

*********************************************
* Monthly vol data
* dol_vol = Trading volume month * closing price final day of month
*********************************************
use CRSP_with_vol_monthly_1926_2024.dta, clear

generate month_id=mofd(date)
label var month_id "Numerical date variables; increases each month by 1; Stata mofd() function. Human readable: format month_id %tm"

gen dol_vol = VOL*abs(PRC)
label var dol_vol "Total dollar volume per month."
keep if dol_vol>0 & dol_vol!=.

rename VOL vol
rename PERMNO permno
keep date permno month_id vol dol_vol

save  vol_monthly_1926_2024.dta,replace
