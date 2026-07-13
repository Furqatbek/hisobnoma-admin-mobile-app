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
- [x] **2.1** `retry_interceptor.dart` now only retries idempotent GET/HEAD. All financial POSTs (`/quick-sale`, `/shifts/open`, `/shifts/{id}/close`, `/shifts/{id}/cash-operation`) are never auto-retried.
- [ ] **2.2** **(needs backend)** client-generated idempotency key (UUID) on sale/shift/cash POSTs so retries could be safe. **BLOCKED: coordinate the field name/header with backend.**
- [x] **2.3** Cash in/out **Confirm** now has a submit guard (disabled while submitting) `[H12]`.
- [x] **2.4** All shift buttons (Open/Close/Cash) share an `_isSubmitting` guard; the sale **Complete** button got its guard in Phase 1.

### 2B. Auth/session resilience `[H3, H4]`
- [x] **2.5** `onTokenExpired` wired in `app.dart` to `AuthCubit.handleSessionExpired`, which routes to login. No more stranding on silently-failing screens.
- [x] **2.6** Token-refresh + retry Dio instances now go through the shared `applyTlsPolicy` (new `tls_policy.dart`), same policy as the main client (folds in 1.10).
- [x] **2.7** `_tryRefreshToken` now distinguishes `rejected` (401/403 → clear tokens, log in) from `networkError` (timeout/connection → keep tokens). A transient blip no longer destroys a valid session.
- [~] **2.8** Session expiry now routes to the login screen (the substance of H4). An explicit "session expired" toast is **deferred to Phase 3** (needs a small state flag through `AuthUnauthenticated`).

### 2C. Shift + terminal correctness `[H5, H9]`
- [x] **2.9** Sales now post against the **open shift's** `terminalId` (`_openShiftTerminalId`), never `?? 1`. If no terminal is resolved, the sale is blocked with a message `[M4]`.
- [~] **2.10** The dangerous half (false "closed" success on a network drop) is fixed via 2.11. Returning a **typed** network-vs-no-shift error from `getCurrentShift` (to stop "no shift" showing during outages, which invites duplicate opens) is **deferred to Phase 3**.
- [x] **2.11** `closeShift` emits `ShiftClosed` only when the server confirms a closed shift; on failure it reloads real state instead of faking success (done in Phase 0.1).

### 2D. Payment type contract `[H6]`
- [ ] **2.12** **(needs backend) BLOCKED.** `'DEBT'` was introduced by the mobile app and has no confirmed backend enum value. **You must confirm the backend's accepted `paymentType` vocabulary** (CASH/CARD/CREDIT/DEBT?). With Phase 1A in place, a rejected debt sale now correctly shows the backend error instead of a false success — so if `'DEBT'` is wrong you will see it fail loudly rather than silently.

### 2E. Environment isolation `[H15]`
- [~] **2.13** You explicitly chose a single backend (`temurmchj.uz`) and there is no separate staging server, so per-environment URLs don't apply. Kept as-is by design; the real risk was log exposure, addressed below.
- [x] **2.14** Prod `enableLogging` is `false`; and Dio's raw `LogInterceptor` (which dumped Authorization headers + PINs) is replaced by `SafeLogInterceptor`, which redacts credentials — so even debug logging can't leak tokens/PINs `[M3]`.

**Exit criteria:** no auto-retry of financial POSTs ✔; session expiry routes to login ✔; shifts/terminals accurate ✔; credentials never logged ✔. **Open (backend):** idempotency key (2.2), payment enum (2.12).

---

## Phase 3 — Correctness & data completeness (HIGH/MEDIUM)

### 3A. State management `[H2, M1]`
- [x] **3.1** The shared `TransactionsCubit` no longer blanks the screen: the sale path reloads `loadData()` on success (Phase 1A), and client-create now calls the repository directly instead of emitting `CustomerCreated`/`TransactionsLoading` on the shared cubit. Its dead `BlocListener` was removed.
- [x] **3.2** `openShift` now settles on `ShiftLoaded` (after the transient `ShiftOpened`), so the sale sheet and AppBar recognize the open shift and the next sale is not wrongly blocked `[M1]`.

