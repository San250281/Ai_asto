# Deployment Guide

## AWS Deployment (Recommended)

### Infrastructure

| Service | Purpose |
|---------|---------|
| ECS Fargate / EKS | FastAPI containers |
| RDS PostgreSQL 15 | Primary database + read replica |
| ElastiCache Redis | Cache & rate limiting |
| S3 + CloudFront | Voice/media assets |
| ALB | Load balancing + SSL |
| Secrets Manager | API keys |
| SNS + FCM | Push notifications |

### Steps

1. **Provision RDS**
   ```bash
   # Create PostgreSQL 15, enable encryption at rest
   # Run: database/schema.sql via migration tool
   ```

2. **Deploy Backend**
   ```bash
   cd backend
   docker build -t ai-jyotish-backend .
   # Push to ECR, deploy ECS service with 2+ tasks
   # Set env vars from Secrets Manager
   ```

3. **Configure Domain & SSL**
   - Route53 → ALB → ACM certificate
   - API: `api.aijyotishguru.com`

4. **Flutter Release**
   ```bash
   cd mobile
   flutter build appbundle --release  # Android
   flutter build ipa --release        # iOS
   ```

5. **Firebase**
   - Enable Phone Auth, FCM
   - Upload `google-services.json` / `GoogleService-Info.plist`

6. **Webhooks**
   - Razorpay: `https://api.aijyotishguru.com/api/v1/payments/razorpay/webhook`
   - Stripe: `https://api.aijyotishguru.com/api/v1/payments/stripe/webhook`

## GCP Alternative

- Cloud Run (backend)
- Cloud SQL PostgreSQL
- Memorystore Redis
- Cloud Storage + CDN

## CI/CD (GitHub Actions)

```yaml
# .github/workflows/deploy.yml
on:
  push:
    branches: [main]
jobs:
  test-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Backend tests
        run: cd backend && pip install -r requirements.txt && pytest
      - name: Build & push Docker
        run: docker build -t $ECR_REPO ./backend && docker push $ECR_REPO
```

## Health Checks

- `GET /health` - liveness
- `GET /ready` - DB + Redis connectivity

## Monitoring

- CloudWatch / Datadog for API latency
- Sentry for error tracking
- Alert on voice pipeline p95 > 5s

## Environment Checklist

- [ ] All `.env` secrets in Secrets Manager
- [ ] `DEBUG=false` in production
- [ ] CORS restricted to app domains
- [ ] Database backups enabled (7-day retention)
- [ ] Rate limits configured
- [ ] GDPR deletion endpoint tested
