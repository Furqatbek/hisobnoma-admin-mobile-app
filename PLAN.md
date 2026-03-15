# Hisobnoma - Mobile App Implementation Plan

## Overview

**App:** Hisobnoma — Financial tracking / accounting mobile app
**Framework:** Flutter (Dart)
**Design:** Apple HIG-compliant, minimal, premium feel
**Backend API:** `/api/v1/mobile` (JWT auth, REST)
**State Management:** flutter_bloc (Cubit pattern)
**Architecture:** Clean Architecture (data → domain → presentation)

---

## BLOCK 1: Project Scaffolding & Configuration

### 1.1 Initialize Flutter Project
- Run `flutter create` with org `com.hisobnoma`
- Set minimum SDK: iOS 15.0, Android API 24
- Configure app name "Hisobnoma" in both platforms

### 1.2 Configure `pubspec.yaml` Dependencies
```yaml
# Core
flutter_bloc / bloc
equatable
get_it (dependency injection)
injectable

# Networking
dio
retrofit
json_annotation / json_serializable

# Storage
shared_preferences
flutter_secure_storage
sqflite (offline cache)

# UI
flutter_svg
cached_network_image
shimmer
fl_chart
intl (date/number formatting)
google_fonts (SF Pro Display fallback)

# Navigation
go_router

# Utils
flutter_screenutil (responsive sizing)
pull_to_refresh_flutter3
```

### 1.3 Set Up Folder Structure
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   └── app_strings.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── light_theme.dart
│   │   └── dark_theme.dart
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── api_endpoints.dart
│   │   ├── interceptors/
│   │   │   ├── auth_interceptor.dart
│   │   │   └── error_interceptor.dart
│   │   └── api_exceptions.dart
│   ├── di/
│   │   └── injection.dart
│   ├── router/
│   │   └── app_router.dart
│   └── utils/
│       ├── formatters.dart
│       └── validators.dart
├── data/
│   ├── models/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── transaction/
│   │   ├── alert/
│   │   └── sync/
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── dashboard_repository.dart
│   │   ├── transaction_repository.dart
│   │   ├── alert_repository.dart
│   │   └── sync_repository.dart
│   └── local/
│       ├── database_helper.dart
│       └── dao/
├── domain/
│   ├── entities/
│   └── repositories/ (abstract interfaces)
├── presentation/
│   ├── widgets/
│   │   ├── common/
│   │   │   ├── app_card.dart
│   │   │   ├── app_button.dart
│   │   │   ├── app_text_field.dart
│   │   │   ├── app_bottom_sheet.dart
│   │   │   ├── loading_shimmer.dart
│   │   │   └── empty_state.dart
│   │   ├── charts/
│   │   │   ├── revenue_chart.dart
│   │   │   └── category_pie_chart.dart
│   │   └── transaction/
│   │       └── transaction_tile.dart
│   ├── screens/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── transactions/
│   │   ├── reports/
│   │   └── settings/
│   └── blocs/
│       ├── auth/
│       ├── dashboard/
│       ├── transactions/
│       ├── reports/
│       └── settings/
└── gen/ (generated code)
```

### 1.4 Platform Configuration
- iOS: Update `Info.plist` (permissions, display name)
- Android: Update `AndroidManifest.xml`, `build.gradle`
- Set up flavors: dev, staging, prod

---

## BLOCK 2: Design System & Theme

### 2.1 Color System
```dart
// Primary
royalBlue: #1E3A8A
royalBlueLight: #2B4FCF
royalBlueDark: #152C6B

// Neutrals
white: #FFFFFF
background: #F5F5F7
cardBackground: #FFFFFF
textPrimary: #1C1C1E
textSecondary: #8E8E93
textTertiary: #AEAEB2
separator: #E5E5EA

