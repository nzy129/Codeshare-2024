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


