-- ThaliumX Test Data Seeding Script
-- ===================================
-- Seeds database with test users, tenants, and data for comprehensive testing

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- PLATFORM ADMIN USER
-- ============================================
INSERT INTO users (
    id, keycloak_id, email, email_verified, first_name, last_name,
    status, kyc_status, kyc_level, mfa_enabled, password_hash,
    created_at, updated_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440000',
    'platform-admin-keycloak-id',
    'admin@thaliumx.com',
    true,
    'Platform',
    'Admin',
    'active',
    'approved',
    3,
    true,
    crypt('AdminPass123!', gen_salt('bf')),
    NOW(),
    NOW()
) ON CONFLICT (email) DO NOTHING;

-- ============================================
-- BROKER TENANT
-- ============================================
INSERT INTO tenants (
    id, name, slug, domain, type, status, keycloak_realm,
    contact_email, settings, fee_structure, limits, features,
    created_at, updated_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440001',
    'Test Broker LLC',
    'test-broker',
    'broker.thaliumx.com',
    'broker',
    'active',
    'thaliumx',
    'support@testbroker.com',
    '{"theme": "dark", "features": ["trading", "wallet", "reports"]}',
    '{"maker_fee": 0.001, "taker_fee": 0.002, "withdrawal_fee": 0.0005}',
    '{"max_daily_withdrawal": 10000, "max_order_size": 1000}',
    '{"trading_enabled": true, "margin_enabled": false, "api_enabled": true}',
    NOW(),
    NOW()
) ON CONFLICT (slug) DO NOTHING;

-- ============================================
-- BROKER ADMIN USER
-- ============================================
INSERT INTO users (
    id, keycloak_id, email, email_verified, first_name, last_name,
    status, kyc_status, kyc_level, mfa_enabled, password_hash,
    created_at, updated_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440002',
    'broker-admin-keycloak-id',
    'broker@thaliumx.com',
    true,
    'Broker',
    'Admin',
    'active',
    'approved',
    2,
    true,
    crypt('BrokerPass123!', gen_salt('bf')),
    NOW(),
    NOW()
) ON CONFLICT (email) DO NOTHING;

-- Link broker admin to tenant
INSERT INTO tenant_users (
    id, tenant_id, user_id, role, permissions, is_primary,
    created_at, updated_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440003',
    '550e8400-e29b-41d4-a716-446655440001', -- broker tenant
    '550e8400-e29b-41d4-a716-446655440002', -- broker admin user
    'admin',
    '["manage_users", "view_reports", "manage_settings"]',
    true,
    NOW(),
    NOW()
) ON CONFLICT (tenant_id, user_id) DO NOTHING;

-- ============================================
-- TRADER USER
-- ============================================
INSERT INTO users (
    id, keycloak_id, email, email_verified, first_name, last_name,
    status, kyc_status, kyc_level, mfa_enabled, password_hash,
    created_at, updated_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440004',
    'trader-keycloak-id',
    'trader@thaliumx.com',
    true,
    'John',
    'Trader',
    'active',
    'approved',
    2,
    false,
    crypt('TraderPass123!', gen_salt('bf')),
    NOW(),
    NOW()
) ON CONFLICT (email) DO NOTHING;

-- ============================================
-- BASIC USER
-- ============================================
INSERT INTO users (
    id, keycloak_id, email, email_verified, first_name, last_name,
    status, kyc_status, kyc_level, mfa_enabled, password_hash,
    created_at, updated_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440005',
    'user-keycloak-id',
    'user@thaliumx.com',
    true,
    'Jane',
    'User',
    'active',
    'approved',
    1,
    false,
    crypt('UserPass123!', gen_salt('bf')),
    NOW(),
    NOW()
) ON CONFLICT (email) DO NOTHING;