// Semantic
success: #34C759
warning: #FF9F0A
error: #FF3B30
income: #34C759
expense: #FF3B30
```

### 2.2 Typography Scale (Apple HIG)
```dart
largeTitle:  34px, bold    (-0.4 tracking)
title1:      28px, bold    (0.36 tracking)
title2:      22px, bold    (0.35 tracking)
title3:      20px, semibold(0.38 tracking)
headline:    17px, semibold(-0.41 tracking)
body:        17px, regular (-0.41 tracking)
callout:     16px, regular (-0.32 tracking)
subheadline: 15px, regular (-0.24 tracking)
footnote:    13px, regular (-0.08 tracking)
caption1:    12px, regular (0 tracking)
caption2:    11px, regular (0.07 tracking)
```

### 2.3 Spacing Grid (8pt system)
```dart
xs:   4px
sm:   8px
md:   16px
lg:   24px
xl:   32px
xxl:  48px
```

### 2.4 Component Tokens
- Border radius: 12px (cards), 10px (buttons), 22px (pills)
- Card shadow: `0 2px 8px rgba(0,0,0,0.08)`
- Card padding: 16px
- List item height: 56px
- Bottom nav height: 83px (with safe area)
- FAB size: 56px

### 2.5 Dark Mode Theme
- Background: #000000
- Card: #1C1C1E
- Elevated: #2C2C2E
- Separator: #38383A
- Maintain same primary blue

### 2.6 App Icon
- 1024x1024 master icon
- Royal blue (#1E3A8A) background
- White geometric "H" letter, centered
- Rounded superellipse (iOS), adaptive icon (Android)

---

## BLOCK 3: Core Infrastructure

### 3.1 Dependency Injection Setup
- Configure `get_it` service locator
- Register all repositories, blocs, API clients
- Initialize in `main.dart` before `runApp()`

### 3.2 Network Layer (Dio + Interceptors)
- Base `ApiClient` class wrapping Dio
- `AuthInterceptor`: attach JWT Bearer token to all requests
- `ErrorInterceptor`: map HTTP errors to typed exceptions
- Token refresh logic (401 → auto-refresh → retry)
- Rate limit handling (429 → backoff)
- Base URL configuration per environment

### 3.3 Router Setup (go_router)
- Shell route with bottom navigation
- Auth guard (redirect to login if no token)
- Routes:
  - `/auth/login` — Login screen
  - `/` — Dashboard (home)
  - `/transactions` — Transaction list
  - `/transactions/add` — Add transaction (modal)
  - `/reports` — Reports
  - `/settings` — Settings
  - `/barcode` — Barcode scanner

### 3.4 Secure Storage
- Store JWT tokens in `flutter_secure_storage`
- Store device ID
- Store user preferences in `shared_preferences`

---

## BLOCK 4: Data Models & API Integration

### 4.1 Auth Models
```dart
LoginRequest { phone, code }
LoginResponse { accessToken, refreshToken, tokenType, expiresIn, userId, tenantId, permissions }
DeviceRegistration { deviceId, fcmToken, platform, deviceName, deviceModel, osVersion, appVersion }
DeviceInfo { id, deviceId, platform, deviceName, active, lastActiveAt }
```

### 4.2 Dashboard Models
```dart
RevenueSummary { todayRevenue, yesterdayRevenue, thisWeekRevenue, lastWeekRevenue,
                 thisMonthRevenue, lastMonthRevenue, todayChangePercent, weekChangePercent,
                 monthChangePercent, todayTransactionCount, thisWeekTransactionCount,
                 thisMonthTransactionCount, averageTransactionValue }
RevenueChartData { label, value, count }
InventorySummary { totalSkuCount, activeSkuCount, totalInventoryValue,
                   lowStockCount, outOfStockCount, expiringCount }
FinancialSummary { totalBankBalance, totalCashBalance, arOutstanding,
                   apOutstanding, netCashPosition }
```

### 4.3 Transaction/Quick Sale Models
```dart
QuickSaleRequest { terminalId, customerId, items[], paymentType, tenderedAmount, notes }
QuickSaleItem { productId, variantId, quantity, unitPrice, discountAmount }
QuickSaleResponse { id, transactionNumber, transactionType, status,
                    totalAmount, paidAmount, changeAmount, completedAt }
QuickCountRequest { productId, locationId, countedQuantity, notes }
QuickCountResponse { productId, productName, sku, locationId,
                     systemQuantity, countedQuantity, variance, variancePercent }
ProductLookup { productId, sku, barcode, name, sellingPrice, costPrice,
                totalStock, category, uom, trackInventory, stockByLocation[] }
```

### 4.4 Alert Models
```dart
Alert { id, alertType, title, message, priority, entityType, entityId, isRead, createdAt }
AlertPreference { id, alertType, pushEnabled, inAppEnabled, emailEnabled,
                  smsEnabled, thresholdValue }
PaginatedAlerts { content[], page, size, totalElements, totalPages }
```

### 4.5 Sync Models
```dart
SyncProduct { id, sku, barcode, name, categoryId, categoryName,
              sellingPrice, costPrice, unitOfMeasure, trackInventory, active, updatedAt }
