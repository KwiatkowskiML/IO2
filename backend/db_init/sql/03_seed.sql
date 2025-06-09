-- Insert a default location for testing
INSERT INTO locations (location_id, name, address, city, country)
VALUES (1, 'Test Venue', '123 Test Street', 'Testville', 'Testland')
ON CONFLICT (location_id) DO NOTHING;

INSERT INTO locations (location_id, name, address, city, country)
VALUES (2, 'Another Venue', '456 Sample Ave', 'Testville', 'Testland')
ON CONFLICT (location_id) DO NOTHING;
