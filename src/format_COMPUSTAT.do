*********************************************
* FORMAT Compustat data
*********************************************
clear all
set more off
cd "/Users/eirik/master-v25/STATA/data"

*********************************************
* Generate month_id
*********************************************
use COMPUSTAT_BM_lev_turnover_1970-01-31_2024-12-31, clear

generate month_id=mofd(public_date)
keep permno bm month_id de_ratio at_turn

rename de_ratio lev
rename at_turn turnover
sort permno month_id

save COMPUSTAT_BM_lev_turnover_1970-01-31_2024-12-31.dta, replace