-- ============================================
-- PENDING KYC USER
-- ============================================
INSERT INTO users (
    id, keycloak_id, email, email_verified, first_name, last_name,
    status, kyc_status, kyc_level, mfa_enabled, password_hash,
    created_at, updated_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440006',
    'pending-kyc-keycloak-id',
    'pending@thaliumx.com',
    true,
    'Pending',
    'KYC',
    'active',
    'pending',
    0,
    false,
    crypt('PendingPass123!', gen_salt('bf')),
    NOW(),
    NOW()
) ON CONFLICT (email) DO NOTHING;

-- ============================================
-- SUSPENDED USER
-- ============================================
INSERT INTO users (
    id, keycloak_id, email, email_verified, first_name, last_name,
    status, kyc_status, kyc_level, mfa_enabled, password_hash,
    created_at, updated_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440007',
    'suspended-keycloak-id',
    'suspended@thaliumx.com',
    true,
    'Suspended',
    'User',
    'suspended',
    'approved',
    1,
    false,
    crypt('SuspendedPass123!', gen_salt('bf')),
    NOW(),
    NOW()
) ON CONFLICT (email) DO NOTHING;

-- ============================================
-- WALLET DATA FOR TRADER
-- ============================================
INSERT INTO wallets (
    id, user_id, tenant_id, currency, type, balance, available_balance,
    created_at, updated_at
) VALUES
(
    '550e8400-e29b-41d4-a716-446655440008',
    '550e8400-e29b-41d4-a716-446655440004', -- trader
    NULL, -- platform wallet
    'USDT',
    'spot',
    10000.00,
    9500.00,
    NOW(),
    NOW()
),
(
    '550e8400-e29b-41d4-a716-446655440009',
    '550e8400-e29b-41d4-a716-446655440004', -- trader
    NULL, -- platform wallet
    'BTC',
    'spot',
    0.5,
    0.45,
    NOW(),
    NOW()
),
(
    '550e8400-e29b-41d4-a716-446655440010',
    '550e8400-e29b-41d4-a716-446655440004', -- trader
    '550e8400-e29b-41d4-a716-446655440001', -- broker tenant
    'USDT',
    'spot',
    5000.00,
    5000.00,
    NOW(),
    NOW()
) ON CONFLICT (user_id, currency, type, tenant_id) DO NOTHING;

-- ============================================
-- SAMPLE ORDERS
-- ============================================
INSERT INTO orders (
    id, user_id, tenant_id, trading_pair_id, symbol, type, side,
    quantity, price, status, created_at, updated_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440011',
    '550e8400-e29b-41d4-a716-446655440004', -- trader
    NULL, -- platform order
    (SELECT id FROM trading_pairs WHERE symbol = 'BTC/USDT' LIMIT 1),
    'BTC/USDT',
    'limit',
    'buy',
    0.01,
    45000.00,
    'filled',
    NOW() - INTERVAL '1 day',
    NOW() - INTERVAL '1 day'
),
(
    '550e8400-e29b-41d4-a716-446655440012',
    '550e8400-e29b-41d4-a716-446655440004', -- trader
    NULL, -- platform order
    (SELECT id FROM trading_pairs WHERE symbol = 'ETH/USDT' LIMIT 1),
    'ETH/USDT',
    'market',
    'sell',
    0.5,
    NULL,
    'open',
    NOW() - INTERVAL '2 hours',
    NOW() - INTERVAL '2 hours'
) ON CONFLICT (id) DO NOTHING;

-- ============================================
-- WALLET TRANSACTIONS
-- ============================================
INSERT INTO wallet_transactions (
    id, wallet_id, user_id, type, amount, currency,
    balance_before, balance_after, status, created_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440013',
    '550e8400-e29b-41d4-a716-446655440008', -- USDT wallet
    '550e8400-e29b-41d4-a716-446655440004', -- trader
    'deposit',
    10000.00,
    'USDT',
    0.00,
    10000.00,
    'completed',
    NOW() - INTERVAL '7 days'
),
(
    '550e8400-e29b-41d4-a716-446655440014',
    '550e8400-e29b-41d4-a716-446655440009', -- BTC wallet
    '550e8400-e29b-41d4-a716-446655440004', -- trader
    'trade',
    0.5,
    'BTC',
    0.0,
    0.5,
    'completed',
    NOW() - INTERVAL '3 days'
) ON CONFLICT (id) DO NOTHING;

