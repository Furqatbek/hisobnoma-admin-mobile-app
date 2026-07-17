# Push Notifications — Direct APNs (no Firebase) — Implementation Plan

Goal: send notifications to users' iPhones (even when the app is closed) using
**Apple Push Notification service (APNs) directly**, with no Firebase/FCM.

Scope: **iOS only.** The app is also on Android, but Android push requires FCM
(Apple's APNs does not serve Android). Android push is a separate effort and is
**out of scope** here — noted in Phase 6.

Ownership legend: **[You]** = Apple Developer account / App Store Connect work ·
**[App]** = Flutter/iOS client work (me) · **[BE]** = backend team.

Authentication choice (decide first): Apple offers two ways for the backend to
authenticate to APNs:
- **Token-based `.p8` auth key (RECOMMENDED)** — one key for the whole team,
  never expires, works for both sandbox and production, simplest to rotate.
- **Certificate-based `.p12`** — per-app, **expires every year** (silent
  breakage when it lapses), separate cert per environment.

You said "certificate"; unless you specifically need `.p12`, use the **`.p8`
token** — it is strictly less painful. The plan below uses `.p8`; a `.p12`
variant is noted where it differs.

---

## Phase 0 — Apple prerequisites (no code) **[You]** — ✅ DONE

- [x] **0.1** Push Notifications enabled on the App ID `com.hisobnoma.admin`.
- [x] **0.2** `.p8` APNs auth key created (Key ID + Team ID recorded).
- [x] **0.4** `.p12` APNs SSL cert also exported (with password). Either works;
  the backend should prefer the `.p8` (no yearly expiry).

**Exit:** ✅ push enabled; both `.p8` and `.p12` in hand.

**Hand to the backend team (Phase 3):**
- Preferred — `.p8`: the file + **Key ID** + **Team ID** + **Bundle ID**
  (`com.hisobnoma.admin`, which is also the `apns-topic`).
- Or `.p12`: the file + its **password** + Bundle ID. Note it **expires yearly**.
- APNs hosts: `api.sandbox.push.apple.com` (TestFlight/dev tokens),
  `api.push.apple.com` (App Store tokens) — route by the token's `environment`.

---

## Phase 1 — iOS native capability **[App]** — 🔨 IN PROGRESS

- [ ] **1.1 [You, Xcode GUI]** In Xcode (`ios/Runner.xcworkspace`) → Runner
  target → **Signing & Capabilities** → **+ Capability** → **Push
  Notifications**. Writes `aps-environment` + `Runner.entitlements` and wires
  the project file. *(Must be done in the GUI — editing the project file by
  hand is error-prone.)*
- [ ] **1.2 [You, Xcode GUI]** **+ Capability → Background Modes** → check
  **Remote notifications**.
- [ ] **1.3 [You]** Confirm `ios/Runner/Runner.entitlements` now exists with an
  `aps-environment` key (Xcode created it in 1.1).
- [x] **1.4 [App]** `AppDelegate.swift` written: sets the
  `UNUserNotificationCenter` delegate, obtains the APNs token
  (`didRegisterForRemoteNotificationsWithDeviceToken` → hex), and bridges token
  + taps to Dart over the `hisobnoma/push` `MethodChannel` (built on the
  implicit-engine registrar for the new scene architecture). ⚠️ Written blind —
  expect one round of build-error fixes on the Mac.
- [x] **1.5 [App]** Permission is requested via `UNUserNotificationCenter`
  (Dart triggers it in Phase 2.2). No Info.plist usage string is required.

**Exit:** the app builds with the push entitlement and obtains a raw APNs token
natively, handing it to Dart.

---

## Phase 2 — Flutter client integration **[App]**

- [ ] **2.1** Decide the transport: a maintained package
  (`flutter_apns_only`) **or** a thin platform-channel + `flutter_local_
  notifications` (for showing notifications while the app is foregrounded).
  Recommendation: platform channel for the token + `flutter_local_
  notifications` for foreground display — zero heavy dependencies, full control.
- [ ] **2.2** Request notification permission via `UNUserNotificationCenter`
  (provisional or explicit). Show it at a sensible moment (e.g. after first
  login), not cold on launch. Handle "denied" gracefully (feature simply off).
- [ ] **2.3** Receive the APNs device token from the native channel; store it in
  memory + secure storage.
- [ ] **2.4** Register the token with the backend after login and on every app
  start if changed: `POST /mobile/devices/push-token`
  `{ token, platform: "ios", environment: "sandbox"|"production", appVersion }`.
  Include the environment so the backend targets the right APNs host.
- [ ] **2.5** Handle token refresh (APNs can rotate it) — re-register when the
  native callback fires with a new token.
- [ ] **2.6** On **logout**, unregister the token
  (`DELETE /mobile/devices/push-token`) so a logged-out phone stops receiving
  that user's notifications.
- [ ] **2.7** Foreground handling: when a push arrives while the app is open,
  show it via `flutter_local_notifications` (iOS won't display remote pushes
  automatically in foreground).
- [ ] **2.8** Tap handling / routing: when the user taps a notification, read
  its custom `data` payload and navigate (e.g. to Alerts, or a specific sale).
  Handle all three launch states: foreground, background, terminated.
- [ ] **2.9** Badge handling: clear the app icon badge when the relevant screen
  is opened.

**Exit:** a real device registers its token with the backend, receives a test
push in all app states, and tapping it routes correctly.

---

## Phase 3 — Backend: token storage + APNs sender **[BE]**

- [ ] **3.1** Table `device_push_tokens`: `id, tenant_id, user_id, token
  (unique), platform, environment, app_version, created_at, updated_at,
  last_seen_at`. Upsert on (token).
- [ ] **3.2** Endpoints: `POST /mobile/devices/push-token` (register/update),
  `DELETE /mobile/devices/push-token` (remove on logout). Auth-scoped to the
  logged-in user.
- [ ] **3.3** APNs client using the `.p8` key: build a JWT (ES256, `iss`=Team
  ID, `kid`=Key ID, refreshed ≤1h), send HTTP/2 POST to
  `api.push.apple.com` (production) or `api.sandbox.push.apple.com` (sandbox),
  path `/3/device/{token}`, header `apns-topic: com.hisobnoma.admin`. Pick the
  host per the token's stored `environment`. *(For `.p12`: mutual-TLS to the
  same hosts instead of the JWT.)*
