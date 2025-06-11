*********************************************
* FORMAT Liquidity data
*********************************************
clear all
set more off
cd "/Users/eirik/master-v25/STATA/data"

*********************************************
* Monthly LIQ data
*********************************************
use LIQ_1962-08_2024-12.dta, clear

rename DATE date
rename PS_INNOV liq

generate month_id=mofd(date)
keep liq date month_id

save  LIQ_1962-08_2024-12.dta,replace
