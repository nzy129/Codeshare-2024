/*
 Codeshare Alliance between JetBlue and American Airlines written by Zheyu Ni 
at The Ohio State University, 3/7/2024
This file estimates the impact of NEA on price dispersion.
*/
///////////////////////////////////////////////////////////////////////////////
/// import the data, cleaned in Python

clear all
import delimited "E:\Research\Codeshare JetBlue AA\pythonProject3\Cleaned_2019_2023_without_delete_small_market_dispersion.csv"

/// rename the columns
rename v8 MktFare_v
rename v9 MktFare_q1
rename v10 MktFare_q9

/// delete the first row
gen row_i = _n
drop if row_i==1
drop row_i

/// start analysis!

destring mktfare, replace
destring MktFare_v, replace
destring MktFare_q1 MktFare_q9, replace
destring roundtrip mktdistance nonstop passengers, replace


/// a mistake in the cleaned file where nea_market_codeshared = nea_market
egen nea_market2 = total(nea_market_codeshared), by(market)
replace nea_market = nea_market2
drop nea_market2

///drop if MktFare_v==0
///drop if MktFare_q1~=0
///drop if MktFare_q9==0
/// delete covid period 
drop if year==2020 |year ==2021 |(year==2022 & quarter ==1)

gen zerosta = MktFare_q1==0
sum zerosta
drop zerosta  // around 19% market only have one flight. 


sum mktfare MktFare_v MktFare_q1 MktFare_q9 nea_market

gen dt = yq(year, quarter)
gen mktdistance2 = mktdistance^2
gen lnMktFare_q1 = ln(MktFare_q1)
gen lnMktFare_q9 = ln(MktFare_q9)

gen MktFare_sd=sqrt(MktFare_v)
gen mktdistance100 = mktdistance/100
gen mktdistance1002=mktdistance100^2

reg MktFare_sd roundtrip nonstop mktdistance100 mktdistance1002 ///
nea_market nea_market_codeshared i.dt [aweight = passengers]
est sto reg1_v

reg lnMktFare_q1 roundtrip nonstop mktdistance100 mktdistance1002 ///
nea_market nea_market_codeshared i.dt [aweight = passengers]
est sto reg1_q1

reg lnMktFare_q9 roundtrip nonstop mktdistance100 mktdistance1002 ///
nea_market nea_market_codeshared i.dt [aweight = passengers]
est sto reg1_q9

drop if total_quantity <1000
egen newidd = group(market)
set matsize 4200
reg MktFare_sd roundtrip nonstop mktdistance100 mktdistance1002 ///
 nea_market_codeshared i.newidd [aweight = passengers]
est sto reg1_v_market_fixed

estout reg1_v reg1_q1 reg1_q9 using result333.xls, cells("b" se)  replace
estout reg1_v_market_fixed  using result333_fixed.xls, cells("b" se)  replace
/// market fixed effects

reg lnMktFare_q9 roundtrip nonstop mktdistance mktdistance2 ///
nea_market nea_market_codeshared i.dt [aweight = passengers]

///////////////////////////////////////////////////////////////////////////////
/// import the data, cleaned in Python

clear all
import delimited "F:\Codeshare JetBlue AA\pythonProject3\Cleaned_2019_2023_without_delete_small_market314_carrier_route.csv"
/// carrier route level
/// rename the columns
rename v12 MktFare_v
rename v13 q1
rename v14 q05
rename v15 q10
rename v16 q15
rename v17 q20
rename v18 q25
rename v19 q30
rename v20 q35
rename v21 q45
rename v22 q50
rename v23 q55
rename v24 q60
rename v25 q65
rename v26 q70
rename v27 q75
rename v28 q80
rename v29 q85
rename v30 q90
rename v31 q99


/// delete the first row
gen row_i = _n
drop if row_i==1
drop row_i


destring mktfare, replace
destring MktFare_v, replace
destring q1 q05 q10 q15 q20 q25 q30 q35 q45 q50 q55 q60 q65 q70 q75 q80 q85 q90 q99, replace
destring roundtrip mktdistance nonstop passengers, replace
egen nea_market = total(nea_market_codeshared), by(market)

