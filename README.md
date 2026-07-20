# StorePass — Mobile

Flutter client (Android/iOS, plus desktop/web targets Flutter ships for
free) for **StorePass**, a multi-shop cashback and loyalty platform.
Talks to the same [backend](../backend) JSON API as the
[React frontend](../frontend), over the same cookie-based sessions — no
JWT, no separate mobile API.

This app was built to mirror the web frontend's feature set and design
language (one accent color, restrained/monochrome UI), not as a lesser or
divergent client.

## Tech stack

- **Flutter** (Material 3) + **Dart**
- **dio** + **cookie_jar** (`PersistCookieJar`) — the backend's session
  cookie is disk-persisted, so a login survives an app restart, same as the
  browser's `credentials: include`
- **provider** for state management (`AuthProvider`, `ThemeProvider`,
  `LockProvider`)
- **mobile_scanner** for camera QR scanning, with a manual-entry fallback
- **google_fonts** (Inter) for typography
- **local_auth** for the opt-in biometric re-lock
- **permission_handler** for the "open Settings" deep link on camera
  permission denial
- **flutter_launcher_icons** / **flutter_native_splash** for the app icon
  and native splash screen (generated from `assets/icon/`)

## Setup

```bash
cd StorePass
flutter pub get
```

### Backend URL

The backend base URL is a runtime variable, not hardcoded, resolved in this
order:

1. Saved in-app via **Server settings** (Profile → Server settings) —
   persisted to `SharedPreferences`, no rebuild needed. Useful because
   "localhost" means something different on an emulator vs. a physical
   device on your Wi-Fi.
2. `--dart-define=API_BASE_URL=http://...` at build/run time.
3. Platform-aware default: `http://10.0.2.2:8000` on the Android emulator
   (its alias for the host machine), `http://localhost:8000` elsewhere.

The backend must actually be running and reachable at whichever URL you
land on — see [`../backend/README.md`](../backend/README.md).

## Run

```bash
flutter run                 # pick a connected device/emulator
flutter build apk --debug   # debug APK to build/app/outputs/flutter-apk/
```

`flutter analyze` and `flutter test` should both be clean before committing
changes here.

## Features by role

| Role     | What                                                                                          |
| -------- | ----------------------------------------------------------------------------------------------- |
| Customer | Shop directory (search), shop detail (reviews + your visit history), scan-to-claim (camera or manual code), wallets, leave a review. |
| Shop     | Generate a purchase QR + cashback amount, live transaction list, your own review feed.        |
| Admin    | Shops (create/edit/deactivate), customers, transactions (filterable by shop), review moderation. |

All three roles share a **Profile** tab: edit display name/password, theme
toggle (light/dark/system), server settings, opt-in biometric lock, sign out.

Auth: phone/email + password (register, login, forgot/reset password — the
reset code is printed to the **backend's** console, since no email/SMS
provider is configured; see the backend README). **Google sign-in is not
yet wired up on mobile** — the web frontend has it (Firebase Auth), but
enabling it here needs a Firebase Android/iOS app registered under the same
project (`storepass-e4a43`) plus the resulting `google-services.json` /
`GoogleService-Info.plist` config files, which only someone with access to
that Firebase console can generate.

## Design

Near-monochrome, restrained UI (`lib/theme/app_theme.dart`): a hand-built
neutral `ColorScheme` — deliberately not `ColorScheme.fromSeed`, which
would tint every surface/border with the accent hue — plus flat, hairline-
bordered cards/buttons/inputs instead of drop shadows. The single indigo
accent (`#4338CA` light / `#818CF8` dark) is reserved for primary buttons,
focused inputs, the selected nav item, and the numbers that matter
(cashback amounts, wallet balances) — not decoration. Star ratings stay
amber, since that's a rating convention rather than a brand color.

## Security notes

- Session cookie persisted via `PersistCookieJar` to the app's support
  directory — same trust model as a browser cookie jar.
- A global Dio interceptor catches `401` responses and flips
  `AuthProvider` back to signed-out, bouncing to the login screen instead
  of leaving whatever screen was open to show a raw error.
- Biometric re-lock (`LockProvider`) is opt-in, off by default, and only
  offered on devices `local_auth` reports as supporting it.
- Uncaught Flutter/async errors flow through `utils/error_logging.dart` —
  logged locally only. No crash reporting service (Sentry/Crashlytics) is
  wired up yet; that file is where you'd add it.

## Project layout

```
StorePass/lib/
  main.dart                       entrypoint — installs error logging, runs StorePassApp
  app.dart                        MultiProvider setup, theme, lifecycle-driven lock, role-based routing
  config/api_config.dart          backend base URL resolution (see Backend URL above)
  services/api_client.dart        Dio wrapper, ApiException, full endpoint surface, 401 interceptor hook
  models/                         Principal, Shop(+Detail), Wallet, Txn, Review, ClaimResult, AdminCustomer
  providers/
    auth_provider.dart              current identity, login/register/logout/restore, 401 handling
    theme_provider.dart              light/dark/system, persisted
    lock_provider.dart               opt-in biometric re-lock state
  theme/app_theme.dart            monochrome ColorScheme + component theming (see Design above)
  screens/
    splash_screen.dart / lock_screen.dart
    auth/                          login, register, forgot/reset password, server settings
    customer/                       shop directory/detail, scan, wallets, review dialog, bottom-nav shell
    shop/                           dashboard (QR + transactions + reviews), shell
    admin/                          shops/customers/transactions/reviews tabs, shop shell
    profile/profile_screen.dart     shared across all three roles
  widgets/                         BrandMark, StarRating(+Input), loading/error/empty states
  utils/                           currency/date formatting, error logging
```

## Known gaps / roadmap

Carried over from the product-wide analysis, still open on mobile
specifically:

- No automated widget/unit tests beyond a single smoke test.
- No CI running `flutter analyze`/`flutter test` on push.
- No crash reporting or analytics (see Security notes above).
- No push notifications.
- Google sign-in (needs Firebase Android/iOS app registration — see
  Features by role above).

Bigger, product-wide items (spend/redeem cashback, notifications, an admin
audit trail, server-side search, real-time updates) are tracked at the
project level, not mobile-specific — see the root [`README.md`](../README.md).
