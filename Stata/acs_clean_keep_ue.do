use acs_dirty, clear

* Keep only 2006 and on
drop if year<2006

* drop duplicates
order serial pernum year
sort serial pernum year
by serial pernum year: gen dup = cond(_N==1,0,_n)
tab dup
drop if dup>0
drop dup

* Set panel and time vars
egen person_id = group(serial pernum)
order person_id year
sort person_id year

xtset person_id year

* Keep only prime age workers
keep if inrange(age,25,55)

* Keeping employed and unemployed, but only those in Labor Force and who worked last year
keep if empstat==1 | empstat==2
keep if workedyr==3

gen emp_status = 2 - empstat

* Keeping only living and working in 50 states & DC
drop if pwstate2==0 | pwstate2>56

* Dropping wage income outliers
sort year
by year: sum incwage, detail
by year: keep if inrange(incwage,r(p1),r(p99))

* Dropping unneccesary vars
drop sample cbserial numprec hhwt cluster strata gq educ empstat empstatd labforce occsoc indnaics workedyr vetstatd pwstate1

* Generate various needed vars
gen age_sq = age^2
gen wfh = (tranwork==80)

* Reordering Variables
order person_id year perwt incwage wfh statefip
sort person_id year

* Aggregating Industry Codes
gen ind_agg = .
replace ind_agg = 1 if inrange(ind,170,290)
replace ind_agg = 2 if inrange(ind,370,490)
replace ind_agg = 3 if ind==770
replace ind_agg = 4 if inrange(ind,1070,3990)
replace ind_agg = 5 if inrange(ind,4070,4590)
replace ind_agg = 6 if inrange(ind,4670,5790)
replace ind_agg = 7 if inrange(ind,6070,6390)
replace ind_agg = 8 if inrange(ind,570,690)
replace ind_agg = 9 if inrange(ind,6470,6780)
replace ind_agg = 10 if inrange(ind,6870,6992)
replace ind_agg = 11 if inrange(ind,7071,7190)
replace ind_agg = 12 if inrange(ind,7270,7490)
replace ind_agg = 13 if ind==7570
replace ind_agg = 14 if inrange(ind,7580,7790)
replace ind_agg = 15 if inrange(ind,7860,7890)
replace ind_agg = 16 if inrange(ind,7970,8470)
replace ind_agg = 17 if inrange(ind,8561,8590)
replace ind_agg = 18 if inrange(ind,8660,8690)
replace ind_agg = 19 if inrange(ind,8770,9290)
replace ind_agg = 20 if inrange(ind,9370,9590)
replace ind_agg = 21 if inrange(ind,9670,9890)
drop if ind_agg == 21

label define ind_agg_lbl 1 `"Agriculture, Forestry, Fishing, and Hunting"'
label define ind_agg_lbl 2 `"Mining, Quarrying, and Oil and Gas Extraction"', add
label define ind_agg_lbl 3 `"Construction"', add
label define ind_agg_lbl 4 `"Manufacturing"', add
label define ind_agg_lbl 5 `"Wholesale Trade"', add
label define ind_agg_lbl 6 `"Retail Trade"', add
label define ind_agg_lbl 7 `"Transportation and Warehousing"', add
label define ind_agg_lbl 8 `"Utilities"', add
label define ind_agg_lbl 9 `"Information"', add
label define ind_agg_lbl 10 `"Finance and Insurance"', add
label define ind_agg_lbl 11 `"Real Estate and Rental and Leasing"', add
label define ind_agg_lbl 12 `"Professional, Scientific, and Technical Services"', add
label define ind_agg_lbl 13 `"Management of companies and enterprises"', add
label define ind_agg_lbl 14 `"Administrative and support and waste management services"', add
label define ind_agg_lbl 15 `"Educational Services"', add
label define ind_agg_lbl 16 `"Health Care and Social Assistance"', add
label define ind_agg_lbl 17 `"Arts, Entertainment, and Recreation"', add
label define ind_agg_lbl 18 `"Accommodation and Food Services"', add
label define ind_agg_lbl 19 `"Other Services, Except Public Administration"', add
label define ind_agg_lbl 20 `"Public Administration"', add
label values ind_agg ind_agg_lbl

