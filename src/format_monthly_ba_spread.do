*********************************************
* FORMAT Monthly Bid ASk Spread
*********************************************
clear all
set more off
cd "/Users/eirik/master-v25/STATA/data"

*********************************************
* Monthly Bid Ask data
*********************************************
use CRSP_with_bid_ask_1926_2024, clear

* lower case vaiable names
rename PERMNO permno
rename EXCHCD exchcd
rename BID bid
rename ASK ask

generate month_id=mofd(date)
label var month_id "for human readeable use: format month_id %tm"

gen ba_spread = ask - bid
collapse (mean) ba_spread, by(permno month_id)

label var ba_spread "Bid ask spread monthly average per stock."
replace ba_spread = 0 if missing(ba_spread)
xtset permno month_id

save DATA_monthly_bid_ask_1926_2024.dta,replace
