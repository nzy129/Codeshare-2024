import urllib.request
import numpy as np
import matplotlib.pyplot as plt


# this file clearn the data
# y =2019
# q=1
def clean_data(y: int, q: int):
    import pandas as pd
    import zipfile

    # with zipfile.ZipFile("Data/Coupon_{}_{}.zip".format(y, q)) as z:
    #    df_coupon = pd.read_csv(z.open('Origin_and_Destination_Survey_DB1BCoupon_{}_{}.csv'.format(2019, 1)), header=0)
    #    df_coupon = df_coupon[
    #        ["ItinID", "MktID", "SeqNum", "Origin", "Dest", "Break", "TkCarrier", "OpCarrier", "RPCarrier"]]

    with zipfile.ZipFile("Data/Ticket_{}_{}.zip".format(y, q)) as z:
        df_ticket = pd.read_csv(z.open('Origin_and_Destination_Survey_DB1BTicket_{}_{}.csv'.format(y, q)), header=0)
        df_ticket = df_ticket[["Origin", "ItinID", "Coupons", "Year", "Quarter", "RoundTrip", "OnLine",
                               "Passengers", "ItinFare", "Distance"]]

    with zipfile.ZipFile("Data/Market_{}_{}.zip".format(y, q)) as z:
        df_market = pd.read_csv(z.open('Origin_and_Destination_Survey_DB1BMarket_{}_{}.csv'.format(y, q)), header=0)

        df_market = df_market[["ItinID", "MktID", "MktCoupons", "Year", "Quarter", "Origin", "Dest", "AirportGroup",
                               "TkCarrierGroup", "OpCarrierGroup", "Passengers", "MktFare", "MktDistance",
                               "NonStopMiles"]]
        df_market = df_market.rename({"Origin": 'Origin_m', "Dest": "Dest_m"}, axis=1)
    # del df
    # df = df[df.Coupons <= 4]

    df_joined = pd.merge(df_market, df_ticket, on=["ItinID", "Quarter", "Year", "Passengers"], how="left")
    # output = df_joined.tail()

    # 97.7% trips have the fewer than or equal to 4 tickets
    # print(len(df_joined[df_joined.Coupons <= 4].ItinID.unique()) / len(df_joined.ItinID.unique()))

    # 99.9% trips have fewer than or equal to 6 tickets
    # print(len(df_joined[df_joined.Coupons <= 6].ItinID.unique()) / len(df_joined.ItinID.unique()))

    # print(len(df_joined[(df_joined.RoundTrip == 0) & (df_joined.Coupons == 3)].ItinID.unique()) / len(df_joined.ItinID.unique()))

    df_joined["market"] = df_joined.Origin_m + ":" + df_joined.Dest_m
    df_joined["TTFare"] = df_joined.MktFare * df_joined.Passengers
    df_test = df_joined[["market", "TkCarrierGroup", "OpCarrierGroup", "AirportGroup",
                         "RoundTrip", "OnLine", "MktCoupons", "Coupons", "Passengers", "Year", "Quarter", "TTFare",
                         "ItinFare", "MktDistance", "NonStopMiles", "MktFare"]]

    # output = df_coupon["OpCarrier"].value_counts()
    # output = df_coupon["TkCarrier"].value_counts()
    # output = df_coupon[df_coupon.TkCarrier == "--"]

    # Replace the regional feeder
    regional_feeder_op = [["OH", "AA"], ["MQ", "AA"], ["YV", "UA"],
                          ["9E", "DL"], ["QX", "AL"], ["PT", "AA"],
                          ["G7", "UA"], ["ZW", "AA"], ["AX", "UA"], ["C5", "UA"], ["BB", "3M"]]
    ti_own = ["BB", "3M"]

    for x in regional_feeder_op:
        df_test.loc[:, "OpCarrierGroup"] = df_test["OpCarrierGroup"].str.replace(x[0], x[1])
    for x in ti_own:
        df_test.loc[:, "TkCarrierGroup"] = df_test["TkCarrierGroup"].str.replace(x[0], x[1])

    def check_unique_op(value):
        return 1 if len(set(value.split(":"))) == 1 else 0

    df_test_new = df_test.copy()  # to get rid of warning
    df_test_new["Nonstop"] = 1 * (df_test_new["AirportGroup"].apply(lambda x: len(x.split(":"))) == 2)

    # find the codeshare products between JetBlue and AA
    df_test_new["B6AA"] = 1 * df_test_new.loc[:, "OpCarrierGroup"].str.contains("B6") * df_test_new.loc[:,
                                                                                        "OpCarrierGroup"].str.contains(
        "AA")
    # the city pair where they do codeshare
    df_test_new['NEA_market'] = 1 * (df_test_new.groupby("market")['B6AA'].transform('sum') > 0)
    df_test_new['NEA_market'] = df_test_new['NEA_market'].astype(int)
    df_test_new['NEA_market_codeshared'] = 1 * (
                df_test_new.groupby(["market", "Year", "Quarter"])['B6AA'].transform('sum') > 0)

    df_test_new.loc[:, "OnLine_new"] = df_test_new.loc[:, "OpCarrierGroup"].apply(check_unique_op)

    df_test_new = df_test_new[(df_test_new.ItinFare < 2500) & (df_test.ItinFare >= 20)]

    # df_test.drop(["OnLine","MktCoupons","Coupons"], axis=1, inplace=True)

    output = df_test_new.groupby(
        by=["market", "TkCarrierGroup", "OpCarrierGroup", "AirportGroup", "RoundTrip", "OnLine_new",
            "MktDistance", "NonStopMiles", "MktCoupons", "Coupons", "Year", "Quarter"],
        level=None).agg('sum').reset_index()

    output['AveFare'] = output["TTFare"] / output["Passengers"]

    output['total_quantity'] = output.groupby("market")['Passengers'].transform('sum')
    cleaned_data = output[output['total_quantity'] >= 1]  # change it to 100 to delete low demand market

    # around 0.76% of the passengers contains  --

    # print(len(cleaned_data.market.unique())) # 10710 markets

    # output = output[output["total_quantity"] >= 50]
    # df_ticket = df_ticket[(df_ticket.ItinFare < 2500) & (df_ticket.ItinFare >= 20)]
    # plt.hist(output.total_quantity.unique(), bins=200)
    # plt.hist(df_ticket.ItinFare, bins=200)
    # plt.title('Histogram of Total Quantity')
    # plt.xlabel('Total Quantity')
    # plt.ylabel('Frequency')
    # plt.show()

    def q1(x, weights):
        sorted_indices = np.argsort(x)
        sorted_weights = weights.iloc[sorted_indices]
        sorted_values = x.iloc[sorted_indices]
        cumulative_weights = np.cumsum(sorted_weights)
        percentile = np.searchsorted(cumulative_weights, 0.1 * cumulative_weights.iloc[-1])
        return sorted_values.iloc[percentile]

    def q9(x, weights):
        sorted_indices = np.argsort(x)
        sorted_weights = weights.iloc[sorted_indices]
        sorted_values = x.iloc[sorted_indices]
        cumulative_weights = np.cumsum(sorted_weights)
        percentile = np.searchsorted(cumulative_weights, 0.9 * cumulative_weights.iloc[-1])
        return sorted_values.iloc[percentile]

    def variance_weighted(x, weights):
        weighted_mean = np.average(x, weights=weights)
        variance = np.average((x - weighted_mean) ** 2, weights=weights)
        return variance

    def average_weighted(x, weights):
        weighted_mean = np.average(x, weights=weights)
        return weighted_mean

    f = {'MktFare': [
        ('mmktfare', lambda x: average_weighted(x, df_test_new.loc[x.index, 'Passengers'])),
        ('vmktfare', lambda x: variance_weighted(x, df_test_new.loc[x.index, 'Passengers'])),
        ('q1fare', lambda x: q1(x, df_test_new.loc[x.index, 'Passengers'])),
        ('q9fare', lambda x: q9(x, df_test_new.loc[x.index, 'Passengers']))],
        'RoundTrip': [lambda x: average_weighted(x, df_test_new.loc[x.index, 'Passengers'])],
        'MktDistance': [lambda x: average_weighted(x, df_test_new.loc[x.index, 'Passengers'])],
        'Nonstop': [lambda x: average_weighted(x, df_test_new.loc[x.index, 'Passengers'])],
        'Passengers': [lambda x: sum(x)]
    }

    output2 = df_test_new.groupby(
        by=["market", "NonStopMiles", "Year", "Quarter", "NEA_market", "NEA_market_codeshared"],
        level=None).agg(f).reset_index()

    output2['total_quantity'] = output2.groupby("market")['Passengers'].transform('sum')
    return cleaned_data, output2
