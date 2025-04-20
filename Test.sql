SELECT u.user_id,
       u.email,
       MAX(t.transaction_date) as last_transaction_date
FROM users u
         INNER JOIN verifications v ON u.user_id = v.user_id
         LEFT JOIN wallets w ON u.user_id = w.user_id
         LEFT JOIN transactions t ON w.wallet_id = t.wallet_id
WHERE v.verification_status = 'APPROVED'
GROUP BY u.user_id
ORDER BY u.registration_date DESC;

SELECT u.user_id, u.first_name, SUM(w.balance) as total_balance
FROM users u
         JOIN wallets w ON u.user_id = w.user_id
GROUP BY u.user_id
ORDER BY total_balance DESC LIMIT 5;

SELECT i.instrument_type,
       AVG(ip.price)           as avg_price,
       COUNT(t.transaction_id) as transaction_count
FROM instruments i
         JOIN instrument_prices ip ON i.instrument_id = ip.instrument_id
         LEFT JOIN transactions t ON i.instrument_id = t.instrument_id
WHERE ip.is_current = TRUE
GROUP BY i.instrument_type;

SELECT DATE_TRUNC('month', t.transaction_date) as month,
       tt.transaction_type_name,
       COUNT(*) as transaction_count,
       SUM(t.amount) as total_amount
FROM transactions t
    JOIN transaction_types tt
ON t.transaction_type_id = tt.transaction_type_id
GROUP BY month, tt.transaction_type_name
ORDER BY month DESC, total_amount DESC;

SELECT u.*
FROM users u
WHERE EXISTS (SELECT 1
              FROM verifications v
              WHERE v.user_id = u.user_id
                AND v.verification_status = 'REJECTED')
ORDER BY u.registration_date;

SELECT instrument_id,
       price,
       valid_from,
       LAG(price) OVER (PARTITION BY instrument_id ORDER BY valid_from) as prev_price, (price - LAG(price) OVER (PARTITION BY instrument_id ORDER BY valid_from)) as price_diff
FROM instrument_prices
ORDER BY instrument_id, valid_from DESC;

SELECT u.user_id, ui.instrument_id, ui.quantity
FROM user_instruments ui
         JOIN users u ON ui.user_id = u.user_id
WHERE ui.quantity > (SELECT AVG(quantity)
                     FROM user_instruments)
ORDER BY ui.quantity DESC LIMIT 10;

SELECT w.wallet_id,
       w.currency,
       SUM(wi.quantity * ip.price) as total_value
FROM wallets w
         JOIN wallet_instruments wi ON w.wallet_id = wi.wallet_id
         JOIN instrument_prices ip ON wi.instrument_id = ip.instrument_id
WHERE ip.is_current = TRUE
GROUP BY w.wallet_id
ORDER BY total_value DESC;

SELECT i.instrument_name,
       COUNT(t.transaction_id) as transaction_count
FROM instruments i
         LEFT JOIN transactions t ON i.instrument_id = t.instrument_id
GROUP BY i.instrument_id
ORDER BY transaction_count DESC;

SELECT u.user_id,
       COALESCE(SUM(w.balance), 0)              as total_cash,
       COALESCE(SUM(ui.quantity * ip.price), 0) as total_investments,
       CASE
           WHEN v.verification_status = 'APPROVED' THEN 'Verified'
           ELSE 'Not Verified'
           END                                  as verification_status
FROM users u
         LEFT JOIN wallets w ON u.user_id = w.user_id
         LEFT JOIN user_instruments ui ON u.user_id = ui.user_id
         LEFT JOIN instrument_prices ip ON ui.instrument_id = ip.instrument_id AND ip.is_current = TRUE
         LEFT JOIN verifications v ON u.user_id = v.user_id
GROUP BY u.user_id, v.verification_status
ORDER BY total_investments DESC LIMIT 10;