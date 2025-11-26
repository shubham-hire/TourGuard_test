-- Seed data for Community Safety Platform
-- Password for all users: "password123" (hashed with bcrypt)

-- Insert admin users
INSERT INTO users (id, name, phone, email, external_id, password_hash, role, medical_conditions, allergies, emergency_contacts) VALUES
('a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'Admin User', '+91-9876543210', 'admin@safety.com', NULL, '$2b$10$rKvVn5Z8yX3nQW9K5X3nQeO5Z8yX3nQW9K5X3nQeO5Z8yX3nQW9K5.', 'admin', NULL, NULL, NULL),
('b2c3d4e5-f6a7-5b6c-9d0e-1f2a3b4c5d6e', 'Sarah Johnson', '+91-9876543211', 'sarah.admin@safety.com', NULL, '$2b$10$rKvVn5Z8yX3nQW9K5X3nQeO5Z8yX3nQW9K5X3nQeO5Z8yX3nQW9K5.', 'admin', NULL, NULL, NULL);

-- Insert regular users
INSERT INTO users (id, name, phone, email, external_id, password_hash, role, medical_conditions, allergies, emergency_contacts) VALUES
('c3f1b9a2-8d9f-4e2b-9f6a-1f2a3b4c5d6e', 'Jane D', '+91-9876578950', 'jane.d@example.com', NULL, '$2b$10$rKvVn5Z8yX3nQW9K5X3nQeO5Z8yX3nQW9K5X3nQeO5Z8yX3nQW9K5.', 'user', 'Asthma (Inhaler)', 'Peanuts', 
'[{"name": "John D", "relation": "Husband", "phone": "+91-555-987-6432"}, {"name": "Sarah K", "relation": "Friend", "phone": "+91-555-987-5432"}]'::jsonb),
('d4e5f6a7-9e0f-5f3c-0a7b-2f3a4b5c6d7e', 'Raj Sharma', '+91-9876578951', 'raj.sharma@example.com', '$2b$10$rKvVn5Z8yX3nQW9K5X3nQeO5Z8yX3nQW9K5X3nQeO5Z8yX3nQW9K5.', 'user', 'Diabetes Type 2', 'None', 
'[{"name": "Priya Sharma", "relation": "Wife", "phone": "+91-555-123-4567"}]'::jsonb),
('e5f6a7b8-0f1a-6a4d-1b8c-3f4a5b6c7d8e', 'Maria Garcia', '+91-9876578952', 'maria.g@example.com', '$2b$10$rKvVn5Z8yX3nQW9K5X3nQeO5Z8yX3nQW9K5X3nQeO5Z8yX3nQW9K5.', 'user', NULL, 'Penicillin', 
'[{"name": "Carlos Garcia", "relation": "Brother", "phone": "+91-555-222-3333"}]'::jsonb);

-- Insert sample SOS events
INSERT INTO sos_events (id, user_id, latitude, longitude, accuracy_meters, message, status, created_at, acknowledged_at, resolved_at) VALUES
('d5a7f3e8-3d59-4b8b-9f1a-2f3b4c5d6e7f', 'c3f1b9a2-8d9f-4e2b-9f6a-1f2a3b4c5d6e', 19.075983, 72.877655, 12, 'I''m in danger — need help', 'pending', '2025-11-24 10:15:00+05:30', NULL, NULL),
('e6b8f4a9-4e6a-5c9c-0a2b-3f4c5d6e7f8a', 'd4e5f6a7-9e0f-5f3c-0a7b-2f3a4b5c6d7e', 19.076123, 72.878901, 18, 'Medical emergency - chest pain', 'acknowledged', '2025-11-24 09:30:00+05:30', '2025-11-24 09:32:00+05:30', NULL),
('f7c9e5b0-5f7b-6d0d-1b3c-4f5d6e7f8a9b', 'e5f6a7b8-0f1a-6a4d-1b8c-3f4a5b6c7d8e', 19.074567, 72.876234, 25, 'Being followed, need police', 'resolved', '2025-11-24 08:00:00+05:30', '2025-11-24 08:02:00+05:30', '2025-11-24 08:45:00+05:30');

-- Insert sample audit logs
INSERT INTO audit_logs (event_type, user_id, sos_event_id, payload) VALUES
('sos_status_change', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'e6b8f4a9-4e6a-5c9c-0a2b-3f4c5d6e7f8a', 
'{"previousStatus": "pending", "newStatus": "acknowledged", "adminName": "Admin User", "timestamp": "2025-11-24T09:32:00+05:30"}'::jsonb),
('sos_status_change', 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 'f7c9e5b0-5f7b-6d0d-1b3c-4f5d6e7f8a9b', 
'{"previousStatus": "acknowledged", "newStatus": "resolved", "adminName": "Admin User", "timestamp": "2025-11-24T08:45:00+05:30"}'::jsonb);
