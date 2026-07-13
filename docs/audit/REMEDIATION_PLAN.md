# Hisobnoma — Remediation Plan

Phased plan to close every confirmed finding in [`FINDINGS.md`](./FINDINGS.md).
Ordered by blast radius: unblock the build, stop money loss, then harden.

**Finding IDs** (e.g. `C1`, `H3`, `M5`) reference `FINDINGS.md`.
**Checkbox states:** `[ ]` todo · `[~]` in progress · `[x]` done

---

## Phase 0 — Unblock the build (must land before anything else)

The branch does not compile; nothing can be built, tested, or shipped until this is fixed.

- [x] **0.1** Fix `closeShift` scope error `[C4/H16]` — catch no longer references the out-of-scope `shift`; only emits `ShiftClosed` on server-confirmed closure. `openShift` catch reviewed (was already fine).
- [~] **0.2** Run `flutter analyze` — no Flutter SDK in this environment; the specific scope fix was verified compiling with a standalone Dart reproduction. **Full `flutter analyze` must be run on your Mac / by the CI gate below.**
- [x] **0.3** CI gate: existing `.github/workflows/ci.yml` (analyze + test + format) now triggers on **every** push and PR, not just main/develop — feature branches are checked so a non-compiling commit is caught. (This gap is why the compile error slipped through.)

**Exit criteria:** `flutter analyze` clean (run on Mac/CI); CI green on this branch's next push.

---

## Phase 1 — Stop money loss and broken checkout (CRITICAL)

These directly cause unrecorded sales, lost sales, or credential theft on the live app. Do not ship a new build without all of Phase 1.

### 1A. Sale submission is honest about failure `[C2]`
- [x] **1.1** `_submitSale` now calls `cubit.transactionRepository.quickSale(...)` directly, so a failed sale throws and reaches the catch (also sidesteps the shared-cubit clobbering for the sale path).
- [x] **1.2** Only pops the sheet + shows the green success snackbar on real success. On failure the sheet stays open and the backend error is shown.
- [x] **1.3** Cart is preserved on failure (sheet not popped) so the cashier can retry.
- [ ] **1.4** Widget test: mock a failing `quickSale` → assert no success snackbar, sheet stays open. **(deferred to Phase 4)**

### 1B. Cash sale without a client no longer crashes `[C3]`
- [x] **1.5** `_selectedClient?['id']` / `?['name']` are now null-safe.
- [x] **1.6** Whole submit body wrapped in try/finally; `_isSubmitting` reset on every exit path (+ early-return double-submit guard).
- [ ] **1.7** Widget test: CASH sale with no client selected → request built and sent, no crash. **(deferred to Phase 4)**

### 1C. TLS — remove the blanket bypass `[C1]` (needs coordinated server fix)
- [ ] **1.8** **Server-side (blocker, YOUR action):** fix the certificate chain on `temurmchj.uz` (install the full intermediate chain). Verify with SSL Labs until it grades without chain warnings and passes default iOS validation.
- [~] **1.9** Bypass no longer unconditional: gated to `!kReleaseMode` and restricted to the exact API host. **Release builds now do full validation.** Delete the block entirely once 1.8 is verified. ⚠️ **The next release build will not connect until 1.8 is done.**
- [ ] **1.10** Apply the same TLS policy to the bare `Dio()` instances in `auth_interceptor.dart` and `retry_interceptor.dart` (folded into Phase 2, tie H7). **(deferred to Phase 2)**
- [x] **1.11** No change needed — the privacy policy claim "encryption in transit (HTTPS)" is accurate; the finding was about certificate *validation*, not absence of encryption.

**Exit criteria:** a failed sale never shows success; a cash sale with no client completes; no unconditional cert bypass in release builds.

---

## Phase 2 — Prevent financial corruption & session breakage (HIGH)

