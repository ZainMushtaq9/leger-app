# SKILL.md — Hisab Rakho AI Developer Guide
## Project: Hisab Rakho (حساب رکھو)
## Version: 1.0 | Platform: Android | Language: Kotlin + XML or Flutter + Dart
## Document Type: AI Agent Context File — Place at project root

================================================================================
SECTION 1 — IDENTITY
================================================================================

App Name      : Hisab Rakho (حساب رکھو)
Tagline       : Track → Remind → Recover | ٹریک کریں → یاد دلائیں → وصول کریں
Purpose       : Smart Udhaar & Business Recovery System for Pakistani shopkeepers
Architecture  : MVVM + Repository Pattern + Room DB + WorkManager + Hilt DI
Platform      : Android 7.0+ (API 24+) — Offline-First
Primary Lang  : Kotlin + XML  (Alternative: Flutter + Dart)
UI Language   : English (LTR) + Urdu (RTL) + Sindhi + Pashto
Target Users  : Small shopkeepers, traders, SMEs, schools, freelancers in Pakistan
Monetization  : Google AdMob banner ads only (non-intrusive)
Backend       : 100% Offline-First — Firebase free tier for optional cloud features

================================================================================
SECTION 2 — GOLDEN RULES (ALWAYS FOLLOW — NO EXCEPTIONS)
================================================================================

RULE 01 — OFFLINE FIRST
  Every feature must work without internet connection.
  No mandatory API calls. All core operations → Room DB only.

RULE 02 — FREE ONLY
  No paid APIs. No paid SDKs. No subscription services.
  Every tool used must be free (open source or free tier).

RULE 03 — NO CRASH ON NO-INTERNET
  Every network call wrapped in try-catch with offline fallback.
  Show graceful "offline" message — never crash.

RULE 04 — ROOM DB IS SOURCE OF TRUTH
  All reads/writes go through: Repository → DAO → Room DB.
  Never access DB directly from ViewModel or UI.

RULE 05 — REACTIVE UI (LIVEDATA / STATEFLOW)
  UI observes data via LiveData or StateFlow.
  Never pull data imperatively from ViewModel.

RULE 06 — WHATSAPP = INTENT ONLY
  Never use WhatsApp Business API (paid/restricted).
  Always use: Intent(ACTION_VIEW, Uri.parse("https://wa.me/{phone}?text={message}"))

RULE 07 — RTL SUPPORT MANDATORY
  Every layout must work in both LTR (English) and RTL (Urdu).
  AndroidManifest: android:supportsRtl="true"
  Use start/end instead of left/right in all XML layouts.

RULE 08 — ADMOB PLACEMENT
  Banner ads: BOTTOM of screen ONLY.
  Interstitial: ONLY after Bulk Reminder completion.
  NEVER block user actions or form inputs with ads.

RULE 09 — NO HARDCODED STRINGS
  All user-visible strings → res/values/strings.xml (English)
  All Urdu strings → res/values-ur/strings.xml (Urdu)
  All Arabic strings → res/values-ar/strings.xml

RULE 10 — SECURITY
  Never store PIN as plain text.
  Use BCrypt or SHA-256 hash for PIN storage.
  Customer GPS locations stored locally only — never upload.

================================================================================
SECTION 3 — DATABASE ENTITIES (Room DB — All Tables)
================================================================================

TABLE: shops
  id             INTEGER  PRIMARY KEY AUTOINCREMENT
  name           TEXT     NOT NULL
  phone          TEXT     NULLABLE
  user_type      TEXT     NOT NULL  -- shopkeeper/school/business/freelancer/enterprise
  logo_path      TEXT     NULLABLE  -- local file path
  created_at     INTEGER  NOT NULL  -- Unix timestamp

TABLE: customers
  id             INTEGER  PRIMARY KEY AUTOINCREMENT
  shop_id        INTEGER  FK → shops.id
  name           TEXT     NOT NULL
  phone          TEXT     NULLABLE  -- with country code (+92...)
  address        TEXT     NULLABLE
  latitude       REAL     NULLABLE  -- for geo reminder F-61
  longitude      REAL     NULLABLE  -- for geo reminder F-61
  notes          TEXT     NULLABLE  -- private shopkeeper notes
  category       TEXT     NULLABLE
  is_favourite   INTEGER  DEFAULT 0  -- 1 = starred/pinned
  recovery_score REAL     DEFAULT 75  -- 0-100 reliability score
  referred_by    INTEGER  FK → customers.id NULLABLE  -- for trust inheritance F-59
  credit_limit   INTEGER  NULLABLE  -- suggested max credit PKR
  tag            TEXT     NULLABLE  -- often_late / trusted / new / risky
  created_at     INTEGER  NOT NULL

