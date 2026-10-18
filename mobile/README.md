# MealMate mobile

## Preview without a database

From the repository root, run `cd mobile` followed by `flutter run`.
On the login page, tap **Explore preview — no login needed** to open Home.
Tap a shop's **View**, add food with **+**, then tap **View Tray** for checkout.
Use the back arrows to return. Profile's **Back to login** exits the preview.
No backend or database is needed for this flow; real authentication and placing
orders are not simulated.

## Local authentication setup

The Android emulator uses `http://10.0.2.2:3000` automatically in debug builds.
Desktop and web debug builds use `http://localhost:3000`.

Start the existing backend in a separate terminal:

```powershell
cd backend
if (!(Test-Path .env)) { Copy-Item .env.example .env }
# Edit .env: enter your database connection and a long random JWT_SECRET.
npm.cmd ci
npm.cmd run dev
```

The database must already contain the project's users table. Keep `.env` private;
it is ignored by Git. Then run the app:

```powershell
cd mobile
flutter pub get
flutter run
```

For a physical phone, use your computer's LAN address (same Wi-Fi):

```powershell
flutter run --dart-define=API_BASE_URL=http://YOUR_PC_LAN_IP:3000
```

Allow the backend's port through your local firewall if required. For deployment,
pass an HTTPS backend origin using `API_BASE_URL`, without `/api/auth`. Release
builds have no localhost fallback. Android HTTP access is enabled only in debug.

## Authentication

- Login sends `POST /api/auth/login` with email and password.
- Register sends `POST /api/auth/register` with name, email, password, and role
  (`student` or `shop_owner`), then opens home after receiving a session.
- Profile loads `GET /api/auth/me` with `Authorization: Bearer <token>`.
- Log out clears the session and navigation history. Expired tokens return users
  to sign-in through the profile screen.
- JWT and user details are held in memory only; restarting the app requires login.
- Student and shop-owner accounts use the same backend login endpoint and current
  home screen. A separate shop-management dashboard is not implemented.
- Google sign-in and password recovery remain unavailable because the backend
  has no endpoints for those features.

## Checks

```powershell
flutter analyze
flutter test
```

Tests cover the HTTP contract, session handling, errors, and login/registration
navigation. Mocked HTTP tests do not verify your database credentials or schema.

## Home screen

The signed-in home screen follows the supplied dark/orange screenshot. Search,
category filters, Explore/View all, shop-menu pages, and four navigation tabs
are interactive. Profile retains the authenticated profile and logout flow.
Shop cards currently use sample data; menu ordering and order history are not
connected. Restaurant photos are bundled sample substitutes, with sources in
`assets/shops/SOURCES.txt`; they are not photos of the named businesses.

To render the 390 x 964 home preview while running the layout tests:

```powershell
flutter test test/home_screen_test.dart --dart-define=CAPTURE_HOME=true
```

The preview is saved to `build/home-preview.png` (not committed).

## Menu and tray screens

Home's View buttons open the screenshot-based food shop screen. Each shop keeps
its own in-memory tray until the home screen is disposed. Quantity controls,
category filters, removal, Clear, and return navigation share the same tray.
The maximum quantity is 20 per item. The sample menu uses LKR 480 for rice
consistently; screenshots supplied different rice prices. Packaging is LKR 40
per nonempty tray. These screens use sample food and shop data, and sample
photography listed under `assets/food/SOURCES.txt`.

Place Order currently explains that this is a preview and does not submit an
order. Live checkout requires actual shop/menu UUIDs and a server-side packaging
fee policy (the existing API currently calculates only item totals).

```powershell
flutter test test/ordering_test.dart --dart-define=CAPTURE_ORDERING=true
```

This produces `build/menu-preview.png` and `build/checkout-preview.png`.