### 2A. No duplicate transactions `[H1]`
- [ ] **2.1** In `retry_interceptor.dart`, only retry idempotent methods (GET). Never auto-retry `POST` to `/quick-sale`, `/shifts/open`, `/shifts/{id}/close`, `/shifts/{id}/cash-operation`.
- [ ] **2.2** (Preferred, with backend) add a client-generated idempotency key (UUID) to sale/shift/cash POST bodies or headers so the server can dedupe; then safe retry becomes possible. Coordinate the field name with backend.
- [ ] **2.3** Add double-tap guard to the cash in/out **Confirm** button in `shift_sheet.dart:721` `[H12]` (disable while submitting).
- [ ] **2.4** Verify the sale **Complete** and shift **Open/Close** buttons all have submit guards; add where missing.

### 2B. Auth/session resilience `[H3, H4]`
- [ ] **2.5** Wire `onTokenExpired` when constructing `AuthInterceptor` in `injection.dart:46` so a failed refresh drives the app to the login screen (via `AuthCubit`).
- [ ] **2.6** Fix token-refresh Dio in `auth_interceptor.dart` to use the same adapter/policy as the main client (folded into 1.10).
- [ ] **2.7** Do not wipe a valid refresh token on a transient network error — distinguish "refresh rejected (401)" from "network failed", only clear tokens on true rejection.
- [ ] **2.8** Surface a localized "session expired, please log in" message instead of raw error screens.

### 2C. Shift + terminal correctness `[H5, H9]`
- [ ] **2.9** Send the **open shift's** `terminalId` on sales, not `?? 1`. If no terminal/shift is resolved, block the sale with a clear message rather than silently posting to terminal 1 `[M4]`.
- [ ] **2.10** Distinguish "network error" from "no open shift" in `getCurrentShift` (repository swallows all errors → `null`). Return/throw a typed error so `closeShift` does not report a false success when offline `[H9]`.
- [ ] **2.11** Do not emit `ShiftClosed` unless the server confirms closure; on network failure keep the shift open and show an error.

### 2D. Payment type contract `[H6]`
- [ ] **2.12** Confirm the backend's accepted `paymentType` enum (get the real vocabulary — CASH/CARD/CREDIT?). Fix the `'DEBT'` value in `add_sale_sheet.dart` to match. Until confirmed, debt sales may be silently rejected (and, pre-1A, shown as success).

### 2E. Environment isolation `[H15]`
- [ ] **2.13** Restore real per-environment base URLs in `app_config.dart`: dev → local/staging, prod → `temurmchj.uz`. Debug builds must not hit production by default.
- [ ] **2.14** Ensure `enableLogging` is `false` for any environment pointing at production `[M3]`.

**Exit criteria:** no auto-retry of financial POSTs; session expiry routes to login; shifts/terminals are accurate; debug builds cannot touch prod data.

---

## Phase 3 — Correctness & data completeness (HIGH/MEDIUM)

### 3A. State management `[H2, M1]`
- [ ] **3.1** Stop the shared `TransactionsCubit` from blanking the transactions screen after a sale/customer-create. Options: separate cubit instance for the sheets, add `buildWhen`/`listenWhen` guards, or reload `loadData()` after a sale completes. Pick one and apply consistently across sale sheet, client sheet, and screen.
- [ ] **3.2** Fix `ShiftOpened` not being recognized as an open shift `[M1]` so the next sale after opening a shift is not blocked (make the check accept `ShiftOpened` or re-emit `ShiftLoaded`).

### 3B. Pagination / data limits `[H13, H14]`
- [ ] **3.3** Product picker: replace the fixed `size: 200` fetch with server-side search + pagination (query the API as the user types), so product #201+ is reachable.
- [ ] **3.4** Client picker: same for the `size: 1000` customer fetch.
- [ ] **3.5** Confirm transactions-history and inventory tabs paginate or clearly indicate truncation.