save "F:\Codeshare JetBlue AA\pythonProject3\Codeshare_stata_314.dta", replace

clear all
use "F:\Codeshare JetBlue AA\pythonProject3\Codeshare_stata_314.dta"

foreach x in "WN" "AA" "DL" "UA" "NK" "AS" "B6" "F9" "G4" "HA" "SY" "XP" "MX" "MM" {
gen `x' = strpos(ticketcarrier, "`x'")>0
}

/// delete covid period 
drop if year==2020 |year ==2021 |(year==2022 & quarter ==1)

gen dt = yq(year, quarter)
gen MktFare_sd=sqrt(MktFare_v)
gen mktdistance100 = mktdistance/100
gen mktdistance1002=mktdistance100^2



reg MktFare_sd roundtrip nonstop mktdistance100 mktdistance1002 ///
nea_market nea_market_codeshared i.dt WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM[aweight = passengers] 
est sto reg1_v

gen lnq1= ln(q1)
gen lnq05= ln(q05)
gen lnq10= ln(q10)
gen lnq15= ln(q15)
gen lnq20= ln(q20)
gen lnq25= ln(q25)
gen lnq30= ln(q30)
gen lnq35= ln(q35)
gen lnq45= ln(q45)
gen lnq50= ln(q50)
gen lnq55= ln(q55)
gen lnq60= ln(q60)
gen lnq65= ln(q65)
gen lnq70= ln(q70)
gen lnq75= ln(q75)
gen lnq80= ln(q80)
gen lnq85= ln(q85)
gen lnq90= ln(q90)
gen lnq95= ln(q95)
gen lnq99= ln(q99)

gen lnmktfare = ln(mktfare)

gen nea_market_codeshared_b6 = nea_market_codeshared* B6
gen nea_market_codeshared_aa = nea_market_codeshared* AA
/// i missed nonstop,  i need to recompute it from python
reg  lnmktfare roundtrip mktdistance100 mktdistance1002 nea_market ///
 nea_market_codeshared   ///
 i.dt WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM[aweight = passengers] 
est sto q1

///
reg  lnq05 roundtrip online_new mktdistance100 mktdistance1002 nea_market ///
 nea_market_codeshared  nea_market_codeshared_b6 nea_market_codeshared_aa ///
 i.dt WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM[aweight = passengers] 
est sto q1

local dependent_vars lnq1 lnq05 lnq10 lnq15 lnq20 lnq25 lnq30 lnq35 lnq45 ///
lnq50 lnq55 lnq60 lnq65 lnq70 lnq75 lnq80 lnq85 lnq90 lnq99

local dependent_vars q1 q05 q10 q15 q20 q25 q30 q35 q45 ///
q50 q55 q60 q65 q70 q75 q80 q85 q90 q99
foreach var of local dependent_vars {
    * Run the regression model
    quietly reg ln`var' mktfare roundtrip mktdistance100 mktdistance1002 ///
nea_market nea_market_codeshared i.dt WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM[aweight = passengers]
    * Store the estimation results
    est store `var'
}

/*
coefplot lnq1 || lnq05 || lnq10 || lnq15 || lnq20 || lnq25 || lnq30 || lnq35 ||  lnq45  || ///
 lnq50 || lnq55 || lnq60 || lnq65 || lnq70 || lnq75 || lnq80 || lnq85 || lnq90 || lnq99 ///
, keep(nea_market_codeshared) vertical bycoefs ytitle("Impact of NEA Codeshare") ///
xtitle("Selected Percentiles") ///
recast(connected)  ciopts(recast(rarea) color(gs14) lpattern(dash)) ///
*/

coefplot q1 || q05 || q10 || q15 || q20 || q25 || q30 || q35 || q45 || ///
 q50 || q55 || q60 || q65 || q70 || q75 || q80 || q85 || q90 || q99, ///
 keep(nea_market_codeshared) vertical bycoefs ytitle("Impact of NEA Codeshare") ///
xtitle("Selected Percentiles") ///
recast(connected)  ciopts(recast(rarea) color(gs14) lpattern(dash)) ///
graphregion(color(none)) plotregion(color(none))
