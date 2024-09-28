********************************************************************************
/*
Codeshare Alliance between JetBlue and American Airlines written by Zheyu Ni, 7/28/2024
This file estimates the impact of NEA at the route level.
*/
********************************************************************************
set more off
********************************************************************************
**# Import the data from F drive
********************************************************************************
cd "F:\Codeshare JetBlue AA\pythonProject3\Data7172024"
cap confirm file "cleaned717_all.dta"

if _rc {
di "process quarterly files"

forvalues y = 2019/2024 {
	forvalues m = 1/4{
	
		if (`y'==2024 & `m'>1) continue
		// Skip quarters for 2024Q2, Q3, Q4
		import delimited "Cleaned717_`y'_`m'.csv", clear

		* drop the first row
		drop if _n==1

		* v36 is the market distance, which is already defined. 
		cap drop v36

		* rename the variables
		rename (v15 v16 v17 v18 v19 v20 v21 v22 v23 v24 v25 v26 v27 v28 v29 v30 v31 v32 v33 v34 v35) ///
		 (MktFare_v q01 q05 q10 q15 q20 q25 q30 q35 q40 q45 q50 q55 q60 q65 q70 q75 q80 q85 q90 q99)

		destring mktfare MktFare_v q* passengers, replace

		gen dt = yq(year, quarter)

		gen MktFare_sd=sqrt(MktFare_v)

		gen mktdistance100 = mktdistance/100
		gen mktdistance1002 = mktdistance100^2
		gen incon = mktdistance/nonstopmiles

		save "Cleaned717_`y'_`m'.dta", replace
	}
}

** append quarterly data
use "Cleaned717_2024_1.dta", clear

forvalues y = 2019/2023 {
	forvalues m = 1/4{
		append using "Cleaned717_`y'_`m'.dta"
	}
}

*reduce file size
compress
save "cleaned717_all.dta"
}

********************************************************************************
**# Generate variables
********************************************************************************
* load data
use "cleaned717_all.dta", clear


foreach x in "WN" "AA" "DL" "UA" "NK" "AS" "B6" "F9" "G4" "HA" "SY" "XP" "MX" "MM" {
gen byte `x' = strpos(tkcarriergroup, "`x'")>0
}

* nonstop flight

gen n_airpots = length(airportgroup) - length(subinstr(airportgroup, ":", "", .)) + 1
gen byte nonstop = n_airpots ==2

tab mktcoupons 

drop if mktcoupons>4
* Four types of Flight, pure online, interline, traditional codeshare and virtual codeshare

*interline
gen byte interline =  (tkcarriergroup == opcarriergroup) & online_new ==0

split opcarriergroup, parse(":") gen(opcarriers)

gen num_op_carriers = 3-missing(opcarriers1)-missing(opcarriers2)-missing(opcarriers3)
split tkcarriergroup, parse(":") gen(tkcarriers)
gen num_tk_carriers = 3-missing(tkcarriers1)-missing(tkcarriers2)-missing(tkcarriers3)

*traditional codeshare
gen byte t_codeshare = 0
replace t_codeshare = 1 if num_op_carriers==2 & opcarriers1 ~= opcarriers2 & tkcarriers1 == tkcarriers2
replace t_codeshare = 1 if num_op_carriers==3 & opcarriers1 ~= opcarriers2 & tkcarriers1 == tkcarriers2
replace t_codeshare = 1 if num_op_carriers==3 & opcarriers2 ~= opcarriers3 & tkcarriers2 == tkcarriers3
replace t_codeshare = 1 if num_op_carriers==3 & opcarriers1 ~= opcarriers3 & tkcarriers1 == tkcarriers3

*virtual codeshare 
gen byte v_codeshare = 0
replace v_codeshare = 1 if num_op_carriers==1 & opcarriers1 ~= tkcarriers1 
replace v_codeshare = 1 if num_op_carriers==2 & opcarriers1 == opcarriers2 & tkcarriers1 == opcarriers2 & tkcarriers1~= opcarriers1
replace v_codeshare = 1 if num_op_carriers==3 & opcarriers1 == opcarriers2 & opcarriers1 == opcarriers3 ///
 & tkcarriers1~= opcarriers1 & opcarriers1== opcarriers2 & opcarriers2== opcarriers3

* pure online 
gen byte pure_online = online_new==1 & v_codeshare==0

*b6 aa codeshared flights
cap drop b6aa_c

gen temp1 = tkcarriergroup + opcarriergroup
gen b6aa_c = index(temp1, "B6") &index(temp1, "AA") & interline==0

drop temp1 

* find the market which is the codeshared market
* regenerate the nea_market_codeshared. The existing one only consider traditional codeshared market
drop nea_market_codeshared

egen nea_market_codeshared = total(b6aa_c), by(market quarter year)
replace nea_market_codeshared=nea_market_codeshared>1

egen nea_market = total(nea_market_codeshared), by(market)
replace nea_market=nea_market>1

compress

save "cleaned924_all.dta", replace
********************************************************************************
**# Summary Statistics for the whole data
********************************************************************************
* use "cleaned924_all.dta", clear
sum mktfare nonstop roundtrip incon online_new interline t_codeshare v_codeshare ///
b6aa_c AA B6 DL UA WN [aweight=passengers] if nea_market == 0 

sum mktfare nonstop roundtrip incon online_new interline t_codeshare v_codeshare  ///
b6aa_c AA B6 DL UA WN [aweight=passengers] if nea_market == 1

sum mktfare nonstop roundtrip incon online_new interline t_codeshare v_codeshare  ///
b6aa_c AA B6 DL UA WN [aweight=passengers]

bysort year quarter market: gen noproduct = _N

*check market level statistics
preserve 
collapse (sum) passengers , by(year quarter market nea_market noproduct mktdistance) 

sum nea_market noproduct
restore 

preserve 
* collapse by market

collapse (sum) passengers (mean)mktfare [aweight = passengers], by(year quarter nea_market noproduct mktdistance) 
tabstat passengers mktfare noproduct nea_market, statistics(mean median sd min max)

* check the comparasion between nea mad non-nea market 
tabstat passengers mktfare mktdistance noproduct, by(nea_market) statistics(mean median sd min max)
restore

********************************************************************************
**# Graphing
********************************************************************************
* store all graphs in graph folder 
cd "F:\Codeshare JetBlue AA\STATA_New_Data_7_2024\graph"

preserve 
* collapse by market

collapse (sum) passengers (mean)mktfare [aweight = passengers], by(year quarter nea_market) 

* check the comparasion between nea mad non-nea market 
*tabstat passengers mktfare, by(nea_market) statistics(mean median sd min max)

gen dt = yq(year, quarter)
format dt %tq
****************************
* graph number of passengers 

* million level
gen pa_m = passenger/1000000

graph twoway (line pa_m  dt if nea_market == 1,yaxis(1)) ///
(line pa_m  dt if nea_market == 0, yaxis(2)), ///
tline(244 254,lp(dash) lc(black)) tla(244 "NEA Starts" 254 "Ends", add angle(45)) ///
xline(244, lwidth(42) lc(gs12)) xline(240,lp(dash)) xline(248,lp(dash)) ///
legend(label(1 NEA markets) label(2 Non-NEA Market) ) /// 
title("No. Passengers from 2019Q1 to 2024Q1") yti("NEA Passengers (m)", axis(1)) ///
ytitle("Non NEA Passengers (m)", axis(2)) graphregion(color(white)) plotregion(color(white))

graph export PassengerTrend.png, replace

****************************
* graph airfare

graph twoway (line mktfare dt if nea_market == 1)(line mktfare dt if nea_market == 0), ///
tline(244 254,lp(dash) lc(black)) tla(244 "NEA Starts" 254 "Ends", add angle(45)) ///
xline(244, lwidth(46) lc(gs12)) xline(240,lp(dash)) xline(248,lp(dash)) ///
 legend(label(1 NEA markets) label(2 Non-NEA Market) ) /// 
 title("Weighted Average Price from 2019Q1 to 2024Q1") yti("Weighted Price ($)") ///
 graphregion(color(white)) plotregion(color(white))

graph export PriceTrend.png, replace
restore 
 
********************************************************************************
**# Drop Small Markets
*******************************************************************************

*drop small markets
*egen total_quantity = total( passengers), by(market year quarter)
*drop if total_quantity<10000

* find the market where JetBlue is a new entrant
* generate JetBlue dummy if JetBlue served the market in a quarter before NEA
egen JetBlue_market_dm = total(B6), by(market year quarter)
gen JetBlue_market_served_before_NEA = JetBlue_market_dm>0 & year<2021
gen JetBlue_market_served_within_NEA = JetBlue_market_dm>0 & ///
(year>=2021& year<=2023 &~(year==2023&quarter==4))

gen JetBlue_market_served = JetBlue_market_dm>0

* generate dummy for the market that's newly served by JetBlue 
egen temp = total(JetBlue_market_served_before_NEA), by(market)
egen temp2 = total(JetBlue_market_served_within_NEA), by(market)
gen byte JetBlue_new_market_served = temp==0&temp2>0

drop temp temp2 

* delete covid period 
drop if year==2020 |year ==2021 |(year==2022 & quarter ==1)

* delete samll markets 
cap drop total_quantity
egen total_quantity = total( passengers), by(market year quarter)
drop if total_quantity<10000  /// 3.9M obs to 279,273 obs

* delete the missing information
drop if strpos(tkcarriergroup, "--")>0 /// 223,396 obs

*preserve 
drop if passengers<10
di _N 
** number of the obs down to 52991
*restore 

********************************************************************************
**# Summary Statistics for the selected markets
********************************************************************************
sum mktfare nonstop roundtrip incon online_new interline t_codeshare v_codeshare ///
b6aa_c AA B6 DL UA WN [aweight=passengers] if nea_market == 0 

sum mktfare nonstop roundtrip incon online_new interline t_codeshare v_codeshare  ///
b6aa_c AA B6 DL UA WN [aweight=passengers] if nea_market == 1

bysort year quarter market: gen noproduct = _N

*check market level statistics
preserve 
collapse (sum) passengers , by(year quarter market nea_market noproduct mktdistance) 

sum nea_market noproduct
restore 

preserve 
* collapse by market

collapse (sum) passengers (mean)mktfare [aweight = passengers], by(year quarter nea_market noproduct mktdistance) 

* check the comparasion between nea mad non-nea market 
tabstat passengers mktfare mktdistance noproduct, by(nea_market) statistics(mean median sd min max)
restore

save "cleaned717_dropsmallmarket.dta", replace

*** RUN REGRESSION FILE
*cd "F:\Codeshare JetBlue AA\STATA_New_Data_7_2024"
*do regression_2024Q1.do
*** End of File