TABLE: transactions
  id             INTEGER  PRIMARY KEY AUTOINCREMENT
  customer_id    INTEGER  FK → customers.id
  shop_id        INTEGER  FK → shops.id
  amount         INTEGER  NOT NULL  -- PKR, no decimals
  type           TEXT     NOT NULL  -- credit / payment / expense / income
  note           TEXT     NULLABLE
  due_date       INTEGER  NULLABLE  -- Unix timestamp
  paid_on_time   INTEGER  NULLABLE  -- NULL=unpaid, 1=on_time, 0=late
  invoice_id     INTEGER  FK → invoices.id NULLABLE
  kisti_plan_id  INTEGER  FK → kisti_plans.id NULLABLE
  created_at     INTEGER  NOT NULL

TABLE: kisti_plans  (NEW — Installment Plans — F-56)
  id                   INTEGER  PRIMARY KEY AUTOINCREMENT
  customer_id          INTEGER  FK → customers.id
  total_amount         INTEGER  NOT NULL
  installment_amount   INTEGER  NOT NULL
  frequency            TEXT     NOT NULL  -- weekly/biweekly/monthly
  total_installments   INTEGER  NOT NULL
  paid_installments    INTEGER  DEFAULT 0
  start_date           INTEGER  NOT NULL  -- first kisti due date
  status               TEXT     DEFAULT 'active'  -- active/completed/defaulted

TABLE: promises  (NEW — F-57)
  id               INTEGER  PRIMARY KEY AUTOINCREMENT
  customer_id      INTEGER  FK → customers.id
  promised_amount  INTEGER  NOT NULL
  promised_date    INTEGER  NOT NULL
  is_kept          INTEGER  NULLABLE  -- NULL=pending, 1=kept, 0=broken
  created_at       INTEGER  NOT NULL

TABLE: reminders
  id          INTEGER  PRIMARY KEY AUTOINCREMENT
  customer_id INTEGER  FK → customers.id
  message     TEXT     NOT NULL
  type        TEXT     NOT NULL  -- soft/normal/strict/kisti/confirmation/group
  sent_via    TEXT     NOT NULL  -- whatsapp/sms/both
  sent_at     INTEGER  NOT NULL

TABLE: invoices
  id             INTEGER  PRIMARY KEY AUTOINCREMENT
  customer_id    INTEGER  FK → customers.id
  invoice_number TEXT     UNIQUE  -- INV-001, INV-002...
  items_json     TEXT     NOT NULL  -- JSON array of line items
  subtotal       INTEGER  NOT NULL
  tax_percent    REAL     DEFAULT 0
  discount       INTEGER  DEFAULT 0
  total          INTEGER  NOT NULL
  status         TEXT     DEFAULT 'unpaid'  -- unpaid/partial/paid
  due_date       INTEGER  NULLABLE
  created_at     INTEGER  NOT NULL

TABLE: staff
  id              INTEGER  PRIMARY KEY AUTOINCREMENT
  shop_id         INTEGER  FK → shops.id
  name            TEXT     NOT NULL
  phone           TEXT     NULLABLE
  salary_type     TEXT     NOT NULL  -- daily/monthly/hourly
  salary_amount   INTEGER  NOT NULL
  joining_date    INTEGER  NOT NULL
  advance_balance INTEGER  DEFAULT 0

TABLE: attendance
  staff_id        INTEGER  FK → staff.id
  shop_id         INTEGER  FK → shops.id
  date            INTEGER  NOT NULL  -- date as Unix timestamp (midnight)
  check_in        INTEGER  NULLABLE
  check_out       INTEGER  NULLABLE
  status          TEXT     NOT NULL  -- present/absent/half/late
  overtime_hours  REAL     DEFAULT 0
  PRIMARY KEY (staff_id, date)

TABLE: stock_items
  id               INTEGER  PRIMARY KEY AUTOINCREMENT
  shop_id          INTEGER  FK → shops.id
  name             TEXT     NOT NULL
  barcode          TEXT     NULLABLE  -- scanned barcode string
  quantity         INTEGER  NOT NULL  DEFAULT 0
  unit             TEXT     NOT NULL  -- kg/pcs/ltr/box/dozen
  buy_price        INTEGER  NOT NULL
  sell_price       INTEGER  NOT NULL
  low_stock_alert  INTEGER  DEFAULT 5
  category         TEXT     NULLABLE
  created_at       INTEGER  NOT NULL

