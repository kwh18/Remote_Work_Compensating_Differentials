
use acs_clean, clear

sum [aweight=perwt]

* Breakdown Summary Stats by Remote Status
sum if wfh==0 [aweight=perwt]
sum if wfh==1 [aweight=perwt]

sum incwage if wfh==0 [aweight=perwt], d
sum incwage if wfh==1 [aweight=perwt], d

* Graph % remote year by year
graph bar (mean) wfh [pweight=perwt], over(year, label(labsize(small))) title("Remote Work by Year (ACS)") graphregion(fcolor(white)) ylabel("")
graph close

* Graph Median Annual Earnings by remote status by year
gen annual_earnings_wfh_none = incwage if wfh==0
gen annual_earnings_wfh_primary = incwage if wfh==1
graph bar (median) annual_earnings_wfh_none annual_earnings_wfh_primary [pweight=perwt], over(year, label(labsize(small))) title("Median Annual Earnings") legend(order(1 "Not Primarily Remote" 2 "Primarily Remote")) graphregion(fcolor(white))
graph close