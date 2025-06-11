clear all
set more off
cd "/Users/eirik/master-v25/STATA/data"

* replication
do "/Users/eirik/master-v25/STATA/do-files/Table_4_1986-2000_ba-spread.do"
do "/Users/eirik/master-v25/STATA/do-files/Table_4_1986-2000_bm.do"
do "/Users/eirik/master-v25/STATA/do-files/Table_4_1986-2000_dol_vol.do"
do "/Users/eirik/master-v25/STATA/do-files/Table_4_1986-2000_lev.do"
do "/Users/eirik/master-v25/STATA/do-files/Table_4_1986-2000_size.do"
do "/Users/eirik/master-v25/STATA/do-files/Table_4_1986-2000_turnover.do"

* extension
do "/Users/eirik/master-v25/STATA/do-files/Table_4_1990-2024_ba-spread.do"
do "/Users/eirik/master-v25/STATA/do-files/Table_4_1990-2024_bm.do"
do "/Users/eirik/master-v25/STATA/do-files/Table_4_1990-2024_dol_vol.do"
do "/Users/eirik/master-v25/STATA/do-files/Table_4_1990-2024_lev.do"
do "/Users/eirik/master-v25/STATA/do-files/Table_4_1990-2024_SIZE.do"
do "/Users/eirik/master-v25/STATA/do-files/Table_4_1990-2024_turnover.do"
