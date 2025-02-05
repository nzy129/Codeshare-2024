import statsmodels.api as sm
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from statsmodels.iolib.summary2 import summary_col
## test
df = pd.read_csv("Cleaned_2019_2023_without_delete_small_market.csv")

# find the codeshare products between JetBlue and AA
df["B6AA"] = 1 * df.loc[:, "OpCarrierGroup"].str.contains("B6") * df.loc[:, "OpCarrierGroup"].str.contains("AA")
df["Interline"] = 1 * ((df["OpCarrierGroup"] == df["TkCarrierGroup"]) & (df["OnLine_new"] == 0))
df["Interline"].sum()
df["Missing_Code"] = 1 * df.loc[:, "OpCarrierGroup"].str.contains("--")
df = df.loc[df["Missing_Code"] == 0]

# the city pair where they do codeshare
df['NEA_market'] = 1 * (df.groupby("market")['B6AA'].transform('sum') > 0)
df['NEA_market'] = df['NEA_market'].astype(int)

df['NEA_market_codeshared'] = 1 * (df.groupby(["market", "Year", "Quarter"])['B6AA'].transform('sum') > 0)

# Summary Statistics
# output = df.describe()
# output.to_csv('output.csv')
##########
df["Weighted_Price"] = df["AveFare"] * df["Passengers"]
grouped_df = df.groupby(['Year', 'Quarter']).agg({"Weighted_Price": "sum", "Passengers": "sum"}).reset_index()
grouped_df['Weighted_Avg_Price'] = grouped_df['Weighted_Price'] / grouped_df['Passengers']
#############

# show the graph in the Descriptive Analysis

########################################################################################################################
# Prepare the data for regression
# delete the markets with less than 100 passengers recorded.
df['total_quantity'] = df.groupby(["market", "Year", "Quarter"])['Passengers'].transform('sum')
# df = df[df['total_quantity'] >= 100]
# 11609866 --> 6839666

market_counts = df.groupby(['market', 'Year', 'Quarter']).size().reset_index(name='count')
print(market_counts.describe())

# Create Ticket Carrier Dummies by extracting the unique carrier e.g. AA:AA --> AA,  AA:AS --> AA:AS
df["TicketCarrier"] = df.loc[:, "TkCarrierGroup"].apply(lambda x: list(set(x.split(":"))))
df["TicketCarrier"] = df["TicketCarrier"].apply(lambda x: ':'.join(x))

df["Nonstop"] = 1 * (df["AirportGroup"].apply(lambda x: len(x.split(":"))) == 2)

df["OpCarrier"] = df.loc[:, "OpCarrierGroup"].apply(lambda x: list(set(x.split(":"))))
df["OpCarrier"] = df["OpCarrier"].apply(lambda x: ':'.join(x))

# create variable Traditional codeshare where there are two operating carriers involved and only one ticketing carrier
df["T_Codeshare"] = 1 * (df["OpCarrier"].apply(lambda x: len(x.split(":"))) == 2) * (
        df["TicketCarrier"].apply(lambda x: len(x.split(":"))) == 1)
# create variable Virtual codeshare where there are two operating carriers involved and only one ticketing carrier and
# operating carrier is different from the ticketing carrier
df["V_Codeshare"] = (1 * (df["OpCarrier"].apply(lambda x: len(x.split(":"))) == 1) *
                     (df["TicketCarrier"].apply(lambda x: len(x.split(":"))) == 1) *
                     (df["OpCarrier"] != df["TicketCarrier"]))

df["T_Codeshare"].sum() + df["V_Codeshare"].sum() + df["Interline"].sum() + df["OnLine_new"].sum()

# test = df[(df["T_Codeshare"] == 0) & (df["V_Codeshare"] == 0) & (df["Interline"] == 0) & (df["OnLine_new"] == 0)]
# test2 = df[df["T_Codeshare"] == 1]
# df.to_csv('cleaned_2019_2023_stata_35.csv')

###########################################################################3

output = df.describe()
output.to_csv('descriptive.csv')
########################################################################################################################
# Check the frequency of the ticketing Carrier
TkGroup_counts = df.groupby(['TicketCarrier'])['Passengers'].sum().reset_index(name='count').sort_values(by='count',
                                                                                                         ascending=False)
