CREATE TABLE bookings (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL,

    room_id BIGINT NOT NULL,

    check_in DATE NOT NULL,

    check_out DATE NOT NULL,

    booking_price NUMERIC(12, 2) NOT NULL,

    booking_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_bookings_user
        FOREIGN KEY (user_id)
        REFERENCES users(id),

    CONSTRAINT fk_bookings_room
        FOREIGN KEY (room_id)
        REFERENCES rooms(id),

    CONSTRAINT check_booking_dates
        CHECK (check_out > check_in),

    CONSTRAINT check_booking_price
        CHECK (booking_price >= 0),

    CONSTRAINT check_booking_status
        CHECK (
            status IN (
                'PENDING',
                'CONFIRMED',
                'CANCELLED',
                'COMPLETED'
            )
        )
);