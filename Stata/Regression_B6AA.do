/// Codeshare Alliance between JetBlue and American Airlines
/// import the data 

clear all
import delimited "E:\Research\Codeshare JetBlue AA\pythonProject3\cleaned_2019_2023_stata.csv"


/// generate the indicator if the flight is codeshared by the B6 and AA
// DELETE the missing data
/// drop if strpos(opcarriergroup, "B6")

///tab ticketcarrier, gen(tk)

// graph 

collapse (mean) avefare [aweight = passengers], by(year quarter) 

gen dt = yq(year, quarter)
format dt %tq
graph twoway line avefare dt
graph export "collapsed_data_plot.png", replace

save collapsed_data, replace

clear 
import delimited "E:\Research\Codeshare JetBlue AA\pythonProject3\cleaned_2019_2023_stata.csv"
/// collapse by market
collapse (mean) avefare [aweight = passengers], by(year quarter nea_market ) 
gen dt = yq(year, quarter)
format dt %tq
save collapsed_dat_nea, replace

graph twoway  ///
(line avefare dt if nea_market == 1)(line avefare dt if nea_market == 0) ///
(scatteri 300 240  300 248, bcolor(gs12 %3) recast(area) plotr(m(zero)) mcolor(%30)) , ///
tline(244 254,lp(dash) lc(black)) tla(244 "NEA Starts" 254 "Ends", add angle(45)) ///
 legend(label(1 NEA markets) label(1 Non-Nea Market))

graph twoway (scatter avefare dt), xline(245, lwidth(4.5) lc(gs12))

graph twoway (line avefare dt if nea_market == 1)(line avefare dt if nea_market == 0), ///
tline(244 254,lp(dash) lc(black)) tla(244 "NEA Starts" 254 "Ends", add angle(45)) ///
xline(244, lwidth(52) lc(gs12)) xline(240,lp(dash)) xline(248,lp(dash)) ///
 legend(label(1 NEA markets) label(2 Non-NEA Market) ) /// 
 title("Weighted Average Price from 2019Q1 to 2023Q3") yti("Weighted Price")
/// sale data



graph twoway (line passengers dt if nea_market == 1)(line avefare dt if nea_market == 0), ///
tline(244 254,lp(dash) lc(black)) tla(244 "NEA Starts" 254 "Ends", add angle(45)) ///
xline(244, lwidth(52) lc(gs12)) xline(240,lp(dash)) xline(248,lp(dash)) ///
 legend(label(1 NEA markets) label(2 Non-NEA Market) ) /// 
 title("No. Passengers from 2019Q1 to 2023Q3") yti("No. Passengers")




clear all
import delimited "E:\Research\Codeshare JetBlue AA\pythonProject3\cleaned_2019_2023_stata.csv"
gen lnfare = ln(avefare)

foreach x in "WN" "AA" "DL" "UA" "NK" "AS" "B6" "F9" "G4" "HA" "SY" "XP" "MX" "MM" {
gen `x' = strpos(ticketcarrier, "`x'")>0
}

gen dt = yq(year, quarter)

drop if total_quantity <100
egen newid = group(market)
gen mktdistance2 = mktdistance^2



reg avefare roundtrip interline online_new mktdistance mktdistance2 b6aa WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM nea_market nea_market_codeshared i.dt [aweight = passengers]

est sto reg1_weight 

reg avefare roundtrip interline online_new mktdistance mktdistance2 1.b6aa#1.AA 1.b6aa#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM nea_market nea_market_codeshared  i.dt
est sto reg2

reg avefare roundtrip interline online_new mktdistance mktdistance2 1.b6aa#1.AA 1.b6aa#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM nea_market nea_market_codeshared  i.dt[aweight = passengers]
est sto reg2_weight

reg lnfare roundtrip interline online_new mktdistance mktdistance2 1.b6aa#1.AA 1.b6aa#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM nea_market nea_market_codeshared i.dt[aweight = passengers]

est sto reg3_weight


estout reg1_weight reg2 reg2_weight reg3_weight using result222.xls, cells("b" se)  replace




/// delete samll markets 
drop if total_quantity<2000

egen newidd = group(market)

set matsize 2200

reg lnfare roundtrip interline online_new  1.b6aa#1.AA 1.b6aa#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM nea_market nea_market_codeshared i.dt i.newidd[aweight = passengers]

est sto reg_market_fixed_ln

reg avefare roundtrip interline online_new  1.b6aa#1.AA 1.b6aa#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM nea_market nea_market_codeshared i.dt i.newidd[aweight = passengers]

est sto reg_market_fixed


estout reg_market_fixed_ln reg_market_fixed using result222_marketfixed.xls, cells("b" se)  replace

/////////////////////////////////////////////////////////////////////////
/// delete covid period 
drop if year==2020 |year ==2021 |(year==2022 & quarter ==1)

drop newidd
egen newidd = group(market)
  ///1969 markets left 

  
  
reg avefare roundtrip interline online_new mktdistance mktdistance2 b6aa WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM nea_market nea_market_codeshared i.dt [aweight = passengers]

est sto reg1_weight_noc



reg avefare roundtrip interline online_new mktdistance mktdistance2 1.b6aa#1.AA 1.b6aa#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM nea_market nea_market_codeshared  i.dt
est sto reg2_noc

reg avefare roundtrip interline online_new mktdistance mktdistance2 1.b6aa#1.AA 1.b6aa#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM nea_market nea_market_codeshared  i.dt[aweight = passengers]
est sto reg2_weight_noc


reg lnfare roundtrip interline online_new mktdistance mktdistance2 1.b6aa#1.AA 1.b6aa#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM nea_market nea_market_codeshared i.dt[aweight = passengers]

est sto reg3_weight_noc


estout reg1_weight_noc reg2_noc reg2_weight_noc reg3_weight_noc using result2222_noc.xls, cells("b" se)   replace


  
  
  

reg lnfare roundtrip interline online_new  1.b6aa#1.AA 1.b6aa#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM  nea_market_codeshared i.dt i.newidd [aweight = passengers]

est sto reg_market_fixed_nocovid_ln

reg avefare roundtrip interline online_new  1.b6aa#1.AA 1.b6aa#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM  nea_market_codeshared i.dt i.newidd [aweight = passengers]

est sto reg_market_fixed_nocovid


estout reg_market_fixed_nocovid_ln reg_market_fixed_nocovid using result222_marketfixed_nocovid.xls, cells("b" se)  replace