TABLE: settings
  id                       INTEGER  PRIMARY KEY AUTOINCREMENT
  shop_id                  INTEGER  FK → shops.id
  auto_send_confirmation   INTEGER  DEFAULT 1  -- Boolean
  ads_enabled              INTEGER  DEFAULT 1  -- Boolean
  app_lock_enabled         INTEGER  DEFAULT 0  -- Boolean
  app_lock_pin             TEXT     NULLABLE   -- SHA-256 hashed
  language                 TEXT     DEFAULT 'en'  -- en/ur/sd/ps
  dark_mode                INTEGER  DEFAULT 0  -- 0=light, 1=dark, 2=system
  last_backup_at           INTEGER  NULLABLE
  user_type                TEXT     DEFAULT 'shopkeeper'

TABLE: cash_book
  id          INTEGER  PRIMARY KEY AUTOINCREMENT
  shop_id     INTEGER  FK → shops.id
  amount      INTEGER  NOT NULL
  type        TEXT     NOT NULL  -- in/out
  category    TEXT     NULLABLE  -- rent/stock/salaries/utilities/other
  note        TEXT     NULLABLE
  date        INTEGER  NOT NULL
  created_at  INTEGER  NOT NULL

TABLE: community_posts  (Firebase Realtime DB — NOT local SQLite)
  post_id         STRING   -- Firebase auto-generated key
  area_city       STRING   -- city/area name only
  customer_name   STRING   -- partial name only for privacy
  amount          INTEGER
  warning_text    STRING
  is_anonymous    BOOLEAN  DEFAULT true
  flagged_count   INTEGER  DEFAULT 0
  created_at      TIMESTAMP

================================================================================
SECTION 4 — KEY ALGORITHMS
================================================================================

--- Recovery Score (F-48) ---
  score = (on_time_payments / total_completed_transactions) × 100
  New customer default: 75 (neutral)
  Referred customer: 75 + (referrer.recovery_score × 0.25)
  Update trigger: AFTER every payment.save()
  Store in: customers.recovery_score (REAL 0-100)

--- Balance Calculation (F-04) ---
  balance = SUM(amount WHERE type='credit') - SUM(amount WHERE type='payment')
  Per customer. Recalculate after every transaction INSERT/UPDATE/DELETE.
  Dashboard total: SUM of all individual balances WHERE balance > 0

--- Overdue Days (F-50) ---
  overdue_days = LocalDate.now().toEpochDay() - due_date_epoch
  If no due_date set: overdue_days = (today - transaction.created_at) in days
  0–7 days   → GREEN (normal)
  7–30 days  → YELLOW (warning)
  30+ days   → RED (urgent)

--- Cashflow Forecast (F-64) ---
  expected_raw = SUM(transactions.amount WHERE type='credit'
                   AND paid_on_time IS NULL
                   AND due_date BETWEEN today AND today+7_days)
  confidence = AVG(recovery_score of those customers) / 100
  expected_display = expected_raw × confidence
  Label: "Expected this week: Rs {expected_display} ({confidence×100}% confidence)"

--- Kisti Plan Generator (F-56) ---
  installment_amount = total_amount / total_installments
  For i in 0..total_installments-1:
    due_date = start_date + (i × frequency_days)
    INSERT transaction(type='credit', amount=installment_amount, due_date=due_date, kisti_plan_id=plan.id)
  Schedule WorkManager notification for each: (due_date - 1_day) at 09:00

--- Credit Limit Suggestion (F-52) ---
  avg_payment = AVG(transactions.amount WHERE type='payment' AND customer_id=X)
  multiplier = IF score > 70 THEN 1.5 ELSE IF score > 40 THEN 1.0 ELSE 0.5
  suggested_limit = avg_payment × multiplier
  Display: "Suggested safe credit limit: Rs {suggested_limit}"

--- Promise Reliability (F-57) ---
  keep_rate = COUNT(is_kept=1) / COUNT(is_kept IS NOT NULL) × 100
  5/5 kept   → tag: "Promise Keeper ✓"
  3+ broken  → tag: "Often Breaks ✗"
  Mixed      → tag: "Inconsistent"

--- Mood-Based Reminder Tone (F-58) ---
  IF score > 70 AND promise_keep_rate > 70 AND last_payment_days < 30:
    → WARM tone
  ELSE IF score >= 40 OR occasional_late:
    → NORMAL tone
  ELSE (score < 40 OR broken_promises OR overdue > 60):
    → FIRM tone

