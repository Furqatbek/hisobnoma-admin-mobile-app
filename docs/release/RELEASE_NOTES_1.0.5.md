# Release 1.0.5 (build 6)

Everything new since the last App Store version (1.0.3).

## Highlights
- **Finance tools** — record an **expense**, **receive a payment from a
  debtor** (reduces their balance), and **pay salary or an advance** to an
  employee. All under **Settings → Finance**.
- **Edit a product's price** — tap a product in the Inventory tab to change its
  selling (and wholesale) price; respects the minimum-price floor.
- **Share the debtors list to Telegram** — from the Debtors tab, send to
  yourself or the whole team.
- **Alerts, one tap away** — a notification bell with an unread badge on the
  home screen opens the Alerts center.
- **Clearer home dashboard** — today's revenue, receivables and payables at a
  glance.

## App Store "What's New" (short)
> New finance tools: record expenses, collect debtor payments, and pay
> salaries/advances. Edit product prices on the go, share your debtors list to
> Telegram, and tap the new bell to see all your alerts in one place.

### Localized "What's New"
- **UZ:** Янги молиявий воситалар: харажатларни киритиш, қарздорлардан
  тўловларни қабул қилиш, ойлик ва аванс тўлаш. Товар нархини ўзгартириш,
  қарздорлар рўйхатини Telegram'га юбориш ва барча огоҳлантиришларни кўриш
  учун янги қўнғироқ белгиси.
- **RU:** Новые финансовые инструменты: запись расходов, приём платежей от
  должников, выплата зарплат и авансов. Изменение цен товаров, отправка списка
  должников в Telegram и новый колокольчик для всех оповещений.

## Reviewer note
This is a business/admin app for shop owners (expenses, debtor payments,
payroll, inventory pricing). All actions require a signed-in staff account with
the appropriate permissions.

## Pre-submit checklist
- [ ] Version `1.0.5+6` (set in `pubspec.yaml`).
- [ ] `flutter pub get`, then `flutter analyze` clean + `flutter test` green.
- [ ] On the Mac: `flutter build ipa --release` → upload (Xcode Organizer or
      Transporter) → submit in App Store Connect.
- [ ] Confirm the build number (6) is higher than any previously uploaded build.

## Notes
- iOS push delivery still depends on the backend APNs credentials being set
  (ops task); the in-app Alerts center and bell work regardless.
- Some finance features need the matching staff permission
  (`MOBILE_EXPENSE_WRITE`, `MOBILE_AR_COLLECT`, `MOBILE_SALARY_PAY`,
  `MOBILE_PRICE_WRITE`).
