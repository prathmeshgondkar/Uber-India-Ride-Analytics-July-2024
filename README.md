# Uber India Ride Analytics – July 2024

One month of ride-hailing booking data for Bangalore, cleaned in SQL and Excel and analysed in Power BI. The questions were the ones an operations team would ask: when is demand highest, where is it, how many requests actually turn into rides, and which service tiers make the money.

![Overview page](Overall.png)

## About the data

The dataset is modelled on the public Ola Bangalore case study, relabelled with Uber service tiers (Uber X, Uber XL, Comfort, Uber Black). Locations, volumes and outcomes describe Bangalore. It's a learning dataset, not Uber's data.

- 40,534 booking requests, 1–31 July 2024, after dropping empty rows
- 19 columns: timestamps, booking status, customer, vehicle type, pickup and drop location, wait times, cancellation reasons, fare, payment method, distance, ratings
- Outcomes: Success, Canceled by Driver, Canceled by Customer, Driver Not Found

## The cleaning (this was most of the work)

- The raw sheet had roughly 62,000 blank rows under the data. Filtered on load.
- Numeric columns used the text `No` as a placeholder for trips that never happened. Converted to `NULL` or `0` with `CASE` expressions depending on the column.
- Date and time were separate columns. Combined into one timestamp so hour-of-day and day-of-week could be derived in SQL.
- Location names were systematically corrupted in the source (`IndiraNogar`, `KammaNohalli`, `BaNoshankari`), which looks like a global find-and-replace on `na` that went wrong somewhere upstream. Standardised to the real neighbourhood names.
- Hourly, daily and per-location counts were produced as SQL aggregations and fed to Power BI, which kept the model light.

The queries are in `Uber.sql`.

## What the data shows

- **62% of requests completed.** 18% were cancelled by the driver, 10% by the customer, 10% ended as Driver Not Found. The failures cluster in peak hours in outlying areas.
- **Two demand peaks**, around 8 AM and 8–9 PM, on an otherwise flat ~1,300–1,400 requests a day.
- **Pickups concentrate** in Indira Nagar, Banashankari, Ramamurthy Nagar and Kammanahalli, then BTM Layout, Cox Town, Sarjapur Road and Kengeri.
- **Comfort earns the most** (₹3.3M on an average fare above ₹500) despite every tier having about a quarter of requests. Uber X averages ₹212 a trip.
- **Cash and UPI** cover about 90% of completed trips.

## Files

| File | What it is |
|---|---|
| `Bookings.xlsx` | Raw dataset |
| `Uber.sql` | Cleaning and aggregation queries |
| `Uber 2024 Data India.pbix` | Power BI report |
| `Uber 2024 Report.pdf` | Full write-up |
| `Overall.png`, `Cancellation.png`, `Revenue.png`, `Ratings.png`, `Vehicle Type.png` | Dashboard pages |

## If I extended it

More months to see seasonality, external factors like weather and holidays, and a simple model for cancellation likelihood per request.
