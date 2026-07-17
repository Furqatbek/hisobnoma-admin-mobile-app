# Push Notifications — Backend Handoff (iOS / APNs)

**Audience:** the backend team. **Scope:** everything the server must build to
deliver Apple push notifications to the Hisobnoma iOS app. The mobile client is
**already built and shipping** the requests described in §1 — they currently hit
a 404 because these endpoints don't exist yet. Build this and push works
end-to-end.

**No Firebase.** iOS uses Apple Push Notification service (APNs) directly.
Android is a separate future effort (FCM) and is out of scope here.

---

## 0. What you need from the Apple side (ask the app owner)

- **`.p8` APNs auth key** file (token-based auth — recommended, never expires)
- **Key ID** (10 chars, shown when the key was created)
- **Team ID** (Apple Developer account, 10 chars)
- **Bundle ID:** `com.hisobnoma.admin` — this is the APNs **`apns-topic`**

> A `.p12` certificate also exists as a fallback, but it **expires yearly** and
> needs mutual-TLS instead of the JWT below. Prefer the `.p8`.

---

## 1. Endpoints the app already calls (build these exactly)

Both are **authenticated**. The Bearer JWT identifies the user and tenant —
**derive `user_id` / `tenant_id` from the token, never from the body.** Base
path is the same `/api/v1` prefix the rest of the mobile API uses.

### 1.1 Register / refresh a device token

```
POST /api/v1/mobile/devices/push-token
Authorization: Bearer <access token>
Content-Type: application/json

{
  "token": "<APNs device token, 64 hex chars>",
  "platform": "ios",
  "environment": "sandbox" | "production",
  "appVersion": "1.0.3"        // optional; may be absent
}
```

- **Upsert keyed on `token`.** If the row exists: update `user_id`,
  `environment`, `app_version`, `last_seen_at`.
- The same physical device can move between users (a shared till / multiple
  cashiers). Last writer wins — the token belongs to whoever logged in last.
- The app calls this: on login (only for users who already granted permission),
  right after the user accepts the in-app permission prompt, and again whenever
  iOS rotates the token.
- Return **2xx** on success. The client fails quietly and retries on the next
  login, so a non-2xx isn't fatal — but unreliable handling means stale tokens.

### 1.2 Remove a device token (logout)

```
DELETE /api/v1/mobile/devices/push-token
Authorization: Bearer <access token>
Content-Type: application/json

{ "token": "<same token>" }
```

Deletes that token so a logged-out phone stops receiving that user's pushes.

---

## 2. Token storage

```
device_push_tokens (
  id           PK,
  tenant_id    FK,
  user_id      FK,
  token        VARCHAR UNIQUE NOT NULL,   -- the APNs device token
  platform     VARCHAR,                   -- "ios" (later "android")
  environment  VARCHAR,                   -- "sandbox" | "production"  (see §4)
  app_version  VARCHAR NULL,
  created_at   TIMESTAMP,
  updated_at   TIMESTAMP,
  last_seen_at TIMESTAMP
)
```

Unique constraint on `token` drives the upsert in §1.1.

---

## 3. Sending to APNs (with the `.p8` key)

### 3.1 Build the auth JWT (ES256)

- **Header:** `{ "alg": "ES256", "kid": "<Key ID>" }`
- **Claims:** `{ "iss": "<Team ID>", "iat": <unix seconds now> }`
- **Sign** with the `.p8` private key.
- **Cache and reuse the JWT for up to 1 hour**, then refresh. APNs rejects
  tokens older than 1h *and* rejects if you regenerate them too frequently — so
  mint once, cache, reuse across all messages. Do **not** create one per push.

### 3.2 Send the request (HTTP/2 only)

APNs is **HTTP/2-only** — make sure your HTTP client negotiates h2 (many
default to HTTP/1.1 and silently fail to connect).

```
POST https://{host}/3/device/{deviceToken}
authorization: bearer <the cached JWT>
apns-topic: com.hisobnoma.admin
apns-push-type: alert
apns-priority: 10

<JSON body — see §5>
```

Pick `{host}` **per token** — see §4.

---

## 4. ⚠️ Route by `environment` — the #1 silent failure

There are two APNs hosts, and a token only works against the one that minted it:

| stored `environment` | host                          | which builds |
|----------------------|-------------------------------|--------------|
| `"sandbox"`          | `api.sandbox.push.apple.com`  | dev / TestFlight |
| `"production"`       | `api.push.apple.com`          | App Store |

