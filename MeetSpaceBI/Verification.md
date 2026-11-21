# MeetSpace BI verification and demonstration

The practical delivery includes the Power BI report, the final Excel workbook, the matching CSV source data, SQL setup and validation scripts, the analytics API, and the desktop and mobile applications. The [README](../README.md) describes the Docker setup and Flutter entry points. The local environment configuration must be supplied separately for a new installation.

## Start the demonstration

1. Start the complete Docker Compose stack with `docker compose up -d --build`. Use `docker compose ps` to confirm that `sqlserver`, `rabbitmq`, `api`, and `subscriber` are running. The `subscriber` is required to process booking status messages and deliver notifications.
2. From the repository root in PowerShell, run `./MeetSpaceBI/Sql/setup_bi.ps1`. The setup uses the separate `MeetSpaceBI` database and checks its state before loading data.
3. Open `PowerBI/MeetSpace_BI.pbix` in Power BI Desktop. Refresh against the local `MeetSpaceBI` SQL database if required. Use the analytics screens in the Windows desktop app and Android app, following the README for their API endpoints.

## Expected results

| Check | Expected result |
| --- | --- |
| BI source | 37 spaces, 12 facilities, 4 cities, 4 space types and 19 source entries |
| Status counts | 4,000 Approved, 400 Pending, 300 Rejected and 300 Cancelled |
| SQL fact rows | 12,145 hourly rows across all statuses |
| 2025 with no other filters | 4,000 confirmed reservations and 9,704 reserved hours |
| January 2025 | 376 confirmed reservations and 872 hours |
| February 2025 | 331 confirmed reservations and 796 hours |
| Monday across 2025 | 729 confirmed reservations and 1,727 hours |
| Tuzla across 2025 | 4 spaces, 402 confirmed reservations and 1,132 hours |
| Desktop table, all spaces | 37 spaces over 5 pages, with 5 spaces on the last page |

The hourly matrix shows how many approved reservations cover each hour. Each reservation contributes a full hour in each applicable cell, so the number of reserved hours in one cell equals the count there. Across several hours, calculate the reservation count by distinct `ReservationCode` and the hours by summing the segments. The daily table and monthly chart display both measures.

The final check created the BI database in a separate empty SQL Server container, ran the setup again against the resulting database, and queried the confirmed totals directly. Both setup runs completed, and the query returned 4,000 reservations and 9,704 hours. All six Excel data sheets were compared with their corresponding CSV files and matched cell for cell.

## Check the operational flow

1. On mobile, select a space in **Demand trends** and check that up to five periods are shown. Changing the space updates the periods.
2. Open the booking screen for that space, choose a future date, and select a free interval. For example, 15:00–16:00 is a valid final interval when available. The booking screen reads the operational `Bookings` data. The simulated 2025 history used in Power BI cannot block a future booking.
3. Complete a reservation with the Stripe test card or PayPal sandbox account. Approve the booking from the desktop app and check that **Booking approved** appears in the mobile app. Both payment flows and the notification after starting the Subscriber were confirmed during the functional checks.

## Interpret the data

The catalog is a selection of locations. All 5,000 historical reservations are simulated. The operational demo catalog contains 22 simulated capacity values and 26 simulated hourly prices. The BI source has 171 pairs of overlapping reservations in the same space, including 107 pairs of approved reservations. The 9,704 hours measure sums approved reservation duration. It cannot be used as a measure of unique occupied hours, actual use, market demand, or future availability.
