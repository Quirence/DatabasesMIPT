CREATE TABLE users
(
    user_id    SERIAL PRIMARY KEY,
    first_name VARCHAR(200) NOT NULL,
    last_name  VARCHAR(200) NOT NULL,
    email      VARCHAR(200) NOT NULL UNIQUE CHECK (email ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
) ,
    phone_number VARCHAR(20) CHECK (phone_number ~ '^\+?[0-9]{10,15}$'),
    registration_date TIMESTAMP NOT NULL CHECK (registration_date <= CURRENT_TIMESTAMP),
    status VARCHAR(100) NOT NULL,
    password_hash VARCHAR(500) NOT NULL,
    salt VARCHAR(500) NOT NULL
);

CREATE TABLE verifications
(
    verification_id SERIAL PRIMARY KEY,
    user_id         INTEGER      NOT NULL UNIQUE REFERENCES users (user_id) ON DELETE CASCADE,
    passport_number VARCHAR(100) NOT NULL CHECK (passport_number ~ '^[0-9]{4} [0-9]{6}$'
) ,
    full_name VARCHAR(200) NOT NULL,
    date_of_birth DATE NOT NULL CHECK (date_of_birth < CURRENT_DATE),
    issue_date DATE NOT NULL CHECK (issue_date <= CURRENT_DATE),
    expiry_date DATE CHECK (expiry_date IS NULL OR expiry_date > CURRENT_DATE),
    issuing_authority VARCHAR(200) NOT NULL,
    verification_status VARCHAR(100) NOT NULL CHECK (verification_status IN ('PENDING', 'APPROVED', 'REJECTED')),
    verification_date TIMESTAMP NOT NULL
);

CREATE TABLE wallets
(
    wallet_id   SERIAL PRIMARY KEY,
    user_id     INTEGER        NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    wallet_name VARCHAR(200),
    currency    VARCHAR(10),
    balance     DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    created_at  TIMESTAMP      NOT NULL CHECK (created_at <= CURRENT_TIMESTAMP),
    status      VARCHAR(100)
);

CREATE TABLE instruments
(
    instrument_id   SERIAL PRIMARY KEY,
    instrument_name VARCHAR(200),
    instrument_type VARCHAR(100),
    market          VARCHAR(100),
    currency        VARCHAR(10),
    issued_date     DATE NOT NULL CHECK (issued_date <= CURRENT_DATE),
    maturity_date   DATE CHECK (maturity_date IS NULL OR maturity_date >= issued_date)
);

CREATE TABLE user_instruments
(
    user_id         INTEGER        NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    instrument_id   INTEGER        NOT NULL REFERENCES instruments (instrument_id) ON DELETE CASCADE,
    quantity        DECIMAL(18, 4) NOT NULL CHECK (quantity > 0),
    purchased_price DECIMAL(18, 4),
    purchased_at    TIMESTAMP,
    PRIMARY KEY (user_id, instrument_id)
);

CREATE TABLE wallet_instruments
(
    wallet_id       INTEGER        NOT NULL REFERENCES wallets (wallet_id) ON DELETE CASCADE,
    instrument_id   INTEGER        NOT NULL REFERENCES instruments (instrument_id) ON DELETE CASCADE,
    quantity        DECIMAL(18, 4),
    purchased_price DECIMAL(18, 4) NOT NULL CHECK (purchased_price >= 0),
    purchased_at    TIMESTAMP      NOT NULL CHECK (purchased_at <= CURRENT_TIMESTAMP),
    PRIMARY KEY (wallet_id, instrument_id)
);

CREATE TABLE transaction_types
(
    transaction_type_id   SERIAL PRIMARY KEY,
    transaction_type_name VARCHAR(100),
    description           TEXT
);

CREATE TABLE transactions
(
    transaction_id      SERIAL PRIMARY KEY,
    wallet_id           INTEGER        NOT NULL REFERENCES wallets (wallet_id) ON DELETE CASCADE,
    transaction_type_id INTEGER        NOT NULL REFERENCES transaction_types (transaction_type_id),
    instrument_id       INTEGER REFERENCES instruments (instrument_id),
    quantity            DECIMAL(18, 4) CHECK (quantity > 0 OR quantity IS NULL),
    amount              DECIMAL(18, 2) NOT NULL CHECK (amount > 0),
    transaction_date    TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP CHECK (transaction_date <= CURRENT_TIMESTAMP),
    description         TEXT,
    status              VARCHAR(100)
);

CREATE TABLE instrument_prices
(
    instrument_id INTEGER        NOT NULL REFERENCES instruments (instrument_id) ON DELETE CASCADE,
    price         DECIMAL(18, 4) NOT NULL,
    valid_from    TIMESTAMP      NOT NULL,
    valid_to      TIMESTAMP CHECK (valid_to IS NULL OR valid_to > valid_from),
    is_current    BOOLEAN        NOT NULL DEFAULT TRUE CHECK (
        (is_current = TRUE AND valid_to IS NULL) OR
        (is_current = FALSE AND valid_to IS NOT NULL)
        ),
    PRIMARY KEY (instrument_id, valid_from)
);