-- ============================================
-- TOKEN SALE DATA
-- ============================================
INSERT INTO token_sales (
    id, name, token_symbol, token_address, network, type, status,
    total_supply, tokens_for_sale, tokens_sold, price_usd,
    min_purchase, max_purchase, hard_cap, soft_cap,
    start_date, end_date, created_at, updated_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440015',
    'THAL Token Presale',
    'THAL',
    '0x1234567890123456789012345678901234567890',
    'ethereum',
    'presale',
    'active',
    1000000000.0, -- 1 billion
    300000000.0,  -- 300 million for sale
    50000000.0,   -- 50 million sold
    0.10,         -- $0.10 per token
    50.0,         -- min $50
    10000.0,      -- max $10k
    30000000.0,   -- $30M hard cap
    20000000.0,   -- $20M soft cap
    NOW() - INTERVAL '30 days',
    NOW() + INTERVAL '30 days',
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- ============================================
-- TOKEN SALE INVESTMENTS
-- ============================================
INSERT INTO token_sale_investments (
    id, sale_id, user_id, tenant_id, amount_invested, currency,
    amount_usd, tokens_purchased, status, tx_hash, created_at, confirmed_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440016',
    '550e8400-e29b-41d4-a716-446655440015', -- THAL presale
    '550e8400-e29b-41d4-a716-446655440004', -- trader
    NULL, -- platform investment
    1000.00,
    'USDT',
    1000.00,
    10000.0, -- 10,000 THAL tokens
    'confirmed',
    '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
    NOW() - INTERVAL '15 days',
    NOW() - INTERVAL '15 days'
) ON CONFLICT (id) DO NOTHING;

-- ============================================
-- USER SESSIONS (FOR TESTING)
-- ============================================
INSERT INTO user_sessions (
    id, user_id, session_token, device_fingerprint, ip_address,
    user_agent, is_active, expires_at, created_at, last_activity_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440017',
    '550e8400-e29b-41d4-a716-446655440004', -- trader
    'test-session-token-12345',
    'test-device-fingerprint',
    '127.0.0.1',
    'Mozilla/5.0 (Test Browser)',
    true,
    NOW() + INTERVAL '24 hours',
    NOW(),
    NOW()
) ON CONFLICT (session_token) DO NOTHING;

-- ============================================
-- AUDIT LOGS SAMPLE
-- ============================================
INSERT INTO audit_logs (
    user_id, action, resource_type, resource_id,
    old_values, new_values, ip_address, status, created_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440004', -- trader
    'LOGIN',
    'user',
    '550e8400-e29b-41d4-a716-446655440004',
    NULL,
    '{"status": "active"}',
    '127.0.0.1',
    'success',
    NOW() - INTERVAL '1 hour'
),
(
    '550e8400-e29b-41d4-a716-446655440004', -- trader
    'TRADE_EXECUTED',
    'order',
    '550e8400-e29b-41d4-a716-446655440011',
    NULL,
    '{"symbol": "BTC/USDT", "side": "buy", "quantity": 0.01}',
    '127.0.0.1',
    'success',
    NOW() - INTERVAL '1 day'
) ON CONFLICT DO NOTHING;

COMMIT;

-- Display seeded data summary
SELECT
    'Users' as table_name,
    COUNT(*) as count
FROM users
WHERE email LIKE '%@thaliumx.com'

UNION ALL

SELECT
    'Tenants' as table_name,
    COUNT(*) as count
FROM tenants

UNION ALL

SELECT
    'Wallets' as table_name,
    COUNT(*) as count
FROM wallets

UNION ALL

SELECT
    'Orders' as table_name,
    COUNT(*) as count
FROM orders

UNION ALL

SELECT
    'Token Sales' as table_name,
    COUNT(*) as count
FROM token_sales;