SyncCustomer { id, code, name, phone, email, priceListId,
               creditLimit, currentBalance, active, updatedAt }
SyncCategory { id, name, parentId, sortOrder, active, updatedAt }
SyncResponse<T> { lastSyncAt, syncVersion, fullSyncRequired, items[] }
```

### 4.6 Repository Implementations
- `AuthRepository` — login, refresh, device registration, logout
- `DashboardRepository` — revenue, inventory, financial summaries
- `TransactionRepository` — quick sale, quick count, barcode lookup, product/customer search
- `AlertRepository` — alerts CRUD, preferences, unread count
- `SyncRepository` — products, customers, categories sync

---

## BLOCK 5: Authentication Flow

### 5.1 AuthBloc / AuthCubit
States: `AuthInitial`, `AuthLoading`, `AuthCodeSent`, `AuthAuthenticated`, `AuthError`, `AuthUnauthenticated`

### 5.2 Login Screen
- Clean, centered layout
- App logo (H icon) at top
- Phone number input with country code (+998)
- "Send Code" button → triggers SMS verification
- 6-digit OTP input (individual digit boxes)
- Auto-submit on last digit
- Loading state with subtle animation
- Error handling with inline messages

### 5.3 Token Management
- Save tokens to secure storage on login
- Auto-refresh on 401 responses
- Clear tokens on logout
- Device registration after successful login

---

## BLOCK 6: Dashboard Screen (Home)

### 6.1 DashboardBloc / DashboardCubit
- Load revenue summary, inventory summary, financial summary in parallel
- Pull-to-refresh support
- Loading shimmer states

### 6.2 Dashboard Layout
```
┌─────────────────────────────┐
│  Hisobnoma          🔔 (3)  │  ← App bar with alert badge
├─────────────────────────────┤
│                             │
│  Good morning, User         │  ← Greeting
│                             │
│  ┌─────────────────────┐    │
│  │  Current Balance     │    │  ← Hero card (Royal Blue)
│  │  57,000,000 UZS      │    │
│  │  ↑ 9.38% this month  │    │
│  └─────────────────────┘    │
│                             │
│  Revenue        Expenses    │  ← Summary pills
│  ┌──────┐      ┌──────┐    │
│  │35.0M │      │ 8.0M │    │
│  │  ↑9% │      │ ↓3%  │    │
│  └──────┘      └──────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │  Revenue Chart       │    │  ← Line chart (7 days)
│  │  ╱╲    ╱╲            │    │
│  │ ╱  ╲╱╱  ╲╱          │    │
│  └─────────────────────┘    │
│                             │
│  Inventory Overview         │  ← Section header
│  ┌──────┐ ┌──────┐ ┌────┐  │
│  │1,420 │ │  45  │ │ 12 │  │
│  │Active│ │ Low  │ │Out │  │
│  └──────┘ └──────┘ └────┘  │
│                             │
│         [ + ]               │  ← FAB (Quick Add)
├─────────────────────────────┤
│ 🏠  📋  📊  ⚙️              │  ← Bottom Navigation
└─────────────────────────────┘
```

### 6.3 Dashboard Components
- `BalanceHeroCard` — gradient royal blue, large balance, change %
- `SummaryPillRow` — income/expense side-by-side mini cards
- `RevenueLineChart` — smooth curved line, 7-day or 30-day
- `InventoryQuickStats` — 3 metric cards in a row
- `AlertBadge` — notification bell with unread count
- Shimmer loading placeholders for each section

---

## BLOCK 7: Transactions Screen

### 7.1 TransactionBloc / TransactionCubit
- Load transactions (paginated)
- Filter by type (income/expense/all)
- Search by product name, SKU, barcode
- Pull-to-refresh, infinite scroll

### 7.2 Transaction List Screen
```
┌─────────────────────────────┐
│  Transactions        🔍     │
├─────────────────────────────┤
│  [All] [Income] [Expense]   │  ← Segmented control
│                             │
│  Today                      │  ← Section header
│  ┌─────────────────────┐    │
│  │ 🛒 Product Sale      │    │
│  │ TXN-20260115-0001   │    │
│  │              +50,000 │    │  ← Green for income
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │ 📦 Stock Purchase    │    │
│  │ TXN-20260115-0002   │    │
│  │              -18,000 │    │  ← Red for expense
│  └─────────────────────┘    │
│                             │
│  Yesterday                  │
│  ┌─────────────────────┐    │
│  │ ...                  │    │
│  └─────────────────────┘    │
│                             │
│         [ + ]               │  ← FAB
├─────────────────────────────┤
│ 🏠  📋  📊  ⚙️              │
└─────────────────────────────┘
```

### 7.3 Add Transaction Bottom Sheet
- Modal bottom sheet (iOS-style drag handle)
- Segmented toggle: Income / Expense
- Product search field (autocomplete from API)
- Quantity, unit price fields
- Customer search (optional)
- Payment type selector (CASH, CARD)
- Notes text area
- Date picker (iOS-style wheel)
- "Save" button (full width, royal blue)
- Haptic feedback on save

### 7.4 Barcode Scanner
- Camera-based barcode scanner
- Overlay with scanning frame
- Auto-lookup via `GET /barcode/{barcode}`
- Display product details card after scan
- Quick actions: Add to sale, View stock

---

## BLOCK 8: Reports Screen

### 8.1 ReportsCubit
- Load revenue chart data (hourly/daily/monthly)
- Compute category breakdown from transactions
- Period selection (this week, this month, custom)

### 8.2 Reports Layout
```
┌─────────────────────────────┐
│  Reports                    │
├─────────────────────────────┤
│  [Week] [Month] [Year]     │  ← Period selector
│                             │
│  ┌─────────────────────┐    │
│  │  Revenue Overview    │    │
│  │                      │    │
│  │  ┌──── 35.0M ────┐  │    │  ← Bar chart
│  │  │ █ █ █ █ █ █ █  │  │    │
│  │  │ █ █ █ █ █ █ █  │  │    │
│  │  └────────────────┘  │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │  Income vs Expense   │    │
│  │     ┌───┐            │    │  ← Donut chart
│  │    │ 81%│            │    │
│  │     └───┘            │    │
│  │  Income   Expense    │    │
│  │  35.0M     8.0M      │    │
│  └─────────────────────┘    │
│                             │
│  Category Breakdown         │
│  ┌─────────────────────┐    │
│  │ Electronics    45%   │    │
│  │ ████████████░░░░░░  │    │
│  │ Food          25%   │    │
│  │ ██████░░░░░░░░░░░░  │    │
│  │ Services      30%   │    │
│  │ ████████░░░░░░░░░░  │    │
│  └─────────────────────┘    │
├─────────────────────────────┤
│ 🏠  📋  📊  ⚙️              │
└─────────────────────────────┘
```

### 8.3 Chart Components
- `RevenueBarChart` — vertical bars, animated entrance
- `IncomeExpenseDonut` — donut chart with center label
- `CategoryBreakdownList` — horizontal progress bars with %

---

## BLOCK 9: Settings Screen

### 9.1 SettingsCubit
- Load/save user preferences
- Theme mode (light/dark/system)
- Currency selection
- Sync status
- Device info

### 9.2 Settings Layout
```
┌─────────────────────────────┐
│  Settings                   │
├─────────────────────────────┤
│                             │
│  Appearance                 │  ← Section header
│  ┌─────────────────────┐    │
│  │ Dark Mode      [🔘] │    │  ← Toggle
│  │─────────────────────│    │
│  │ Currency       UZS > │    │  ← Drill-down
│  └─────────────────────┘    │
│                             │
│  Data                       │
│  ┌─────────────────────┐    │
│  │ Sync Data           >│    │
│  │─────────────────────│    │
│  │ Last sync: 10:30 AM │    │
│  │─────────────────────│    │
│  │ Clear Cache         >│    │
│  └─────────────────────┘    │
│                             │
│  Notifications              │
│  ┌─────────────────────┐    │
│  │ Alert Preferences   >│    │  ← Opens alert prefs
│  │─────────────────────│    │
│  │ Devices             >│    │  ← Manage devices
│  └─────────────────────┘    │
│                             │
│  Account                    │
│  ┌─────────────────────┐    │
│  │ Log Out              │    │  ← Red text
│  └─────────────────────┘    │
│                             │
│  v1.0.0                     │  ← App version
├─────────────────────────────┤
│ 🏠  📋  📊  ⚙️              │
└─────────────────────────────┘
```

### 9.3 Sub-screens
- Currency picker (list with checkmark)
- Alert preferences (toggles per alert type)
- Device management (list with swipe-to-delete)
- Sync screen (progress indicator, force sync button)

---

## BLOCK 10: Alerts System

### 10.1 AlertsCubit
- Load paginated alerts
- Mark read/unread
- Unread count polling (every 60s)
- Filter by type

### 10.2 Alerts Screen (accessed from bell icon)
- List of alert cards grouped by date
- Swipe-to-mark-read gesture
- "Mark All Read" button in header
- Alert type icons and priority color coding
- Tap to navigate to related entity

### 10.3 Push Notifications
- FCM integration (device registration on login)
- Local notification display
- Deep linking from notification to relevant screen

---

## BLOCK 11: Offline Sync

### 11.1 SyncService
- SQLite local database for products, customers, categories
- Incremental sync using `lastSyncAt` timestamp
- Full sync on first launch
- Background sync on app resume
- Conflict resolution (server wins)

### 11.2 Local Database Schema
```sql
products (id, sku, barcode, name, categoryId, categoryName,
          sellingPrice, costPrice, uom, trackInventory, active, updatedAt)
