*********************************************
* FORMAT Fama-French Data
*********************************************
clear all
set more off
cd "/Users/eirik/master-v25/STATA/data"

*********************************************
* Daily FF3 data
*********************************************
use FF3_daily_1926_2024.dta, clear

generate month_id=mofd(date)
label var month_id "numerical date variables; increases each month by 1; Stata mofd() function"
tsset  date

save FF3_daily_1926_2024.dta
