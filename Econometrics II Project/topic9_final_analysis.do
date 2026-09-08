*******************************************************
* Topic 9 
* Oil price volatility, industrial production growth,
* and S&P 500 returns in the US
*******************************************************

clear all
set more off

* outputs to be saved
global outdir "C:\Users\hello\OneDrive\Desktop\Econ2checking"
cd "$outdir"

capture log close

log using "$outdir\topic9_final_log.txt", text replace

*******************************************************
* 1) Loading final analysis data
*******************************************************
use "C:\Users\hello\OneDrive\Desktop\Econometrics 2 data sets\topic9_analysis_data_mominfl.dta", clear
tsset mdate, monthly

*******************************************************
* 2) Full-sample 4-variable VAR
*    ovx_level ip_growth infl_mom sp500_ret
*******************************************************
display "===== FULL-SAMPLE 4-VARIABLE VAR ====="

varsoc ovx_level ip_growth infl_mom sp500_ret, maxlag(12)

var ovx_level ip_growth infl_mom sp500_ret, lags(1/2)
display "----- FULL-SAMPLE 4-VARIABLE VAR(2): varstable -----"
varstable
display "----- FULL-SAMPLE 4-VARIABLE VAR(2): varlmar -----"
varlmar

var ovx_level ip_growth infl_mom sp500_ret, lags(1/4)
display "----- FULL-SAMPLE 4-VARIABLE VAR(4): varstable -----"
varstable
display "----- FULL-SAMPLE 4-VARIABLE VAR(4): varlmar -----"
varlmar

*******************************************************
* 3) Post-2010 4-variable VAR
*******************************************************
use "C:\Users\hello\OneDrive\Desktop\Econometrics 2 data sets\topic9_analysis_data_mominfl.dta", clear
tsset mdate, monthly
keep if mdate >= tm(2010m1)

display "===== POST-2010 4-VARIABLE VAR ====="

varsoc ovx_level ip_growth infl_mom sp500_ret, maxlag(12)

var ovx_level ip_growth infl_mom sp500_ret, lags(1/2)
display "----- POST-2010 4-VARIABLE VAR(2): varstable -----"
varstable
display "----- POST-2010 4-VARIABLE VAR(2): varlmar -----"
varlmar

var ovx_level ip_growth infl_mom sp500_ret, lags(1/4)
display "----- POST-2010 4-VARIABLE VAR(4): varstable -----"
varstable
display "----- POST-2010 4-VARIABLE VAR(4): varlmar -----"
varlmar

*******************************************************
* 4) Post-2010 3-variable VAR (final baseline choice)
*******************************************************
use "C:\Users\hello\OneDrive\Desktop\Econometrics 2 data sets\topic9_analysis_data_mominfl.dta", clear
tsset mdate, monthly
keep if mdate >= tm(2010m1)

display "===== POST-2010 3-VARIABLE VAR ====="

varsoc ovx_level ip_growth sp500_ret, maxlag(12)

var ovx_level ip_growth sp500_ret, lags(1/2)
estimates store final_var2
display "----- POST-2010 3-VARIABLE VAR(2): varstable -----"
varstable
display "----- POST-2010 3-VARIABLE VAR(2): varlmar -----"
varlmar

var ovx_level ip_growth sp500_ret, lags(1/4)
display "----- POST-2010 3-VARIABLE VAR(4): varstable -----"
varstable
display "----- POST-2010 3-VARIABLE VAR(4): varlmar -----"
varlmar

*******************************************************
* 5) Re-estimate=ing final baseline for IRFs and FEVD
*******************************************************
use "C:\Users\hello\OneDrive\Desktop\Econometrics 2 data sets\topic9_analysis_data_mominfl.dta", clear
tsset mdate, monthly
keep if mdate >= tm(2010m1)

var ovx_level ip_growth sp500_ret, lags(1/2)

* baseline ordering: ovx_level -> ip_growth -> sp500_ret
irf set topic9_var3_post2010_baseline, replace
irf create baseline_order, step(12) replace

irf graph oirf, impulse(ovx_level) response(ip_growth sp500_ret) name(g1, replace)
graph export "$outdir\irf_baseline_order.png", replace

irf graph fevd, impulse(ovx_level) response(ip_growth sp500_ret) name(g2, replace)
graph export "$outdir\fevd_baseline_order.png", replace

*******************************************************
* 6) Reverse-ordering robustness check
*    sp500_ret -> ip_growth -> ovx_level
*******************************************************
var sp500_ret ip_growth ovx_level, lags(1/2)

display "===== REVERSE ORDERING CHECK ====="
display "----- REVERSE ORDERING: varstable -----"
varstable
display "----- REVERSE ORDERING: varlmar -----"
varlmar

irf set topic9_var3_post2010_reverse, replace
irf create reverse_order, step(12) replace

irf graph oirf, impulse(ovx_level) response(ip_growth sp500_ret) name(g3, replace)
graph export "$outdir\irf_reverse_order.png", replace

irf graph fevd, impulse(ovx_level) response(ip_growth sp500_ret) name(g4, replace)
graph export "$outdir\fevd_reverse_order.png", replace

*******************************************************
* 7) Recursive SVAR extension
*******************************************************
use "C:\Users\hello\OneDrive\Desktop\Econometrics 2 data sets\topic9_analysis_data_mominfl.dta", clear
tsset mdate, monthly
keep if mdate >= tm(2010m1)

matrix A = (1,0,0 \ .,1,0 \ .,.,1)

svar ovx_level ip_growth sp500_ret, lags(1/2) aeq(A)

irf set topic9_svar3_post2010, replace
irf create svar3_post2010, step(12) replace

irf graph sirf, impulse(ovx_level) response(ip_growth sp500_ret) name(g5, replace)
graph export "$outdir\irf_structural_svar.png", replace

*******************************************************
* 8) A few simple summaries for the report
*******************************************************
use "C:\Users\hello\OneDrive\Desktop\Econometrics 2 data sets\topic9_analysis_data_mominfl.dta", clear
tsset mdate, monthly
keep if mdate >= tm(2010m1)

display "===== SUMMARY STATS: POST-2010 FINAL VARIABLES ====="
summarize ovx_level ip_growth sp500_ret

display "===== SAMPLE WINDOW ====="
summarize mdate

log close