customers (id, code, name, phone, email, priceListId,
           creditLimit, currentBalance, active, updatedAt)
categories (id, name, parentId, sortOrder, active, updatedAt)
sync_metadata (entity, lastSyncAt, syncVersion)
```

### 11.3 Offline-First Flow
- Product/customer search queries local DB first
- Falls back to API if not found locally
- Queued actions for offline quick-sales (sync when online)

---

## BLOCK 12: Shared UI Components Library

### 12.1 Core Components
- `HisobCard` — rounded card with shadow, padding, optional header
- `HisobButton` — primary (filled), secondary (outlined), text variants
- `HisobTextField` — labeled input with validation, Apple-style
- `HisobSegmentedControl` — iOS-style segmented toggle
- `HisobBottomSheet` — modal sheet with drag handle
- `HisobListTile` — settings-style list item with accessory
- `HisobBadge` — notification count badge
- `HisobEmptyState` — icon + message + action for empty lists
- `HisobShimmer` — loading placeholder animations

### 12.2 Animation Utilities
- Page transition (iOS slide from right)
- Bottom sheet spring animation
- Chart entrance animations (staggered)
- FAB scale animation
- Pull-to-refresh with custom indicator
- Haptic feedback helper

---

## BLOCK 13: App Icon & Branding Assets

### 13.1 App Icon Specification
- Canvas: 1024x1024px
- Background: Solid #1E3A8A (Royal Blue)
- Letter "H": White (#FFFFFF), geometric sans-serif
- H dimensions: ~600px tall, centered
- H stroke width: ~90px
- Corner radius: iOS auto (superellipse), Android adaptive

### 13.2 Generated Sizes
- iOS: 20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024
- Android: mdpi(48), hdpi(72), xhdpi(96), xxhdpi(144), xxxhdpi(192)
- Use `flutter_launcher_icons` package for generation

### 13.3 Splash Screen
- White background (light) / Black background (dark)
- Centered app icon (120px)
- Use `flutter_native_splash` package

---

## BLOCK 14: Testing & Quality

### 14.1 Unit Tests
- All Cubit/Bloc state transitions
- Repository methods (mock API responses)
- Data model serialization/deserialization
- Formatter utilities

### 14.2 Widget Tests
- Each reusable component
- Screen layouts with mock data
- Navigation flows

### 14.3 Integration Tests
- Auth flow (login → dashboard)
- Add transaction flow
- Sync flow

### 14.4 Code Quality
- `flutter_lints` strict rules
- Dart format enforcement
- Generated code with `build_runner`

---

## BLOCK 15: Build & Release

### 15.1 iOS Build
```bash
flutter build ios --release
# Requires: Xcode, Apple Developer account
# Config: Runner.xcworkspace signing
```

### 15.2 Android Build
```bash
flutter build appbundle --release
# Config: key.properties, upload-keystore.jks
```

### 15.3 CI/CD (GitHub Actions)
- Lint + test on PR
- Build APK/IPA on merge to main
- Auto-increment version

---

## Implementation Order

| Phase | Blocks | Description |
|-------|--------|-------------|
| 1 | 1, 2, 3 | Scaffolding, design system, core infra |
| 2 | 4, 5 | Data models, API layer, auth flow |
| 3 | 6 | Dashboard screen |
| 4 | 7 | Transactions screen + add flow |
| 5 | 8 | Reports screen + charts |
| 6 | 9, 10 | Settings + alerts |
| 7 | 11 | Offline sync |
| 8 | 12, 13 | Component polish, icons, splash |
| 9 | 14, 15 | Testing, build, release |

Each block is independently implementable and testable. Blocks within the same phase can be parallelized where there are no dependencies.