* Aggregating Occupation Codes
gen occ_agg = .
gen DN_class_agg = 0
replace occ_agg = 1 if inrange(occ,10,440)
replace occ_agg = 2 if inrange(occ,500,960)
replace occ_agg = 3 if inrange(occ,1005,1240)
replace occ_agg = 4 if inrange(occ,1305,1560)
replace occ_agg = 5 if inrange(occ,1600,1980)
replace occ_agg = 6 if inrange(occ,2001,2060)
replace occ_agg = 7 if inrange(occ,2100,2180)
replace occ_agg = 8 if inrange(occ,2205,2555)
replace occ_agg = 9 if inrange(occ,2600,2970)
replace occ_agg = 10 if inrange(occ,3000,3550)
replace occ_agg = 11 if inrange(occ,3601,3655)
replace occ_agg = 12 if inrange(occ,3700,3960)
replace occ_agg = 13 if inrange(occ,4000,4160)
replace occ_agg = 14 if inrange(occ,4200,4255)
replace occ_agg = 15 if inrange(occ,4330,4655)
replace occ_agg = 16 if inrange(occ,4700,4965)
replace occ_agg = 17 if inrange(occ,5000,5940)
replace occ_agg = 18 if inrange(occ,6005,6130)
replace occ_agg = 19 if inrange(occ,6200,6950)
replace occ_agg = 20 if inrange(occ,7000,7640)
replace occ_agg = 21 if inrange(occ,7700,8990)
replace occ_agg = 22 if inrange(occ,9005,9430)
replace occ_agg = 23 if inrange(occ,9510,9760)
replace occ_agg = 24 if inrange(occ,9800,9840)
drop if occ_agg == 24

label define occ_agg_lbl 1 `"Management"'
replace DN_class_agg = 0.87 if occ_agg==1
label define occ_agg_lbl 2 `"Business and Financial Operations"', add
replace DN_class_agg = 0.88 if occ_agg==2
label define occ_agg_lbl 3 `"Computer and Mathematical"', add
replace DN_class_agg = 1 if occ_agg==3
label define occ_agg_lbl 4 `"Architecture and Engineering"', add
replace DN_class_agg = 0.61 if occ_agg==4
label define occ_agg_lbl 5 `"Life, Physical, and Social Science"', add
replace DN_class_agg = 0.54 if occ_agg==5
label define occ_agg_lbl 6 `"Community and Social Service"', add
replace DN_class_agg = 0.37 if occ_agg==6
label define occ_agg_lbl 7 `"Legal"', add
replace DN_class_agg = 0.97 if occ_agg==7
label define occ_agg_lbl 8 `"Educational Instruction, and Library"', add
replace DN_class_agg = 0.98 if occ_agg==8
label define occ_agg_lbl 9 `"Arts, Design, Entertainment, Sports, and Media"', add
replace DN_class_agg = 0.76 if occ_agg==9
label define occ_agg_lbl 10 `"Healthcare Practitioners and Technical"', add
replace DN_class_agg = 0.05 if occ_agg==10
label define occ_agg_lbl 11 `"Healthcare Support"', add
replace DN_class_agg = 0.02 if occ_agg==11
label define occ_agg_lbl 12 `"Protective Service"', add
replace DN_class_agg = 0.06 if occ_agg==12
label define occ_agg_lbl 13 `"Food Preparation and Serving Related"', add
label define occ_agg_lbl 14 `"Building and Grounds Cleaning and Maintenance"', add
label define occ_agg_lbl 15 `"Personal Care and Service"', add
replace DN_class_agg = 0.26 if occ_agg==15
label define occ_agg_lbl 16 `"Sales and Related"', add
replace DN_class_agg = 0.28 if occ_agg==16
label define occ_agg_lbl 17 `"Office and Administrative Support"', add
replace DN_class_agg = 0.65 if occ_agg==17
label define occ_agg_lbl 18 `"Farming, Fishing, and Forestry"', add
replace DN_class_agg = 0.01 if occ_agg==18
label define occ_agg_lbl 19 `"Construction and Extraction"', add
label define occ_agg_lbl 20 `"Installation, Maintenance, and Repair"', add
replace DN_class_agg = 0.01 if occ_agg==20
label define occ_agg_lbl 21 `"Production"', add
replace DN_class_agg = 0.01 if occ_agg==21
label define occ_agg_lbl 22 `"Transportation"', add
replace DN_class_agg = 0.03 if occ_agg==22
label define occ_agg_lbl 23 `"Material Moving"', add
replace DN_class_agg = 0.03 if occ_agg==23
label values occ_agg occ_agg_lbl

statastates, fips(statefip)
drop state_name _merge
rename state_abbrev state

save acs_clean_keep_ue, replace