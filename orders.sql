CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    configuration_id VARCHAR(50),
    order_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);