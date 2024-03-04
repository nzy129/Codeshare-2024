import statsmodels.api as sm
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

df = pd.read_csv('cleaned_2019_2023_stata.csv')
# create the summary statistics before 2021 and after 2021
print(df.columns)

#df_bos = df[df.market.str.contains("BOS")]
#city = "JFK"
def plot_city_share(city):
        df_bos = df[df.market.str.contains(city)]
        test = (df_bos[["TicketCarrier", "Passengers", "Year", "Quarter"]].groupby(["TicketCarrier", "Year", "Quarter"])
                .sum().sort_values(by="Passengers", ascending=False).reset_index())
        test['tq'] = test.groupby(["Year", "Quarter"])['Passengers'].transform('sum')
        test["Share"] = test["Passengers"] / test["tq"]
        test.sort_values(by='Share', ascending=False).reset_index(drop=True)
        test.TicketCarrier[:1000].unique()
        # top frequency carriers are
        carrier = ['B6', 'AA', 'DL', 'UA', 'WN', 'NK', 'AS', 'F9', 'G4', 'HA', 'SY']
        test = test.loc[test.TicketCarrier.isin(carrier)]
        test.loc[:, 'Date'] = pd.to_datetime(test['Year'].astype(str) + 'Q' + test['Quarter'].astype(str)).dt.to_period('Q')

        test = test.loc[:, ['TicketCarrier', 'Date', 'Share']]
        test.set_index(['Date', 'TicketCarrier'], inplace=True)
        market_share_df = test.unstack(level=1)
        stacking_order = market_share_df.iloc[0,:].sort_values(ascending=False).index
        # stacking_order = [('Share', 'B6'), ('Share', 'AA'), ('Share', 'DL'), ('Share', 'UA'),
        #                  ('Share', 'WN'), ('Share', 'NK'), ('Share', 'AS'), ('Share', 'F9'),
        #                  ('Share', 'G4'), ('Share', 'HA'), ('Share', 'SY')]
        market_share_df = market_share_df[stacking_order]

        ax = market_share_df.plot.bar(stacked=True, rot=0, cmap='tab20', figsize=(10, 6))
        ax.legend(bbox_to_anchor=(1.01, 1.02), loc='upper left')
        plt.xlabel('Date (Quarterly)',fontsize=18)
        plt.ylabel('Market Share in ' + city,fontsize=18)
        plt.xticks(range(len(market_share_df.index)), market_share_df.index, rotation=45)
        plt.tight_layout()
        plt.savefig(city+'_SHARE.png')
        plt.show()

plot_city_share("BOS")

plot_city_share("JFK")

plot_city_share("LGA")

plot_city_share("EWR")
