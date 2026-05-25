# AI Jyotish Guru - System Architecture

## High-Level Architecture

```mermaid
flowchart TB
    subgraph clients [Client Layer]
        Flutter[Flutter Mobile App]
        Admin[Admin Dashboard]
    end

    subgraph gateway [API Gateway Layer]
        LB[Load Balancer / CDN]
        API[FastAPI Application]
    end

    subgraph services [Service Layer]
        AuthSvc[Auth Service]
        KundliSvc[Kundli Engine]
        AISvc[AI Astrologer Service]
        VoiceSvc[Voice Pipeline]
        HoroscopeSvc[Horoscope Service]
        PaySvc[Payment Service]
        NotifSvc[Notification Service]
    end

    subgraph external [External APIs]
        Firebase[Firebase Auth]
        OpenAI[OpenAI GPT + Whisper]
        ElevenLabs[ElevenLabs TTS]
        VedicAPI[Vedic / Swiss Ephemeris]
        Razorpay[Razorpay]
        Stripe[Stripe]
        FCM[FCM Push]
    end

    subgraph data [Data Layer]
        PG[(PostgreSQL)]
        Redis[(Redis Cache)]
        S3[AWS S3 Media]
    end

    Flutter --> LB
    Admin --> LB
    LB --> API
    API --> AuthSvc
    API --> KundliSvc
    API --> AISvc
    API --> VoiceSvc
    API --> HoroscopeSvc
    API --> PaySvc
    API --> NotifSvc

    AuthSvc --> Firebase
    AuthSvc --> PG
    KundliSvc --> VedicAPI
    KundliSvc --> PG
    AISvc --> OpenAI
    AISvc --> Redis
    AISvc --> PG
    VoiceSvc --> OpenAI
    VoiceSvc --> ElevenLabs
    VoiceSvc --> S3
    HoroscopeSvc --> KundliSvc
    HoroscopeSvc --> PG
    PaySvc --> Razorpay
    PaySvc --> Stripe
    PaySvc --> PG
    NotifSvc --> FCM
    NotifSvc --> PG
```

## Voice Chat Pipeline

```mermaid
sequenceDiagram
    participant User
    participant Flutter
    participant API
    participant Whisper
    participant GPT
    participant ElevenLabs

    User->>Flutter: Speak (Hindi)
    Flutter->>API: POST /voice/chat (audio stream)
    API->>Whisper: Transcribe audio
    Whisper-->>API: Hindi text
    API->>GPT: Context + Kundli + History
    GPT-->>API: Astrology response
    API->>ElevenLabs: TTS (emotional Hindi voice)
    ElevenLabs-->>API: Audio stream
    API-->>Flutter: Stream audio + text
    Flutter-->>User: Play natural voice
```

## Scalability Design (1M+ Users)

| Component | Strategy |
|-----------|----------|
| API | Horizontal scaling (K8s/ECS), 4+ workers per instance |
| Database | Read replicas, connection pooling (asyncpg), indexed queries |
| Redis | Session cache, rate limits, hot horoscope cache |
| Voice | Async job queue for long TTS, WebSocket streaming |
| Media | S3 + CloudFront CDN |
| AI | Request batching, token limits, conversation summarization |

## Security Layers

1. **Firebase ID Token** verification on mobile login
2. **JWT** access/refresh tokens for API sessions
3. **Fernet encryption** for sensitive birth data at rest
4. **HTTPS** everywhere in production
5. **Rate limiting** per user/IP (Redis)
6. **Webhook signature** verification (Razorpay/Stripe)
7. **GDPR**: data export, account deletion endpoints

## Module Boundaries

```
backend/app/
├── api/v1/          # HTTP routes only
├── services/        # Business logic
├── models/          # SQLAlchemy ORM
├── schemas/         # Pydantic DTOs
├── core/            # Config, security, DB
└── integrations/    # External API clients
```

## Mobile Architecture (Flutter)

Clean Architecture + Feature modules:

```
lib/
├── core/           # Theme, router, DI, network
├── features/       # auth, kundli, voice, horoscope, profile, subscription
└── shared/         # Widgets, models, utils
```

State management: **Riverpod**  
Routing: **go_router**  
Networking: **Dio** + interceptors
