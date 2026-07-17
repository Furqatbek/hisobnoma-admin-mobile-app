# Release 1.0.4 (build 5)

## Highlights
- **Push notifications (iOS).** Get notified about new sales, low stock and
  payments due — even when the app is closed. You're asked to turn them on after
  your first sale, and there's a master switch in **Settings → Notifications**.
- **Alerts, now one tap away.** A notification bell with an unread badge on the
  home screen opens the Alerts center.

## App Store "What's New" (short)
> Stay on top of your business with push notifications for new sales, low stock
> and payments due. Tap the new bell on the home screen to see all your alerts
> in one place.

### Localized "What's New"
- **UZ:** Янги сотувлар, кам қолган товарлар ва тўловлар ҳақида пуш
  билдиришномалар. Барча огоҳлантиришларни кўриш учун бош экрандаги қўнғироқ
  белгисини босинг.
- **RU:** Push-уведомления о новых продажах, низком остатке и предстоящих
  платежах. Нажмите на колокольчик на главном экране, чтобы увидеть все
  оповещения.

## Reviewer note (permission purpose)
Notifications are used **to alert the business owner about their own store
activity** — new sales, low/out-of-stock items, and payments due. No marketing
spam. The permission prompt appears after the user's first sale, in context.

## Pre-submit checklist
- [ ] Version `1.0.4+5` (already set in `pubspec.yaml`).
- [ ] Phase 1 Xcode capabilities present (Push Notifications + Background Modes →
      Remote notifications); `Runner.entitlements` has `aps-environment`.
- [ ] `flutter analyze` clean, `flutter test` green (incl. new
      `notification_router_test`).
- [ ] `flutter build ipa --release` → upload via Xcode/Transporter → submit.
- [ ] (Recommended) verify a **sandbox** push on a TestFlight build first — see
      `docs/push/TESTING_RUNBOOK.md` — before promoting to production.

## Notes
- Push only *delivers* once backend ops sets the `APNS_*` env vars; the app can
  ship before then (registration works, sends are a no-op until configured).
- Android push is a future effort (needs FCM) — not in this release.
