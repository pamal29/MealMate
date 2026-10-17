# MealMate mobile

Flutter application. The initial screen implements the Figma login design (node 1:110).

## Run

Use a Flutter SDK compatible with the Dart constraint in pubspec.yaml.

```sh
flutter pub get
flutter run --dart-define=API_BASE_URL=https://your-mealmate-api.example
```

Replace the example URL with your running backend origin, without `/api/auth`.
Use HTTPS for device/release builds. Email login calls `POST /api/auth/login`;
only a successful response opens the existing home screen. The token and user
are held in memory for this session; persistent login is not implemented.
Without API_BASE_URL, the screen still opens and reports that login is unavailable.

Google sign-in, password recovery, registration, and the separate shop login
flow show an explanatory dialog until those screens/integrations are implemented.

## Checks

```sh
flutter analyze
flutter test
```

Widget tests cover validation, password visibility, pending/failed/successful
login, and a small screen with larger text. The API callback is injected in tests.

Design icons are bundled under assets/login; Inter and Plus Jakarta Sans fonts
and their OFL licenses are under assets/fonts. No temporary Figma URLs are used
at runtime. The existing home theme is preserved.
