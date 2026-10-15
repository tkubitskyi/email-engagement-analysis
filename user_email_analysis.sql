-- 1. Account counts for each unique combination of attributes
WITH account AS (
  SELECT
    ss.date AS created_date,                     -- session (account creation) date
    sp.country AS country,                       -- user country
    acc.send_interval,                           -- email send interval (daily/weekly/etc.)
    acc.is_verified,                             -- whether the account is verified
    acc.is_unsubscribed,                         -- whether the user unsubscribed
    COUNT(DISTINCT acc.id) AS account_cnt        -- number of unique accounts
  FROM data-analytics-mate.DA.account acc
  JOIN data-analytics-mate.DA.account_session acs
    ON acc.id = acs.account_id
  JOIN data-analytics-mate.DA.session ss
    ON ss.ga_session_id = acs.ga_session_id
  JOIN data-analytics-mate.DA.session_params sp
    ON ss.ga_session_id = sp.ga_session_id
  GROUP BY ss.date, sp.country, acc.send_interval, acc.is_verified, acc.is_unsubscribed
),


-- 2. Email engagement metrics: sent, opened, visited
email_metrics AS (
  SELECT
    DATE_ADD(ss.date, INTERVAL ems.sent_date DAY) AS sent_date, -- actual send date (session date + day offset)
    sp.country AS country,
    acc.send_interval,
    acc.is_verified,
    acc.is_unsubscribed,
    COUNT(DISTINCT ems.id_message) AS sent_msg,    -- emails sent
    COUNT(DISTINCT emo.id_message) AS open_msg,    -- emails opened
    COUNT(DISTINCT emv.id_message) AS visit_msg    -- emails that led to a site visit
  FROM data-analytics-mate.DA.email_sent ems
  LEFT JOIN data-analytics-mate.DA.email_open emo
    ON ems.id_message = emo.id_message
  LEFT JOIN data-analytics-mate.DA.email_visit emv
    ON ems.id_message = emv.id_message
  JOIN data-analytics-mate.DA.account_session acs
    ON ems.id_account = acs.account_id
  JOIN data-analytics-mate.DA.account acc
    ON acc.id = acs.account_id
  JOIN data-analytics-mate.DA.session ss
    ON acs.ga_session_id = ss.ga_session_id
  JOIN data-analytics-mate.DA.session_params sp
    ON ss.ga_session_id = sp.ga_session_id
  GROUP BY DATE_ADD(ss.date, INTERVAL ems.sent_date DAY), sp.country, acc.send_interval, acc.is_verified, acc.is_unsubscribed
),


-- 3. Combine account and email metrics into one dataset (UNION ALL)
unions AS (
  SELECT
    created_date AS date,
    country,
    send_interval,
    is_verified,
    is_unsubscribed,
    account_cnt,
    NULL AS sent_msg,
    NULL AS open_msg,
    NULL AS visit_msg
  FROM account

  UNION ALL

  SELECT
    sent_date AS date,
    country,
    send_interval,
    is_verified,
    is_unsubscribed,
    NULL AS account_cnt,
    sent_msg,
    open_msg,
    visit_msg
  FROM email_metrics
),


-- 4. Aggregate all metrics to one grain: date + grouping attributes
final_groups AS (
  SELECT
    date,
    country,
    send_interval,
    is_verified,
    is_unsubscribed,
    SUM(account_cnt) AS account_cnt,     -- accounts
    SUM(sent_msg) AS sent_msg,           -- sent
    SUM(open_msg) AS open_msg,           -- opened
    SUM(visit_msg) AS visit_msg          -- visited
  FROM unions
  GROUP BY date, country, send_interval, is_verified, is_unsubscribed
),


-- 5.1 Country-level totals (window functions)
country_sums AS (
  SELECT
    *,
    SUM(account_cnt) OVER (PARTITION BY country) AS total_country_account_cnt,  -- total accounts in the country
    SUM(sent_msg) OVER (PARTITION BY country) AS total_country_sent_cnt         -- total emails sent in the country
  FROM final_groups
),


-- 5.2 Rank countries by their totals
country_totals AS (
  SELECT
    *,
    DENSE_RANK() OVER (ORDER BY total_country_account_cnt DESC) AS rank_total_country_account_cnt,  -- country rank by accounts
    DENSE_RANK() OVER (ORDER BY total_country_sent_cnt DESC) AS rank_total_country_sent_cnt          -- country rank by sent emails
  FROM country_sums
)


-- 6. Final output: top-10 countries by accounts or by sent emails
SELECT
  date,
  country,
  send_interval,
  is_verified,
  is_unsubscribed,
  account_cnt,
  sent_msg,
  open_msg,
  visit_msg,
  total_country_account_cnt,
  total_country_sent_cnt,
  rank_total_country_account_cnt,
  rank_total_country_sent_cnt
FROM country_totals
WHERE rank_total_country_account_cnt <= 10     -- top 10 by accounts
   OR rank_total_country_sent_cnt <= 10        -- or top 10 by sent emails
ORDER BY date, country                          -- sort by date and country
