CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    login VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    creation_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    user_type VARCHAR(20) NOT NULL -- 'customer', 'organiser', 'administrator'
);

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE organisers (
    organiser_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    company_name VARCHAR(255) NOT NULL,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE administrators (
    admin_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE events (
    event_id SERIAL PRIMARY KEY,
    organiser_id INTEGER NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    minimum_age INTEGER NOT NULL DEFAULT 0,
    location_name VARCHAR(255) NOT NULL,
    location_address VARCHAR(255) NOT NULL,
    location_zipcode VARCHAR(20),
    location_city VARCHAR(100) NOT NULL,
    location_country VARCHAR(100) NOT NULL,
    location_latitude DECIMAL(10,8),
    location_longitude DECIMAL(11,8),
    status VARCHAR(20) NOT NULL DEFAULT 'created', -- 'created', 'in_progress', 'finished', 'cancelled'
    FOREIGN KEY (organiser_id) REFERENCES organisers(organiser_id) ON DELETE CASCADE,
    CHECK (start_date < end_date)
);

CREATE TABLE event_categories (
    event_id INTEGER NOT NULL,
    category VARCHAR(100) NOT NULL,
    PRIMARY KEY (event_id, category),
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE
);

CREATE TABLE ticket_types (
    type_id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL,
    description VARCHAR(255),
    max_count INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'PLN',
    available_from TIMESTAMP NOT NULL,
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE
);

CREATE TABLE tickets (
    ticket_id SERIAL PRIMARY KEY,
    type_id INTEGER NOT NULL,
    owner_id INTEGER,
    name_on_ticket VARCHAR(255),
    seat VARCHAR(50),
    for_resell BOOLEAN NOT NULL DEFAULT FALSE,
    resell_price DECIMAL(10,2),
    purchased BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(20) NOT NULL DEFAULT 'in_cart', -- 'in_cart', 'owned', 'on_sale', 'used', 'expired', 'cancelled'
    FOREIGN KEY (type_id) REFERENCES ticket_types(type_id) ON DELETE CASCADE,
    FOREIGN KEY (owner_id) REFERENCES customers(customer_id) ON DELETE SET NULL
);

CREATE TABLE shopping_carts (
    cart_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL UNIQUE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

CREATE TABLE cart_tickets (
    cart_id INTEGER NOT NULL,
    ticket_id INTEGER NOT NULL,
    added_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (cart_id, ticket_id),
    FOREIGN KEY (cart_id) REFERENCES shopping_carts(cart_id) ON DELETE CASCADE,
    FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id) ON DELETE CASCADE
);

CREATE TABLE messages (
    message_id SERIAL PRIMARY KEY,
    sender_id INTEGER NOT NULL,
    recipient_id INTEGER NOT NULL,
    event_id INTEGER,
    content TEXT NOT NULL,
    sent_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (recipient_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE SET NULL
);

-- Indeksy dla poprawy wydajności zapytań
CREATE INDEX idx_tickets_owner ON tickets(owner_id);
CREATE INDEX idx_tickets_type ON tickets(type_id);
CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_events_organiser ON events(organiser_id);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_date ON events(start_date, end_date);
CREATE INDEX idx_ticket_types_event ON ticket_types(event_id);

-- Wyzwalacz do automatycznego tworzenia koszyka dla nowego klienta
CREATE OR REPLACE FUNCTION create_shopping_cart()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO shopping_carts (customer_id) VALUES (NEW.customer_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_customer_insert
AFTER INSERT ON customers
FOR EACH ROW
EXECUTE FUNCTION create_shopping_cart();

-- Wyzwalacz aktualizujący status biletów po zmianie statusu wydarzenia
CREATE OR REPLACE FUNCTION update_tickets_on_event_cancel()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
        UPDATE tickets
        SET status = 'cancelled'
        FROM ticket_types
        WHERE tickets.type_id = ticket_types.type_id
        AND ticket_types.event_id = NEW.event_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_event_update
AFTER UPDATE ON events
FOR EACH ROW
EXECUTE FUNCTION update_tickets_on_event_cancel();

-- Procedura do czyszczenia przeterminowanych biletów w koszyku
CREATE OR REPLACE PROCEDURE cleanup_expired_cart_tickets()
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE tickets
    SET status = 'cancelled'
    WHERE ticket_id IN (
        SELECT t.ticket_id
        FROM tickets t
        JOIN cart_tickets ct ON t.ticket_id = ct.ticket_id
        WHERE t.status = 'in_cart'
        AND ct.added_at < (CURRENT_TIMESTAMP - INTERVAL '30 minutes')
    );

    DELETE FROM cart_tickets
    WHERE ticket_id IN (
        SELECT ticket_id
        FROM tickets
        WHERE status = 'cancelled'
    );
END;
$$;
