# Spark Clinic

## Development (Docker Compose)

- Start services: `docker compose up --build`
- App URL: `http://localhost:3000`
- Code changes hot‑reload (source is bind‑mounted, no image rebuild needed).

### First‑time setup

- Prepare DB: `docker compose exec web ./bin/rails db:prepare`

### Common commands

- Rails console: `docker compose exec web ./bin/rails console`
- Run tests: `docker compose exec web ./bin/rails test`
- Migrate DB: `docker compose exec web ./bin/rails db:migrate`
- Install new gems: `docker compose exec web bundle install`
  - If native extensions are needed, rebuild the image: `docker compose build web && docker compose up -d`

### Data and volumes

- PostgreSQL data persists in the `postgres_data` volume.
- Remove everything (including DB data): `docker compose down -v`

## Production image (optional)

The Dockerfile is suitable for building a standalone image. Example:

```
docker build -t spark_clinic .
docker run -d -p 3000:3000 \
  -e DATABASE_URL=postgresql://USER:PASS@HOST:5432/DBNAME \
  -e SECRET_KEY_BASE=your_secret_key \
  --name spark_clinic spark_clinic
```

Note: In development we rely on Compose (with bind mounts and a dev DB). Rebuild the image only when `Gemfile*` or the Dockerfile changes.

## FHIR-like Ingest API

- Endpoint: `POST /api/v1/fhir/observations?account=<account_id_or_slug>`
- Purpose: Accepts a minimal FHIR-like payload and enqueues `Observations::Fhir::IngestJob` to create an Observation.

Example (glucose):

```
curl -X POST http://localhost:3000/api/v1/fhir/observations?account=your-slug \
  -H 'Content-Type: application/json' \
  -d '{
    "patient_external_id": "P1",
    "type": "Observation::Glucose",
    "code": "GLU",
    "recorded_at": "2025-08-25T12:00:00Z",
    "value": 98,
    "unit": "mg/dL"
  }'
```

Example (blood pressure, using short type):

```
curl -X POST http://localhost:3000/api/v1/fhir/observations?account=your-slug \
  -H 'Content-Type: application/json' \
  -d '{
    "patient_external_id": "P1",
    "type": "blood_pressure",
    "code": "BP",
    "recorded_at": "2025-08-25T12:30:00Z",
    "systolic": 120,
    "diastolic": 80,
    "unit": "mmHg"
  }'
```

Notes
- `type` accepts fully qualified names (e.g., `Observation::Glucose`) or short names: `glucose`, `blood_pressure`, `weight`.
- `recorded_at` should be ISO8601; if missing/invalid, current time is used.
- The job scopes by the provided `account` and finds the `patient` by `patient_external_id`.

### Curl Examples

Set variables:

```
BASE=http://localhost:3000
ACCOUNT=your-slug
```

## Theming Demo

This app includes a basic theme system using CSS variables (no build step required). The current theme comes from `Account#theme` and is applied as a class on the `<body>` (`theme-light`, `theme-dark`, `theme-ocean`).

- Files:
  - `app/assets/stylesheets/theme.css` – defines theme variables and simple UI styles.
  - `app/views/layouts/application.html.erb` – applies a `theme-*` class from the current account.
  - `app/views/patients/*` – uses styles to demonstrate theming.

Set a theme from the Rails console:

```
account = Account.first
account.update!(theme: 'dark')   # options: light (default), dark, ocean, blue, green
```

Reload the page to see the theme take effect.

Examples:

```
# Glucose (mg/dL)
curl -X POST "$BASE/api/v1/fhir/observations?account=$ACCOUNT" \
  -H "Content-Type: application/json" \
  -d '{"patient_external_id":"P1","type":"Observation::Glucose","code":"GLU","recorded_at":"2025-08-25T12:00:00Z","value":98,"unit":"mg/dL"}'

# Glucose (short type, mmol/L)
curl -X POST "$BASE/api/v1/fhir/observations?account=$ACCOUNT" \
  -H "Content-Type: application/json" \
  -d '{"patient_external_id":"P1","type":"glucose","code":"GLU","recorded_at":"2025-08-25T12:05:00Z","value":5.4,"unit":"mmol/L"}'

# Blood pressure
curl -X POST "$BASE/api/v1/fhir/observations?account=$ACCOUNT" \
  -H "Content-Type: application/json" \
  -d '{"patient_external_id":"P1","type":"blood_pressure","code":"BP","recorded_at":"2025-08-25T12:30:00Z","systolic":120,"diastolic":80,"unit":"mmHg"}'

# Weight
curl -X POST "$BASE/api/v1/fhir/observations?account=$ACCOUNT" \
  -H "Content-Type: application/json" \
  -d '{"patient_external_id":"P1","type":"Observation::Weight","code":"WEIGHT","recorded_at":"2025-08-25T13:00:00Z","value":72.5,"unit":"kg"}'
```
