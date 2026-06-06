
create database stock;
select * from price;
Alter table price 
rename column date to dates;


-- Which stocks generated the highest percentage growth from their first recorded closing price to their last recorded closing price?
WITH ranked_prices AS (
    SELECT 
        symbol,
        close,
        ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY dates ASC) as row_start,
        ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY dates DESC) as row_end
    FROM price
),
start_prices AS (
    SELECT symbol, close as start_close FROM ranked_prices WHERE row_start = 1
),
end_prices AS (
    SELECT symbol, close as end_close FROM ranked_prices WHERE row_end = 1
)
SELECT 
    s.symbol,
    s.start_close,
    e.end_close,
    ((e.end_close - s.start_close) / s.start_close) * 100 as percentage_growth
FROM start_prices s
JOIN end_prices e ON s.symbol = e.symbol
WHERE s.start_close > 0
ORDER BY percentage_growth DESC
LIMIT 10;


-- Which stocks generated the highest total return?
WITH ranked_prices AS (
    SELECT 
        symbol,
        close,
        ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY dates ASC) as row_start,
        ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY dates DESC) as row_end
    FROM price
),
start_prices AS (
    SELECT symbol, close as start_close FROM ranked_prices WHERE row_start = 1
),
end_prices AS (
    SELECT symbol, close as end_close FROM ranked_prices WHERE row_end = 1
)
SELECT 
    s.symbol,
    s.start_close,
    e.end_close,
    (e.end_close - s.start_close) as total_dollar_return
FROM start_prices  s
JOIN end_prices e ON s.symbol = e.symbol
ORDER BY total_dollar_return DESC
LIMIT 10;


-- Which stocks are the most volatile?
WITH daily_returns AS (
    SELECT 
        symbol,
        ((close - LAG(close) OVER (PARTITION BY symbol ORDER BY dates ASC)) / LAG(close) OVER (PARTITION BY symbol ORDER BY dates ASC)) as daily_return
    FROM price
)
SELECT 
    symbol,
    STDDEV(daily_return) as daily_volatility
FROM daily_returns
WHERE daily_return IS NOT NULL
GROUP BY symbol
ORDER BY daily_volatility DESC
LIMIT 10;

-- Which stocks are the most efficient?
WITH daily_returns AS (
    SELECT 
        symbol,
        ((close - LAG(close) OVER (PARTITION BY symbol ORDER BY dates ASC)) / LAG(close) OVER (PARTITION BY symbol ORDER BY dates ASC)) as daily_return
    FROM price
)
SELECT 
    symbol,
    AVG(daily_return) / STDDEV(daily_return) as efficiency_ratio
FROM daily_returns
WHERE daily_return IS NOT NULL
GROUP BY symbol
HAVING STDDEV(daily_return) > 0
ORDER BY efficiency_ratio DESC
LIMIT 10;

-- Which stocks have the highest average trading volume?
SELECT
    symbol,
    ROUND(AVG(volume), 0) AS avg_volume
FROM price
GROUP BY symbol
ORDER BY avg_volume DESC limit 10;

-- Which stocks had the most days with positive returns?
WITH daily_returns AS (
    SELECT 
        symbol,
        close,
        LAG(close) OVER (PARTITION BY symbol ORDER BY dates ASC) as prev_close
    FROM price
)
SELECT 
    symbol,
    COUNT(*) as positive_days
FROM daily_returns
WHERE prev_close IS NOT NULL 
  AND ((close - prev_close) / prev_close) > 0
GROUP BY symbol
ORDER BY positive_days DESC
LIMIT 10;

-- Top 10 overall gainers?
WITH ranked_prices AS (
    SELECT 
        symbol,
        dates,
        open,
        close,
        ROW_NUMBER() OVER(PARTITION BY symbol ORDER BY dates ASC) as row_start,
        ROW_NUMBER() OVER(PARTITION BY symbol ORDER BY dates DESC) as row_end
    FROM price
),
start_prices AS (
    SELECT symbol, open as start_price, dates as start_date
    FROM ranked_prices
    WHERE row_start = 1
),
end_prices AS (
    SELECT symbol, close as end_price, dates as end_date
    FROM ranked_prices
    WHERE row_end = 1
)
SELECT 
    s.symbol,
    s.start_date,
    s.start_price,
    e.end_date,
    e.end_price,
    ((e.end_price - s.start_price) / s.start_price) * 100 as percentage_gain
FROM start_prices s
JOIN end_prices e ON s.symbol = e.symbol
WHERE s.start_price > 0
ORDER BY percentage_gain DESC
LIMIT 10;


-- Top 10 overall Laggards?

WITH ranked_prices AS (
    SELECT 
        symbol,
        dates,
        open,
        close,
        ROW_NUMBER() OVER(PARTITION BY symbol ORDER BY dates ASC) as row_start,
        ROW_NUMBER() OVER(PARTITION BY symbol ORDER BY dates DESC) as row_end
    FROM price
),
start_prices AS (
    SELECT symbol, open as start_price, dates as start_date
    FROM ranked_prices
    WHERE row_start = 1
),
end_prices AS (
    SELECT symbol, close as end_price, dates as end_date
    FROM ranked_prices
    WHERE row_end = 1
)
SELECT 
    s.symbol,
    s.start_date,
    s.start_price,
    e.end_date,
    e.end_price,
    ((e.end_price - s.start_price) / s.start_price) * 100 as percentage_loss
FROM start_prices s
JOIN end_prices e ON s.symbol = e.symbol
WHERE s.start_price > 0
ORDER BY percentage_loss ASC
LIMIT 10;

-- Most volatile stocks
SELECT 
    symbol,
    COUNT(*) as trading_days,
    AVG(((high - low) / low) * 100) as avg_daily_volatility_pct
FROM price
WHERE low > 0 AND high IS NOT NULL AND low IS NOT NULL
GROUP BY symbol
ORDER BY avg_daily_volatility_pct DESC
LIMIT 10;

-- Most active stock by average Dollar Volume 
WITH daily_dollar_volume AS (
    SELECT 
        symbol,
        dates,
        (close * volume) as dollar_volume
    FROM price
)
SELECT 
    symbol,
    AVG(dollar_volume) as avg_dollar_volume
FROM daily_dollar_volume
GROUP BY symbol
ORDER BY avg_dollar_volume DESC
LIMIT 10;





