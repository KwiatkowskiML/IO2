-- This script populates the database with a complete set of mock data for testing.
-- It is designed to be idempotent, so it can be run multiple times without creating duplicate entries.
-- Hashed password for 'Password123' is '$2b$12$6Nmd5vImpsdcoJvIPrjY2u4eZlIVfsh1i6Gv/pfFkMNTj8Jg5v3s.'

-- ==== USERS ====
INSERT INTO users (user_id, email, login, password_hash, first_name, last_name, user_type, is_active) VALUES
(1, 'customer@example.com', 'testcustomer', '$2b$12$6Nmd5vImpsdcoJvIPrjY2u4eZlIVfsh1i6Gv/pfFkMNTj8Jg5v3s.', 'John', 'Doe', 'customer', true),
(2, 'organizer@example.com', 'testorganizer', '$2b$12$6Nmd5vImpsdcoJvIPrjY2u4eZlIVfsh1i6Gv/pfFkMNTj8Jg5v3s.', 'Jane', 'Smith', 'organizer', true),
(3, 'unverified@example.com', 'unverifiedorg', '$2b$12$6Nmd5vImpsdcoJvIPrjY2u4eZlIVfsh1i6Gv/pfFkMNTj8Jg5v3s.', 'Unverified', 'User', 'organizer', true),
(4, 'admin@example.com', 'testadmin', '$2b$12$6Nmd5vImpsdcoJvIPrjY2u4eZlIVfsh1i6Gv/pfFkMNTj8Jg5v3s.', 'Admin', 'Istrator', 'administrator', true)
ON CONFLICT (user_id) DO NOTHING;

-- ==== ROLES ====
INSERT INTO customers (customer_id, user_id) VALUES (1, 1) ON CONFLICT (customer_id) DO NOTHING;
INSERT INTO organizers (organizer_id, user_id, company_name, is_verified) VALUES (1, 2, 'Live Events LLC', true) ON CONFLICT (organizer_id) DO NOTHING;
INSERT INTO organizers (organizer_id, user_id, company_name, is_verified) VALUES (2, 3, 'New Wave Promos', false) ON CONFLICT (organizer_id) DO NOTHING;
INSERT INTO administrators (admin_id, user_id) VALUES (1, 4) ON CONFLICT (admin_id) DO NOTHING;

-- ==== LOCATIONS ====
INSERT INTO locations (location_id, name, address, city, country) VALUES
(1, 'National Stadium', 'al. Księcia Józefa Poniatowskiego 1', 'Warsaw', 'Poland'),
(2, 'Tauron Arena', 'Stanisława Lema 7', 'Krakow', 'Poland'),
(3, 'Ergo Arena', 'plac Dwóch Miast 1', 'Gdansk', 'Poland'),
(4, 'Centennial Hall', 'Wystawowa 1', 'Wroclaw', 'Poland'),
(5, 'City Park', 'Central Avenue', 'Warsaw', 'Poland')
ON CONFLICT (location_id) DO NOTHING;

-- ==== EVENTS ====
INSERT INTO events (event_id, organizer_id, location_id, name, description, start_date, end_date, minimum_age, status) VALUES
(1, 1, 1, 'Rock Fest 2025', 'The biggest rock festival in the country, featuring international stars and local legends. Three days of pure energy!', '2025-07-18 16:00:00', '2025-07-20 23:00:00', 18, 'created'),
(2, 1, 2, 'Smooth Jazz Night', 'An elegant evening with the smoothest jazz tunes. Perfect for a relaxing night out.', '2025-08-22 20:00:00', '2025-08-22 23:30:00', 21, 'created'),
(3, 1, 4, 'Tech Conference 2024', 'A look back at the future of technology. Keynotes, workshops, and networking.', '2024-05-10 09:00:00', '2024-05-12 18:00:00', NULL, 'created'),
(4, 2, 5, 'Local Charity 5K Run', 'A fun run for a good cause. All proceeds go to the local animal shelter. This event is pending organizer verification.', '2025-09-05 10:00:00', '2025-09-05 13:00:00', NULL, 'pending')
ON CONFLICT (event_id) DO NOTHING;

-- ==== TICKET TYPES ====
INSERT INTO ticket_types (type_id, event_id, description, max_count, price, currency, available_from) VALUES
(1, 1, 'Standard Entry', 5000, 199.99, 'PLN', '2025-01-15 12:00:00'),
(2, 1, 'VIP Backstage Pass', 200, 499.50, 'PLN', '2025-01-15 12:00:00'),
(3, 2, 'General Admission', 300, 120.00, 'PLN', '2025-03-01 12:00:00'),
(4, 3, 'Regular Pass', 1000, 850.00, 'PLN', '2024-01-10 12:00:00')
ON CONFLICT (type_id) DO NOTHING;

-- ==== TICKETS (Owned by customer@example.com, user_id=1) ====
INSERT INTO tickets (ticket_id, type_id, owner_id, seat, resell_price) VALUES
(1, 1, 1, 'GA-A123', NULL),
(2, 2, 1, 'VIP-B12', 650.00), -- This ticket is on resale
(3, 4, 1, 'Row 15, Seat 8', NULL) -- A ticket for a past event
ON CONFLICT (ticket_id) DO NOTHING;

-- ==== SHOPPING CART for customer@example.com (customer_id=1) ====
INSERT INTO shopping_carts (cart_id, customer_id) VALUES
(1, 1)
ON CONFLICT (cart_id) DO NOTHING;

-- ==== CART ITEMS for customer@example.com ====
INSERT INTO cart_items (cart_item_id, cart_id, ticket_type_id, quantity) VALUES
(1, 1, 3, 2) -- 2 tickets for 'Smooth Jazz Night' in the cart
ON CONFLICT (cart_item_id) DO NOTHING;


-- Manually update sequences to prevent collision with new auto-generated IDs.
-- This is crucial for a robust seeding script that uses hardcoded IDs.
SELECT setval('users_user_id_seq', (SELECT MAX(user_id) FROM users));
SELECT setval('customers_customer_id_seq', (SELECT MAX(customer_id) FROM customers), (SELECT MAX(customer_id) FROM customers) IS NOT NULL);
SELECT setval('organizers_organizer_id_seq', (SELECT MAX(organizer_id) FROM organizers));
SELECT setval('administrators_admin_id_seq', (SELECT MAX(admin_id) FROM administrators), (SELECT MAX(admin_id) FROM administrators) IS NOT NULL);
SELECT setval('locations_location_id_seq', (SELECT MAX(location_id) FROM locations));
SELECT setval('events_event_id_seq', (SELECT MAX(event_id) FROM events));
SELECT setval('ticket_types_type_id_seq', (SELECT MAX(type_id) FROM ticket_types));
SELECT setval('tickets_ticket_id_seq', (SELECT MAX(ticket_id) FROM tickets));
SELECT setval('shopping_carts_cart_id_seq', (SELECT MAX(cart_id) FROM shopping_carts));
SELECT setval('cart_items_cart_item_id_seq', (SELECT MAX(cart_item_id) FROM cart_items));
