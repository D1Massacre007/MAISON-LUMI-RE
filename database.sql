-- Products table
CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    sku VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'EUR',
    in_stock BOOLEAN DEFAULT TRUE,
    stock_quantity INT DEFAULT 0,
    colors JSON, -- ['Black', 'Cognac', 'Ivory']
    sizes JSON, -- ['Small', 'Medium', 'Large']
    materials TEXT,
    handcrafted_days INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Product variants
CREATE TABLE product_variants (
    id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT,
    color VARCHAR(50),
    size VARCHAR(50),
    sku_suffix VARCHAR(20),
    stock_quantity INT DEFAULT 0,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- Customer inquiries / chat history
CREATE TABLE chat_conversations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    session_id VARCHAR(255),
    customer_email VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE chat_messages (
    id INT PRIMARY KEY AUTO_INCREMENT,
    conversation_id INT,
    role ENUM('user', 'assistant', 'system') NOT NULL,
    message TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES chat_conversations(id) ON DELETE CASCADE
);

-- Bespoke orders
CREATE TABLE bespoke_orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer_name VARCHAR(255) NOT NULL,
    customer_email VARCHAR(255) NOT NULL,
    customer_phone VARCHAR(50),
    product_type VARCHAR(100),
    leather_type VARCHAR(100),
    color_preference VARCHAR(100),
    hardware_type VARCHAR(100),
    monogram_text VARCHAR(10),
    notes TEXT,
    status ENUM('pending', 'consultation', 'in_production', 'completed') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Newsletter subscribers
CREATE TABLE newsletter_subscribers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255) UNIQUE NOT NULL,
    subscribed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Boutique locations
CREATE TABLE boutiques (
    id INT PRIMARY KEY AUTO_INCREMENT,
    city VARCHAR(100),
    address TEXT,
    district VARCHAR(100),
    phone VARCHAR(50),
    email VARCHAR(255),
    hours JSON,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8)
);

-- Policies
CREATE TABLE policies (
    id INT PRIMARY KEY AUTO_INCREMENT,
    policy_type ENUM('return', 'shipping', 'repair', 'monogram') UNIQUE NOT NULL,
    title VARCHAR(255),
    content TEXT,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO products (sku, name, category, description, price, in_stock, stock_quantity, colors, sizes, materials, handcrafted_days) VALUES
('ML-TOTE-001', 'Le Grand Sac', 'Tote', 'Full-grain Tuscan calfskin tote bag, hand-stitched by master artisans. Features interior pocket and gold hardware.', 2450.00, TRUE, 15, '["Black", "Cognac", "Ivory"]', '["Large"]', 'Full-grain calfskin, vegetable-tanned', 5),
('ML-EVE-002', 'Nuit Étoilée', 'Evening', 'Elegant evening bag with subtle shimmer, hand-patinated finish. Limited edition.', 3200.00, TRUE, 4, '["Black", "Bordeaux"]', '["One Size"]', 'Calfskin with metallic finish', 3),
('ML-TPH-003', 'Bambou Élégant', 'Top Handle', 'Sophisticated top handle bag with bamboo-inspired handle detail.', 1890.00, TRUE, 8, '["Cognac", "Black"]', '["Medium"]', 'Full-grain calfskin', 4),
('ML-SHL-004', 'Demi-Lune', 'Shoulder', 'Crescent-shaped shoulder bag, versatile day-to-night piece.', 2100.00, TRUE, 12, '["Ivory", "Black"]', '["One Size"]', 'Calfskin with suede lining', 4),
('ML-CLT-005', 'Soirée Chic', 'Clutch', 'Minimalist clutch for sophisticated evenings.', 1450.00, TRUE, 10, '["Gold", "Black", "Silver"]', '["One Size"]', 'Metallic calfskin', 3);

INSERT INTO product_variants (product_id, color, size, sku_suffix, stock_quantity) VALUES
(1, 'Black', 'Large', 'BLK-L', 8),
(1, 'Cognac', 'Large', 'COG-L', 5),
(1, 'Ivory', 'Large', 'IVR-L', 2),
(2, 'Black', 'One Size', 'BLK-OS', 3),
(2, 'Bordeaux', 'One Size', 'BRD-OS', 1),
(3, 'Cognac', 'Medium', 'COG-M', 5),
(3, 'Black', 'Medium', 'BLK-M', 3),
(4, 'Ivory', 'One Size', 'IVR-OS', 7),
(4, 'Black', 'One Size', 'BLK-OS', 5),
(5, 'Gold', 'One Size', 'GLD-OS', 4),
(5, 'Black', 'One Size', 'BLK-OS', 4),
(5, 'Silver', 'One Size', 'SLV-OS', 2);

INSERT INTO boutiques (city, address, district, phone, email, hours) VALUES
('Paris', '12 Rue de Grenelle', 'Saint-Germain-des-Prés', '+33 1 42 22 33 44', 'paris@maisonlumiere.com', '{"monday":"10:00-19:00","tuesday":"10:00-19:00","wednesday":"10:00-19:00","thursday":"10:00-19:00","friday":"10:00-20:00","saturday":"11:00-19:00","sunday":"Closed"}'),
('Milan', 'Via Montenapoleone 8', 'Quadrilatero della Moda', '+39 02 7639 1234', 'milan@maisonlumiere.com', '{"monday":"10:00-19:00","tuesday":"10:00-19:00","wednesday":"10:00-19:00","thursday":"10:00-19:00","friday":"10:00-20:00","saturday":"10:30-19:00","sunday":"12:00-18:00"}'),
('New York', '785 Madison Avenue', 'Upper East Side', '+1 212 555 1234', 'nyc@maisonlumiere.com', '{"monday":"11:00-19:00","tuesday":"11:00-19:00","wednesday":"11:00-19:00","thursday":"11:00-19:00","friday":"11:00-20:00","saturday":"11:00-19:00","sunday":"12:00-18:00"}'),
('Tokyo', '5-3-16 Minami-Aoyama', 'Aoyama', '+81 3 6427 1234', 'tokyo@maisonlumiere.com', '{"monday":"11:00-20:00","tuesday":"11:00-20:00","wednesday":"11:00-20:00","thursday":"11:00-20:00","friday":"11:00-20:00","saturday":"11:00-20:00","sunday":"11:00-19:00"}');

INSERT INTO policies (policy_type, title, content) VALUES
('return', 'Return Policy', 'You may return unworn items within 14 days of delivery. Items must include original packaging and dust bag. Bespoke and monogrammed pieces are final sale.'),
('shipping', 'Shipping Policy', 'Complimentary worldwide express shipping on all orders. Delivery within 3-5 business days. Signature required upon delivery.'),
('repair', 'Care & Repair', 'Lifetime repair service at our Florence atelier. We restore patina, replace hardware, and restitch seams. Contact client services to initiate a repair.'),
('monogram', 'Bespoke Monogramming', 'Complimentary monogramming (up to 3 initials) available on most pieces. Adds 3-4 weeks to delivery time. Full bespoke consultation available for custom pieces.');