================================================================================
SECTION 5 — WHATSAPP INTENT — EXACT IMPLEMENTATION
================================================================================

  // Kotlin implementation
  fun openWhatsApp(context: Context, phone: String, message: String) {
      var formatted = phone.replace(Regex("[^0-9]"), "")
      if (formatted.startsWith("0")) formatted = "92" + formatted.substring(1)
      if (!formatted.startsWith("92")) formatted = "92" + formatted
      val encoded = Uri.encode(message)
      val uri = Uri.parse("https://wa.me/$formatted?text=$encoded")
      val intent = Intent(Intent.ACTION_VIEW, uri)
      intent.setPackage("com.whatsapp")
      try {
          context.startActivity(intent)
      } catch (e: ActivityNotFoundException) {
          // WhatsApp not installed — open in browser instead
          intent.setPackage(null)
          context.startActivity(intent)
      }
  }

================================================================================
SECTION 6 — WORKMANAGER JOBS (All Scheduled Tasks)
================================================================================

  JOB 1: DailyActionEngine
    Trigger: Every day at 09:00 AM
    Task:    Query overdue customers → build Today's Actions list → send push notification
    Class:   DailyActionWorker.kt
    Type:    PeriodicWorkRequest (1 day interval)

  JOB 2: PromiseChecker
    Trigger: On promise.promised_date at 09:00 AM (OneTime per promise)
    Task:    Notify shopkeeper: "[Name] ne aaj payment ka wada kiya tha (Rs X)"
    Class:   PromiseCheckWorker.kt
    Type:    OneTimeWorkRequest with setInitialDelay

  JOB 3: KistiReminder
    Trigger: (kisti_due_date - 1 day) at 09:00 AM (OneTime per kisti)
    Task:    Notify: "[Name] ki kisti (Rs X) kal aane wali hai"
    Class:   KistiReminderWorker.kt
    Type:    OneTimeWorkRequest with setInitialDelay

  JOB 4: AutoBackup
    Trigger: Every day at 02:00 AM — WiFi only
    Task:    Export Room DB → JSON → upload to Google Drive
    Class:   AutoBackupWorker.kt
    Type:    PeriodicWorkRequest (1 day) with Constraints.requiresNetwork(UNMETERED)

  JOB 5: TagUpdater
    Trigger: Every day at 00:01 AM
    Task:    Recalculate often_late tags for all customers
    Class:   TagUpdateWorker.kt
    Type:    PeriodicWorkRequest (1 day)

  JOB 6: WeeklyReport
    Trigger: Every Monday at 08:00 AM
    Task:    Generate weekly summary → send notification → available in Reports screen
    Class:   WeeklyReportWorker.kt
    Type:    PeriodicWorkRequest (7 days)

  JOB 7: LowStockChecker
    Trigger: Every day at 10:00 AM
    Task:    Check all stock_items WHERE quantity <= low_stock_alert → notify
    Class:   StockAlertWorker.kt
    Type:    PeriodicWorkRequest (1 day)

================================================================================
SECTION 7 — SCREEN NAVIGATION MAP
================================================================================

  SplashActivity
    ↓ (first launch) → OnboardingActivity (user type + shop setup)
    ↓ (returning)    → AppLockActivity (if PIN enabled)
    ↓                → DashboardActivity

  DashboardActivity
    ↓ [Customer List]    → CustomerListActivity
    ↓ [Reports]          → ReportsActivity
    ↓ [Cash Book]        → CashBookActivity
    ↓ [Staff]            → StaffActivity
    ↓ [Inventory]        → StockActivity
    ↓ [Invoices]         → InvoiceListActivity
    ↓ [Community Wall]   → CommunityWallActivity
    ↓ [Settings]         → SettingsActivity
    ↓ [FAB +]            → QuickAddBottomSheet (F-70)

  CustomerListActivity
    ↓ [Tap customer]     → CustomerDetailActivity
    ↓ [Add customer]     → AddCustomerActivity
    ↓ [Swipe left]       → ReminderBottomSheet (F-71)
    ↓ [Swipe right]      → QuickPaymentBottomSheet (F-71)

  CustomerDetailActivity
    ↓ [Add Udhaar]       → AddUdhaarActivity → KistiPlannerActivity (F-56)
    ↓ [Record Payment]   → RecordPaymentActivity
    ↓ [Send Reminder]    → ReminderActivity
    ↓ [Record Promise]   → PromiseBottomSheet (F-57)
    ↓ [Share Statement]  → PdfGeneratorActivity

  StockActivity
    ↓ [Scan Barcode]     → BarcodeScanActivity (F-23)

  SettingsActivity
    ↓ [Backup/Restore]   → BackupRestoreActivity (F-37/38)
    ↓ [Business Card]    → BusinessCardActivity (F-47)
    ↓ [Community Portal] → CustomerPortalSettingsActivity (F-62)

