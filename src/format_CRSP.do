*********************************************
* FORMAT CRSP Data
*********************************************
clear all
set more off
cd "/Users/eirik/master-v25/STATA/data"

*********************************************
* FORMAT Monthly CRSP Data
*********************************************
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
generate market_cap_l1=l1.market_cap
label var market_cap "Market cap [million USD] at end of current month"
label var market_cap_l1 "Market cap [million USD] at end of previous month"

save DATA_CRSP_monthly_1926_2024.dta, replace

*********************************************
* FORMAT Daily CRSP Data
*********************************************
use CRSP_daily_1926-01_2024-12.dta, clear

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
label var month_id "numerical date variables; increases each month by 1; Stata mofd() function. Human readable: format month_id %tm"

keep if shrcd==10 | shrcd==11
keep if exchcd==1 | exchcd==2 | exchcd==3 

sort permno date
xtset permno date

generate market_cap=abs(prc)*shrout/1000
gen market_cap_l1= .
by permno (date): replace market_cap_l1 = market_cap[_n-1]
label var market_cap "Market cap [million USD] at end of current day"
label var market_cap_l1 "Market cap [million USD] at end of previous day"

drop dlret
save DATA_CRSP_daily_1926-01_2024-12.dta, replace
