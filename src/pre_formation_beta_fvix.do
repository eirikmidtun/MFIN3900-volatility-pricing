/**************************************************************
* Calculate monthly beta fvix
**************************************************************/
clear all
set more off
cd "/Users/eirik/master-v25/STATA/data"

/**************************************************************
* Preprosess CRSP daily data
**************************************************************/
// DATA LOAD
use CRSP_daily_1926-01_2024-12, clear
keep if month_id>=mofd(mdy(1,1,1986)) & month_id < mofd(mdy(1,1,2001))

* lower case vaiable names
rename PERMNO permno
rename SHRCD shrcd
rename EXCHCD exchcd
rename DLRET dlret
rename PRC prc
rename RET ret
rename SHROUT shrout

generate month_id=mofd(date)
label var month_id "for human readeable use: format month_id %tm"

* Ordinary U.S. stocks on NYSE, NASDAQ and NYSE American
keep if shrcd==10 | shrcd==11
keep if exchcd==1 | exchcd==2 | exchcd==3

* Use compounded delisting returns
replace ret = . if ret > .
replace dlret = . if dlret > .
replace ret=(1+ret)*(1+dlret)-1 if dlret!=.
replace ret=dlret if ret==. & dlret!=.

/**************************************************************
* Merging datasets
**************************************************************/
merge m:1 date using FF3_daily_1926_2024.dta
keep if _merge==3
drop _merge

merge m:1 date using DATA_fvix_daily_1986-2000.dta
*merge m:1 date using DATA_fvix_daily_1990-2024.dta
keep if _merge==3
drop _merge

merge m:1 date using MKT_FACTOR_Daily_1925-12_2024-12.dta
keep if _merge==3
drop _merge

drop dlret smb hml shrout exchcd shrcd prc umd shrout 
sort permno month_id

replace ret = ret - rf
drop rf 

*********************************************
* Running regression
*********************************************
keep if month_id>=mofd(mdy(1,1,1986)) & month_id < mofd(mdy(1,1,2001))

replace fvix = fvix/100

by permno month_id: asreg ret vwretd fvix, fit save(betas)

rename _b_vwretd b_mkt
rename _b_fvix b_fvix

label var b_mkt "Monthly calculated from: asreg ret vwretd fvix"
label var b_fvix "Monthly delta fvix calculated from: asreg ret vwretd fvix"

keep b_mkt b_fvix month_id permno
duplicates drop 
keep if b_fvix != .
duplicates list month_id permno
save DATA_b_fvix_monthly_stocks_1986-2000.dta, replace
*save DATA_b_fvix_monthly_stocks_1990-2024.dta, replace