================================================================================
SECTION 8 — MESSAGE TEMPLATES (English + Urdu)
================================================================================

  TEMPLATE: SOFT (overdue 0–7 days)
    EN: "Assalamualaikum {name}, gentle reminder about Rs {amount} udhaar.
         Kindly pay when convenient. Thank you! — {shop}"
    UR: "السلام علیکم {name} بھائی، Rs {amount} کی یاد دہانی۔
         جب آسان ہو ادا کر دیں۔ شکریہ! — {دکان}"

  TEMPLATE: NORMAL (overdue 7–30 days)
    EN: "Assalamualaikum {name}, your Rs {amount} payment
         has been pending for {days} days. Please pay soon. — {shop}"
    UR: "السلام علیکم {name}، آپ کا Rs {amount} کا ادھار
         {days} دن سے باقی ہے۔ مہربانی فرما کر جلد ادا کریں۔ — {دکان}"

  TEMPLATE: STRICT (overdue 30+ days)
    EN: "Assalamualaikum {name}, Rs {amount} has been outstanding
         for {days} days. Urgent: Please pay immediately. — {shop}"
    UR: "السلام علیکم {name}، Rs {amount} کا ادھار {days} دن سے باقی ہے۔
         برائے کرم فوری ادا کریں۔ — {دکان}"

  TEMPLATE: PAYMENT CONFIRMATION (full paid)
    EN: "Assalamualaikum {name}, your full payment of Rs {amount}
         has been received. Thank you! — {shop}"
    UR: "السلام علیکم {name}، آپ کی پوری رقم Rs {amount} وصول ہو گئی۔
         بہت شکریہ! — {دکان}"

  TEMPLATE: PAYMENT CONFIRMATION (partial paid)
    EN: "Assalamualaikum {name}, Rs {paid} received. Thank you!
         Remaining balance: Rs {remaining}. — {shop}"
    UR: "السلام علیکم {name}، Rs {paid} موصول ہو گئے۔ شکریہ!
         باقی رقم: Rs {remaining}۔ — {دکان}"

  TEMPLATE: KISTI DUE TOMORROW
    EN: "{name}, your installment of Rs {amount} is due tomorrow ({date}).
         Please keep it ready. — {shop}"
    UR: "{name}، آپ کی Rs {amount} کی قسط کل ({date}) ادا کرنی ہے۔
         تیار رکھیں۔ — {دکان}"

  TEMPLATE: PROMISE REMINDER
    EN: "{name}, you had promised to pay Rs {amount} today.
         Please complete the payment. — {shop}"
    UR: "{name}، آپ نے آج Rs {amount} دینے کا وعدہ کیا تھا۔
         مہربانی ادا کریں۔ — {دکان}"

================================================================================
SECTION 9 — DYNAMIC TERMINOLOGY ENGINE (F-73)
================================================================================

  USER TYPE → TERMINOLOGY MAPPING:

  shopkeeper:
    udhaar     → "Udhaar" / "ادھار"
    customer   → "Customer" / "گاہک"
    credit     → "Credit" / "ادھار"
    payment    → "Payment" / "ادائیگی"
    balance    → "Balance" / "بقایا"

  school:
    udhaar     → "Fee" / "فیس"
    customer   → "Student" / "طالب علم"
    credit     → "Fee Entry" / "فیس اندراج"
    payment    → "Fee Payment" / "فیس ادائیگی"
    balance    → "Fee Due" / "واجب الادا"

  business:
    udhaar     → "Invoice" / "انوائس"
    customer   → "Client" / "کلائنٹ"
    credit     → "Receivable" / "قابل وصول"
    payment    → "Receipt" / "رسید"
    balance    → "Outstanding" / "واجب الادا"

  freelancer:
    udhaar     → "Project Payment" / "پروجیکٹ ادائیگی"
    customer   → "Client" / "کلائنٹ"
    credit     → "Work Done" / "کام مکمل"
    payment    → "Payment Received" / "رقم ملی"
    balance    → "Pending Amount" / "زیر التوا"

