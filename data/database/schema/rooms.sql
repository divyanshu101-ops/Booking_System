CREATE TABLE rooms(
	id BIGSERIAL PRIMARY KEY,
	hotel_id BIGINT NOT NULL,
	room_number VARCHAR(20) NOT NULL,
	room_type VARCHAR(50) NOT NULL,
	max_occupancy INT NOT NULL,
	price_per_night NUMERIC(10, 2) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_rooms_hotel
        FOREIGN KEY (hotel_id)
        REFERENCES hotels(id),

    CONSTRAINT unique_room_number_per_hotel
        UNIQUE (hotel_id, room_number),

    CONSTRAINT check_max_occupancy
        CHECK (max_occupancy > 0),

    CONSTRAINT check_room_price
        CHECK (price_per_night >= 0),

    CONSTRAINT check_room_status
        CHECK (status IN ('AVAILABLE', 'MAINTENANCE', 'INACTIVE'))
)