- [ ] **3.4** Payload builder: `{ aps: { alert: { title, body }, sound,
  badge }, data: {…routing…} }`.
- [ ] **3.5** Response handling: on `410 Gone` or `BadDeviceToken`, **delete**
  the token (it is dead). Log failures.
- [ ] **3.6** Admin send action: broadcast to all tenant users, or target a
  user/group. Start with a simple authenticated "send announcement" endpoint.
- [ ] **3.7** (Optional) fan-out/queue for large sends so one request doesn't
  block on thousands of APNs calls.

**Exit:** backend can persist tokens and deliver a push to a specific device
via APNs, and prunes dead tokens.

---

## Phase 4 — Payload contract & UX polish **[App]+[BE]**

- [ ] **4.1** Agree the payload schema (title/body + a `type` and `id` in
  `data` for routing). Document it in `docs/api/MOBILE_MODULE_API.md`.
- [ ] **4.2** Localize notification text server-side (send in the user's
  language — the app already supports uz/ru/en; store the user's locale or send
  per-locale).
- [ ] **4.3** Define notification categories if you want action buttons later
  (optional).
- [ ] **4.4** Rate/quiet-hours policy so users aren't spammed (optional).

**Exit:** a stable, documented payload contract both sides implement against.

---

## Phase 5 — Testing & rollout **[You]+[App]+[BE]**

- [ ] **5.1** Sandbox test: TestFlight/dev build uses **sandbox** APNs. Register
  a token, send from the backend to `api.sandbox.push.apple.com`, verify
  delivery on a **real device** (remote push is unreliable on the simulator).
- [ ] **5.2** Test all states: app foreground, backgrounded, and **terminated**
  (killed) — plus tap-to-route in each.
- [ ] **5.3** Test permission denied, token refresh, and logout-unregister.
- [ ] **5.4** Test dead-token cleanup (uninstall the app → send → backend gets
  `410` → token removed).
- [ ] **5.5** Production test: an App Store/TestFlight-signed build uses
  **production** APNs (`api.push.apple.com`). Confirm the backend picks the host
  by the token's `environment`.
- [ ] **5.6** Send the first real announcement to a small internal group before
  a full broadcast.

**Exit:** delivery verified in sandbox and production, all app states, with
token hygiene working.

---

## Phase 6 — Release & follow-ups **[You]+[App]**

- [ ] **6.1** Bump version, `flutter build ipa --release`, upload, submit. The
  push capability + permission prompt may draw a brief App Review look — keep
  the permission purpose honest ("to notify you about your business activity
  and updates").
- [ ] **6.2** After approval, use the backend admin action to send announcements
  (e.g. "New update available", low-stock alerts, payment reminders).
- [ ] **6.3** (Future) **Android push** — needs FCM (APNs can't reach Android).
  Separate effort: FCM project, `google-services.json`, `firebase_messaging`,
  and an FCM sender in the backend. Not part of this plan.
- [ ] **6.4** (Future) analytics on delivery/open rates; silent/content pushes
  for background data refresh.

**Exit:** push live on iOS; you can notify users on demand.

---

## Critical facts to not trip over

- **App Store updates never notify users** — that is why this whole feature is
  needed. Push is the only way to proactively reach a phone.
- **Sandbox vs production are different APNs hosts.** A TestFlight/dev token
  only works against sandbox; an App Store token only against production. The
  backend MUST route by the token's stored `environment`, or every push
  silently fails with `BadDeviceToken`.
- **Permission is opt-in.** Users who deny get nothing; that is expected.
- **`.p8` doesn't expire; `.p12` expires yearly** and will silently break push
  when it lapses — set a calendar reminder if you choose `.p12`.
- **Real device required** for reliable testing; the simulator is unreliable for
  remote push.

## Who does what, in order

1. **[You]** Phase 0 — enable push, create `.p8`, hand `.p8`/Key ID/Team ID to
   the backend team. *(Blocks everything.)*
2. **[App]** Phases 1–2 — I add the iOS capability, native token bridge,
   permission, token registration, and tap routing.
3. **[BE]** Phase 3 — token storage + APNs sender.
4. **[App]+[BE]** Phase 4 — payload contract.
5. **All** Phase 5 — test sandbox → production on a real device.
6. **[You]+[App]** Phase 6 — release and send.
