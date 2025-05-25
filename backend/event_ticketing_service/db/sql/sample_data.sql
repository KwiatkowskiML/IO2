INSERT INTO locations (name, address, zipcode, city, country) VALUES
  ('Main Hall',   '123 Center St',      '00-100', 'Warsaw',    'Poland'),
  ('Open Arena',  '45 Stadium Rd',      NULL,     'Gdansk',    'Poland'),
  ('Conference X','789 Tech Parkway',   '10-200', 'Krakow',    'Poland');

INSERT INTO events (organizer_id, location_id, name,               description,                         start_date,          end_date,            minimum_age)
VALUES
  (1, 1, 'Spring Gala',    'An evening of music & dance',       '2025-05-10 19:00',  '2025-05-10 23:00',     0),
  (2, 2, 'Open-Air Concert','Rock bands under the stars',         '2025-06-20 18:00',  '2025-06-20 22:30',    12),
  (1, 3, 'Tech Conference', 'Latest in AI & Cloud Computing',    '2025-07-15 09:00',  '2025-07-17 17:00',    16);

INSERT INTO ticket_types (event_id, description,  max_count, price,   currency, available_from) VALUES
  (1, 'VIP Front Row',     50,        299.99, 'PLN',   '2025-04-01 09:00'),
  (1, 'General Admission', 200,       99.99,  'PLN',   '2025-04-01 09:00'),
  (2, 'Standing',          500,       79.50,  'PLN',   '2025-05-01 10:00'),
  (3, 'Full Conference',   300,       499.00, 'PLN',   '2025-05-01 08:00');

INSERT INTO tickets (type_id, owner_id, seat,      resell_price) VALUES
  (1, 101, 'A1',        NULL),
  (1, 102, 'A2',        NULL),
  (2, 103, NULL,        NULL),
  (3, 201, NULL,        89.50),
  (4, 301, NULL,        NULL);

INSERT INTO shopping_carts (customer_id) VALUES
  (101),
  (202),
  (303);
