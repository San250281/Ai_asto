# Deploy AI Jyotish Guru to Google Play Store

Complete guide from signing to publishing.

---

## Phase 1: Accounts & legal (before build)

### 1. Google Play Console
- Go to https://play.google.com/console
- Pay **one-time $25** developer registration fee
- Create app → **Create app**
  - App name: **AI Jyotish Guru**
  - Default language: English (add Hindi in store listing)
  - App / Game: **App**
  - Free or Paid: **Free** (subscriptions are in-app)

### 2. Required URLs (host on your website)
| Item | Required |
|------|----------|
| Privacy Policy | **Yes** – must mention data collected (birth details, voice, phone, AI) |
| Terms of Service | Recommended |
| Support email | **Yes** – e.g. support@yourdomain.com |

### 3. Production backend
Play Store build must NOT use `localhost` or `10.0.2.2`.

Deploy backend to a public HTTPS URL, e.g.:
- `https://api.aijyotishguru.com/api/v1`

Set in Play Store build:
```bash
--dart-define=API_BASE_URL=https://api.aijyotishguru.com/api/v1
```

---

## Phase 2: Create release signing key (one time)

**Never lose this keystore.** You cannot update the app on Play Store without it.

```powershell
cd d:\Ai_Kundli\Ai_asto\mobile\android\app

keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Answer prompts (name, organization, country). Remember the **passwords**.

Create `android/key.properties` (DO NOT commit to Git):

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=app/upload-keystore.jks
```

Copy from example:
```powershell
copy d:\Ai_Kundli\Ai_asto\mobile\android\key.properties.example d:\Ai_Kundli\Ai_asto\mobile\android\key.properties
```

---

## Phase 3: Production configuration

### Firebase (release)
1. Firebase Console → Project Settings
2. Add Android app: package `com.aijyotish.guru`
3. Download `google-services.json` → place in:
   `mobile/android/app/google-services.json`
4. Enable **Phone Authentication** in Firebase Auth
5. Add **SHA-1** and **SHA-256** of your **release** keystore:

```powershell
keytool -list -v -keystore d:\Ai_Kundli\Ai_asto\mobile\android\app\upload-keystore.jks -alias upload
```

Paste fingerprints in Firebase → Project Settings → Your Android app.

### API keys (backend production `.env`)
- `OPENAI_API_KEY`
- `ELEVENLABS_API_KEY`
- `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET` (live keys for production)
- `FIREBASE_CREDENTIALS_PATH`
- `SECRET_KEY`, `ENCRYPTION_KEY` (strong random values)
- `DEBUG=false`

### App version
Edit `mobile/pubspec.yaml`:
```yaml
version: 1.0.0+1   # 1.0.0 = versionName, 1 = versionCode (increment each upload)
```

Each Play Store upload needs **higher versionCode** (the number after `+`).

---

## Phase 4: Build release App Bundle (AAB)

Google Play requires **AAB**, not APK.

```powershell
cd d:\Ai_Kundli\Ai_asto
.\scripts\build_playstore.ps1 -ApiUrl "https://api.aijyotishguru.com/api/v1"
```

Or manually:

```powershell
cd d:\Ai_Kundli\Ai_asto\mobile
flutter pub get
flutter build appbundle --release `
  --dart-define=API_BASE_URL=https://api.aijyotishguru.com/api/v1
```

Output file:
```
mobile\build\app\outputs\bundle\release\app-release.aab
```

Upload this file to Play Console.

---

## Phase 5: Play Console setup

### Store listing
- **Short description** (80 chars)
- **Full description** (4000 chars) – features: Kundli, voice AI, horoscope, Hindi
- **App icon**: 512×512 PNG
- **Feature graphic**: 1024×500
- **Screenshots**: min 2 phone screenshots (1080×1920 or similar)
- **Category**: Lifestyle or Entertainment

### App content (declarations)
| Section | Your app |
|---------|----------|
| Privacy policy | URL required |
| Ads | No (unless you add ads later) |
| App access | Login required → explain test credentials or invite-only |
| Content rating | Fill questionnaire (IARC) |
| Target audience | 18+ recommended (astrology/financial guidance) |
| Data safety | Declare: name, DOB, phone, audio, location (birth place) |
| Permissions | Microphone, Internet, Notifications – justify each |

### Data safety form (important)
Declare collection of:
- Personal info: name, email, phone, DOB, birth place
- Audio: voice recordings for AI consultation
- App activity: chat history
- Purpose: app functionality, personalization
- Encrypted in transit: Yes (HTTPS)

### Sensitive permissions
**RECORD_AUDIO** – declare: "Voice consultation with AI astrologer"

### Subscriptions (if using Premium)
Play Console → **Monetize → Subscriptions**  
OR keep Razorpay-only (declare as external payment in some regions – check Google policy; in India many apps use Razorpay with proper disclosure).

For Razorpay in-app: mention in description that payments are processed securely via Razorpay.

---

## Phase 6: Upload & release

1. Play Console → **Release → Production** (or Internal testing first)
2. **Create new release**
3. Upload `app-release.aab`
4. Release name: `1.0.0 (1)`
5. Release notes (Hindi + English):
   ```
   पहला संस्करण – कुंडली, AI वॉयस ज्योतिषी, दैनिक राशिफल
   First release – Kundli, AI voice astrologer, daily horoscope
   ```
6. **Review and roll out**

### Recommended rollout path
1. **Internal testing** – your team (up to 100 testers)
2. **Closed testing** – beta users
3. **Open testing** – optional
4. **Production** – 20% → 50% → 100% staged rollout

First review usually takes **1–7 days**.

---

## Phase 7: Checklist before submit

- [ ] `key.properties` + `upload-keystore.jks` created (keystore backed up safely)
- [ ] `google-services.json` in `android/app/`
- [ ] Release SHA-1/SHA-256 added to Firebase
- [ ] Production API on HTTPS with valid SSL
- [ ] Privacy policy URL live
- [ ] `versionCode` incremented
- [ ] Tested release build on real device
- [ ] Login, Kundli, voice, payment tested on production API
- [ ] No debug logs / test API keys in release build
- [ ] `usesCleartextTraffic` disabled for production (HTTPS only)

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Upload failed: signing | Use release keystore in `build.gradle`, not debug |
| Firebase Auth fails on release | Add release SHA fingerprints to Firebase |
| API network error on Play build | Use production `API_BASE_URL` dart-define |
| Rejected: missing privacy policy | Add URL in Store settings |
| Rejected: microphone | Explain in Data safety + permission declaration |

---

## Update app later

1. Bump `pubspec.yaml`: `version: 1.0.1+2`
2. Rebuild AAB
3. Play Console → new release → upload new AAB

---

## Quick command reference

```powershell
# Build for Play Store
cd d:\Ai_Kundli\Ai_asto\mobile
flutter build appbundle --release --dart-define=API_BASE_URL=https://YOUR_API_URL/api/v1

# Get SHA for Firebase
keytool -list -v -keystore android\app\upload-keystore.jks -alias upload
```
