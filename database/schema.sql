-- AI Jyotish Guru - PostgreSQL Schema
-- Version: 1.0.0

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Enums
CREATE TYPE gender_type AS ENUM ('male', 'female', 'other');
CREATE TYPE language_type AS ENUM ('hindi', 'english', 'hinglish');
CREATE TYPE subscription_plan AS ENUM ('free', 'premium_monthly', 'premium_yearly');
CREATE TYPE subscription_status AS ENUM ('active', 'cancelled', 'expired', 'pending');
CREATE TYPE payment_gateway AS ENUM ('razorpay', 'stripe');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
CREATE TYPE prediction_type AS ENUM (
    'daily', 'weekly', 'career', 'marriage', 'health', 'dosha', 'transit'
);
CREATE TYPE notification_type AS ENUM (
    'horoscope', 'festival', 'transit', 'prediction', 'subscription', 'system'
);
CREATE TYPE chat_role AS ENUM ('user', 'assistant', 'system');

-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firebase_uid VARCHAR(128) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    gender gender_type NOT NULL,
    date_of_birth DATE NOT NULL,
    birth_time TIME NOT NULL,
    birth_place VARCHAR(255) NOT NULL,
    birth_latitude DECIMAL(10, 7),
    birth_longitude DECIMAL(10, 7),
    birth_timezone VARCHAR(64) DEFAULT 'Asia/Kolkata',
    current_city VARCHAR(255),
    language_preference language_type DEFAULT 'hindi',
    mobile_number VARCHAR(20) UNIQUE,
    mobile_verified BOOLEAN DEFAULT FALSE,
    email VARCHAR(255),
    profile_image_url TEXT,
    is_premium BOOLEAN DEFAULT FALSE,
    encrypted_birth_data BYTEA,
    fcm_token TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    gdpr_consent BOOLEAN DEFAULT FALSE,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_users_mobile ON users(mobile_number);
CREATE INDEX idx_users_premium ON users(is_premium) WHERE is_premium = TRUE;

-- Kundli Reports
CREATE TABLE kundli_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lagna_chart JSONB NOT NULL DEFAULT '{}',
    planet_positions JSONB NOT NULL DEFAULT '{}',
    dasha JSONB NOT NULL DEFAULT '{}',
    horoscope_summary TEXT,
    dosha_analysis JSONB DEFAULT '{}',
    nakshatra VARCHAR(64),
    rashi VARCHAR(64),
    raw_ephemeris_data JSONB,
    generated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE INDEX idx_kundli_user ON kundli_reports(user_id);

-- Astrology Predictions
CREATE TABLE astrology_predictions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    prediction_type prediction_type NOT NULL,
    prediction_date DATE NOT NULL,
    content_hi TEXT,
    content_en TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, prediction_type, prediction_date)
);

CREATE INDEX idx_predictions_user_date ON astrology_predictions(user_id, prediction_date DESC);
CREATE INDEX idx_predictions_type ON astrology_predictions(prediction_type);

-- Chat History
CREATE TABLE chat_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id UUID NOT NULL DEFAULT uuid_generate_v4(),
    role chat_role NOT NULL,
    message TEXT NOT NULL,
    language language_type DEFAULT 'hindi',
    kundli_context JSONB,
    tokens_used INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_chat_user_session ON chat_history(user_id, session_id, created_at);
CREATE INDEX idx_chat_user_recent ON chat_history(user_id, created_at DESC);

-- Subscriptions
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_type subscription_plan NOT NULL DEFAULT 'free',
    status subscription_status NOT NULL DEFAULT 'pending',
    razorpay_subscription_id VARCHAR(128),
    stripe_subscription_id VARCHAR(128),
    starts_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    auto_renew BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_active ON subscriptions(status, expires_at)
    WHERE status = 'active';

-- Payments
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES subscriptions(id),
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'INR',
    gateway payment_gateway NOT NULL,
    transaction_id VARCHAR(255) UNIQUE,
    gateway_order_id VARCHAR(255),
    status payment_status DEFAULT 'pending',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_payments_user ON payments(user_id, created_at DESC);
CREATE INDEX idx_payments_transaction ON payments(transaction_id);

-- Voice Logs
CREATE TABLE voice_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id UUID,
    audio_input_url TEXT,
    audio_output_url TEXT,
    transcript TEXT,
    ai_response TEXT,
    language language_type DEFAULT 'hindi',
    duration_ms INTEGER,
    tokens_used INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_voice_user ON voice_logs(user_id, created_at DESC);

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type notification_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read, sent_at DESC);

-- Admin Users
CREATE TABLE admin_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    role VARCHAR(32) DEFAULT 'admin',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI Prompt Templates (admin-controlled)
CREATE TABLE ai_prompts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(128) UNIQUE NOT NULL,
    system_prompt TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    version INTEGER DEFAULT 1,
    updated_by UUID REFERENCES admin_users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- OTP Verification
CREATE TABLE otp_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mobile_number VARCHAR(20) NOT NULL,
    otp_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    verified BOOLEAN DEFAULT FALSE,
    attempts INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_otp_mobile ON otp_verifications(mobile_number, expires_at);

-- Analytics Events
CREATE TABLE analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_name VARCHAR(128) NOT NULL,
    properties JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_analytics_event ON analytics_events(event_name, created_at DESC);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Default AI system prompt
INSERT INTO ai_prompts (name, system_prompt, is_active) VALUES (
    'astrologer_default',
    'You are an experienced Indian astrologer with 20+ years of experience in Vedic astrology.

You speak naturally in Hindi and English.

You analyze:
- Kundli
- Planet positions
- Dasha
- Transit
- Zodiac signs

You provide:
- Career guidance
- Marriage guidance
- Financial guidance
- Health guidance
- Spiritual guidance

Your tone should be:
- Calm
- Spiritual
- Positive
- Emotional
- Human-like

Never sound robotic.
Always speak respectfully.

Do not make harmful, fearful, or extreme predictions.

Always provide practical and positive guidance.',
    TRUE
);
