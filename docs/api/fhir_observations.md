# FHIR Observations API

Base URL: `/api/v1/fhir/observations`

Authentication: none (scoped by `account` param or subdomain). Ensure the `account` (id or slug) resolves to an existing account.

## GET /api/v1/fhir/observations

- Returns a FHIR `Bundle` of Observation resources for the account.
- Query params:
  - `patient_external_id` (optional)
  - `code` (optional)
  - `type` (optional; accepts short names like `glucose`, `blood_pressure`, `weight` or full class names like `Observation::Glucose`).

Example:

```
curl "$BASE/api/v1/fhir/observations?account=$ACCOUNT&patient_external_id=P1"
```

Response (truncated):

```
{
  "resourceType": "Bundle",
  "type": "searchset",
  "total": 1,
  "entry": [
    {
      "resource": {
        "resourceType": "Observation",
        "status": "final",
        "code": {"text":"GLU"},
        "subject": {"reference":"Patient/P1"},
        "valueQuantity": {"value":95, "unit":"mg/dL"}
      }
    }
  ]
}
```

## POST /api/v1/fhir/observations

Enqueues `Observations::Fhir::IngestJob` to create an Observation.

Body (JSON):

- `patient_external_id` (required)
- `type` (optional): fully qualified (e.g., `Observation::Glucose`) or short (`glucose`, `blood_pressure`, `weight`)
- `code` (optional)
- `recorded_at` (optional ISO8601; falls back to current time)
- Quantity fields: `value`, `unit`
- Blood pressure fields: `systolic`, `diastolic`, `unit` (defaults to `mmHg`)

Examples:

```
# Glucose
curl -X POST "$BASE/api/v1/fhir/observations?account=$ACCOUNT" \
  -H "Content-Type: application/json" \
  -d '{"patient_external_id":"P1","type":"Observation::Glucose","code":"GLU","recorded_at":"2025-08-25T12:00:00Z","value":98,"unit":"mg/dL"}'

# Blood pressure (short type)
curl -X POST "$BASE/api/v1/fhir/observations?account=$ACCOUNT" \
  -H "Content-Type: application/json" \
  -d '{"patient_external_id":"P1","type":"blood_pressure","code":"BP","recorded_at":"2025-08-25T12:30:00Z","systolic":120,"diastolic":80,"unit":"mmHg"}'
```

Notes:

- The job runs asynchronously; the API returns `202 Accepted`.
- If the patient is missing for the account, the job will raise (you can add controller-level validation to return `422`).