### 3C. Pricing / quantity guards (MEDIUM)
- [ ] **3.6** Enforce a price floor on edited prices (e.g. `minSellingPrice` from the product model) rather than only `> 0`.
- [ ] **3.7** Decide and enforce per-UOM quantity rules (fractional allowed for weight, integer for UNIT).
- [ ] **3.8** Round currency math to a fixed scale at submission to avoid IEEE `double` drift.

### 3D. Error UX & i18n (MEDIUM)
- [ ] **3.9** Map raw `DioException.toString()` to friendly, localized messages across core cubits `[M6]`; never show stack-trace-ish text.
- [ ] **3.10** Fix dead wrong-PIN detection in `auth_cubit._parseError` and localize login errors `[M7]`.
- [ ] **3.11** Give the shift/sale/client sheets real retry affordances when their load APIs fail instead of misleading empty states `[M8]`.
- [ ] **3.12** Move remaining hardcoded English strings (`shift_sheet` "Terminal"/"No terminals available", `error_handler` "Error"/"OK"/"Network error", settings "System", localized dates/formatters) into the ARB files.

**Exit criteria:** screens survive normal use without blanking; all catalog items reachable; errors are friendly and localized.

---

## Phase 4 — Test the money paths (HIGH)

`[H17, M-tests]` — currently the only tests are a `1+1==2` placeholder and one button widget test.

- [ ] **4.1** Unit-test `transaction_repository` response parsing for every method (both wrapped and unwrapped shapes) — the class of bug that has already crashed this app repeatedly.
- [ ] **4.2** Unit-test `ErrorInterceptor` (top-level and nested error bodies, status mapping) and `retry_interceptor` (no POST retries after 2.1).
- [ ] **4.3** Widget-test the sale flow: success, failure (no false success — 1.4), cash sale without client (1.7), debt sale requires client.
- [ ] **4.4** Widget-test shift open/close/cash-op including the offline false-success guard (2.11).
- [ ] **4.5** Add a real app-boot smoke test replacing the placeholder (crash-on-launch guard).
- [ ] **4.6** Add pinning tests for each past production regression (render overflow/constraints, wrong endpoints, type-cast crashes) so they cannot silently return.
- [ ] **4.7** Turn the Phase 0.3 CI gate into a required check.

**Exit criteria:** every money path has a failing-and-passing test; CI blocks regressions.

---

## Phase 5 — Operational hygiene (MEDIUM/LOW)

- [ ] **5.1** Add crash/error reporting (e.g. Sentry/Crashlytics) so production crashes are visible instead of swallowed into `debugPrint` `[M-main]`.
- [ ] **5.2** Fail the Android release build loudly if `key.properties` is missing instead of silently signing with the debug key.
- [ ] **5.3** Either implement offline (enqueue + process `offline_queue`, read the synced DB) or remove the dead offline code and stop claiming "works offline" `[M2]`.
- [ ] **5.4** Remove dead dependencies (`flutter_screenutil`, `pull_to_refresh_flutter3`, etc.) and move build-time tools out of runtime deps.
- [ ] **5.5** Bundle the Inter font instead of fetching from `fonts.gstatic.com` at runtime (offline + privacy).
- [ ] **5.6** Decide web support: either fix `dart:io` usage behind conditional imports or drop the web target.
- [ ] **5.7** Regenerate l10n from ARB (`flutter gen-l10n`) instead of hand-editing generated files, so future edits don't drift.

**Exit criteria:** production failures are observable; no misleading capabilities; clean dependency surface.

---

## Suggested execution order & release gates

1. **Phase 0** → commit, get CI green. (No release.)
2. **Phase 1** → this is the minimum bar for a **hotfix release** to the App Store. Do not ship without it.
3. **Phase 2** → second release; makes the app financially trustworthy under real network conditions.
4. **Phase 3 + 4** together → correctness + the tests that lock it in.
5. **Phase 5** → ongoing hardening.

Each phase should land as its own PR with its mini-tasks checked off and CI green.