================================================================================
SECTION 10 — FILE & FOLDER STRUCTURE
================================================================================

  app/
  ├── src/main/
  │   ├── java/com/hisabrakho/
  │   │   ├── data/
  │   │   │   ├── db/
  │   │   │   │   ├── AppDatabase.kt        -- Room DB singleton
  │   │   │   │   ├── entity/               -- All @Entity data classes
  │   │   │   │   └── dao/                  -- All @Dao interfaces
  │   │   │   ├── repository/
  │   │   │   │   ├── CustomerRepository.kt
  │   │   │   │   ├── TransactionRepository.kt
  │   │   │   │   ├── KistiRepository.kt
  │   │   │   │   ├── PromiseRepository.kt
  │   │   │   │   ├── ReminderRepository.kt
  │   │   │   │   ├── InvoiceRepository.kt
  │   │   │   │   ├── StaffRepository.kt
  │   │   │   │   ├── StockRepository.kt
  │   │   │   │   └── BackupRepository.kt
  │   │   │   └── model/                    -- Non-entity data classes, DTOs
  │   │   ├── domain/
  │   │   │   └── usecase/
  │   │   │       ├── CalculateRecoveryScoreUseCase.kt
  │   │   │       ├── CalculateBalanceUseCase.kt
  │   │   │       ├── BuildReminderMessageUseCase.kt
  │   │   │       ├── GenerateKistiPlanUseCase.kt
  │   │   │       ├── CashflowForecastUseCase.kt
  │   │   │       └── CreditLimitSuggestionUseCase.kt
  │   │   ├── ui/
  │   │   │   ├── dashboard/                -- DashboardFragment + VM
  │   │   │   ├── customer/                 -- List + Detail + Add Fragments
  │   │   │   ├── udhaar/                   -- AddUdhaarFragment
  │   │   │   ├── payment/                  -- RecordPaymentFragment
  │   │   │   ├── kisti/                    -- KistiPlannerFragment (F-56)
  │   │   │   ├── promise/                  -- PromiseFragment (F-57)
  │   │   │   ├── invoice/                  -- InvoiceList + Create Fragments
  │   │   │   ├── stock/                    -- StockFragment + BarcodeScan
  │   │   │   ├── staff/                    -- Staff + Attendance + Salary Fragments
  │   │   │   ├── reports/                  -- ReportsFragment + Charts
  │   │   │   ├── cashbook/                 -- CashBookFragment
  │   │   │   ├── community/                -- CommunityWallFragment (F-60)
  │   │   │   ├── portal/                   -- CustomerPortalSettingsFragment (F-62)
  │   │   │   ├── settings/                 -- SettingsFragment
  │   │   │   └── backup/                   -- BackupRestoreFragment
  │   │   ├── worker/
  │   │   │   ├── DailyActionWorker.kt      -- F-55
  │   │   │   ├── PromiseCheckWorker.kt     -- F-57
  │   │   │   ├── KistiReminderWorker.kt    -- F-56
  │   │   │   ├── AutoBackupWorker.kt       -- F-37
  │   │   │   ├── TagUpdateWorker.kt        -- F-53
  │   │   │   ├── WeeklyReportWorker.kt     -- F-21
  │   │   │   └── StockAlertWorker.kt       -- F-22
  │   │   ├── util/
  │   │   │   ├── WhatsAppHelper.kt         -- All WhatsApp intent logic
  │   │   │   ├── MessageTemplates.kt       -- All EN + UR message templates
  │   │   │   ├── RecoveryCalculator.kt     -- Score calculation logic
  │   │   │   ├── PdfGenerator.kt           -- PDF generation for statements
  │   │   │   ├── LanguageManager.kt        -- Locale switching + RTL
  │   │   │   ├── TerminologyEngine.kt      -- F-73 user type terminology map
  │   │   │   ├── GeofenceHelper.kt         -- F-61 location geofence setup
  │   │   │   ├── VoiceInputHelper.kt       -- F-68 SpeechRecognizer wrapper
  │   │   │   ├── AdMobHelper.kt            -- F-75 AdMob initialization
  │   │   │   └── BackupHelper.kt           -- Google Drive backup/restore
  │   │   └── di/
  │   │       └── AppModule.kt              -- Hilt DI module
  │   └── res/
  │       ├── values/strings.xml            -- English strings
  │       ├── values-ur/strings.xml         -- Urdu strings
  │       ├── values/colors.xml             -- Light mode colors
  │       ├── values-night/colors.xml       -- Dark mode colors (F-74)
  │       ├── layout/                       -- All XML layouts (LTR)
  │       ├── font/                         -- Noto Nastaliq Urdu font
  │       └── navigation/nav_graph.xml      -- Navigation component graph

