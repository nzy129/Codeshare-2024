import pandas as pd
from multiprocessing import Pool

from Clean import clean_data
if __name__ == '__main__':
    df1 = pd.DataFrame()
    df2 = pd.DataFrame()
    df3 = pd.DataFrame()

    years = [2019, 2020, 2021, 2022, 2023]
    quarters = [list(range(1, 5)) if y != 2023 else list(range(1, 4)) for y in years]

    # Create a pool of workers
    with Pool(processes=4) as pool:  # Adjust the number of processes as needed
        results = pool.starmap(clean_data, [(y, q) for y, qs in zip(years, quarters) for q in qs])

    # Process the results
    for output in results:
        df1 = pd.concat([df1, output[0]], ignore_index=True)
        # df2 = pd.concat([df2, output[1]], ignore_index=True)
        df3 = pd.concat([df3, output[2]], ignore_index=True)

    df1.to_csv('Cleaned_2019_2023_without_delete_small_market_dispersion312.csv', index=False)
    #df2.to_csv('Cleaned_2019_2023_without_delete_small_market312.csv', index=False)
    df3.to_csv('Cleaned_2019_2023_without_delete_small_market312_carrier_route.csv', index=False)