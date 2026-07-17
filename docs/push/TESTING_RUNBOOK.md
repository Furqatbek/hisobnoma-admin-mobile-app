# Push Notifications — Testing Runbook (Phase 5)

Execute this once **both** are true:
- Backend ops has set `APNS_ENABLED=true` + `APNS_TEAM_ID` / `APNS_KEY_ID` /
  `APNS_BUNDLE_ID` / `APNS_PRIVATE_KEY` (until then a broadcast returns
  `apnsConfigured: false` and sends are a logged no-op — token *registration*
  already works).
- You have a **real iPhone** (remote push is unreliable on the simulator).

The client is contract-complete; this runbook is verification, not development.

---

## A. Sandbox test (TestFlight / dev build)

A dev or TestFlight build mints a **sandbox** token; the app reports
`environment: "sandbox"`, so the backend must send via
`api.sandbox.push.apple.com`.

1. **Install** a dev build on the device (`flutter run --release` over cable, or
   a TestFlight build).
2. **Log in**, then **make one sale** → the priming sheet appears → tap
   **Enable notifications** → accept the iOS system prompt.
3. **Confirm the token registered:** the backend `device_push_tokens` table has a
   row for your user with `environment = sandbox`. (Or add a temporary log on
   `POST /mobile/devices/push-token`.)
4. **Send a test push:** `POST /api/v1/admin/notifications/send` with
   `{ "audience": "user", "userId": <you>, "title": "Test", "body": "Hello",
   "type": "system", "route": "/alerts" }` (needs the `MOBILE_PUSH_SEND`
   permission). Response should show `sent: 1`, `apnsConfigured: true`.
5. **Verify delivery** in each app state (see §C).

## B. Production test (App Store / TestFlight-release build)

An App Store build mints a **production** token (`environment: "production"`) →
backend sends via `api.push.apple.com`. Repeat A.3–A.5 with a release build and
confirm the backend picks the production host from the stored `environment`.
This is the step that proves §4 host-routing works end to end.

---

## C. App-state matrix (run for both sandbox and production)

| State | How to test | Expect |
|-------|-------------|--------|
| **Foreground** | App open when the push arrives | Banner + sound; badge updates (handled natively in `willPresent`). |
| **Background** | Home-screen the app, then send | Banner on lock/home screen. |
| **Terminated** | Swipe-kill the app, then send | Banner appears; **tapping cold-launches** the app and routes (native buffers the tap and flushes it when the channel comes up). |
| **Tap routing** | Tap the notification in each state | `route: "/alerts"` → Alerts center; `type: new_order/large_transaction` → Transactions; unknown deep link → Alerts (never a GoRouter error page). |

## D. Lifecycle & hygiene

- [ ] **Permission denied:** on a fresh install, decline the iOS prompt → app
      keeps working, no token registered, no crash.
- [ ] **Token refresh:** reinstall → new token registers; old one should be
      pruned by the backend on its next failed send.
- [ ] **Logout unregisters:** log out → `DELETE /mobile/devices/push-token`
      fires → a push to that user no longer reaches the device.
- [ ] **Master toggle OFF:** Settings → Push notifications off → token removed →
      no delivery. Toggle back ON → re-registers → delivery resumes.
- [ ] **Badge clears:** send with `badge: 3` → icon shows 3 → open the Alerts
      center → badge clears to 0.
- [ ] **Dead-token cleanup:** uninstall the app → send → backend gets
      `410 / BadDeviceToken` → token row deleted.

---

## E. First real announcement

Once C and D pass in production, send the first real broadcast to a **small
internal group** (audience `user` to a couple of staff) before a full
`audience: tenant` blast. Confirm wording/localization, then go wide.

---

## Troubleshooting quick map

| Symptom | Likely cause |
|---------|--------------|
| `apnsConfigured: false` in send response | Ops hasn't set the `APNS_*` env vars. |
| `sent: 0`, token exists | Wrong host for the token's `environment` (§4 in the handoff) — sandbox token sent to prod host or vice-versa. |
| Push arrives but tap does nothing / error screen | Payload routing key issue — confirm `type`/`id`/`route` are **top-level**, not nested under `data`. |
| No banner in foreground only | `willPresent` options — already handled natively; check the build is current. |
| Nothing at all, token never registers | App not built with the Push Notifications capability / entitlement (Phase 1). |