================================================================================
SECTION 11 — MANDATORY DEPENDENCIES (build.gradle app module)
================================================================================

  // Room DB
  implementation("androidx.room:room-runtime:2.6.1")
  implementation("androidx.room:room-ktx:2.6.1")
  kapt("androidx.room:room-compiler:2.6.1")

  // WorkManager
  implementation("androidx.work:work-runtime-ktx:2.9.0")

  // Hilt Dependency Injection
  implementation("com.google.dagger:hilt-android:2.50")
  kapt("com.google.dagger:hilt-compiler:2.50")

  // Charts
  implementation("com.github.PhilJay:MPAndroidChart:3.1.0")

  // Barcode Scanner
  implementation("com.google.zxing:core:3.5.2")
  implementation("com.journeyapps:zxing-android-embedded:4.3.0")

  // JSON Serialization (for backup)
  implementation("com.google.code.gson:gson:2.10.1")

  // Location & Geofencing
  implementation("com.google.android.gms:play-services-location:21.2.0")

  // Firebase (optional cloud features)
  implementation(platform("com.google.firebase:firebase-bom:33.1.0"))
  implementation("com.google.firebase:firebase-database-ktx")
  implementation("com.google.firebase:firebase-auth-ktx")
  implementation("com.google.firebase:firebase-analytics-ktx")

  // Google Drive Backup
  implementation("com.google.android.gms:play-services-auth:21.1.1")
  implementation("com.google.apis:google-api-services-drive:v3-rev20240521-2.0.0")

  // AdMob
  implementation("com.google.android.gms:play-services-ads:23.2.0")

  // Biometric Lock
  implementation("androidx.biometric:biometric:1.2.0-alpha05")

  // Image Loading
  implementation("com.github.bumptech.glide:glide:4.16.0")

  // Lottie Animations
  implementation("com.airbnb.android:lottie:6.4.0")

  // CSV Import
  implementation("com.opencsv:opencsv:5.9")

================================================================================
SECTION 12 — FEATURE ID QUICK REFERENCE TABLE
================================================================================

  F-01  Customer Ledger Creation                   [ALL PK]
  F-02  Udhaar Credit Entry Recording              [ALL PK]
  F-03  Payment Recording                          [ALL PK]
  F-04  Running Balance Calculation                [ALL PK]
  F-05  Transaction History per Customer           [ALL PK]
  F-06  Due Date Setting per Transaction           [ALL PK]
  F-07  Notes & Photo Attachments                  [ALL PK]
  F-08  Supplier / Payable Ledger                  [ALL PK]
  F-09  Free SMS Reminder                          [ALL PK]
  F-10  WhatsApp Reminder via Intent               [ALL PK]
  F-11  Bulk Reminder All Customers                [ALL PK]
  F-12  Soft / Normal / Strict Templates           [ALL PK]
  F-13  Payment Confirmation Message               [ALL PK]
  F-14  PDF Statement Generation & Share           [ALL PK]
  F-15  Payment Link / Request Money               [SOME PK]
  F-16  Reminder History Log                       [ALL PK]
  F-17  Cash Book Daily In/Out                     [ALL PK]
  F-18  Expense Tracking by Category               [ALL PK]
  F-19  Sales & Profit/Loss Reporting              [ALL PK]
  F-20  Bank Book Multi-Account                    [SOME PK]
  F-21  Weekly Monthly Business Reports            [ALL PK]
  F-22  Stock Inventory Management                 [ALL PK]
  F-23  Barcode Scanner for Stock                  [SOME PK]
  F-24  Excel CSV Import for Stock                 [SOME PK]
  F-25  Bulk Price List Sharing                    [SOME PK]
  F-26  Digital Invoice Generator                  [ALL PK]
  F-27  GST-Compliant Invoices                     [SOME PK]
  F-28  Estimates Quotation Creation               [SOME PK]
  F-29  Staff Attendance Tracking                  [ALL PK]
  F-30  Salary Payroll Management                  [ALL PK]
  F-31  Salary Advance Staff Khata                 [ALL PK]
  F-32  Salary Slip Generation & Share             [ALL PK]
  F-33  PIN Fingerprint App Lock                   [ALL PK]
  F-34  Hidden Balance Privacy Mode                [SOME PK]
  F-35  Multi-User Partner Access                  [ALL PK]
  F-36  Multi-Business Multi-Shop                  [ALL PK]
  F-37  Auto Cloud Backup                          [ALL PK]
  F-38  Google Drive Manual Backup Restore         [SOME PK]
  F-39  Offline-First System                       [ALL PK]
  F-40  Easyload Selling Commission                [ALL PK]
  F-41  Bill Payment Service                       [ALL PK]
  F-42  Gaming Voucher Selling                     [SOME PK]
  F-43  Business Digital Wallet                    [SOME PK]
  F-44  B2B Wholesale Marketplace                  [SOME PK]
  F-45  Multi-Language RTL Support                 [ALL PK]
  F-46  Shop Branding on All Messages              [ALL PK]
  F-47  Digital Business Card Creation             [SOME PK]

  -- NEW FEATURES (Not in any Pakistani app yet) --

  F-48  Recovery Score per Customer                [NEW | HOT]
  F-49  Payment Probability Badge                  [NEW]
  F-50  Urgency Color System                       [NEW | HOT]
  F-51  Risk Alert Before Adding Udhaar            [NEW]
  F-52  Credit Limit Suggestion                    [NEW]
  F-53  Repeat Delay Detector / Often Late Tag     [NEW]
  F-54  Money Stuck Timer                          [NEW | HOT]
  F-55  Daily Action Engine                        [NEW | HOT]
  F-56  Kisti Installment Planner                  [NEW | HOT]
  F-57  Payment Promise Tracker                    [NEW | HOT]
  F-58  Mood-Based Reminder Tone Selector          [NEW]
  F-59  Social Amanat Trust Score                  [NEW]
  F-60  Shopkeeper Community Fraud Wall            [NEW]
  F-61  Geo Reminder Visit Trigger                 [NEW]
  F-62  Customer Self-Service Web Portal           [NEW | HOT]
  F-63  WhatsApp Group Smart Reminder              [NEW]
  F-64  Cashflow Forecast Engine                   [NEW | HOT]
  F-65  Monthly Recovery Gamification & Streak     [NEW]
  F-66  Customer Ranking Best to Worst Payers      [NEW]
  F-67  Total Overdue Age Analysis                 [NEW]
  F-68  Urdu Voice Input for Udhaar Entry          [NEW]
  F-69  Smart Amount Autofill                      [NEW]
  F-70  Quick Add 2-Tap Udhaar Entry               [NEW]
  F-71  Swipe Actions on Customer List             [NEW]
  F-72  Favourite Pinned Customers                 [NEW]
  F-73  Dynamic Terminology Engine                 [NEW]
  F-74  Dark Mode                                  [NEW]
  F-75  AdMob Monetization Non-Intrusive           [NEW]

