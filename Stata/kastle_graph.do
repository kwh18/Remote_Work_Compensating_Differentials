
use kastle_back_to_work, clear

label var top10_city_avg "Top 10 City Avg"
label var austin "Austin"
label var san_jose "San Jose"

gen date2 = date(date, "MDY")
drop date
rename date2 date
drop if missing(date)
format date %td
label var date "Date"
tsset date

destring top10_city_avg austin san_jose, replace
replace top10_city_avg = top10_city_avg/100
replace austin = austin/100
replace san_jose = san_jose/100

graph twoway tsline top10_city_avg austin san_jose, title("Kastle Back to Work Barometer") ytitle("") tlabel(01jan2020 01jan2021 01jan2022 01jan2023, format(%tdMon_CCYY) ) note("{stSerif:{it:Notes}. Historical Chart for Kastle Back to Work Barometer 2/12/20 to 3/1/23, Bloomberg March 2023.}", margin(small))  graphregion(fcolor(white))

*graph close