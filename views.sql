CREATE MATERIALIZED VIEW verifications_expiring_soon AS
SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    v.passport_number,
    v.expiry_date,
    v.verification_status
FROM users u
JOIN verifications v ON u.user_id = v.user_id
WHERE
    v.expiry_date IS NOT NULL
    AND v.expiry_date <= CURRENT_DATE + INTERVAL '14 days'
    AND v.verification_status = 'APPROVED';

-- Пример ручного обновления раз в сутки - чтобы предупредить пользователей.
REFRESH MATERIALIZED VIEW verifications_expiring_soon;

CREATE VIEW wallet_balances_by_user AS
SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    w.wallet_id,
    w.wallet_name,
    w.currency,
    w.balance
FROM users u
JOIN wallets w ON u.user_id = w.user_id;

CREATE VIEW current_instrument_prices AS
SELECT
    i.instrument_id,
    i.instrument_name,
    ip.price,
    ip.valid_from
FROM instruments i
JOIN instrument_prices ip ON i.instrument_id = ip.instrument_id
WHERE ip.is_current = TRUE;

CREATE VIEW portfolio_value_by_wallet AS
SELECT
    wi.wallet_id,
    w.wallet_name,
    w.currency,
    SUM(wi.quantity * ip.price) AS portfolio_value
FROM wallet_instruments wi
JOIN wallets w ON wi.wallet_id = w.wallet_id
JOIN instrument_prices ip ON wi.instrument_id = ip.instrument_id AND ip.is_current = TRUE
GROUP BY wi.wallet_id, w.wallet_name, w.currency;
