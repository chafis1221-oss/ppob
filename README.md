# PPOB Warung Mama Fahri

Flutter PPOB demo app with offline transaction flows for pulsa, data, game vouchers, e-wallet, PLN, and PDAM.

## Scope

- Flutter Android app under `frontend/`
- Offline demo data; no backend required
- Local transaction history during the current app session

## Run locally

```bash
cd frontend
flutter pub get
flutter analyze
flutter test
flutter run
```

## Build Android

```bash
cd frontend
flutter build apk --debug
```

CI runs dependency installation, static analysis, tests, and a debug APK build on pushes to `main` and pull requests.

## Project layout

- `frontend/lib/main.dart` — application entry point
- `frontend/lib/app.dart` — PPOB UI and transaction flow
- `frontend/test/` — Flutter tests
- `frontend/android/` — Android host project
- `frontend/assets/` — bundled app assets
- `.github/workflows/build.yml` — CI build workflow

## License

MIT
