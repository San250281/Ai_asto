# AI Jyotish Guru

Production-ready AI-powered Vedic astrology mobile application with human-like Hindi voice assistant.

## Stack

| Layer | Technology |
|-------|------------|
| Mobile | Flutter (Android + iOS) |
| Backend | Python FastAPI |
| Database | PostgreSQL |
| Cache | Redis |
| Auth | Firebase + JWT |
| AI | OpenAI GPT-4o |
| STT | OpenAI Whisper |
| TTS | ElevenLabs |
| Astrology | Swiss Ephemeris / Vedic API |
| Payments | Razorpay + Stripe |
| Cloud | AWS / GCP ready |

## Repository Structure

```
Ai_asto/
├── mobile/          # Flutter app
├── backend/         # FastAPI API server
├── admin/           # Admin dashboard (React)
├── database/        # SQL schema & migrations
├── docs/            # Architecture & deployment
├── docker-compose.yml
└── .env.example
```

## Quick Start

### Prerequisites

- Docker & Docker Compose
- Python 3.11+
- Flutter 3.16+
- PostgreSQL 15+ (or use Docker)

### 1. Environment

```bash
cp .env.example .env
# Edit .env with your API keys
```

### 2. Start Infrastructure

```bash
docker-compose up -d postgres redis
```

### 3. Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 4. Mobile

```bash
cd mobile
flutter pub get
# Add firebase config files (google-services.json, GoogleService-Info.plist)
flutter run
```

### 5. Admin Panel

```bash
cd admin
npm install
npm run dev
```

## API Documentation

When backend is running: http://localhost:8000/docs

## Features

- User registration with OTP
- Kundli generation (Lagna, planets, dasha, dosha)
- AI voice astrologer (Hindi/English/Hinglish)
- Daily/weekly personalized horoscope
- Chat history & remedies
- Premium subscriptions (Razorpay/Stripe)
- Push notifications
- Admin dashboard

## License

Proprietary - All rights reserved.
