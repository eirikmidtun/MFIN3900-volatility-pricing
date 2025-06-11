/**************************************************************
* Calculate monthly idiosyncratic volatility 
**************************************************************/
clear all
set more off
cd "/Users/eirik/master-v25/STATA/data"

/**************************************************************
* Preprosess CRSP daily data
**************************************************************/
use CRSP_daily_1926-01_2024-12, clear

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

merge m:1 date using FF3_daily_1926_2024.dta
keep if _merge==3
drop _merge

replace ret = ret - rf

drop dlret exchcd shrcd prc umd shrout rf
sort permno month_id

/*************************************************************
* Running regression
**************************************************************/
by permno month_id: asreg ret mktrf smb hml, fit
gcollapse (sd) iv = _residuals (sd) vol = ret, by(permno month_id)

label var iv "Idiosyncratic Risk (ff3)"
label var vol "Total volatility"

save DATA_IV_monthly_stocks_1926-2024.dta.dta, replace