# Created the Top 14 Carriers based on the frequency
TKGroup_Dummy = ["WN", "AA", "DL", "UA", "NK", "AS", "B6", "F9", "G4", "HA", "SY", "XP", "MX", "MM"]
carrier_dummy = pd.get_dummies(df.loc[:, "TicketCarrier"])  # 264 --> 190 after deleting the small markets
carrier_dummy = carrier_dummy[[col for col in carrier_dummy.columns if col in TKGroup_Dummy]] * 1

Year_dummy = pd.get_dummies(df.loc[:, "Year"]) * 1
Year_dummy = Year_dummy.iloc[:, 0:-1]
Quarter_dummy = pd.get_dummies(df.loc[:, "Quarter"]) * 1
Quarter_dummy = Quarter_dummy.iloc[:, 0:-1]
# scale the distance by 100
df.loc[:, "MktDistance"] = df.loc[:, "MktDistance"] / 100

# market_dummy = pd.get_dummies(df.loc[:, "market"]) the data gets too large
###############################################################################################
# Baseline
df['Constant'] = 1
# cluster created based on the markets
df['gpID'] = df.groupby(['market']).ngroup()

X = df[["Constant", "RoundTrip", "Interline", "OnLine_new", "MktDistance"]]
X = pd.concat([X, carrier_dummy, Year_dummy, Quarter_dummy], axis=1)
y = df["AveFare"]

mod = sm.OLS(y, X).fit()
print(mod.summary())

# cluster robust by markets
mod_r = mod.get_robustcov_results(cov_type="cluster", groups=df["gpID"])
print(mod_r.summary())

# regression OLS with ((X'*X)\X')*Y to solve memory issue
# beta_r = np.linalg.inv(X.transpose().dot(X)).dot(X.transpose()).dot(y)
# Add B6AA dummy

X = df[["Constant", "RoundTrip", "Interline", "OnLine_new", "MktDistance", "B6AA"]]
X = pd.concat([X, carrier_dummy, Year_dummy, Quarter_dummy], axis=1)
y = df["AveFare"]

mod2 = sm.OLS(y, X).fit()
mod2_r = mod2.get_robustcov_results(cov_type="cluster", groups=df["gpID"])
print(mod2_r.summary())

# Regression with market fixed effects is in the python file "TopMarket Analysis"
# Add NEA_market dummy
X = df[["Constant", "RoundTrip", "Interline", "OnLine_new", "MktDistance", "B6AA", "NEA_market"]]
X = pd.concat([X, carrier_dummy, Year_dummy, Quarter_dummy], axis=1)
y = df["AveFare"]

mod3 = sm.OLS(y, X).fit()
print(mod3.summary())
mod3_r = mod3.get_robustcov_results(cov_type="cluster", groups=df["gpID"])
# add the interactive term --> Diff-In-Diff Regression
# NEA market_codeshared will the vairable of interest
X = df[["Constant", "RoundTrip", "Interline", "OnLine_new", "MktDistance", "B6AA", "NEA_market",
        "NEA_market_codeshared"]]
X = pd.concat([X, carrier_dummy, Year_dummy, Quarter_dummy], axis=1)
y = df["AveFare"]

mod4 = sm.OLS(y, X).fit()
print(mod4.summary())
mod4_r = mod4.get_robustcov_results(cov_type="cluster", groups=df["gpID"])

################################################################################################
# Check log(fare)

X = df[["Constant", "RoundTrip", "Interline", "OnLine_new", "MktDistance", "B6AA", "NEA_market",
        "NEA_market_codeshared"]]
X = pd.concat([X, carrier_dummy, Year_dummy, Quarter_dummy], axis=1)
y = np.log(df["AveFare"])

mod5 = sm.OLS(y, X).fit()
mod5_r = mod5.get_robustcov_results(cov_type="cluster", groups=df["gpID"])

res = summary_col([mod_r, mod2_r, mod3_r, mod4_r, mod5_r], regressor_order=mod.params.index.tolist())
res.tables[0].to_csv("output2152024_2.csv")

print(df.market.unique().size)
# my own exploration

X = df[["Constant", "RoundTrip", "Interline", "OnLine_new", "MktDistance", "B6AA", "NEA_market",
        "NEA_market_codeshared"]]
temp = pd.DataFrame(df.loc[:, "MktDistance"] ** 2, columns=["MktDistance2"])

X = pd.concat([X, carrier_dummy, Year_dummy, Quarter_dummy, temp], axis=1)
y = np.log(df["AveFare"])

mod6 = sm.OLS(y, X).fit()
mod6_r = mod6.get_robustcov_results(cov_type="cluster", groups=df["gpID"])
print(mod6_r.summary())