**Choose the host from each token's stored `environment`, not globally.** Send
an App Store token to the sandbox host (or vice-versa) and APNs returns
`BadDeviceToken` — and **nothing surfaces to the user**; the push just
disappears. This is the single most common reason "push doesn't work."

---

## 5. Payload contract (Phase 4)

Everything **inside `aps`** is Apple's; everything **outside `aps`** is the
custom `data` the app reads to route a tap. Keep the routing keys at the top
level as shown.

```json
{
  "aps": {
    "alert": { "title": "Payment due", "body": "Ali Valiyev owes 1 200 000 so'm" },
    "sound": "default",
    "badge": 3
  },
  "type": "payment_due",
  "id": "12345",
  "route": "/alerts"
}
```

### Fields

| Field         | Where      | Meaning |
|---------------|------------|---------|
| `aps.alert.title` / `.body` | Apple | Text shown on the notification. **Localize server-side** (see below). |
| `aps.sound`   | Apple      | `"default"` for a normal alert. |
| `aps.badge`   | Apple      | App-icon number. Send the user's current unread count; send `0` to clear. |
| `type`        | data       | Logical category — drives in-app routing. See table. |
| `id`          | data       | The target entity's id (customer id, product id, transaction id…). |
| `route`       | data       | Optional explicit route override. If present, the app navigates here directly; otherwise it maps `type` → screen. |

### `type` values the app will route on

Mirror the existing in-app alert types so pushes and the Alerts center agree:

| `type`             | tap opens |
|--------------------|-----------|
| `low_stock`, `out_of_stock`, `expiring_inventory` | the product (by `id`) |
| `payment_due`, `payment_overdue`, `payment_received` | the customer / receivable (by `id`) |
| `large_transaction`, `new_order` | the transaction (by `id`) |
| `daily_summary`, `system`, or unknown | the Alerts center |

> Until per-`type` deep-routing is finalized on the client, any push routes to
> the Alerts center — so sending `type` now is forward-compatible and safe.

### Localization

The app supports **uz / ru / en**. Localize `title`/`body` **server-side** —
either store each user's locale and translate before sending, or send per-locale
copy. The `data` fields (`type`/`id`/`route`) are language-neutral and never
translated.

---

## 6. Response handling & dead-token cleanup

Read the APNs response per token:

- **`200`** — delivered to APNs (not a delivery guarantee to the device, but
  accepted).
- **`410 Gone`**, or **`400`** with reason **`BadDeviceToken`** / **`Unregistered`**
  → the token is dead (app uninstalled / token invalid). **Delete that row.**
- Anything else → log it (status + `reason` from the JSON body) for debugging.

Without cleanup, dead tokens pile up and every broadcast wastes calls on phones
that will never receive them.

---

## 7. A send action

Start minimal — one authenticated endpoint is enough to be useful:

```
POST /api/v1/admin/notifications/send
{
  "audience": "tenant" | "user",
  "userId": <id>,                 // when audience = "user"
  "title": "...", "body": "...",
  "type": "system", "id": null, "route": "/alerts"
}
```

Broadcast = fan out to every token in the tenant, routing each by its
`environment` (§4) and pruning dead ones (§6).

**Optional later:** push the fan-out onto a queue so a large broadcast (thousands
of tokens) doesn't block one request on thousands of sequential APNs calls.

---

## 8. Definition of done

The backend can:

1. Persist a token from `POST /mobile/devices/push-token` and remove it on
   `DELETE`.
2. Build a cached ES256 JWT from the `.p8` and POST to APNs over HTTP/2 with
   `apns-topic: com.hisobnoma.admin`.
3. **Route each send to the correct host by the token's `environment`.**
4. Deliver the §5 payload so the app can display and route it.
5. Delete tokens APNs reports dead (§6).
6. Expose a "send" action for announcements + the business alerts.

Once that's live: we run a real-device **sandbox** test (TestFlight/dev build),
then a **production** test (App Store build), then send the first announcement.

---

## 9. Quick reference — what the client already does

- Requests permission **after the user's first sale** (not at login), plus a
  master toggle in Settings.
- Registers/refreshes the token via §1.1; unregisters via §1.2 on logout.
- Displays foreground notifications natively (banner + sound + badge).
- On tap, reads the `data` payload and routes to `route` (or the Alerts center).
- Sends `environment: "sandbox"` from debug builds and `"production"` from
  release builds — so your §4 routing just works if you trust that field.
