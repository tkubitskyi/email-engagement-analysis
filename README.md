# 📧 Email Engagement & Account Activity Analysis | BigQuery + Looker Studio

**[▶ Open the interactive dashboard](https://datastudio.google.com/s/uBgeeD-vZjc)**

## 🔍 Project Overview

This project analyzes account creation and email engagement for an e-commerce product using data in Google BigQuery.

I built a single reporting-ready dataset that combines account metrics and email activity metrics, then visualized it in Looker Studio to compare countries by volume, engagement and activity over time.

## 🎯 Business Questions

- Which countries bring the most accounts and receive the most emails?
- Does email volume simply follow the size of the user base, or do some markets receive disproportionately more?
- How engaged are users in different countries (open rate, click rate)?
- How did email activity change over time?

## 🛠 Tools & Techniques

- **SQL / Google BigQuery:** CTEs, `UNION ALL`, window functions (`SUM() OVER`, `DENSE_RANK()`)
- **Looker Studio:** calculated fields, bar charts, time series, multi-page report
- **Analysis:** segmentation by country and account attributes, ratio metrics, data validation

## 📊 Dataset Structure

The final dataset is aggregated by `date`, `country`, `send_interval`, `is_verified` and `is_unsubscribed`.

| Metric | Description |
|---|---|
| `account_cnt` | Number of created accounts |
| `sent_msg` | Emails sent |
| `open_msg` | Emails opened |
| `visit_msg` | Emails that led to a site visit |
| `total_country_account_cnt` | Total accounts per country (window function) |
| `total_country_sent_cnt` | Total emails sent per country (window function) |
| `rank_total_country_account_cnt` | Country rank by accounts |
| `rank_total_country_sent_cnt` | Country rank by sent emails |

The output is filtered to the top 10 countries by accounts **or** by sent emails (11 countries due to rank ties).

## ⚙️ What I Did

1. Calculated account metrics and email metrics in separate CTEs, because they live on different date logic (account creation date vs. email send date).
2. Combined both metric groups with `UNION ALL` and aggregated them to one grain.
3. Added country-level totals and rankings with window functions.
4. Built engagement metrics in Looker Studio as **ratios of sums**: `SUM(open_msg) / SUM(sent_msg)` and `SUM(visit_msg) / SUM(sent_msg)`.

## 📈 Key Insights

- **The United States dominates** both account creation (12,384 accounts) and email volume (233,503 sent messages).
- **Email volume scales with the user base.** Country rankings by sent emails closely mirror rankings by accounts, at roughly 17–21 messages per account.
- **Engagement differs more than volume.** Overall open rate is 35.5% and click rate 3.9%. China has the highest open rate (41.2%), while Spain and Singapore have the lowest (~29.5%).
- **Singapore stands out:** the highest email volume per account (23.7) combined with the lowest click rate (2.6%). This may point to email fatigue. It is a hypothesis worth testing (for example, an A/B test on send frequency), not a proven cause.
- **Activity over time:** email volume rises through November 2020, plateaus from mid-December to late January, then drops. The ramp-up and drop likely reflect the boundaries of the data window rather than changes in user behavior.

## 📷 Dashboard

<img width="871" height="652" alt="Знімок екрана 2026-10-15 173613" src="https://github.com/user-attachments/assets/41bc8a6d-4ada-48bf-a8f5-5c07ecec4e82" />
<img width="872" height="658" alt="Знімок екрана 2026-10-15 173627" src="https://github.com/user-attachments/assets/2dbd9391-eb73-4aee-b13a-67fc5e712b65" />

- **Page 1 – Volume by Country:** accounts and sent emails by country, metrics table
- **Page 2 – Engagement & Timeline:** open rate and click rate by country, daily email activity

## 🔁 Revision Note

An earlier version of the dashboard summed the country rank field in Looker Studio. Because the rank repeats on every row, the charts showed *rank × number of rows* and inverted the country comparison, which led to an incorrect insight. I found the issue while re-validating the dashboard against the query output, fixed the aggregation, replaced rank charts with direct metrics and added engagement rates.

## 🚀 Outcome

Raw data → SQL transformation → reporting-ready dataset → dashboard → validated business insights.
