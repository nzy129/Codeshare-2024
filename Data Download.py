# download the data https://transtats.bts.gov/PREZIP/Origin_and_Destination_Survey_DB1BCoupon_2019_1.zip

import urllib.request
import pandas as pd
import zipfile

for y in [2019, 2020, 2021, 2022, 2023]:
    for q in range(1, 5):
        url_file = ("https://transtats.bts.gov/PREZIP/Origin_and_Destination"
                    "_Survey_DB1BCoupon_{}_{}.zip").format(y, q)
        a = urllib.request.urlretrieve(url_file,
                                       "Coupon_{}_{}.zip".format(y, q))
        url_file = ("https://transtats.bts.gov/PREZIP/Origin_and_Destination"
                    "_Survey_DB1BTicket_{}_{}.zip").format(y, q)
        a = urllib.request.urlretrieve(url_file,
                                       "Ticket_{}_{}.zip".format(y, q))
        url_file = ("https://transtats.bts.gov/PREZIP/Origin_and_Destination"
                    "_Survey_DB1BMarket_{}_{}.zip").format(y, q)
        a = urllib.request.urlretrieve(url_file,
                                       "Market_{}_{}.zip".format(y, q))
