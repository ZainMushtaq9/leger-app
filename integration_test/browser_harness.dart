import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/app.dart';
import 'package:hisab_rakho/src/controller.dart';
import 'package:hisab_rakho/src/data/in_memory_ledger_repository.dart';
import 'package:hisab_rakho/src/models.dart';

Future<void> pumpSeededApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final controller = HisabRakhoController(
    repository: InMemoryLedgerRepository(initialSnapshot: seededSnapshot()),
  );
  await controller.load();

  await tester.pumpWidget(
    HisabRakhoApp(
      controller: controller,
      splashDelay: Duration.zero,
      adsEnabled: false,
    ),
  );
  await settle(tester);
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first);
  await settle(tester);
}

Future<void> scrollUntilVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester);
    return;
  }
  await tester.ensureVisible(finder.first);
  await settle(tester);
}

Future<void> goBack(WidgetTester tester) async {
  final backButton = find.byTooltip('Back');
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton.first);
  } else {
    await tester.pageBack();
  }
  await settle(tester);
}

Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

void logStep(String value) {
  debugPrint('STEP $value');
}

AppDataSnapshot seededSnapshot() {
  final now = DateTime.now();
  const shopId = 'shop-1';
  const customerId = 'customer-1';
  const supplierId = 'supplier-1';
  const inventoryItemId = 'inventory-1';
  const staffId = 'staff-1';
  const advanceId = 'advance-1';
  const payrollRunId = 'payroll-1';

  final shop = ShopProfile(
    id: shopId,
    name: 'Test General Store',
    phone: '03001234567',
    userType: UserType.shopkeeper,
    createdAt: now.subtract(const Duration(days: 120)),
    address: 'Saddar, Karachi',
    email: 'store@example.com',
    tagline: 'Daily retail and wholesale',
    ntn: '1234567-8',
    strn: '9876543-2',
    salesTaxPercent: 18,
  );

  final customer = Customer(
    id: customerId,
    shopId: shopId,
    shareCode: 'ALI001',
    name: 'Ali Raza',
    phone: '03001112222',
    createdAt: now.subtract(const Duration(days: 60)),
    category: 'Regular',
    address: 'Block 5, Karachi',
    notes: 'Prefers evening follow-ups.',
    tag: 'Priority',
    city: 'Karachi',
    cnic: '42101-1234567-1',
    groupName: 'Family A',
    creditLimit: 7000,
    isFavourite: true,
    promisedPaymentDate: now.add(const Duration(days: 3)),
    promisedPaymentAmount: 1200,
  );

  return AppDataSnapshot(
    shops: <ShopProfile>[shop],
    customers: <Customer>[customer],
    transactions: <LedgerTransaction>[
      LedgerTransaction(
        id: 'txn-credit-1',
        customerId: customerId,
        shopId: shopId,
        amount: 5000,
        type: TransactionType.credit,
        note: 'Groceries on credit',
        date: now.subtract(const Duration(days: 15)),
        dueDate: now.subtract(const Duration(days: 2)),
      ),
      LedgerTransaction(
        id: 'txn-payment-1',
        customerId: customerId,
        shopId: shopId,
        amount: 1000,
        type: TransactionType.payment,
        note: 'Partial payment',
        date: now.subtract(const Duration(days: 4)),
        paidOnTime: false,
      ),
    ],
    settings: AppSettings(
      shopName: shop.name,
      organizationPhone: shop.phone,
      userType: shop.userType,
      hasCompletedOnboarding: true,
      isPaidUser: true,
      lowDataMode: false,
      adsEnabled: false,
      autoBackupDays: 1,
      lastBackupAt: now.subtract(const Duration(hours: 6)),
      activeShopId: shop.id,
      communityBlacklistEnabled: true,
    ),
    suppliers: <Supplier>[
      Supplier(
        id: supplierId,
        shopId: shopId,
        name: 'Fresh Farms',
        phone: '03004445555',
        createdAt: now.subtract(const Duration(days: 45)),
        notes: 'Rice and flour supplier',
      ),
    ],
    supplierLedgerEntries: <SupplierLedgerEntry>[
      SupplierLedgerEntry(
        id: 'supplier-entry-1',
        shopId: shopId,
        supplierId: supplierId,
        amount: 12000,
        type: SupplierEntryType.purchase,
        date: now.subtract(const Duration(days: 10)),
        note: 'Rice stock purchase',
        quantity: 20,
        unitCost: 600,
      ),
    ],
    inventoryItems: <InventoryItem>[
      InventoryItem(
        id: inventoryItemId,
        shopId: shopId,
        name: 'Rice Bag',
        createdAt: now.subtract(const Duration(days: 30)),
        sku: 'RICE-25KG',
        stockQuantity: 15,
        reorderLevel: 5,
        costPrice: 5800,
        salePrice: 6400,
        supplierId: supplierId,
        notes: 'Fast-moving item',
      ),
    ],
    wholesaleListings: <WholesaleListing>[
      WholesaleListing(
        id: 'listing-1',
        shopId: shopId,
        title: 'Rice Bag Bulk',
        price: 6200,
        createdAt: now.subtract(const Duration(days: 6)),
        category: 'Grains',
        unit: 'bag',
        minQuantity: 5,
        phone: shop.phone,
        note: 'Wholesale rate for regular dealers',
      ),
    ],
    saleRecords: <SaleRecord>[
      SaleRecord(
        id: 'sale-1',
        shopId: shopId,
        type: SaleRecordType.cash,
        date: now.subtract(const Duration(days: 2)),
        lineItems: const <SaleLineItem>[
          SaleLineItem(
            inventoryItemId: inventoryItemId,
            itemName: 'Rice Bag',
            quantity: 2,
            unitPrice: 6400,
            costPrice: 5800,
          ),
        ],
        note: 'Walk-in sale',
      ),
    ],
    reminderLogs: <ReminderLog>[
      ReminderLog(
        id: 'reminder-log-1',
        customerId: customerId,
        message: 'Please clear your pending balance.',
        tone: ReminderTone.normal,
        sentAt: now.subtract(const Duration(days: 3)),
      ),
    ],
    backups: <BackupRecord>[
      BackupRecord(
        id: 'backup-1',
        createdAt: now.subtract(const Duration(hours: 6)),
        source: 'local',
        status: 'success',
        customerCount: 1,
        transactionCount: 2,
        reminderCount: 1,
        checksum: 'seeded',
        payload: '{"seed":"backup"}',
        sizeBytes: 128,
        integrityStatus: BackupIntegrityStatus.verified.name,
      ),
    ],
    reminderInbox: <ReminderInboxItem>[
      ReminderInboxItem(
        id: 'inbox-1',
        customerId: customerId,
        title: 'Promise follow-up',
        message: 'Follow up on the promised payment from Ali Raza.',
        tone: ReminderTone.strict,
        type: ReminderInboxType.promiseFollowUp,
        status: ReminderInboxStatus.pending,
        createdAt: now.subtract(const Duration(hours: 12)),
        dueAt: now.subtract(const Duration(hours: 1)),
        notificationId: 1,
        note: 'Generated from seeded integration data',
      ),
    ],
    installmentPlans: <InstallmentPlan>[
      InstallmentPlan(
        id: 'plan-1',
        customerId: customerId,
        totalAmount: 4000,
        installmentAmount: 1000,
        installmentCount: 4,
        completedInstallments: 1,
        intervalDays: 30,
        createdAt: now.subtract(const Duration(days: 9)),
        firstDueDate: now.subtract(const Duration(days: 2)),
        nextDueDate: now.add(const Duration(days: 7)),
        note: 'Monthly recovery plan',
      ),
    ],
    customerVisits: <CustomerVisit>[
      CustomerVisit(
        id: 'visit-1',
        customerId: customerId,
        visitedAt: now.subtract(const Duration(days: 5)),
        note: 'Discussed pending balance.',
        followUpDueAt: now.add(const Duration(days: 1)),
        locationLabel: 'Main market',
        latitude: 24.8607,
        longitude: 67.0011,
      ),
    ],
    communityBlacklistEntries: <CommunityBlacklistEntry>[
      CommunityBlacklistEntry(
        id: 'risk-1',
        shopId: shopId,
        customerName: customer.name,
        phone: customer.phone,
        city: customer.city,
        reason: 'Repeated broken promises',
        createdAt: now.subtract(const Duration(days: 20)),
        note: 'Observed across local shops.',
        reportedCustomerId: customer.id,
        riskLevel: CommunityRiskLevel.blacklist,
      ),
    ],
    staffMembers: <StaffMember>[
      StaffMember(
        id: staffId,
        shopId: shopId,
        name: 'Ahmed',
        phone: '03003334444',
        role: 'Cashier',
        payType: StaffPayType.monthly,
        baseRate: 30000,
        createdAt: now.subtract(const Duration(days: 90)),
        overtimeRate: 300,
      ),
    ],
    staffAttendanceEntries: <StaffAttendanceEntry>[
      StaffAttendanceEntry(
        id: 'attendance-1',
        shopId: shopId,
        staffId: staffId,
        date: now,
        status: StaffAttendanceStatus.present,
        createdAt: now,
        workedHours: 9,
        overtimeHours: 1,
      ),
    ],
    staffAdvanceEntries: <StaffAdvanceEntry>[
      StaffAdvanceEntry(
        id: advanceId,
        shopId: shopId,
        staffId: staffId,
        amount: 1500,
        date: now.subtract(const Duration(days: 12)),
        note: 'Emergency cash advance',
      ),
    ],
    staffPayrollRuns: <StaffPayrollRun>[
      StaffPayrollRun(
        id: payrollRunId,
        shopId: shopId,
        staffId: staffId,
        payType: StaffPayType.monthly,
        periodStart: DateTime(now.year, now.month, 1),
        periodEnd: now,
        payDate: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
        basePay: 30000,
        overtimePay: 300,
        advanceDeduction: 1500,
        netPay: 28800,
        paidUnits: 1,
        workingHours: 208,
        overtimeHours: 1,
        note: 'Seeded payroll run',
        includedAdvanceIds: const <String>[advanceId],
      ),
    ],
  );
}
