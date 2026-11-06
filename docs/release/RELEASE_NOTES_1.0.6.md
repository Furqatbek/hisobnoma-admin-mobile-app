# Release 1.0.6 (build 7)

Everything new since 1.0.5.

## Highlights
- **Share a debtor's statement as a file** — open any debtor and tap the share
  icon to send their full debt breakdown (`ID, Product, Price, Comment, Date`)
  as a **CSV spreadsheet** via Telegram, WhatsApp, email or any app. As a file
  it has no message-length limit and opens in Excel / Google Sheets.
- **Telegram account linking** (Settings → Notifications → Telegram) — link
  your account to the Hisobnoma bot to receive its notifications. Optional.

## App Store "What's New" (short)
> Send any debtor their full statement as a spreadsheet file — straight from
> the debtor's page to Telegram, WhatsApp or email. Plus Telegram account
> linking for bot notifications.

### Localized "What's New"
- **UZ:** Исталган қарздорга тўлиқ қарз рўйхатини жадвал файли сифатида
  юборинг — қарздор саҳифасидан тўғридан-тўғри Telegram, WhatsApp ёки
  электрон почта орқали. Шунингдек, бот билдиришномалари учун Telegram
  аккаунтини улаш.
- **RU:** Отправляйте любому должнику полную выписку по долгу в виде
  файла-таблицы — прямо со страницы должника в Telegram, WhatsApp или на
  почту. Плюс привязка Telegram для уведомлений бота.

## Reviewer note
The share action uses the standard OS share sheet with a user-generated CSV of
the business's own receivables. Telegram linking is an opt-in integration with
the business's own bot; nothing is sent without the user's action.

## Pre-submit checklist
- [ ] Version `1.0.6+7` (set in `pubspec.yaml`); build 7 > last upload (6).
- [ ] `flutter pub get`, then `flutter analyze` clean + `flutter test` green
      (CI green on the release commit).
- [ ] On the Mac: `flutter build ipa --release` (or Xcode Organizer →
      Distribute App) → upload → submit in App Store Connect.

## Notes
- The "Deployment target too low (iOS 13)" upload warning is informational;
  Apple requires iOS 15+ from **April 2027**. Bump before then (drops iOS
  13/14 devices).
- No backend changes are required for this release.
