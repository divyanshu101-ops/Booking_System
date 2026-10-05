-- =====================================================
-- 1. USERS (the admin is also a row here, role = 'admin')
-- =====================================================
CREATE TABLE users (
  id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  email         TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role          TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  balance       BIGINT NOT NULL DEFAULT 0 CHECK (balance >= 0),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- at most one admin can ever exist
CREATE UNIQUE INDEX one_admin_only ON users (role) WHERE role = 'admin';

-- =====================================================
-- 2. SHOWS (template created by admin: what is playing)
-- =====================================================
CREATE TABLE shows (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title      TEXT NOT NULL,
  status     TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'CANCELLED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================
-- 3. SHOW_SEAT_TEMPLATES (seat layout and price, copied into every showtime)
-- =====================================================
CREATE TABLE show_seat_templates (
  show_id BIGINT NOT NULL REFERENCES shows (id),
  label   TEXT NOT NULL,
  price   BIGINT NOT NULL CHECK (price > 0),
  PRIMARY KEY (show_id, label)
);

-- =====================================================
-- 4. SHOWTIMES (one real screening: a show on a specific date and shift)
-- =====================================================
CREATE TABLE showtimes (
  id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  show_id   BIGINT NOT NULL REFERENCES shows (id),
  starts_at TIMESTAMPTZ NOT NULL,
  status    TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'CANCELLED')),
  UNIQUE (show_id, starts_at)
);

CREATE INDEX idx_showtimes_starts_at ON showtimes (starts_at);

-- =====================================================
-- 5. BOOKINGS
-- =====================================================
CREATE TABLE bookings (
  id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id         BIGINT NOT NULL REFERENCES users (id),
  showtime_id     BIGINT NOT NULL REFERENCES showtimes (id),
  total_amount    BIGINT NOT NULL CHECK (total_amount > 0),
  status          TEXT NOT NULL DEFAULT 'CONFIRMED' CHECK (status IN ('CONFIRMED', 'CANCELLED')),
  idempotency_key TEXT NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  cancelled_at    TIMESTAMPTZ,
  UNIQUE (user_id, idempotency_key),
  CHECK ((status = 'CANCELLED') = (cancelled_at IS NOT NULL))
);

CREATE INDEX idx_bookings_user ON bookings (user_id);
CREATE INDEX idx_bookings_showtime ON bookings (showtime_id);

-- =====================================================
-- 6. SEATS (each seat belongs to exactly one showtime)
-- =====================================================
CREATE TABLE seats (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  showtime_id BIGINT NOT NULL REFERENCES showtimes (id),
  label       TEXT NOT NULL,
  price       BIGINT NOT NULL CHECK (price > 0),
  status      TEXT NOT NULL DEFAULT 'AVAILABLE' CHECK (status IN ('AVAILABLE', 'BOOKED')),
  booking_id  BIGINT REFERENCES bookings (id),
  UNIQUE (showtime_id, label),
  CHECK ((status = 'BOOKED') = (booking_id IS NOT NULL))
);

CREATE INDEX idx_seats_showtime ON seats (showtime_id);

-- =====================================================
-- 7. BOOKING_SEATS (history, keeps the price paid at booking time)
-- =====================================================
CREATE TABLE booking_seats (
  booking_id       BIGINT NOT NULL REFERENCES bookings (id),
  seat_id          BIGINT NOT NULL REFERENCES seats (id),
  price_at_booking BIGINT NOT NULL CHECK (price_at_booking > 0),
  PRIMARY KEY (booking_id, seat_id)
);

-- =====================================================
-- 8. LEDGER (insert-only record of every money movement)
-- =====================================================
CREATE TABLE ledger (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    BIGINT NOT NULL REFERENCES users (id),
  booking_id BIGINT REFERENCES bookings (id),
  entry_type TEXT NOT NULL CHECK (entry_type IN
             ('SIGNUP_BONUS', 'BOOKING_PAYMENT', 'BOOKING_CREDIT', 'REFUND_DEBIT', 'REFUND_CREDIT')),
  amount     BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (
    (entry_type IN ('SIGNUP_BONUS', 'BOOKING_CREDIT', 'REFUND_CREDIT') AND amount > 0) OR
    (entry_type IN ('BOOKING_PAYMENT', 'REFUND_DEBIT') AND amount < 0)
  ),
  CHECK ((entry_type = 'SIGNUP_BONUS') = (booking_id IS NULL))
);

CREATE INDEX idx_ledger_user ON ledger (user_id);
CREATE INDEX idx_ledger_booking ON ledger (booking_id);