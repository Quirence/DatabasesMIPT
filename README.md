# Задание 5. Реализация схемы посредством DDL-скриптов

Схема базы данных состоит из следующих таблиц:

### Основные таблицы:
- **users** - хранит информацию о пользователях
- **verifications** - содержит данные верификации пользователей
- **wallets** - кошельки пользователей
- **instruments** - финансовые инструменты
- **transaction_types** - типы транзакций

### Таблицы-связки:
- **user_instruments** - связь пользователей с инструментами
- **wallet_instruments** - связь кошельков с инструментами
- **transactions** - транзакции по кошелькам

### Таблица версионных данных:
- **instrument_prices** - исторические цены инструментов

Все таблицы связаны через внешние ключи с соответствующими ограничениями целостности.
[Готовый файл](https://github.com/Quirence/DatabasesMIPT/blob/master/DDL.sql)

## Задание 6. Заполнение схемы данными

База данных заполнена тестовыми данными с соблюдением требований:

### Основные таблицы (15+ записей):
- **users** - 15 записей
- **verifications** - 10 записей (только для верифицированных пользователей)
- **wallets** - 15 записей
- **instruments** - 15 записей
- **transaction_types** - 6 типов транзакций

### Таблицы-связки (30+ записей):
- **user_instruments** - 30 записей
- **wallet_instruments** - 30 записей
- **transactions** - 30 записей

### Таблица версионных данных:
- **instrument_prices** - 25 записей (история изменения цен)\
[Готовый файл](https://github.com/Quirence/DatabasesMIPT/blob/master/DML.sql)

# Задание 7. 

Написание 10+ SQL-запросов, выполненных к реляционной базе данных, включающей таблицы пользователей, кошельков, транзакций и финансовых инструментов. Все запросы снабжены описанием логики, используемых операторов (`JOIN`, `WHERE`, `GROUP BY`, `HAVING`, оконные функции и др.) и предназначены для анализа пользовательской и финансовой активности.
```sql
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
```
**Описание:** Находит дату последней транзакции каждого пользователя, чья верификация прошла успешно.
```SQL
SELECT u.user_id, u.first_name, SUM(w.balance) as total_balance
FROM users u
         JOIN wallets w ON u.user_id = w.user_id
GROUP BY u.user_id
ORDER BY total_balance DESC LIMIT 5;
```
**Описание:** Определяет пятерку пользователей с наибольшими средствами на кошельках.
```sql
SELECT i.instrument_type,
       AVG(ip.price)           as avg_price,
       COUNT(t.transaction_id) as transaction_count
FROM instruments i
         JOIN instrument_prices ip ON i.instrument_id = ip.instrument_id
         LEFT JOIN transactions t ON i.instrument_id = t.instrument_id
WHERE ip.is_current = TRUE
GROUP BY i.instrument_type;
```
**Описание:** Показывает среднюю текущую цену и количество транзакций по каждому типу инструмента.
```sql
SELECT DATE_TRUNC('month', t.transaction_date) as month,
       tt.transaction_type_name,
       COUNT(*) as transaction_count,
       SUM(t.amount) as total_amount
FROM transactions t
    JOIN transaction_types tt
ON t.transaction_type_id = tt.transaction_type_id
GROUP BY month, tt.transaction_type_name
ORDER BY month DESC, total_amount DESC;
```
**Описание:** Ежемесячная статистика количества и суммы транзакций по их типам.
```sql
SELECT u.*
FROM users u
WHERE EXISTS (SELECT 1
              FROM verifications v
              WHERE v.user_id = u.user_id
                AND v.verification_status = 'REJECTED')
ORDER BY u.registration_date;
```
**Описание:** Список пользователей, чьи заявки на верификацию были отклонены.
```sql
SELECT instrument_id,
       price,
       valid_from,
       LAG(price) OVER (PARTITION BY instrument_id ORDER BY valid_from) as prev_price,
       (price - LAG(price) OVER (PARTITION BY instrument_id ORDER BY valid_from)) as price_diff
FROM instrument_prices
ORDER BY instrument_id, valid_from DESC;
```
**Описание:** Показывает изменение цен по каждому инструменту на основе прошлой цены.
```sql
SELECT u.user_id, ui.instrument_id, ui.quantity
FROM user_instruments ui
         JOIN users u ON ui.user_id = u.user_id
WHERE ui.quantity > (SELECT AVG(quantity)
                     FROM user_instruments)
ORDER BY ui.quantity DESC LIMIT 10;
```
**Описание:** Показывает пользователей, владеющих объемами инструментов выше среднего.
```sql
SELECT w.wallet_id,
       w.currency,
       SUM(wi.quantity * ip.price) as total_value
FROM wallets w
         JOIN wallet_instruments wi ON w.wallet_id = wi.wallet_id
         JOIN instrument_prices ip ON wi.instrument_id = ip.instrument_id
WHERE ip.is_current = TRUE
GROUP BY w.wallet_id
ORDER BY total_value DESC;
```
**Описание:** Рассчитывает текущую стоимость активов в каждом кошельке.
```sql
SELECT i.instrument_name,
       COUNT(t.transaction_id) as transaction_count
FROM instruments i
         LEFT JOIN transactions t ON i.instrument_id = t.instrument_id
GROUP BY i.instrument_id
ORDER BY transaction_count DESC;
```
**Описание:** Считает количество транзакций по каждому инструменту, включая те, что не участвовали в транзакциях.
```sql
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
```
[Готовый файл](https://github.com/Quirence/DatabasesMIPT/blob/master/Test.sql)

**Описание:** Показывает топ-10 пользователей по объему инвестиций с учетом их верификационного статуса и наличных средств.

# Дополнительные этапы проекта

## Задание 1. Создание представлений (не менее двух)

```sql
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
```
Статическое представление: verifications_expiring_soon \
Цель: Предупреждать, кого надо в ближайшее время попросить обновить документы. \
Срок действия паспорта/верификации — не меняется каждый час. \
Вполне достаточно обновлять вью раз в день, например, ночью, чтобы заранее уведомить пользователей.

```sql
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
```
Цель: получить текущий баланс всех кошельков пользователя.

```sql
CREATE VIEW current_instrument_prices AS
SELECT
    i.instrument_id,
    i.instrument_name,
    ip.price,
    ip.valid_from
FROM instruments i
JOIN instrument_prices ip ON i.instrument_id = ip.instrument_id
WHERE ip.is_current = TRUE;
```
Цель: показать текущие (актуальные) цены инструментов.

```sql
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
```
Цель: рассчитать стоимость портфеля в каждом кошельке, исходя из текущих цен.\
[Готовый файл](https://github.com/Quirence/DatabasesMIPT/blob/master/views.sql)
## Задание 2. Создание индексов для технических таблиц

1. Индексы для таблицы transactions
```sql
CREATE INDEX idx_transactions_wallet_date
ON transactions (wallet_id, transaction_date DESC);

CREATE INDEX idx_transactions_status
ON transactions (status);
```
```wallet_id``` + ```transaction_date``` часто используются в аналитике, истории транзакций.\
```status``` позволяет быстро фильтровать по PENDING, SUCCESS, FAILED и т.п.

2. Индексы для таблицы instrument_prices
```sql
CREATE INDEX idx_instrument_prices_current
ON instrument_prices (instrument_id)
WHERE is_current = TRUE;

CREATE INDEX idx_instrument_prices_valid_range
ON instrument_prices (valid_from, valid_to);
```
По ```is_current = TRUE``` строится множество представлений (например, portfolio_value_by_wallet).\
По временным интервалам ```valid_from, valid_to``` строятся графики и ретроспективные аналитики.\
[Готовый файл](https://github.com/Quirence/DatabasesMIPT/blob/master/indexes.sql)
