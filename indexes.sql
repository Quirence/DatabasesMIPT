-- Индекс для быстрого поиска транзакций по кошельку и дате
CREATE INDEX idx_transactions_wallet_date
ON transactions (wallet_id, transaction_date DESC);

-- Индекс по статусу транзакции
CREATE INDEX idx_transactions_status
ON transactions (status);

-- Индекс для ускорения поиска актуальных цен
CREATE INDEX idx_instrument_prices_current
ON instrument_prices (instrument_id)
WHERE is_current = TRUE;

-- Индекс по периоду действия (часто нужен в исторических графиках)
CREATE INDEX idx_instrument_prices_valid_range
ON instrument_prices (valid_from, valid_to);
