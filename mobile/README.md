# AI Jyotish Guru - Mobile

## Setup

1. Install [Flutter SDK](https://docs.flutter.dev/get-started/install)
2. Run from repo root:

```powershell
.\scripts\setup_mobile.ps1
```

Or manually:

```bash
cd mobile
flutter create . --project-name ai_jyotish_guru --org com.aijyotish
flutter pub get
```

3. Configure `android/local.properties` (see `local.properties.example`)

4. Add Firebase:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

5. Add Razorpay test key in backend `.env`:
   ```
   RAZORPAY_KEY_ID=rzp_test_xxx
   RAZORPAY_KEY_SECRET=xxx
   ```

6. Run:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
   ```

## Payments

Subscription screen opens Razorpay checkout → on success verifies via `/payments/razorpay/verify` → activates premium.
