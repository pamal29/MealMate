# MealMate

A mobile app connecting Sabaragamuwa University students with campus food shops
for faster pre-ordering. IS5109 – IS Project for Community (Group 12).

## Tech stack
| Layer | Technology |
|---|---|
| Mobile | Flutter / Dart |
| Backend | Node.js + Express |
| Database | PostgreSQL (Supabase) |
| Auth | JWT + bcrypt |
| Notifications | Firebase Cloud Messaging |
| Hosting | Render |

## Structure
- `mobile/` Flutter app
- `backend/` REST API
- `docs/` proposal, diagrams, API notes

## Getting started
### Backend
    cd backend
    cp .env.example .env    # then fill in values
    npm install
    npm run dev

### Mobile
    cd mobile
    flutter pub get
    flutter run

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md).