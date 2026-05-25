# Database Design

## ER Diagram

```mermaid
erDiagram
    users ||--o{ kundli_reports : has
    users ||--o{ astrology_predictions : receives
    users ||--o{ chat_history : has
    users ||--o| subscriptions : has
    users ||--o{ payments : makes
    users ||--o{ voice_logs : generates
    users ||--o{ notifications : receives

    users {
        uuid id PK
        string firebase_uid UK
        string full_name
        string gender
        date date_of_birth
        time birth_time
        string birth_place
        float birth_lat
        float birth_lng
        string current_city
        string language_preference
        string mobile_number UK
        boolean mobile_verified
        string email
        boolean is_premium
        timestamp created_at
    }

    kundli_reports {
        uuid id PK
        uuid user_id FK
        jsonb lagna_chart
        jsonb planet_positions
        jsonb dasha
        jsonb dosha_analysis
        text raw_data
        timestamp generated_at
    }

    astrology_predictions {
        uuid id PK
        uuid user_id FK
        string prediction_type
        date prediction_date
        text content_hi
        text content_en
        jsonb metadata
    }

    chat_history {
        uuid id PK
        uuid user_id FK
        string role
        text message
        string language
        jsonb kundli_context
        timestamp created_at
    }

    subscriptions {
        uuid id PK
        uuid user_id FK
        string plan_type
        string status
        timestamp starts_at
        timestamp expires_at
    }

    payments {
        uuid id PK
        uuid user_id FK
        uuid subscription_id FK
        decimal amount
        string currency
        string gateway
        string transaction_id
        string status
    }

    voice_logs {
        uuid id PK
        uuid user_id FK
        string audio_url
        text transcript
        text ai_response
        int duration_ms
    }

    notifications {
        uuid id PK
        uuid user_id FK
        string type
        string title
        text body
        boolean is_read
        timestamp sent_at
    }
```

## Indexes (Performance)

- `users(firebase_uid)`, `users(mobile_number)`
- `kundli_reports(user_id, generated_at DESC)`
- `chat_history(user_id, created_at DESC)`
- `astrology_predictions(user_id, prediction_type, prediction_date)`
- `subscriptions(user_id, status)`
- `notifications(user_id, is_read, sent_at DESC)`

## Partitioning (Scale)

For 1M+ users, consider:
- `chat_history` partitioned by month
- `voice_logs` archived to cold storage after 90 days
- `astrology_predictions` TTL cache in Redis
