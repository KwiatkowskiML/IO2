CREATE TABLE IF NOT EXISTS locations (
    location_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(255) NOT NULL,
    zipcode VARCHAR(20),
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS events (
    event_id SERIAL PRIMARY KEY,
    organizer_id INTEGER NOT NULL,
    location_id INTEGER NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    minimum_age INTEGER,
    status VARCHAR(20) NOT NULL DEFAULT 'created',
    FOREIGN KEY (location_id) REFERENCES locations(location_id) ON DELETE RESTRICT,
    CHECK (start_date < end_date)
);

CREATE TABLE IF NOT EXISTS ticket_types (
    type_id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL,
    description VARCHAR(255),
    max_count INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'PLN',
    available_from TIMESTAMP NOT NULL,
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS tickets (
    ticket_id SERIAL PRIMARY KEY,
    type_id INTEGER NOT NULL,
    owner_id INTEGER,
    seat VARCHAR(50),
    resell_price DECIMAL(10,2),
    FOREIGN KEY (type_id) REFERENCES ticket_types(type_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS shopping_carts (
    cart_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS cart_items (
    cart_item_id SERIAL PRIMARY KEY,
    cart_id INTEGER NOT NULL,
    ticket_id INTEGER NULL,
    ticket_type_id INTEGER NULL,
    quantity INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT fk_cart
        FOREIGN KEY(cart_id)
        REFERENCES shopping_carts(cart_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_ticket
        FOREIGN KEY(ticket_id)
        REFERENCES tickets(ticket_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_ticket_type
        FOREIGN KEY(ticket_type_id)
        REFERENCES ticket_types(type_id)
        ON DELETE CASCADE,
    
    CONSTRAINT chk_cart_item_type
        CHECK ((ticket_id IS NOT NULL AND ticket_type_id IS NULL) OR (ticket_id IS NULL AND ticket_type_id IS NOT NULL))
);