================================================================================
SECTION 13 — DEVELOPER WORKFLOW — HOW TO BUILD EACH FEATURE
================================================================================

  STEP 1: Read Feature ID from Master Prompt (F-XX section)
  STEP 2: Create Entity class in data/db/entity/ if new table required
  STEP 3: Create DAO interface in data/db/dao/ with @Query methods
  STEP 4: Add Entity + DAO to AppDatabase.kt (entities list, abstract DAO functions)
  STEP 5: Create Repository class in data/repository/
  STEP 6: Create UseCase class in domain/usecase/ (pure business logic)
  STEP 7: Inject Repository into ViewModel (data/ui/{screen}/ViewModel)
  STEP 8: Create Fragment in ui/{screen}/
  STEP 9: Create XML layout in res/layout/ with LTR + RTL support
  STEP 10: Add strings to res/values/strings.xml AND res/values-ur/strings.xml
  STEP 11: Register in nav_graph.xml if new screen
  STEP 12: Write unit test in test/ for UseCase logic
  STEP 13: Write instrumented test in androidTest/ for DAO operations

================================================================================
SECTION 14 — TESTING REQUIREMENTS
================================================================================

  For EVERY feature:
    [ ] Unit test: UseCase with mock repository
    [ ] DAO test: in-memory Room DB test
    [ ] UI test: Espresso for critical user flows
    [ ] Offline test: disable network → verify no crash
    [ ] RTL test: switch to Urdu locale → verify layout

  Critical paths requiring end-to-end test:
    [ ] Add customer → Add udhaar → Record payment → Check balance = 0
    [ ] Kisti plan created → all installment transactions exist with correct dates
    [ ] Promise recorded → WorkManager fires notification on promised_date
    [ ] Recovery score updates correctly after on-time vs late payment
    [ ] Google Drive backup → restore → verify all records intact
    [ ] WhatsApp intent opens with correct phone + encoded message
    [ ] Language switch EN→UR → layout flips RTL → all strings in Urdu

================================================================================

END OF SKILL.md
Hisab Rakho — Track → Remind → Recover
حساب رکھو — ٹریک کریں → یاد دلائیں → وصول کریں

Place this file at: /your-project-root/SKILL.md
Your AI coding agent reads this before writing any code.
Total Features: 75 | Tables: 13 | Screens: 18 | All Free Tools

================================================================================
