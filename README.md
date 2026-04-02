# leger-app

Hisab Rakho is a Flutter ledger and shop-management app with customer khata, reminders, reports, backup, security, business tools, staff/payroll, portal access, and advanced shop workflows.

## Run locally

```powershell
flutter pub get
flutter run -d chrome `
  --dart-define=FIREBASE_API_KEY=your_key `
  --dart-define=FIREBASE_APP_ID=your_app_id `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=your_sender_id `
  --dart-define=FIREBASE_PROJECT_ID=your_project_id `
  --dart-define=FIREBASE_AUTH_DOMAIN=your_auth_domain `
  --dart-define=FIREBASE_STORAGE_BUCKET=your_storage_bucket `
  --dart-define=FIREBASE_MEASUREMENT_ID=your_measurement_id
```

## Build web

```powershell
flutter build web --release `
  --dart-define=FIREBASE_API_KEY=your_key `
  --dart-define=FIREBASE_APP_ID=your_app_id `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=your_sender_id `
  --dart-define=FIREBASE_PROJECT_ID=your_project_id `
  --dart-define=FIREBASE_AUTH_DOMAIN=your_auth_domain `
  --dart-define=FIREBASE_STORAGE_BUCKET=your_storage_bucket `
  --dart-define=FIREBASE_MEASUREMENT_ID=your_measurement_id
```

## Deploy on Vercel

This repo includes a root [vercel.json](/c:/Users/Kashif/Documents/New%20folder%20(3)/vercel.json) that:

- installs Flutter in the Vercel build
- runs [vercel-build.sh](/c:/Users/Kashif/Documents/New%20folder%20(3)/vercel-build.sh) so the Firebase dart defines stay out of the short Vercel command field
- serves the `build/web` output
- rewrites all routes to `index.html` for SPA-style navigation

You can import the GitHub repo into Vercel and deploy it as an `Other` framework project.

Before deploying, add these Environment Variables in Vercel Project Settings:

- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_AUTH_DOMAIN`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_MEASUREMENT_ID`

If these values are missing, the app still runs, but Firebase-backed sign-in and cloud backup stay unavailable.