### 3B. Pagination / data limits `[H13, H14]`  — **DEFERRED**
- [ ] **3.3** Product picker: replace the fixed `size: 200` fetch with server-side search + pagination. *(Fine for shops under ~200 SKUs; needs the `/mobile/products/search` endpoint wired with a debounce.)*
- [ ] **3.4** Client picker: same for the `size: 1000` customer fetch.
- [ ] **3.5** Confirm transactions-history and inventory tabs paginate or indicate truncation.

### 3C. Pricing / quantity guards (MEDIUM)
- [x] **3.6** Added `minSellingPrice` to `InventoryProduct` and the price-edit dialog now rejects a price below the floor (when the backend provides one) with a clear message.
- [ ] **3.7** Per-UOM quantity rules (integer for UNIT, fractional for weight) — **DEFERRED**; needs the UOM policy confirmed.
- [x] **3.8** Money amounts (`unitPrice`, `tenderedAmount`) are rounded to 2 decimals at submission via `_money()`, avoiding IEEE `double` drift.

### 3D. Error UX & i18n (MEDIUM)
- [x] **3.9** Extracted a pure `extractErrorMessage` into `lib/core/utils/error_message.dart` (maps `DioException`/`ApiException`/network to friendly text) and routed **all** list cubits (transactions ×11, shift ×3, reports, alerts) through it instead of `e.toString()`. `error_handler` now delegates to the same core function. No screen shows raw `DioException … null` anymore `[M6]`.
- [x] **3.10** `auth_cubit._parseError` now unwraps the `DioException`→`ApiException` (code/status) so wrong-PIN, network, and rate-limit cases are detected correctly instead of always showing the generic message. *(Full localization of these 4 strings still English — deferred.)*
- [ ] **3.11** Retry affordances on load failure in the sheets — **DEFERRED**.
- [ ] **3.12** Move remaining hardcoded English strings into ARB — **DEFERRED**.

**Exit criteria:** screens survive normal use without blanking ✔; price floor + money rounding enforced ✔; login errors detected ✔. **Deferred:** catalog pagination, per-UOM rules, remaining i18n/retry polish.

---

## Phase 4 — Test the money paths (HIGH)

> Note: the app already has more tests than the audit's testing finding implied
> (`auth_cubit`, `alerts_cubit`, `formatters`, model + widget tests). That
> finding was in the unverified bucket and overstated. The gaps below are still
> real. **These require a Flutter SDK to run — write on the Mac / rely on CI.**

- [x] **4.1a** Extracted the sale-path money/quantity logic into a pure,
  Flutter-free util (`lib/core/utils/money.dart`) and added `money_test.dart`
  covering IEEE-drift rounding and quantity formatting. **Verified passing**
  against the Dart SDK directly. Locks in fix 3.8.
- [x] **4.x** Guarded the existing `auth_cubit_test` from breaking: the
  `_parseError` detection fix (3.10) was made additive so the existing
  wrong-PIN / network assertions still hold.
- [ ] **4.1** Unit-test `transaction_repository` response parsing for every method (wrapped + unwrapped shapes). *(Mac — needs dio + mocks.)*
- [ ] **4.2** Unit-test `ErrorInterceptor` and `retry_interceptor` (assert no POST retries after 2.1). *(Mac.)*
- [ ] **4.3** Widget-test the sale flow: success, failure (no false success), cash sale without client, debt requires client. *(Mac.)*
- [ ] **4.4** Widget-test shift open/close/cash-op including the offline false-success guard. *(Mac.)*
- [ ] **4.5** Replace the `1+1` smoke test with a real app-boot test. *(Mac.)*
- [ ] **4.6** Pinning tests for each past regression (render overflow, wrong endpoints, type-casts). *(Mac.)*
- [ ] **4.7** Make the CI gate a required check on the branch/PR settings.

**Exit criteria:** every money path has a test; CI blocks regressions. **Started:** pure money logic tested + verified; interceptor/widget tests remain (need Flutter SDK).

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
