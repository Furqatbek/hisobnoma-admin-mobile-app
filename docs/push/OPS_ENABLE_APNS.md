# Ops task — enable APNs push sending

Push is fully built on both the app and backend. Sending is **off** until these
environment variables are set on the backend (the send endpoint currently
returns `apnsConfigured: false` and no-ops). Token registration already works,
so no data is lost by enabling this later.

## Set these env vars on the backend service

| Variable | Value | Where it comes from |
|---|---|---|
| `APNS_ENABLED` | `true` | Flip to turn sending on. |
| `APNS_TEAM_ID` | 10-char Team ID | Apple Developer → Membership → **Team ID**. |
| `APNS_KEY_ID` | 10-char Key ID | The `.p8` key's ID. It's in the filename: `AuthKey_XXXXXXXXXX.p8` → `XXXXXXXXXX`. Also on Apple Developer → Keys. |
| `APNS_BUNDLE_ID` | `com.hisobnoma.admin` | The app's bundle id. Can be omitted — this is the default. |
| `APNS_PRIVATE_KEY` | full contents of the `.p8` file | The PEM text **including** the `-----BEGIN PRIVATE KEY-----` / `-----END PRIVATE KEY-----` lines. |

## Important

- **`APNS_PRIVATE_KEY` is a secret.** Put it in the secret manager / encrypted
  env, **not** in the repo or plaintext config. If newlines are awkward in your
  env system, keep the literal `\n` line breaks or base64 the file — match
  whatever the backend code expects (confirm with the backend author).
- The `.p8` key, Team ID, and Key ID are the same ones handed over for the
  backend build. If you don't have them, ask the Apple Developer account holder
  (they were exported in Phase 0).
- After setting them, a test send should return `apnsConfigured: true`.

## How to verify it's on

Call the send endpoint once (staff token with `MOBILE_PUSH_SEND`):

```
POST /api/v1/admin/notifications/send
{ "audience": "user", "userId": <a test user>, "title": "Test", "body": "Hello",
  "type": "system", "route": "/alerts" }
```

Response should show `apnsConfigured: true`. Delivery to a real device is then
verified with `docs/push/TESTING_RUNBOOK.md`.
