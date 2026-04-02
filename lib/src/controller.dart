import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' show Locale;

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
import 'copy.dart';
import 'data/ledger_repository.dart';
import 'domain/usecases/apply_payment_use_case.dart';
import 'domain/usecases/build_reminder_message_use_case.dart';
import 'domain/usecases/calculate_customer_insight_use_case.dart';
import 'domain/usecases/parse_voice_credit_use_case.dart';
import 'models.dart';
import 'services/cloud_auth_service.dart';
import 'services/cloud_backup_service.dart';
import 'services/local_notification_service.dart';

class HisabRakhoController extends ChangeNotifier {
  static const List<String> _csvNameAliases = <String>[
    'name',
    'customer',
    'customername',
    'client',
    'clientname',
    'party',
    'partyname',
    'account',
    'accountname',
  ];
  static const List<String> _csvPhoneAliases = <String>[
    'phone',
    'mobile',
    'mobilenumber',
    'number',
    'contact',
    'contactnumber',
  ];
  static const List<String> _csvCategoryAliases = <String>[
    'category',
    'segment',
    'customercategory',
  ];
  static const List<String> _csvCityAliases = <String>[
    'city',
    'area',
    'location',
  ];
  static const List<String> _csvAddressAliases = <String>[
    'address',
    'fulladdress',
  ];
  static const List<String> _csvCnicAliases = <String>['cnic', 'nic'];
  static const List<String> _csvGroupAliases = <String>[
    'group',
    'groupname',
    'family',
    'familyname',
  ];
  static const List<String> _csvNoteAliases = <String>[
    'note',
    'notes',
    'details',
    'description',
    'remarks',
    'item',
  ];
  static const List<String> _csvDateAliases = <String>[
    'date',
    'transactiondate',
    'entrydate',
    'createdat',
  ];
  static const List<String> _csvDueDateAliases = <String>[
    'duedate',
    'promiseddate',
    'commitmentdate',
  ];
  static const List<String> _csvBalanceAliases = <String>[
    'balance',
    'openingbalance',
    'outstanding',
    'amountdue',
    'dues',
    'udhaarbalance',
  ];
  static const List<String> _csvCreditAliases = <String>[
    'credit',
    'udhaar',
    'invoice',
    'debit',
    'purchase',
    'charge',
  ];
  static const List<String> _csvPaymentAliases = <String>[
    'payment',
    'paid',
    'received',
    'collection',
    'creditreceived',
  ];
  static const List<String> _csvAmountAliases = <String>[
    'amount',
    'total',
    'value',
  ];
  static const List<String> _csvTypeAliases = <String>[
    'type',
    'transactiontype',
    'entrytype',
  ];

  HisabRakhoController({
    required LedgerRepository repository,
    CalculateCustomerInsightUseCase? calculateCustomerInsightUseCase,
    BuildReminderMessageUseCase? buildReminderMessageUseCase,
    ParseVoiceCreditUseCase? parseVoiceCreditUseCase,
    ApplyPaymentUseCase? applyPaymentUseCase,
    CloudBackupService? cloudBackupService,
    CloudAuthService? cloudAuthService,
    LocalNotificationService? localNotificationService,
  }) : _repository = repository,
       _calculateCustomerInsightUseCase =
           calculateCustomerInsightUseCase ?? CalculateCustomerInsightUseCase(),
       _buildReminderMessageUseCase =
           buildReminderMessageUseCase ?? BuildReminderMessageUseCase(),
       _parseVoiceCreditUseCase =
           parseVoiceCreditUseCase ?? ParseVoiceCreditUseCase(),
       _applyPaymentUseCase = applyPaymentUseCase ?? ApplyPaymentUseCase(),
       _cloudBackupService = cloudBackupService,
       _cloudAuthService = cloudAuthService,
       _localNotificationService = localNotificationService;

  final LedgerRepository _repository;
  final CalculateCustomerInsightUseCase _calculateCustomerInsightUseCase;
  final BuildReminderMessageUseCase _buildReminderMessageUseCase;
  final ParseVoiceCreditUseCase _parseVoiceCreditUseCase;
  final ApplyPaymentUseCase _applyPaymentUseCase;
  final CloudBackupService? _cloudBackupService;
  final CloudAuthService? _cloudAuthService;
  final LocalNotificationService? _localNotificationService;
  final Random _random = Random();
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'Rs ',
    decimalDigits: 0,
  );

  List<ShopProfile> _shops = <ShopProfile>[];
  List<Customer> _customers = <Customer>[];
  List<LedgerTransaction> _transactions = <LedgerTransaction>[];
  List<StaffMember> _staffMembers = <StaffMember>[];
  List<StaffAttendanceEntry> _staffAttendanceEntries = <StaffAttendanceEntry>[];
  List<StaffAdvanceEntry> _staffAdvanceEntries = <StaffAdvanceEntry>[];
  List<StaffPayrollRun> _staffPayrollRuns = <StaffPayrollRun>[];
  List<Supplier> _suppliers = <Supplier>[];
  List<SupplierLedgerEntry> _supplierLedgerEntries = <SupplierLedgerEntry>[];
  List<InventoryItem> _inventoryItems = <InventoryItem>[];
  List<WholesaleListing> _wholesaleListings = <WholesaleListing>[];
  List<SaleRecord> _saleRecords = <SaleRecord>[];
  List<ReminderLog> _reminderLogs = <ReminderLog>[];
  List<BackupRecord> _backups = <BackupRecord>[];
  List<ReminderInboxItem> _reminderInbox = <ReminderInboxItem>[];
  List<InstallmentPlan> _installmentPlans = <InstallmentPlan>[];
  List<CustomerVisit> _customerVisits = <CustomerVisit>[];
  List<PartnerAccessProfile> _partnerAccessProfiles = <PartnerAccessProfile>[];
  List<CommunityBlacklistEntry> _communityBlacklistEntries =
      <CommunityBlacklistEntry>[];
  List<CloudBackupManifest> _cloudBackups = <CloudBackupManifest>[];
  List<CloudWorkspaceDirectoryEntry> _accountCloudWorkspaces =
      <CloudWorkspaceDirectoryEntry>[];
  CloudAccountProfile? _cloudAccount;
  AppSettings _settings = AppDataSnapshot.empty().settings;
  LocalDataProtectionStatus _localDataProtectionStatus =
      const LocalDataProtectionStatus(
        storageLabel: 'Local storage',
        encryptedAtRest: false,
        keyStoredSecurely: false,
        usesDeviceVault: false,
      );
  bool _hasStorageError = false;
  bool _isAppUnlocked = true;
  bool _isDecoySession = false;
  bool _cloudSyncReady = false;
  bool _cloudAuthReady = false;

  bool isLoaded = false;

  List<ShopProfile> get shops {
    final snapshot = <ShopProfile>[..._shops];
    snapshot.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return snapshot;
  }

  ShopProfile get activeShop {
    for (final shop in _shops) {
      if (shop.id == _settings.activeShopId) {
        return shop;
      }
    }
    return _shops.isNotEmpty
        ? _shops.first
        : ShopProfile(
            id: AppSettings.defaultShopId,
            name: _settings.shopName,
            phone: _settings.organizationPhone,
            userType: _settings.userType,
            createdAt: DateTime.now(),
          );
  }

  String get activeShopId => activeShop.id;
  AppCopy get copy => const AppCopy(AppLanguage.english);
  Locale get appLocale => const Locale('en', 'PK');
  bool get isRtl => false;

  List<Customer> get customers {
    final snapshot = <Customer>[..._visibleCustomers];
    snapshot.sort((a, b) {
      if (a.isFavourite != b.isFavourite) {
        return a.isFavourite ? -1 : 1;
      }
      if (a.isHidden != b.isHidden) {
        return a.isHidden ? 1 : -1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return snapshot;
  }

  List<ReminderLog> get reminderLogs {
    final snapshot = _reminderLogs.where((log) {
      final customer = customerById(log.customerId);
      return customer?.shopId == activeShopId;
    }).toList();
    snapshot.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return snapshot;
  }

  List<BackupRecord> get backups {
    final snapshot = <BackupRecord>[..._backups];
    snapshot.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return snapshot;
  }

  List<CloudBackupManifest> get cloudBackups {
    final snapshot = <CloudBackupManifest>[..._cloudBackups];
    snapshot.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return snapshot;
  }

  List<CloudWorkspaceDirectoryEntry> get accountCloudWorkspaces {
    final snapshot = <CloudWorkspaceDirectoryEntry>[..._accountCloudWorkspaces];
    snapshot.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return snapshot;
  }

  List<ReminderInboxItem> get reminderInbox {
    final snapshot = _reminderInbox.where((item) {
      final customer = customerById(item.customerId);
      return customer?.shopId == activeShopId;
    }).toList();
    snapshot.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return snapshot;
  }

  List<PartnerAccessProfile> get partnerAccessProfiles {
    final snapshot =
        _partnerAccessProfiles
            .where((profile) => profile.shopId == activeShopId)
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    return snapshot;
  }

  List<ReminderInboxItem> get pendingReminderInbox => reminderInbox
      .where((item) => item.status == ReminderInboxStatus.pending)
      .toList();

  List<ReminderInboxItem> get handledReminderInbox =>
      reminderInbox
          .where((item) => item.status != ReminderInboxStatus.pending)
          .toList()
        ..sort(
          (a, b) => (b.handledAt ?? b.dueAt).compareTo(a.handledAt ?? a.dueAt),
        );

  List<InstallmentPlan> get installmentPlans {
    final snapshot = _installmentPlans.where((plan) {
      final customer = customerById(plan.customerId);
      return customer?.shopId == activeShopId;
    }).toList();
    snapshot.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return snapshot;
  }

  List<CustomerVisit> get customerVisits {
    final snapshot = _customerVisits.where((visit) {
      final customer = customerById(visit.customerId);
      return customer?.shopId == activeShopId;
    }).toList();
    snapshot.sort((a, b) => b.visitedAt.compareTo(a.visitedAt));
    return snapshot;
  }

  List<CommunityBlacklistEntry> get communityBlacklistEntries {
    final snapshot = <CommunityBlacklistEntry>[..._communityBlacklistEntries];
    snapshot.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return snapshot;
  }

  List<String> get communityBlacklistCities {
    final cities =
        communityBlacklistEntries
            .map((entry) => entry.city.trim())
            .where((city) => city.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return cities;
  }

  List<Supplier> get suppliers {
    final snapshot = <Supplier>[..._activeSuppliers];
    snapshot.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return snapshot;
  }

  List<SupplierLedgerEntry> get supplierLedgerEntries {
    final snapshot = <SupplierLedgerEntry>[..._activeSupplierLedgerEntries];
    snapshot.sort((a, b) => b.date.compareTo(a.date));
    return snapshot;
  }

  List<InventoryItem> get inventoryItems {
    final snapshot = _activeInventoryItems
        .where((item) => !item.isArchived)
        .toList();
    snapshot.sort((a, b) {
      if (a.isLowStock != b.isLowStock) {
        return a.isLowStock ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return snapshot;
  }

  List<InventoryItem> get lowStockItems =>
      inventoryItems.where((item) => item.isLowStock).toList();

  List<WholesaleListing> get wholesaleListings {
    final snapshot = _wholesaleListings
        .where((listing) => listing.shopId == activeShopId && listing.isActive)
        .toList();
    snapshot.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return snapshot;
  }

  int get wholesaleListingCount => wholesaleListings.length;

  List<SaleRecord> get saleRecords {
    final snapshot = <SaleRecord>[..._activeSaleRecords];
    snapshot.sort((a, b) => b.date.compareTo(a.date));
    return snapshot;
  }

  List<StaffMember> get staffMembers {
    final snapshot = _activeStaffMembers
        .where((staff) => staff.isActive)
        .toList();
    snapshot.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return snapshot;
  }

  List<StaffMember> get allStaffMembers {
    final snapshot = <StaffMember>[..._activeStaffMembers];
    snapshot.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return snapshot;
  }

  List<StaffAttendanceEntry> get staffAttendanceEntries {
    final snapshot = <StaffAttendanceEntry>[..._activeStaffAttendanceEntries];
    snapshot.sort((a, b) => b.date.compareTo(a.date));
    return snapshot;
  }

  List<StaffAdvanceEntry> get staffAdvanceEntries {
    final snapshot = <StaffAdvanceEntry>[..._activeStaffAdvanceEntries];
    snapshot.sort((a, b) => b.date.compareTo(a.date));
    return snapshot;
  }

  List<StaffPayrollRun> get staffPayrollRuns {
    final snapshot = <StaffPayrollRun>[..._activeStaffPayrollRuns];
    snapshot.sort((a, b) => b.payDate.compareTo(a.payDate));
    return snapshot;
  }

  AppSettings get settings => _settings;
  AppTerminology get terminology => AppTerminology.forUserType(
    _settings.userType,
    language: _settings.language,
  );
  bool get needsOnboarding => !_settings.hasCompletedOnboarding;
  String get entitySingularLabel => terminology.entitySingular;
  String get entityPluralLabel => terminology.entityPlural;
  String get creditLabel => terminology.creditLabel;
  String get outstandingLabel => terminology.outstandingLabel;
  String get categoryLabel => terminology.categoryLabel;
  String get entryLabel => terminology.entryLabel;
  String get dashboardSubtitle => terminology.dashboardSubtitle;
  String get userTypeLabel => terminology.userTypeLabel;
  String get organizationName => _settings.shopName;
  String get organizationPhone => _settings.organizationPhone;
  String get organizationAddress => activeShop.address;
  String get organizationEmail => activeShop.email;
  bool get hasStorageError => _hasStorageError;
  LocalDataProtectionStatus get localDataProtectionStatus =>
      _localDataProtectionStatus;
  bool get isSecurityEnabled =>
      _settings.appLockEnabled && _settings.pinHash.trim().isNotEmpty;
  bool get isLocked => isSecurityEnabled && !_isAppUnlocked;
  bool get isDecoySession => _isDecoySession;
  bool get canWriteData => !_isDecoySession;
  bool get shouldHideBalances => _settings.hideBalances || _isDecoySession;
  bool get shouldHideHiddenCustomers =>
      _settings.hideHiddenCustomers || _isDecoySession;
  bool get communityBlacklistEnabled => _settings.communityBlacklistEnabled;
  bool get hasDecoyPinConfigured =>
      _settings.decoyModeEnabled && _settings.decoyPinHash.trim().isNotEmpty;
  bool get hasPinConfigured => _settings.pinHash.trim().isNotEmpty;
  int get partnerAccessCount => partnerAccessProfiles.length;
  int get autoLockMinutes => _settings.autoLockMinutes;
  Duration? get autoLockDuration =>
      autoLockMinutes <= 0 ? null : Duration(minutes: autoLockMinutes);

  bool get hasSyncError => _hasStorageError;
  bool get usingCachedData => false;
  bool get hasCloudDatabase => _cloudBackupService != null && _cloudSyncReady;
  bool get hasCloudSignIn => _cloudAuthService != null && _cloudAuthReady;
  bool get isCloudAccountSignedIn => cloudAccount != null;
  bool get isAutoBackupEnabled => _settings.autoBackupDays > 0;
  bool get isAutoBackupDue => autoBackupDue();
  bool get isCloudSyncConfigured =>
      _settings.cloudSyncEnabled &&
      _settings.cloudWorkspaceId.trim().isNotEmpty;
  String get cloudWorkspaceId =>
      _normalizeCloudWorkspaceId(_settings.cloudWorkspaceId);
  String get cloudDeviceLabel {
    final trimmed = _settings.cloudDeviceLabel.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return _defaultCloudDeviceLabel();
  }

  DateTime? get lastCloudSyncAt => _settings.lastCloudSyncAt;
  DateTime? get lastCloudRestoreAt => _settings.lastCloudRestoreAt;
  String get cloudSyncLastError => _settings.cloudSyncLastError.trim();
  bool get requiresStartupAuthentication => hasCloudSignIn;
  bool get needsCloudEmailVerification {
    final account = cloudAccount;
    if (account == null) {
      return false;
    }
    if (account.provider == 'google.com') {
      return false;
    }
    return account.email.trim().isNotEmpty && !account.isEmailVerified;
  }

  CloudAccountProfile? get cloudAccount {
    if (_cloudAccount != null) {
      return _cloudAccount;
    }
    if (_settings.cloudAccountId.trim().isEmpty &&
        _settings.cloudAccountEmail.trim().isEmpty) {
      return null;
    }
    return CloudAccountProfile(
      id: _settings.cloudAccountId,
      email: _settings.cloudAccountEmail,
      phoneNumber: _settings.cloudAccountPhone,
      displayName: _settings.cloudAccountDisplayName,
      provider: _settings.cloudAccountProvider,
      isEmailVerified: _settings.cloudAccountEmailVerified,
      signedInAt: _settings.lastCloudAccountSignInAt ?? DateTime.now(),
    );
  }

  int get customerCount => _visibleCustomers.length;
  int get transactionCount => _activeTransactions.length;
  int get reminderCount => reminderLogs.length;
  int get reminderInboxCount => reminderInbox.length;
  int get pendingReminderInboxCount => pendingReminderInbox.length;
  int get installmentPlanCount => installmentPlans.length;
  int get customerVisitCount => customerVisits.length;
  int get staffCount => staffMembers.length;
  int get supplierCount => suppliers.length;
  int get inventoryItemCount => inventoryItems.length;
  int get lowStockItemCount => lowStockItems.length;
  int get saleRecordCount => saleRecords.length;
  int get communityBlacklistCount => communityBlacklistEntries.length;
  bool get isDatabaseEmpty =>
      _customers.isEmpty &&
      _transactions.isEmpty &&
      _staffMembers.isEmpty &&
      _staffAttendanceEntries.isEmpty &&
      _staffAdvanceEntries.isEmpty &&
      _staffPayrollRuns.isEmpty &&
      _suppliers.isEmpty &&
      _supplierLedgerEntries.isEmpty &&
      _inventoryItems.isEmpty &&
      _wholesaleListings.isEmpty &&
      _saleRecords.isEmpty &&
      _reminderLogs.isEmpty &&
      _backups.isEmpty &&
      _reminderInbox.isEmpty &&
      _installmentPlans.isEmpty &&
      _customerVisits.isEmpty &&
      _partnerAccessProfiles.isEmpty &&
      _communityBlacklistEntries.isEmpty;

  Future<void> load() async {
    isLoaded = false;
    notifyListeners();

    try {
      final snapshot = await _repository.load();
      _hydrate(snapshot);
      await _refreshLocalProtectionStatus();
      await _initializeCloudSync();
      await _initializeCloudAccount();
      await _runScheduledAutoBackupIfDue();
      _hasStorageError = false;
    } catch (_) {
      _hasStorageError = true;
    }

    isLoaded = true;
    notifyListeners();
  }

  Future<void> reloadFromStorage() async {
    await load();
  }

  void _hydrate(AppDataSnapshot snapshot) {
    _shops = <ShopProfile>[...snapshot.shops];
    _customers = <Customer>[...snapshot.customers];
    _transactions = <LedgerTransaction>[...snapshot.transactions]
      ..sort((a, b) => b.date.compareTo(a.date));
    _staffMembers = <StaffMember>[...snapshot.staffMembers]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _staffAttendanceEntries = <StaffAttendanceEntry>[
      ...snapshot.staffAttendanceEntries,
    ]..sort((a, b) => b.date.compareTo(a.date));
    _staffAdvanceEntries = <StaffAdvanceEntry>[...snapshot.staffAdvanceEntries]
      ..sort((a, b) => b.date.compareTo(a.date));
    _staffPayrollRuns = <StaffPayrollRun>[...snapshot.staffPayrollRuns]
      ..sort((a, b) => b.payDate.compareTo(a.payDate));
    _suppliers = <Supplier>[...snapshot.suppliers]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _supplierLedgerEntries = <SupplierLedgerEntry>[
      ...snapshot.supplierLedgerEntries,
    ]..sort((a, b) => b.date.compareTo(a.date));
    _inventoryItems = <InventoryItem>[...snapshot.inventoryItems]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _wholesaleListings = <WholesaleListing>[...snapshot.wholesaleListings]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _saleRecords = <SaleRecord>[...snapshot.saleRecords]
      ..sort((a, b) => b.date.compareTo(a.date));
    _reminderLogs = <ReminderLog>[...snapshot.reminderLogs]
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    _backups = <BackupRecord>[...snapshot.backups]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _reminderInbox = <ReminderInboxItem>[...snapshot.reminderInbox]
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    _installmentPlans = <InstallmentPlan>[...snapshot.installmentPlans]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _customerVisits = <CustomerVisit>[...snapshot.customerVisits]
      ..sort((a, b) => b.visitedAt.compareTo(a.visitedAt));
    _partnerAccessProfiles = <PartnerAccessProfile>[...snapshot.partnerProfiles]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _communityBlacklistEntries = <CommunityBlacklistEntry>[
      ...snapshot.communityBlacklistEntries,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _settings = snapshot.settings;
    _resetSecurityStateAfterLoad();
  }

  AppDataSnapshot get _snapshot {
    return AppDataSnapshot(
      shops: <ShopProfile>[..._shops],
      customers: <Customer>[..._customers],
      transactions: <LedgerTransaction>[..._transactions],
      settings: _settings,
      partnerProfiles: <PartnerAccessProfile>[..._partnerAccessProfiles],
      staffMembers: <StaffMember>[..._staffMembers],
      staffAttendanceEntries: <StaffAttendanceEntry>[
        ..._staffAttendanceEntries,
      ],
      staffAdvanceEntries: <StaffAdvanceEntry>[..._staffAdvanceEntries],
      staffPayrollRuns: <StaffPayrollRun>[..._staffPayrollRuns],
      suppliers: <Supplier>[..._suppliers],
      supplierLedgerEntries: <SupplierLedgerEntry>[..._supplierLedgerEntries],
      inventoryItems: <InventoryItem>[..._inventoryItems],
      wholesaleListings: <WholesaleListing>[..._wholesaleListings],
      saleRecords: <SaleRecord>[..._saleRecords],
      reminderLogs: <ReminderLog>[..._reminderLogs],
      backups: <BackupRecord>[..._backups],
      reminderInbox: <ReminderInboxItem>[..._reminderInbox],
      installmentPlans: <InstallmentPlan>[..._installmentPlans],
      customerVisits: <CustomerVisit>[..._customerVisits],
      communityBlacklistEntries: <CommunityBlacklistEntry>[
        ..._communityBlacklistEntries,
      ],
    );
  }

  Future<void> _persist({bool notify = false}) async {
    try {
      await _repository.save(_snapshot);
      _localDataProtectionStatus = await _repository.protectionStatus();
      _hasStorageError = false;
    } catch (_) {
      _hasStorageError = true;
    }
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _initializeCloudSync() async {
    if (_cloudBackupService == null) {
      _cloudSyncReady = false;
      _cloudBackups = <CloudBackupManifest>[];
      _accountCloudWorkspaces = <CloudWorkspaceDirectoryEntry>[];
      return;
    }
    _cloudSyncReady = await _cloudBackupService.initialize();
    if (!_cloudSyncReady) {
      _cloudBackups = <CloudBackupManifest>[];
      _accountCloudWorkspaces = <CloudWorkspaceDirectoryEntry>[];
      return;
    }
    if (isCloudSyncConfigured) {
      try {
        _cloudBackups = await _cloudBackupService.listBackups(
          workspaceId: cloudWorkspaceId,
          limit: 8,
        );
      } catch (_) {
        _cloudBackups = <CloudBackupManifest>[];
      }
    } else {
      _cloudBackups = <CloudBackupManifest>[];
    }
  }

  Future<void> _initializeCloudAccount() async {
    if (_cloudAuthService == null) {
      _cloudAuthReady = false;
      _cloudAccount = null;
      _accountCloudWorkspaces = <CloudWorkspaceDirectoryEntry>[];
      return;
    }
    _cloudAuthReady = await _cloudAuthService.initialize();
    if (!_cloudAuthReady) {
      _cloudAccount = null;
      _accountCloudWorkspaces = <CloudWorkspaceDirectoryEntry>[];
      return;
    }
    final account = await _cloudAuthService.currentAccount();
    await _applyCloudAccount(account, notify: false);
    if (account != null && _cloudSyncReady) {
      try {
        final service = await _requireCloudBackupService();
        _accountCloudWorkspaces = await service.listAccountWorkspaces(
          accountId: account.id,
          limit: 12,
        );
      } catch (_) {
        _accountCloudWorkspaces = <CloudWorkspaceDirectoryEntry>[];
      }
    } else {
      _accountCloudWorkspaces = <CloudWorkspaceDirectoryEntry>[];
    }
  }

  Future<CloudBackupService> _requireCloudBackupService() async {
    if (_cloudBackupService == null) {
      throw StateError('Cloud backup is not available on this device.');
    }
    if (!_cloudSyncReady) {
      _cloudSyncReady = await _cloudBackupService.initialize();
    }
    if (!_cloudSyncReady) {
      throw StateError('Cloud backup is not available on this device.');
    }
    return _cloudBackupService;
  }

  Future<CloudAuthService> _requireCloudAuthService() async {
    if (_cloudAuthService == null) {
      throw StateError('Cloud sign-in is not available on this device.');
    }
    if (!_cloudAuthReady) {
      _cloudAuthReady = await _cloudAuthService.initialize();
    }
    if (!_cloudAuthReady) {
      throw StateError('Cloud sign-in is not available on this device.');
    }
    return _cloudAuthService;
  }

  String _normalizeCloudWorkspaceId(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  String _defaultCloudDeviceLabel() {
    if (kIsWeb) {
      return 'Web device';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android device';
      case TargetPlatform.iOS:
        return 'iPhone or iPad';
      case TargetPlatform.macOS:
        return 'Mac device';
      case TargetPlatform.windows:
        return 'Windows device';
      case TargetPlatform.linux:
        return 'Linux device';
      case TargetPlatform.fuchsia:
        return 'Fuchsia device';
    }
  }

  Future<void> _setCloudSyncError(String message) async {
    _settings = _settings.copyWith(
      cloudSyncLastError: message,
      clearCloudSyncLastError: message.trim().isEmpty,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> _applyCloudAccount(
    CloudAccountProfile? account, {
    bool notify = true,
  }) async {
    _cloudAccount = account;
    _settings = _settings.copyWith(
      cloudAccountId: account?.id.trim() ?? '',
      cloudAccountEmail: account?.email.trim() ?? '',
      cloudAccountPhone: account?.phoneNumber.trim() ?? '',
      cloudAccountDisplayName: account?.displayName.trim() ?? '',
      cloudAccountProvider: account?.provider.trim() ?? '',
      cloudAccountEmailVerified: account?.isEmailVerified ?? false,
      lastCloudAccountSignInAt: account?.signedInAt,
      clearCloudAccount: account == null,
    );
    await _persist();
    if (notify) {
      notifyListeners();
    }
  }

  List<Customer> get _activeCustomers =>
      _customers.where((customer) => customer.shopId == activeShopId).toList();

  List<Customer> get _visibleCustomers => _activeCustomers
      .where((customer) => !shouldHideHiddenCustomers || !customer.isHidden)
      .toList();

  List<Customer> get hiddenCustomers {
    final snapshot = _activeCustomers
        .where((customer) => customer.isHidden)
        .toList();
    snapshot.sort(
      (left, right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );
    return snapshot;
  }

  List<LedgerTransaction> get _activeTransactions => _transactions
      .where((transaction) => transaction.shopId == activeShopId)
      .toList();

  List<StaffMember> get _activeStaffMembers =>
      _staffMembers.where((staff) => staff.shopId == activeShopId).toList();

  List<StaffAttendanceEntry> get _activeStaffAttendanceEntries =>
      _staffAttendanceEntries
          .where((entry) => entry.shopId == activeShopId)
          .toList();

  List<StaffAdvanceEntry> get _activeStaffAdvanceEntries => _staffAdvanceEntries
      .where((entry) => entry.shopId == activeShopId)
      .toList();

  List<StaffPayrollRun> get _activeStaffPayrollRuns =>
      _staffPayrollRuns.where((run) => run.shopId == activeShopId).toList();

  List<Supplier> get _activeSuppliers =>
      _suppliers.where((supplier) => supplier.shopId == activeShopId).toList();

  List<SupplierLedgerEntry> get _activeSupplierLedgerEntries =>
      _supplierLedgerEntries
          .where((entry) => entry.shopId == activeShopId)
          .toList();

  List<InventoryItem> get _activeInventoryItems =>
      _inventoryItems.where((item) => item.shopId == activeShopId).toList();

  List<SaleRecord> get _activeSaleRecords =>
      _saleRecords.where((sale) => sale.shopId == activeShopId).toList();

  Customer? customerById(String customerId) {
    for (final customer in _customers) {
      if (customer.id == customerId) {
        return customer;
      }
    }
    return null;
  }

  ShopProfile? shopById(String shopId) {
    for (final shop in _shops) {
      if (shop.id == shopId) {
        return shop;
      }
    }
    return null;
  }

  Supplier? supplierById(String supplierId) {
    for (final supplier in _suppliers) {
      if (supplier.id == supplierId) {
        return supplier;
      }
    }
    return null;
  }

  StaffMember? staffMemberById(String staffId) {
    for (final staff in _staffMembers) {
      if (staff.id == staffId) {
        return staff;
      }
    }
    return null;
  }

  InventoryItem? inventoryItemById(String inventoryItemId) {
    for (final item in _inventoryItems) {
      if (item.id == inventoryItemId) {
        return item;
      }
    }
    return null;
  }

  SaleRecord? saleRecordById(String saleRecordId) {
    for (final sale in _saleRecords) {
      if (sale.id == saleRecordId) {
        return sale;
      }
    }
    return null;
  }

  LedgerTransaction? transactionById(String transactionId) {
    for (final transaction in _transactions) {
      if (transaction.id == transactionId) {
        return transaction;
      }
    }
    return null;
  }

  List<ReminderLog> remindersFor(String customerId) {
    final logs = _reminderLogs
        .where((item) => item.customerId == customerId)
        .toList();
    logs.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return logs;
  }

  ReminderInboxItem? reminderInboxById(String reminderInboxId) {
    for (final item in _reminderInbox) {
      if (item.id == reminderInboxId) {
        return item;
      }
    }
    return null;
  }

  List<LedgerTransaction> transactionsFor(String customerId) {
    final snapshot = _transactions
        .where((item) => item.customerId == customerId)
        .toList();
    snapshot.sort((a, b) => b.date.compareTo(a.date));
    return snapshot;
  }

  List<SupplierLedgerEntry> supplierLedgerFor(String supplierId) {
    final snapshot = _supplierLedgerEntries
        .where((entry) => entry.supplierId == supplierId)
        .toList();
    snapshot.sort((a, b) => b.date.compareTo(a.date));
    return snapshot;
  }

  List<ReminderInboxItem> pendingReminderInboxForCustomer(String customerId) {
    final snapshot = _reminderInbox
        .where(
          (item) =>
              item.customerId == customerId &&
              item.status == ReminderInboxStatus.pending,
        )
        .toList();
    snapshot.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return snapshot;
  }

  List<InstallmentPlan> installmentPlansFor(String customerId) {
    final snapshot = _installmentPlans
        .where((plan) => plan.customerId == customerId)
        .toList();
    snapshot.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return snapshot;
  }

  List<CustomerVisit> customerVisitsFor(String customerId) {
    final snapshot = _customerVisits
        .where((visit) => visit.customerId == customerId)
        .toList();
    snapshot.sort((a, b) => b.visitedAt.compareTo(a.visitedAt));
    return snapshot;
  }

  List<CommunityBlacklistEntry> communityBlacklistMatchesForCustomer(
    String customerId,
  ) {
    final customer = customerById(customerId);
    if (customer == null) {
      return const <CommunityBlacklistEntry>[];
    }
    final snapshot = communityBlacklistEntries
        .where(
          (entry) => _communityBlacklistEntryMatchesCustomer(entry, customer),
        )
        .toList();
    snapshot.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return snapshot;
  }

  List<CommunityBlacklistEntry> searchCommunityBlacklist({
    String query = '',
    String city = '',
    CommunityRiskLevel? riskLevel,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final digitQuery = _digitsOnly(query);
    final normalizedPhoneQuery = _normalizePakPhone(query);
    final normalizedCity = city.trim().toLowerCase();
    final snapshot = communityBlacklistEntries.where((entry) {
      if (normalizedCity.isNotEmpty &&
          entry.city.trim().toLowerCase() != normalizedCity) {
        return false;
      }
      if (riskLevel != null && entry.riskLevel != riskLevel) {
        return false;
      }
      if (normalizedQuery.isEmpty && digitQuery.isEmpty) {
        return true;
      }
      final normalizedPhone = _normalizePakPhone(entry.phone);
      final normalizedCnic = _digitsOnly(entry.cnic);
      final haystack = <String>[
        entry.customerName.trim().toLowerCase(),
        entry.reason.trim().toLowerCase(),
        entry.note.trim().toLowerCase(),
        entry.city.trim().toLowerCase(),
      ];
      final textMatch = haystack.any(
        (value) => value.contains(normalizedQuery),
      );
      final digitMatch =
          (normalizedPhoneQuery.isNotEmpty &&
              normalizedPhone.contains(normalizedPhoneQuery)) ||
          (digitQuery.isNotEmpty &&
              (normalizedPhone.contains(digitQuery) ||
                  normalizedCnic.contains(digitQuery)));
      return textMatch || digitMatch;
    }).toList();
    snapshot.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return snapshot;
  }

  InstallmentPlan? activeInstallmentPlanFor(String customerId) {
    for (final plan in installmentPlansFor(customerId)) {
      if (!plan.isCompleted) {
        return plan;
      }
    }
    return null;
  }

  List<Customer> get customersWithPendingBalance {
    final snapshot = _visibleCustomers
        .where((customer) => insightFor(customer.id).balance > 0)
        .toList();
    snapshot.sort(
      (a, b) => insightFor(b.id).balance.compareTo(insightFor(a.id).balance),
    );
    return snapshot;
  }

  List<Customer> get topCustomers =>
      customersWithPendingBalance.take(5).toList();

  List<Customer> get highestRiskCustomers {
    final snapshot = customersWithPendingBalance.toList();
    snapshot.sort(
      (left, right) =>
          _priorityScoreFor(right.id).compareTo(_priorityScoreFor(left.id)),
    );
    return snapshot.take(5).toList();
  }

  List<Customer> get favouriteCustomers =>
      customers.where((customer) => customer.isFavourite).toList();

  List<String> get categoryOptions {
    final categories = <String>{'VIP', 'Regular', 'Risky', 'New'};
    for (final customer in _visibleCustomers) {
      if (customer.category.trim().isNotEmpty) {
        categories.add(customer.category.trim());
      }
    }
    final sorted = categories.toList()..sort();
    return sorted;
  }

  List<Customer> availableReferralCustomers({String? excludeCustomerId}) {
    return customers
        .where((customer) => customer.id != excludeCustomerId)
        .toList();
  }

  List<Customer> groupedCustomers(String groupName) {
    final normalizedGroup = groupName.trim().toLowerCase();
    if (normalizedGroup.isEmpty) {
      return const <Customer>[];
    }
    final snapshot = _visibleCustomers
        .where(
          (customer) =>
              customer.groupName.trim().toLowerCase() == normalizedGroup,
        )
        .toList();
    snapshot.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return snapshot;
  }

  Map<String, double> get groupOutstandingTotals {
    final totals = <String, double>{};
    for (final customer in _visibleCustomers) {
      final groupName = customer.groupName.trim();
      if (groupName.isEmpty) {
        continue;
      }
      final balance = insightFor(customer.id).balance;
      if (balance <= 0) {
        continue;
      }
      totals.update(
        groupName,
        (value) => value + balance,
        ifAbsent: () => balance,
      );
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map<String, double>.fromEntries(entries);
  }

  double supplierOutstandingBalance(String supplierId) {
    final entries = supplierLedgerFor(supplierId);
    final purchases = entries
        .where((entry) => entry.type == SupplierEntryType.purchase)
        .fold<double>(0, (total, entry) => total + entry.amount);
    final payments = entries
        .where((entry) => entry.type == SupplierEntryType.payment)
        .fold<double>(0, (total, entry) => total + entry.amount);
    return max(0, purchases - payments);
  }

  double get totalSupplierPayables => suppliers.fold<double>(
    0,
    (total, supplier) => total + supplierOutstandingBalance(supplier.id),
  );

  double get totalInventoryCostValue => inventoryItems.fold<double>(
    0,
    (total, item) => total + item.stockCostValue,
  );

  double get totalInventoryRetailValue => inventoryItems.fold<double>(
    0,
    (total, item) => total + item.stockRetailValue,
  );

  double get monthlyCashSales {
    final now = DateTime.now();
    return saleRecords
        .where(
          (sale) =>
              sale.type == SaleRecordType.cash &&
              sale.date.year == now.year &&
              sale.date.month == now.month,
        )
        .fold<double>(0, (total, sale) => total + sale.totalAmount);
  }

  double get monthlySalesMargin {
    final now = DateTime.now();
    return saleRecords
        .where(
          (sale) => sale.date.year == now.year && sale.date.month == now.month,
        )
        .fold<double>(0, (total, sale) => total + sale.totalMargin);
  }

  List<SaleRecord> saleRecordsForCustomer(String customerId) {
    final snapshot =
        saleRecords.where((sale) => sale.customerId == customerId).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return snapshot;
  }

  List<StaffAttendanceEntry> attendanceForStaff(
    String staffId, {
    DateTime? start,
    DateTime? end,
  }) {
    final snapshot = staffAttendanceEntries.where((entry) {
      if (entry.staffId != staffId) {
        return false;
      }
      if (start != null && entry.date.isBefore(start)) {
        return false;
      }
      if (end != null && entry.date.isAfter(end)) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
    return snapshot;
  }

  StaffAttendanceEntry? attendanceForStaffOnDate(
    String staffId,
    DateTime date,
  ) {
    for (final entry in _activeStaffAttendanceEntries) {
      if (entry.staffId == staffId && _isSameDay(entry.date, date)) {
        return entry;
      }
    }
    return null;
  }

  List<StaffAdvanceEntry> advancesForStaff(
    String staffId, {
    bool includeSettled = true,
  }) {
    final snapshot = staffAdvanceEntries.where((entry) {
      if (entry.staffId != staffId) {
        return false;
      }
      return includeSettled || !entry.isSettled;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
    return snapshot;
  }

  List<StaffPayrollRun> payrollRunsForStaff(String staffId) {
    final snapshot =
        staffPayrollRuns.where((run) => run.staffId == staffId).toList()
          ..sort((a, b) => b.payDate.compareTo(a.payDate));
    return snapshot;
  }

  StaffPayrollRun? payrollRunById(String payrollRunId) {
    for (final run in _staffPayrollRuns) {
      if (run.id == payrollRunId) {
        return run;
      }
    }
    return null;
  }

  double staffOutstandingAdvanceTotal(String staffId) {
    return advancesForStaff(
      staffId,
      includeSettled: false,
    ).fold<double>(0, (total, entry) => total + entry.amount);
  }

  double get totalOutstandingStaffAdvances => _activeStaffAdvanceEntries
      .where((entry) => !entry.isSettled)
      .fold<double>(0, (total, entry) => total + entry.amount);

  double get monthlyPayrollNet {
    final now = DateTime.now();
    return staffPayrollRuns
        .where(
          (run) =>
              run.payDate.year == now.year && run.payDate.month == now.month,
        )
        .fold<double>(0, (total, run) => total + run.netPay);
  }

  double get monthlyStaffOvertimeHours {
    final now = DateTime.now();
    return staffAttendanceEntries
        .where(
          (entry) =>
              entry.date.year == now.year && entry.date.month == now.month,
        )
        .fold<double>(0, (total, entry) => total + entry.overtimeHours);
  }

  int get presentStaffTodayCount {
    final today = DateTime.now();
    return staffMembers.where((staff) {
      final attendance = attendanceForStaffOnDate(staff.id, today);
      return attendance != null &&
          attendance.status != StaffAttendanceStatus.absent;
    }).length;
  }

  Future<StaffMember> saveStaffMember({
    String? staffId,
    required String name,
    String phone = '',
    String role = '',
    StaffPayType payType = StaffPayType.monthly,
    required double baseRate,
    double defaultHoursPerDay = 8,
    double overtimeRate = 0,
    String notes = '',
    bool isActive = true,
  }) async {
    _ensureWritableSession();
    final existing = staffId == null ? null : staffMemberById(staffId);
    final staff = existing == null
        ? StaffMember(
            id: _makeId(),
            shopId: activeShopId,
            name: name.trim(),
            phone: phone.trim(),
            role: role.trim().isEmpty ? 'Staff member' : role.trim(),
            payType: payType,
            baseRate: max(0, baseRate),
            createdAt: DateTime.now(),
            defaultHoursPerDay: defaultHoursPerDay <= 0
                ? 8
                : defaultHoursPerDay,
            overtimeRate: max(0, overtimeRate),
            notes: notes.trim(),
            isActive: isActive,
          )
        : existing.copyWith(
            name: name.trim(),
            phone: phone.trim(),
            role: role.trim().isEmpty ? existing.role : role.trim(),
            payType: payType,
            baseRate: max(0, baseRate),
            defaultHoursPerDay: defaultHoursPerDay <= 0
                ? existing.defaultHoursPerDay
                : defaultHoursPerDay,
            overtimeRate: max(0, overtimeRate),
            notes: notes.trim(),
            isActive: isActive,
          );

    if (existing == null) {
      _staffMembers = <StaffMember>[staff, ..._staffMembers];
    } else {
      _staffMembers = _staffMembers
          .map((entry) => entry.id == staff.id ? staff : entry)
          .toList();
    }

    await _persist();
    notifyListeners();
    return staff;
  }

  Future<StaffAttendanceEntry> saveStaffAttendance({
    String? attendanceId,
    required String staffId,
    required DateTime date,
    required StaffAttendanceStatus status,
    double workedHours = 0,
    double overtimeHours = 0,
    String note = '',
  }) async {
    _ensureWritableSession();
    final staff = staffMemberById(staffId);
    if (staff == null) {
      throw ArgumentError('Staff member not found.');
    }
    StaffAttendanceEntry? resolvedExisting;
    if (attendanceId == null) {
      resolvedExisting = attendanceForStaffOnDate(staffId, date);
    } else {
      final existing = _staffAttendanceEntries.firstWhere(
        (entry) => entry.id == attendanceId,
        orElse: () => StaffAttendanceEntry(
          id: '',
          shopId: '',
          staffId: '',
          date: date,
          status: status,
          createdAt: DateTime.now(),
        ),
      );
      resolvedExisting = existing.id.isEmpty ? null : existing;
    }
    final normalizedWorkedHours = workedHours > 0
        ? workedHours
        : _defaultWorkedHoursForStatus(staff, status);
    final entry = resolvedExisting == null
        ? StaffAttendanceEntry(
            id: _makeId(),
            shopId: activeShopId,
            staffId: staffId,
            date: DateTime(date.year, date.month, date.day),
            status: status,
            createdAt: DateTime.now(),
            workedHours: normalizedWorkedHours,
            overtimeHours: max(0, overtimeHours),
            note: note.trim(),
          )
        : resolvedExisting.copyWith(
            date: DateTime(date.year, date.month, date.day),
            status: status,
            workedHours: normalizedWorkedHours,
            overtimeHours: max(0, overtimeHours),
            note: note.trim(),
          );

    if (resolvedExisting == null) {
      _staffAttendanceEntries = <StaffAttendanceEntry>[
        entry,
        ..._staffAttendanceEntries,
      ];
    } else {
      _staffAttendanceEntries = _staffAttendanceEntries
          .map((item) => item.id == entry.id ? entry : item)
          .toList();
    }
    _staffAttendanceEntries.sort((a, b) => b.date.compareTo(a.date));

    await _persist();
    notifyListeners();
    return entry;
  }

  Future<StaffAdvanceEntry> recordStaffAdvance({
    required String staffId,
    required double amount,
    String note = '',
    DateTime? date,
  }) async {
    _ensureWritableSession();
    final staff = staffMemberById(staffId);
    if (staff == null) {
      throw ArgumentError('Staff member not found.');
    }
    if (amount <= 0) {
      throw ArgumentError('Advance amount must be greater than zero.');
    }
    final entry = StaffAdvanceEntry(
      id: _makeId(),
      shopId: activeShopId,
      staffId: staffId,
      amount: amount,
      date: date ?? DateTime.now(),
      note: note.trim(),
    );
    _staffAdvanceEntries = <StaffAdvanceEntry>[entry, ..._staffAdvanceEntries]
      ..sort((a, b) => b.date.compareTo(a.date));
    await _persist();
    notifyListeners();
    return entry;
  }

  Future<StaffPayrollRun> runStaffPayroll({
    required String staffId,
    required DateTime periodStart,
    required DateTime periodEnd,
    DateTime? payDate,
    String note = '',
  }) async {
    _ensureWritableSession();
    final staff = staffMemberById(staffId);
    if (staff == null) {
      throw ArgumentError('Staff member not found.');
    }
    final normalizedStart = DateTime(
      periodStart.year,
      periodStart.month,
      periodStart.day,
    );
    final normalizedEnd = DateTime(
      periodEnd.year,
      periodEnd.month,
      periodEnd.day,
      23,
      59,
      59,
      999,
    );
    if (normalizedEnd.isBefore(normalizedStart)) {
      throw ArgumentError('Payroll end date must be on or after start date.');
    }

    StaffPayrollRun? existingRun;
    for (final run in _activeStaffPayrollRuns) {
      if (run.staffId == staffId &&
          _isSameDay(run.periodStart, normalizedStart) &&
          _isSameDay(run.periodEnd, normalizedEnd)) {
        existingRun = run;
        break;
      }
    }

    final attendance = attendanceForStaff(
      staffId,
      start: normalizedStart,
      end: normalizedEnd,
    );
    final expectedWorkingDays = _workingDaysBetween(
      normalizedStart,
      normalizedEnd,
    );
    final paidUnits = attendance.fold<double>(
      0,
      (total, entry) => total + _attendanceUnitsForStatus(entry.status),
    );
    final workingHours = attendance.fold<double>(
      0,
      (total, entry) =>
          total +
          (entry.workedHours > 0
              ? entry.workedHours
              : _defaultWorkedHoursForStatus(staff, entry.status)),
    );
    final overtimeHours = attendance.fold<double>(
      0,
      (total, entry) => total + max(0, entry.overtimeHours),
    );

    double basePay;
    switch (staff.payType) {
      case StaffPayType.daily:
        basePay = staff.baseRate * paidUnits;
      case StaffPayType.hourly:
        basePay = staff.baseRate * workingHours;
      case StaffPayType.monthly:
        if (attendance.isEmpty) {
          basePay = staff.baseRate;
        } else {
          final denominator = max(1, expectedWorkingDays);
          final factor = (paidUnits / denominator).clamp(0, 1).toDouble();
          basePay = staff.baseRate * factor;
        }
    }

    final overtimeRate = _effectiveStaffOvertimeRate(
      staff,
      expectedWorkingDays: max(1, expectedWorkingDays),
    );
    final overtimePay = overtimeHours * overtimeRate;
    final grossPay = basePay + overtimePay;

    final unsettledAdvances =
        advancesForStaff(
            staffId,
            includeSettled: false,
          ).where((entry) => !entry.date.isAfter(normalizedEnd)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final previousAdvanceIds =
        existingRun?.includedAdvanceIds.toSet() ?? <String>{};
    if (previousAdvanceIds.isNotEmpty) {
      _staffAdvanceEntries = _staffAdvanceEntries.map((entry) {
        if (!previousAdvanceIds.contains(entry.id)) {
          return entry;
        }
        return entry.copyWith(clearSettledPayrollRunId: true);
      }).toList();
    }

    var remainingAdvanceBudget = grossPay;
    var advanceDeduction = 0.0;
    final includedAdvanceIds = <String>[];
    for (final entry in unsettledAdvances) {
      if (entry.amount > remainingAdvanceBudget + 0.0001) {
        continue;
      }
      includedAdvanceIds.add(entry.id);
      advanceDeduction += entry.amount;
      remainingAdvanceBudget -= entry.amount;
    }

    final payroll = existingRun == null
        ? StaffPayrollRun(
            id: _makeId(),
            shopId: activeShopId,
            staffId: staffId,
            payType: staff.payType,
            periodStart: normalizedStart,
            periodEnd: normalizedEnd,
            payDate: payDate ?? DateTime.now(),
            createdAt: DateTime.now(),
            basePay: basePay,
            overtimePay: overtimePay,
            advanceDeduction: advanceDeduction,
            netPay: max(0, grossPay - advanceDeduction),
            paidUnits: paidUnits,
            workingHours: workingHours,
            overtimeHours: overtimeHours,
            note: note.trim(),
            includedAdvanceIds: includedAdvanceIds,
          )
        : existingRun.copyWith(
            payType: staff.payType,
            periodStart: normalizedStart,
            periodEnd: normalizedEnd,
            payDate: payDate ?? existingRun.payDate,
            basePay: basePay,
            overtimePay: overtimePay,
            advanceDeduction: advanceDeduction,
            netPay: max(0, grossPay - advanceDeduction),
            paidUnits: paidUnits,
            workingHours: workingHours,
            overtimeHours: overtimeHours,
            note: note.trim(),
            includedAdvanceIds: includedAdvanceIds,
          );

    if (existingRun == null) {
      _staffPayrollRuns = <StaffPayrollRun>[payroll, ..._staffPayrollRuns];
    } else {
      _staffPayrollRuns = _staffPayrollRuns
          .map((entry) => entry.id == payroll.id ? payroll : entry)
          .toList();
    }
    _staffPayrollRuns.sort((a, b) => b.payDate.compareTo(a.payDate));

    _staffAdvanceEntries = _staffAdvanceEntries.map((entry) {
      if (!includedAdvanceIds.contains(entry.id)) {
        return entry;
      }
      return entry.copyWith(settledPayrollRunId: payroll.id);
    }).toList();

    await _persist();
    notifyListeners();
    return payroll;
  }

  String salarySlipNumberForRun(StaffPayrollRun run) {
    final suffix = run.id.length <= 6 ? run.id : run.id.substring(0, 6);
    return 'SAL-${DateFormat('yyyyMMdd').format(run.payDate)}-${suffix.toUpperCase()}';
  }

  String buildSalarySlipDocument(StaffPayrollRun run) {
    final staff = staffMemberById(run.staffId);
    final shop = shopById(run.shopId) ?? activeShop;
    final advances = run.includedAdvanceIds
        .map(
          (advanceId) => _staffAdvanceEntries.firstWhere(
            (entry) => entry.id == advanceId,
            orElse: () => StaffAdvanceEntry(
              id: '',
              shopId: run.shopId,
              staffId: run.staffId,
              amount: 0,
              date: run.payDate,
            ),
          ),
        )
        .where((entry) => entry.id.isNotEmpty)
        .toList();
    final buffer = StringBuffer()
      ..writeln('SALARY SLIP')
      ..writeln(shop.name);

    if (shop.tagline.trim().isNotEmpty) {
      buffer.writeln(shop.tagline.trim());
    }
    if (shop.address.trim().isNotEmpty) {
      buffer.writeln('Address: ${shop.address.trim()}');
    }
    buffer
      ..writeln('')
      ..writeln('Slip No: ${salarySlipNumberForRun(run)}')
      ..writeln('Pay date: ${formatDateTime(run.payDate)}')
      ..writeln(
        'Period: ${formatDate(run.periodStart)} - ${formatDate(run.periodEnd)}',
      )
      ..writeln('Staff: ${staff?.name ?? 'Unknown staff'}');

    if (staff != null) {
      buffer
        ..writeln('Role: ${staff.role}')
        ..writeln('Pay model: ${staffPayTypeLabel(staff.payType)}');
      if (staff.phone.trim().isNotEmpty) {
        buffer.writeln('Phone: ${staff.phone}');
      }
    }

    buffer
      ..writeln('')
      ..writeln('PAY SUMMARY')
      ..writeln('Base pay: ${formatCurrency(run.basePay)}')
      ..writeln('Overtime pay: ${formatCurrency(run.overtimePay)}')
      ..writeln('Gross pay: ${formatCurrency(run.grossPay)}')
      ..writeln('Advance deduction: ${formatCurrency(run.advanceDeduction)}')
      ..writeln('Net pay: ${formatCurrency(run.netPay)}')
      ..writeln('')
      ..writeln('ATTENDANCE')
      ..writeln('Paid units: ${run.paidUnits.toStringAsFixed(1)}')
      ..writeln('Working hours: ${run.workingHours.toStringAsFixed(1)}')
      ..writeln('Overtime hours: ${run.overtimeHours.toStringAsFixed(1)}');

    if (advances.isNotEmpty) {
      buffer
        ..writeln('')
        ..writeln('ADVANCES INCLUDED');
      for (final advance in advances) {
        buffer.writeln(
          '${formatDate(advance.date)} | ${formatCurrency(advance.amount)}${advance.note.trim().isEmpty ? '' : ' | ${advance.note.trim()}'}',
        );
      }
    }

    if (run.note.trim().isNotEmpty) {
      buffer
        ..writeln('')
        ..writeln('NOTES')
        ..writeln(run.note.trim());
    }

    return buffer.toString().trimRight();
  }

  double _attendanceUnitsForStatus(StaffAttendanceStatus status) {
    switch (status) {
      case StaffAttendanceStatus.present:
        return 1;
      case StaffAttendanceStatus.absent:
        return 0;
      case StaffAttendanceStatus.halfDay:
        return 0.5;
      case StaffAttendanceStatus.leave:
        return 1;
    }
  }

  double _defaultWorkedHoursForStatus(
    StaffMember staff,
    StaffAttendanceStatus status,
  ) {
    switch (status) {
      case StaffAttendanceStatus.present:
        return staff.defaultHoursPerDay;
      case StaffAttendanceStatus.absent:
        return 0;
      case StaffAttendanceStatus.halfDay:
        return staff.defaultHoursPerDay / 2;
      case StaffAttendanceStatus.leave:
        return 0;
    }
  }

  double _effectiveStaffOvertimeRate(
    StaffMember staff, {
    required int expectedWorkingDays,
  }) {
    if (staff.overtimeRate > 0) {
      return staff.overtimeRate;
    }
    switch (staff.payType) {
      case StaffPayType.daily:
        return staff.defaultHoursPerDay <= 0
            ? 0
            : staff.baseRate / staff.defaultHoursPerDay;
      case StaffPayType.monthly:
        final divisor =
            max(1, expectedWorkingDays) *
            (staff.defaultHoursPerDay <= 0 ? 8 : staff.defaultHoursPerDay);
        return divisor <= 0 ? 0 : staff.baseRate / divisor;
      case StaffPayType.hourly:
        return staff.baseRate;
    }
  }

  int _workingDaysBetween(DateTime start, DateTime end) {
    var count = 0;
    var cursor = DateTime(start.year, start.month, start.day);
    final lastDay = DateTime(end.year, end.month, end.day);
    while (!cursor.isAfter(lastDay)) {
      if (cursor.weekday != DateTime.saturday &&
          cursor.weekday != DateTime.sunday) {
        count += 1;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return count;
  }

  Customer? referredByFor(Customer customer) {
    final referredByCustomerId = customer.referredByCustomerId;
    if (referredByCustomerId == null || referredByCustomerId.isEmpty) {
      return null;
    }
    return customerById(referredByCustomerId);
  }

  int inheritedTrustBoost(Customer customer) {
    final referrer = referredByFor(customer);
    if (referrer == null) {
      return 0;
    }
    return (insightFor(referrer.id).recoveryScore * 0.25).round();
  }

  double get totalUdhaar {
    return _activeCustomers.fold<double>(
      0,
      (total, customer) => total + insightFor(customer.id).balance,
    );
  }

  double get totalCredits => _activeTransactions
      .where((entry) => entry.type == TransactionType.credit)
      .fold<double>(0, (total, item) => total + item.amount);

  double get totalPayments => _activeTransactions
      .where((entry) => entry.type == TransactionType.payment)
      .fold<double>(0, (total, item) => total + item.amount);

  double get overdueAmount {
    return _activeCustomers.fold<double>(0, (total, customer) {
      final insight = insightFor(customer.id);
      return insight.overdueDays > 0 ? total + insight.balance : total;
    });
  }

  double get monthlyRecovery {
    final now = DateTime.now();
    return _activeTransactions
        .where(
          (entry) =>
              entry.type == TransactionType.payment &&
              entry.date.year == now.year &&
              entry.date.month == now.month,
        )
        .fold<double>(0, (total, item) => total + item.amount);
  }

  double get lastMonthRecovery {
    final now = DateTime.now();
    final previous = DateTime(now.year, now.month - 1, 1);
    return _activeTransactions
        .where(
          (entry) =>
              entry.type == TransactionType.payment &&
              entry.date.year == previous.year &&
              entry.date.month == previous.month,
        )
        .fold<double>(0, (total, item) => total + item.amount);
  }

  bool get beatLastMonth => monthlyRecovery > lastMonthRecovery;

  double get collectionEfficiency {
    if (totalCredits <= 0) {
      return 0;
    }
    return totalPayments / totalCredits;
  }

  double get averageRecoveryScore {
    if (_visibleCustomers.isEmpty) {
      return 0;
    }
    final total = _visibleCustomers.fold<int>(
      0,
      (value, customer) => value + insightFor(customer.id).recoveryScore,
    );
    return total / _visibleCustomers.length;
  }

  int get riskyCustomerCount => _visibleCustomers.where((customer) {
    final insight = insightFor(customer.id);
    return insight.paymentChance == PaymentChance.low ||
        insight.isOverCreditLimit;
  }).length;

  int get remindersThisMonth {
    final now = DateTime.now();
    return reminderLogs
        .where(
          (log) => log.sentAt.year == now.year && log.sentAt.month == now.month,
        )
        .length;
  }

  Map<String, double> get categoryBalanceBreakdown {
    final data = <String, double>{};
    for (final customer in _visibleCustomers) {
      final balance = insightFor(customer.id).balance;
      if (balance <= 0) {
        continue;
      }
      final key = customer.category.trim().isEmpty
          ? 'Uncategorized'
          : customer.category;
      data.update(key, (value) => value + balance, ifAbsent: () => balance);
    }
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map<String, double>.fromEntries(entries);
  }

  List<SaleRecord> saleRecordsInRange(ReportRange range) {
    final snapshot = _activeSaleRecords
        .where((sale) => range.contains(sale.date))
        .toList();
    snapshot.sort((a, b) => a.date.compareTo(b.date));
    return snapshot;
  }

  List<LedgerTransaction> transactionsInRange(ReportRange range) {
    final snapshot = _activeTransactions
        .where((entry) => range.contains(entry.date))
        .toList();
    snapshot.sort((a, b) => a.date.compareTo(b.date));
    return snapshot;
  }

  List<ReminderLog> reminderLogsInRange(ReportRange range) {
    final snapshot = reminderLogs
        .where((entry) => range.contains(entry.sentAt))
        .toList();
    snapshot.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return snapshot;
  }

  List<Customer> customersTouchedInRange(ReportRange range) {
    final customerIds = transactionsInRange(
      range,
    ).map((entry) => entry.customerId).toSet();
    final snapshot = _visibleCustomers
        .where((customer) => customerIds.contains(customer.id))
        .toList();
    snapshot.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return snapshot;
  }

  double creditsIssuedForRange(ReportRange range) {
    return transactionsInRange(range)
        .where((entry) => entry.type == TransactionType.credit)
        .fold<double>(0, (total, entry) => total + entry.amount);
  }

  double paymentsReceivedForRange(ReportRange range) {
    return transactionsInRange(range)
        .where((entry) => entry.type == TransactionType.payment)
        .fold<double>(0, (total, entry) => total + entry.amount);
  }

  int remindersSentForRange(ReportRange range) {
    return reminderLogsInRange(range).length;
  }

  double salesAmountForRange(ReportRange range, {SaleRecordType? type}) {
    return saleRecordsInRange(range)
        .where((sale) => type == null || sale.type == type)
        .fold<double>(0, (total, sale) => total + sale.totalAmount);
  }

  double costOfGoodsSoldForRange(ReportRange range) {
    return saleRecordsInRange(range).fold<double>(
      0,
      (total, sale) =>
          total +
          sale.lineItems.fold<double>(
            0,
            (lineTotal, item) => lineTotal + (item.costPrice * item.quantity),
          ),
    );
  }

  double grossProfitForRange(ReportRange range) {
    return saleRecordsInRange(
      range,
    ).fold<double>(0, (total, sale) => total + sale.totalMargin);
  }

  double payrollExpenseForRange(ReportRange range) {
    return staffPayrollRuns
        .where((run) => range.contains(run.payDate))
        .fold<double>(0, (total, run) => total + run.grossPay);
  }

  double supplierPurchasesForRange(ReportRange range) {
    return supplierLedgerEntries
        .where(
          (entry) =>
              entry.type == SupplierEntryType.purchase &&
              range.contains(entry.date),
        )
        .fold<double>(0, (total, entry) => total + entry.amount);
  }

  double supplierPaymentsForRange(ReportRange range) {
    return supplierLedgerEntries
        .where(
          (entry) =>
              entry.type == SupplierEntryType.payment &&
              range.contains(entry.date),
        )
        .fold<double>(0, (total, entry) => total + entry.amount);
  }

  ProfitLossSummary profitLossSummaryForRange(ReportRange range) {
    final totalSales = salesAmountForRange(range);
    final cashSales = salesAmountForRange(range, type: SaleRecordType.cash);
    final udhaarSales = salesAmountForRange(range, type: SaleRecordType.udhaar);
    final costOfGoodsSold = costOfGoodsSoldForRange(range);
    final grossProfit = totalSales - costOfGoodsSold;
    final payrollExpense = payrollExpenseForRange(range);
    return ProfitLossSummary(
      totalSales: totalSales,
      cashSales: cashSales,
      udhaarSales: udhaarSales,
      costOfGoodsSold: costOfGoodsSold,
      grossProfit: grossProfit,
      payrollExpense: payrollExpense,
      operatingProfit: grossProfit - payrollExpense,
    );
  }

  TaxSummary taxSummaryForRange(ReportRange range) {
    final grossSales = salesAmountForRange(range);
    final salesTaxRate = activeShop.salesTaxPercent;
    final taxableSales = _taxableAmountFromInclusiveTotal(
      grossSales,
      salesTaxRate,
    );
    return TaxSummary(
      salesTaxRate: salesTaxRate,
      grossSales: grossSales,
      taxableSales: taxableSales,
      salesTaxAmount: grossSales - taxableSales,
    );
  }

  double balanceSheetDiscrepancyForRange(ReportRange range) {
    final expectedClosing =
        openingBalanceForRange(range) +
        creditsIssuedForRange(range) -
        paymentsReceivedForRange(range);
    return expectedClosing - closingBalanceForRange(range);
  }

  List<PeriodBusinessSummary> weeklyBusinessSummaries({
    int count = 6,
    DateTime? now,
  }) {
    final anchor = now ?? DateTime.now();
    final weekStart = DateTime(
      anchor.year,
      anchor.month,
      anchor.day,
    ).subtract(Duration(days: anchor.weekday - 1));
    final summaries = <PeriodBusinessSummary>[];
    for (var index = count - 1; index >= 0; index -= 1) {
      final start = weekStart.subtract(Duration(days: index * 7));
      final end = start.add(const Duration(days: 6));
      final range = ReportRange(
        label:
            '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM').format(end)}',
        start: start,
        end: end,
      );
      final profitLoss = profitLossSummaryForRange(range);
      summaries.add(
        PeriodBusinessSummary(
          label: 'Week of ${DateFormat('d MMM').format(start)}',
          range: range,
          sales: profitLoss.totalSales,
          payments: paymentsReceivedForRange(range),
          creditIssued: creditsIssuedForRange(range),
          grossProfit: profitLoss.grossProfit,
          operatingProfit: profitLoss.operatingProfit,
        ),
      );
    }
    return summaries;
  }

  List<PeriodBusinessSummary> monthlyBusinessSummaries({
    int count = 6,
    DateTime? now,
  }) {
    final anchor = now ?? DateTime.now();
    final firstMonth = DateTime(anchor.year, anchor.month, 1);
    final summaries = <PeriodBusinessSummary>[];
    for (var index = count - 1; index >= 0; index -= 1) {
      final monthDate = DateTime(firstMonth.year, firstMonth.month - index, 1);
      final start = DateTime(monthDate.year, monthDate.month, 1);
      final end = DateTime(monthDate.year, monthDate.month + 1, 0);
      final range = ReportRange(
        label: DateFormat('MMM yyyy').format(start),
        start: start,
        end: end,
      );
      final profitLoss = profitLossSummaryForRange(range);
      summaries.add(
        PeriodBusinessSummary(
          label: DateFormat('MMM yyyy').format(start),
          range: range,
          sales: profitLoss.totalSales,
          payments: paymentsReceivedForRange(range),
          creditIssued: creditsIssuedForRange(range),
          grossProfit: profitLoss.grossProfit,
          operatingProfit: profitLoss.operatingProfit,
        ),
      );
    }
    return summaries;
  }

  List<SalesItemSummary> topSellingItemsForRange(
    ReportRange range, {
    int limit = 6,
  }) {
    final totals = <String, List<num>>{};
    for (final sale in saleRecordsInRange(range)) {
      for (final item in sale.lineItems) {
        final bucket = totals.putIfAbsent(item.itemName, () => <num>[0, 0, 0]);
        bucket[0] = bucket[0].toInt() + item.quantity;
        bucket[1] = bucket[1].toDouble() + item.lineTotal;
        bucket[2] = bucket[2].toDouble() + item.lineMargin;
      }
    }
    final items =
        totals.entries
            .map(
              (entry) => SalesItemSummary(
                itemName: entry.key,
                quantity: entry.value[0].toInt(),
                salesAmount: entry.value[1].toDouble(),
                margin: entry.value[2].toDouble(),
              ),
            )
            .toList()
          ..sort((a, b) => b.salesAmount.compareTo(a.salesAmount));
    if (items.length <= limit) {
      return items;
    }
    return items.take(limit).toList();
  }

  double netCashFlowForRange(ReportRange range) {
    return paymentsReceivedForRange(range) - creditsIssuedForRange(range);
  }

  double openingBalanceForRange(ReportRange range) {
    final startAt = range.startAt;
    if (startAt == null) {
      return 0;
    }
    return _balanceForTransactions(
      _activeTransactions.where((entry) => entry.date.isBefore(startAt)),
    );
  }

  double closingBalanceForRange(ReportRange range) {
    final endAt = range.endAt;
    return _balanceForTransactions(
      endAt == null
          ? _activeTransactions
          : _activeTransactions.where((entry) => !entry.date.isAfter(endAt)),
    );
  }

  double zakatEstimateForRange(ReportRange range) {
    return closingBalanceForRange(range) * 0.025;
  }

  double creditsIssuedForCustomerInRange(String customerId, ReportRange range) {
    return transactionsFor(customerId)
        .where(
          (entry) =>
              entry.type == TransactionType.credit &&
              range.contains(entry.date),
        )
        .fold<double>(0, (total, entry) => total + entry.amount);
  }

  double paymentsReceivedForCustomerInRange(
    String customerId,
    ReportRange range,
  ) {
    return transactionsFor(customerId)
        .where(
          (entry) =>
              entry.type == TransactionType.payment &&
              range.contains(entry.date),
        )
        .fold<double>(0, (total, entry) => total + entry.amount);
  }

  double openingBalanceForCustomerInRange(
    String customerId,
    ReportRange range,
  ) {
    final startAt = range.startAt;
    if (startAt == null) {
      return 0;
    }
    return _balanceForTransactions(
      transactionsFor(
        customerId,
      ).where((entry) => entry.date.isBefore(startAt)),
    );
  }

  double closingBalanceForCustomerInRange(
    String customerId,
    ReportRange range,
  ) {
    final endAt = range.endAt;
    return _balanceForTransactions(
      endAt == null
          ? transactionsFor(customerId)
          : transactionsFor(
              customerId,
            ).where((entry) => !entry.date.isAfter(endAt)),
    );
  }

  Map<String, double> creditIssuedCategoryBreakdownForRange(ReportRange range) {
    final data = <String, double>{};
    for (final transaction in transactionsInRange(range)) {
      if (transaction.type != TransactionType.credit) {
        continue;
      }
      final customer = customerById(transaction.customerId);
      final key = customer == null || customer.category.trim().isEmpty
          ? 'Uncategorized'
          : customer.category;
      data.update(
        key,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map<String, double>.fromEntries(entries);
  }

  List<CashFlowBucket> cashFlowBucketsForRange(ReportRange range) {
    final transactions = transactionsInRange(range);
    if (transactions.isEmpty) {
      return const <CashFlowBucket>[];
    }
    final effectiveStart = range.startAt ?? transactions.first.date;
    final effectiveEnd = range.endAt ?? transactions.last.date;
    final spanDays = effectiveEnd.difference(effectiveStart).inDays + 1;
    final bucketMap = <String, List<double>>{};

    for (final transaction in transactions) {
      final bucketKey = spanDays > 45
          ? DateFormat('MMM yyyy').format(transaction.date)
          : DateFormat('d MMM').format(transaction.date);
      final values = bucketMap.putIfAbsent(bucketKey, () => <double>[0, 0]);
      if (transaction.type == TransactionType.credit) {
        values[0] += transaction.amount;
      } else {
        values[1] += transaction.amount;
      }
    }

    return bucketMap.entries
        .map(
          (entry) => CashFlowBucket(
            label: entry.key,
            credits: entry.value[0],
            payments: entry.value[1],
          ),
        )
        .toList();
  }

  String buildReportSummaryText(ReportRange range) {
    final touchedCustomers = customersTouchedInRange(range);
    final profitLoss = profitLossSummaryForRange(range);
    final taxSummary = taxSummaryForRange(range);
    final buffer = StringBuffer()
      ..writeln('Hisab Rakho report')
      ..writeln('Range: ${range.label}')
      ..writeln(
        'Opening balance: ${formatCurrency(openingBalanceForRange(range))}',
      )
      ..writeln(
        'Credit issued: ${formatCurrency(creditsIssuedForRange(range))}',
      )
      ..writeln(
        'Payments received: ${formatCurrency(paymentsReceivedForRange(range))}',
      )
      ..writeln('Net cash flow: ${formatCurrency(netCashFlowForRange(range))}')
      ..writeln(
        'Closing balance: ${formatCurrency(closingBalanceForRange(range))}',
      )
      ..writeln('Reminders sent: ${remindersSentForRange(range)}')
      ..writeln('Sales booked: ${formatCurrency(profitLoss.totalSales)}')
      ..writeln('Gross profit: ${formatCurrency(profitLoss.grossProfit)}')
      ..writeln(
        'Operating result: ${formatCurrency(profitLoss.operatingProfit)}',
      )
      ..writeln('Customers active: ${touchedCustomers.length}')
      ..writeln('Current overdue snapshot: ${formatCurrency(overdueAmount)}')
      ..writeln('Taxable sales: ${formatCurrency(taxSummary.taxableSales)}')
      ..writeln('Sales tax: ${formatCurrency(taxSummary.salesTaxAmount)}')
      ..writeln(
        'Zakat estimate: ${formatCurrency(zakatEstimateForRange(range))}',
      );
    return buffer.toString().trimRight();
  }

  String buildReportDocumentText(ReportRange range) {
    final touchedCustomers = customersTouchedInRange(range);
    final cashFlow = cashFlowBucketsForRange(range);
    final profitLoss = profitLossSummaryForRange(range);
    final taxSummary = taxSummaryForRange(range);
    final topItems = topSellingItemsForRange(range);
    final buffer = StringBuffer()
      ..writeln('HISAB RAKHO REPORT')
      ..writeln(_settings.shopName)
      ..writeln('Range: ${range.label}')
      ..writeln('')
      ..writeln('SUMMARY')
      ..writeln(
        'Opening balance: ${formatCurrency(openingBalanceForRange(range))}',
      )
      ..writeln(
        'Credit issued: ${formatCurrency(creditsIssuedForRange(range))}',
      )
      ..writeln(
        'Payments received: ${formatCurrency(paymentsReceivedForRange(range))}',
      )
      ..writeln('Net cash flow: ${formatCurrency(netCashFlowForRange(range))}')
      ..writeln(
        'Closing balance: ${formatCurrency(closingBalanceForRange(range))}',
      )
      ..writeln('Reminders sent: ${remindersSentForRange(range)}')
      ..writeln('Sales booked: ${formatCurrency(profitLoss.totalSales)}')
      ..writeln('Gross profit: ${formatCurrency(profitLoss.grossProfit)}')
      ..writeln(
        'Operating result: ${formatCurrency(profitLoss.operatingProfit)}',
      )
      ..writeln('')
      ..writeln('PROFIT AND LOSS')
      ..writeln('Cash sales: ${formatCurrency(profitLoss.cashSales)}')
      ..writeln('Udhaar sales: ${formatCurrency(profitLoss.udhaarSales)}')
      ..writeln(
        'Cost of goods sold: ${formatCurrency(profitLoss.costOfGoodsSold)}',
      )
      ..writeln('Payroll expense: ${formatCurrency(profitLoss.payrollExpense)}')
      ..writeln('Gross profit: ${formatCurrency(profitLoss.grossProfit)}')
      ..writeln(
        'Operating result: ${formatCurrency(profitLoss.operatingProfit)}',
      )
      ..writeln('')
      ..writeln('TAX SUMMARY')
      ..writeln('Taxable sales: ${formatCurrency(taxSummary.taxableSales)}')
      ..writeln(
        'Sales tax ${_formatPercent(taxSummary.salesTaxRate)}%: ${formatCurrency(taxSummary.salesTaxAmount)}',
      )
      ..writeln(
        'Balance sheet discrepancy: ${formatCurrency(balanceSheetDiscrepancyForRange(range))}',
      )
      ..writeln('')
      ..writeln('ACTIVE PROFILES');

    if (touchedCustomers.isEmpty) {
      buffer.writeln('No customer activity in the selected period.');
    } else {
      for (final customer in touchedCustomers.take(12)) {
        buffer.writeln(
          '- ${customer.name} | Open ${formatCurrency(openingBalanceForCustomerInRange(customer.id, range))} | Credit ${formatCurrency(creditsIssuedForCustomerInRange(customer.id, range))} | Payment ${formatCurrency(paymentsReceivedForCustomerInRange(customer.id, range))} | Close ${formatCurrency(closingBalanceForCustomerInRange(customer.id, range))}',
        );
      }
    }

    buffer
      ..writeln('')
      ..writeln('TOP SELLING ITEMS');
    if (topItems.isEmpty) {
      buffer.writeln('No sales activity in the selected period.');
    } else {
      for (final item in topItems) {
        buffer.writeln(
          '- ${item.itemName}: qty ${item.quantity}, sales ${formatCurrency(item.salesAmount)}, margin ${formatCurrency(item.margin)}',
        );
      }
    }

    buffer
      ..writeln('')
      ..writeln('CASH FLOW');
    if (cashFlow.isEmpty) {
      buffer.writeln('No cash flow entries in the selected period.');
    } else {
      for (final bucket in cashFlow.take(12)) {
        buffer.writeln(
          '- ${bucket.label}: credit ${formatCurrency(bucket.credits)}, payments ${formatCurrency(bucket.payments)}, net ${formatCurrency(bucket.net)}',
        );
      }
    }
    return buffer.toString().trimRight();
  }

  String exportReportCsv(ReportRange range) {
    final profitLoss = profitLossSummaryForRange(range);
    final taxSummary = taxSummaryForRange(range);
    final buffer = StringBuffer()
      ..writeln('Section,Metric,Value')
      ..writeln('Summary,Range,${_escapeCsvValue(range.label)}')
      ..writeln(
        'Summary,Opening Balance,${openingBalanceForRange(range).toStringAsFixed(2)}',
      )
      ..writeln(
        'Summary,Credit Issued,${creditsIssuedForRange(range).toStringAsFixed(2)}',
      )
      ..writeln(
        'Summary,Payments Received,${paymentsReceivedForRange(range).toStringAsFixed(2)}',
      )
      ..writeln(
        'Summary,Net Cash Flow,${netCashFlowForRange(range).toStringAsFixed(2)}',
      )
      ..writeln(
        'Summary,Closing Balance,${closingBalanceForRange(range).toStringAsFixed(2)}',
      )
      ..writeln('Summary,Reminders Sent,${remindersSentForRange(range)}')
      ..writeln(
        'Summary,Sales Booked,${profitLoss.totalSales.toStringAsFixed(2)}',
      )
      ..writeln('Summary,Cash Sales,${profitLoss.cashSales.toStringAsFixed(2)}')
      ..writeln(
        'Summary,Udhaar Sales,${profitLoss.udhaarSales.toStringAsFixed(2)}',
      )
      ..writeln(
        'Summary,Cost Of Goods Sold,${profitLoss.costOfGoodsSold.toStringAsFixed(2)}',
      )
      ..writeln(
        'Summary,Gross Profit,${profitLoss.grossProfit.toStringAsFixed(2)}',
      )
      ..writeln(
        'Summary,Payroll Expense,${profitLoss.payrollExpense.toStringAsFixed(2)}',
      )
      ..writeln(
        'Summary,Operating Result,${profitLoss.operatingProfit.toStringAsFixed(2)}',
      )
      ..writeln(
        'Summary,Taxable Sales,${taxSummary.taxableSales.toStringAsFixed(2)}',
      )
      ..writeln(
        'Summary,Sales Tax,${taxSummary.salesTaxAmount.toStringAsFixed(2)}',
      )
      ..writeln(
        'Summary,Balance Sheet Discrepancy,${balanceSheetDiscrepancyForRange(range).toStringAsFixed(2)}',
      )
      ..writeln(
        'Summary,Zakat Estimate,${zakatEstimateForRange(range).toStringAsFixed(2)}',
      )
      ..writeln()
      ..writeln(
        'Customer,Phone,Category,Opening Balance,Credit Issued,Payments Received,Closing Balance,Recovery Score,Overdue Days',
      );

    final customers = customersTouchedInRange(range);
    for (final customer in customers) {
      final insight = insightFor(customer.id);
      buffer.writeln(
        '${_escapeCsvValue(customer.name)},'
        '${_escapeCsvValue(customer.phone)},'
        '${_escapeCsvValue(customer.category)},'
        '${openingBalanceForCustomerInRange(customer.id, range).toStringAsFixed(2)},'
        '${creditsIssuedForCustomerInRange(customer.id, range).toStringAsFixed(2)},'
        '${paymentsReceivedForCustomerInRange(customer.id, range).toStringAsFixed(2)},'
        '${closingBalanceForCustomerInRange(customer.id, range).toStringAsFixed(2)},'
        '${insight.recoveryScore},'
        '${insight.overdueDays}',
      );
    }
    buffer
      ..writeln()
      ..writeln('Item,Quantity,Sales Amount,Margin');
    for (final item in topSellingItemsForRange(range, limit: 20)) {
      buffer.writeln(
        '${_escapeCsvValue(item.itemName)},${item.quantity},${item.salesAmount.toStringAsFixed(2)},${item.margin.toStringAsFixed(2)}',
      );
    }
    return buffer.toString().trimRight();
  }

  String buildCustomerStatementDocument(
    Customer customer, {
    ReportRange? range,
  }) {
    final effectiveRange = range;
    final transactions =
        effectiveRange == null
              ? transactionsFor(customer.id)
              : transactionsFor(
                  customer.id,
                ).where((entry) => effectiveRange.contains(entry.date)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final openingBalance = effectiveRange == null
        ? 0.0
        : openingBalanceForCustomerInRange(customer.id, effectiveRange);
    final closingBalance = effectiveRange == null
        ? insightFor(customer.id).balance
        : closingBalanceForCustomerInRange(customer.id, effectiveRange);
    final statement = StringBuffer()
      ..writeln('HISAB RAKHO STATEMENT')
      ..writeln(_settings.shopName)
      ..writeln('Name: ${customer.name}')
      ..writeln('Phone: ${customer.phone}')
      ..writeln('Category: ${customer.category}')
      ..writeln('Range: ${effectiveRange?.label ?? 'All activity'}')
      ..writeln('Opening balance: ${formatCurrency(openingBalance)}')
      ..writeln('Closing balance: ${formatCurrency(closingBalance)}')
      ..writeln('');

    if (transactions.isEmpty) {
      statement.writeln('No transactions found for this period.');
    } else {
      statement.writeln('TRANSACTIONS');
      for (final entry in transactions) {
        statement.writeln(
          '${DateFormat('yyyy-MM-dd').format(entry.date)} | ${transactionTypeLabel(entry.type)} | ${formatCurrency(entry.amount)} | ${entry.note}',
        );
      }
    }

    if (customer.promisedPaymentDate != null) {
      statement
        ..writeln('')
        ..writeln('Promise date: ${formatDate(customer.promisedPaymentDate!)}');
    }
    statement
      ..writeln('')
      ..writeln('View link: ${buildCustomerStatementLink(customer)}');
    return statement.toString().trimRight();
  }

  String exportCustomerStatementCsv(Customer customer, {ReportRange? range}) {
    final effectiveRange = range;
    final transactions =
        effectiveRange == null
              ? transactionsFor(customer.id)
              : transactionsFor(
                  customer.id,
                ).where((entry) => effectiveRange.contains(entry.date)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final buffer = StringBuffer()
      ..writeln('Customer,Phone,Range,Opening Balance,Closing Balance')
      ..writeln(
        '${_escapeCsvValue(customer.name)},${_escapeCsvValue(customer.phone)},${_escapeCsvValue(effectiveRange?.label ?? 'All activity')},${(effectiveRange == null ? 0 : openingBalanceForCustomerInRange(customer.id, effectiveRange)).toStringAsFixed(2)},${(effectiveRange == null ? insightFor(customer.id).balance : closingBalanceForCustomerInRange(customer.id, effectiveRange)).toStringAsFixed(2)}',
      )
      ..writeln()
      ..writeln('Date,Type,Amount,Reference,Note');

    for (final entry in transactions) {
      buffer.writeln(
        '${DateFormat('yyyy-MM-dd HH:mm').format(entry.date)},${_escapeCsvValue(transactionTypeLabel(entry.type))},${entry.amount.toStringAsFixed(2)},${_escapeCsvValue(entry.reference)},${_escapeCsvValue(entry.note)}',
      );
    }
    return buffer.toString().trimRight();
  }

  int get streakDays {
    final activityDays =
        _activeTransactions
            .map(
              (entry) =>
                  DateTime(entry.date.year, entry.date.month, entry.date.day),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    var streak = 0;
    for (var index = 0; index < 30; index++) {
      final day = DateTime(now.year, now.month, now.day - index);
      if (activityDays.contains(day)) {
        streak += 1;
      } else if (streak > 0) {
        break;
      }
    }
    return streak;
  }

  List<DailyAction> get todayActions {
    final candidates = customersWithPendingBalance.toList();
    candidates.sort((first, second) {
      final left = _priorityScoreFor(first.id);
      final right = _priorityScoreFor(second.id);
      return right.compareTo(left);
    });

    return candidates.take(_settings.lowDataMode ? 3 : 5).map((customer) {
      final insight = insightFor(customer.id);
      final followUpLabel = customer.promisedPaymentDate != null
          ? 'promise ${formatDate(customer.promisedPaymentDate!)}'
          : customer.lastReminderAt == null
          ? 'pehli yaad dehani bhejein'
          : '${_daysSince(customer.lastReminderAt!)} din se follow-up nahi hua';

      final overdueLabel = insight.overdueDays == 0
          ? 'fresh balance'
          : '${insight.overdueDays} din overdue';

      final limitLabel = insight.isOverCreditLimit
          ? 'credit limit cross ho chuki hai'
          : followUpLabel;

      return DailyAction(
        customerId: customer.id,
        title:
            'Follow up ${customer.name} (${formatCurrency(insight.balance)})',
        subtitle: insight.paymentChance == PaymentChance.low
            ? '$overdueLabel, $limitLabel'
            : '$followUpLabel, ${reminderToneLabel(insight.recommendedTone)} suggest hai',
        tone: insight.recommendedTone,
      );
    }).toList();
  }

  CustomerInsight insightFor(String customerId) {
    return _calculateCustomerInsightUseCase(
      customer: customerById(customerId),
      transactions: transactionsFor(customerId),
    );
  }

  List<Customer> filteredCustomers({
    String query = '',
    CustomerFilter filter = CustomerFilter.all,
    CustomerSort sort = CustomerSort.name,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final snapshot = _visibleCustomers.where((customer) {
      final insight = insightFor(customer.id);
      final category = customer.category.toLowerCase();
      final matchesQuery =
          normalizedQuery.isEmpty ||
          customer.name.toLowerCase().contains(normalizedQuery) ||
          customer.phone.contains(normalizedQuery) ||
          category.contains(normalizedQuery) ||
          customer.tag.toLowerCase().contains(normalizedQuery) ||
          customer.address.toLowerCase().contains(normalizedQuery) ||
          customer.city.toLowerCase().contains(normalizedQuery) ||
          customer.cnic.contains(normalizedQuery) ||
          customer.groupName.toLowerCase().contains(normalizedQuery);

      if (!matchesQuery) {
        return false;
      }

      switch (filter) {
        case CustomerFilter.all:
          return true;
        case CustomerFilter.favourites:
          return customer.isFavourite;
        case CustomerFilter.overdue:
          return insight.balance > 0 && insight.overdueDays > 0;
        case CustomerFilter.risky:
          return insight.paymentChance == PaymentChance.low ||
              insight.isOverCreditLimit;
        case CustomerFilter.vip:
          return category == 'vip';
        case CustomerFilter.newProfiles:
          return DateTime.now().difference(customer.createdAt).inDays <= 30 ||
              category == 'new';
      }
    }).toList();

    snapshot.sort((left, right) {
      switch (sort) {
        case CustomerSort.name:
          if (left.isFavourite != right.isFavourite) {
            return left.isFavourite ? -1 : 1;
          }
          return left.name.toLowerCase().compareTo(right.name.toLowerCase());
        case CustomerSort.highestBalance:
          return insightFor(
            right.id,
          ).balance.compareTo(insightFor(left.id).balance);
        case CustomerSort.recoveryScore:
          return insightFor(
            left.id,
          ).recoveryScore.compareTo(insightFor(right.id).recoveryScore);
        case CustomerSort.lastReminder:
          final leftDate = left.lastReminderAt ?? DateTime(1970);
          final rightDate = right.lastReminderAt ?? DateTime(1970);
          return leftDate.compareTo(rightDate);
      }
    });

    return snapshot;
  }

  String formatCurrency(double value) => _currency.format(value);

  String displayCurrency(double value) {
    if (shouldHideBalances) {
      return '****';
    }
    return shouldHideBalances ? '••••' : formatCurrency(value);
  }

  String securityModeLabel() {
    if (_isDecoySession) {
      return 'Decoy mode active';
    }
    if (isSecurityEnabled) {
      return 'App lock active';
    }
    return 'Security off';
  }

  String partnerAccessRoleLabel(PartnerAccessRole role) {
    switch (role) {
      case PartnerAccessRole.viewer:
        return 'Viewer';
      case PartnerAccessRole.operator:
        return 'Operator';
      case PartnerAccessRole.manager:
        return 'Manager';
    }
  }

  String autoLockLabel(int minutes) {
    if (minutes <= 0) {
      return 'Never';
    }
    if (minutes == 1) {
      return '1 minute';
    }
    return '$minutes minutes';
  }

  String formatDate(DateTime value) => DateFormat('d MMM').format(value);

  String formatDateTime(DateTime value) =>
      DateFormat('d MMM, h:mm a').format(value);

  String urgencyLabel(UrgencyLevel urgency) {
    switch (urgency) {
      case UrgencyLevel.normal:
        return 'Normal';
      case UrgencyLevel.warning:
        return 'Warning';
      case UrgencyLevel.danger:
        return 'Urgent';
    }
  }

  String paymentChanceLabel(PaymentChance chance) {
    switch (chance) {
      case PaymentChance.high:
        return 'High';
      case PaymentChance.medium:
        return 'Medium';
      case PaymentChance.low:
        return 'Low';
    }
  }

  String reminderToneLabel(ReminderTone tone) {
    switch (tone) {
      case ReminderTone.soft:
        return 'soft reminder';
      case ReminderTone.normal:
        return 'normal reminder';
      case ReminderTone.strict:
        return 'urgent reminder';
    }
  }

  String transactionTypeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.credit:
        return creditLabel;
      case TransactionType.payment:
        return 'Payment';
    }
  }

  String staffPayTypeLabel(StaffPayType payType) {
    switch (payType) {
      case StaffPayType.daily:
        return 'Daily';
      case StaffPayType.monthly:
        return 'Monthly';
      case StaffPayType.hourly:
        return 'Hourly';
    }
  }

  String staffAttendanceStatusLabel(StaffAttendanceStatus status) {
    switch (status) {
      case StaffAttendanceStatus.present:
        return 'Present';
      case StaffAttendanceStatus.absent:
        return 'Absent';
      case StaffAttendanceStatus.halfDay:
        return 'Half day';
      case StaffAttendanceStatus.leave:
        return 'Leave';
    }
  }

  String reminderInboxTypeLabel(ReminderInboxType type) {
    switch (type) {
      case ReminderInboxType.scheduledReminder:
        return 'Scheduled';
      case ReminderInboxType.bulkReminder:
        return 'Bulk';
      case ReminderInboxType.promiseFollowUp:
        return 'Promise';
      case ReminderInboxType.installmentDue:
        return 'Installment';
      case ReminderInboxType.dailyAction:
        return 'Daily action';
      case ReminderInboxType.visitFollowUp:
        return 'Visit follow-up';
    }
  }

  String communityRiskLevelLabel(CommunityRiskLevel level) {
    switch (level) {
      case CommunityRiskLevel.watch:
        return 'Watch';
      case CommunityRiskLevel.blacklist:
        return 'Blacklist';
    }
  }

  String languageLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.romanUrdu:
        return 'Roman Urdu';
      case AppLanguage.urdu:
        return 'Urdu';
      case AppLanguage.sindhi:
        return 'Sindhi';
      case AppLanguage.pashto:
        return 'Pashto';
    }
  }

  String themeModeLabel(AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.system:
        return copy.systemModeLabel;
      case AppThemeMode.light:
        return copy.lightModeLabel;
      case AppThemeMode.dark:
        return copy.darkModeLabel;
    }
  }

  String customerFilterLabel(CustomerFilter filter) {
    switch (filter) {
      case CustomerFilter.all:
        return 'All';
      case CustomerFilter.favourites:
        return 'Favourites';
      case CustomerFilter.overdue:
        return 'Overdue';
      case CustomerFilter.risky:
        return 'Risky';
      case CustomerFilter.vip:
        return 'VIP';
      case CustomerFilter.newProfiles:
        return 'New';
    }
  }

  String customerSortLabel(CustomerSort sort) {
    switch (sort) {
      case CustomerSort.name:
        return 'By Name';
      case CustomerSort.highestBalance:
        return 'By Amount';
      case CustomerSort.recoveryScore:
        return 'Recovery Score';
      case CustomerSort.lastReminder:
        return 'Last Reminder';
    }
  }

  int shopCustomerCount(String shopId) =>
      _customers.where((customer) => customer.shopId == shopId).length;

  double shopOutstandingTotal(String shopId) {
    return _customers
        .where((customer) => customer.shopId == shopId)
        .fold<double>(
          0,
          (total, customer) => total + insightFor(customer.id).balance,
        );
  }

  Future<ShopProfile> saveShopProfile({
    String? shopId,
    required String name,
    required String phone,
    required UserType userType,
    String address = '',
    String email = '',
    String tagline = '',
    String ntn = '',
    String strn = '',
    String invoicePrefix = 'INV',
    String quotationPrefix = 'QTN',
    double salesTaxPercent = 0,
    bool activate = false,
  }) async {
    _ensureWritableSession();
    final normalizedName = name.trim().isEmpty
        ? 'Hisab Rakho Store'
        : name.trim();
    final normalizedPhone = phone.trim();
    final normalizedInvoicePrefix = invoicePrefix.trim().isEmpty
        ? 'INV'
        : invoicePrefix.trim().toUpperCase();
    final normalizedQuotationPrefix = quotationPrefix.trim().isEmpty
        ? 'QTN'
        : quotationPrefix.trim().toUpperCase();
    ShopProfile? existing;
    if (shopId != null) {
      for (final shop in _shops) {
        if (shop.id == shopId) {
          existing = shop;
          break;
        }
      }
    }
    final shop = existing == null
        ? ShopProfile(
            id: _makeShopId(),
            name: normalizedName,
            phone: normalizedPhone,
            userType: userType,
            createdAt: DateTime.now(),
            address: address.trim(),
            email: email.trim(),
            tagline: tagline.trim(),
            ntn: ntn.trim(),
            strn: strn.trim(),
            invoicePrefix: normalizedInvoicePrefix,
            quotationPrefix: normalizedQuotationPrefix,
            salesTaxPercent: salesTaxPercent < 0 ? 0 : salesTaxPercent,
          )
        : existing.copyWith(
            name: normalizedName,
            phone: normalizedPhone,
            userType: userType,
            address: address.trim(),
            email: email.trim(),
            tagline: tagline.trim(),
            ntn: ntn.trim(),
            strn: strn.trim(),
            invoicePrefix: normalizedInvoicePrefix,
            quotationPrefix: normalizedQuotationPrefix,
            salesTaxPercent: salesTaxPercent < 0 ? 0 : salesTaxPercent,
          );

    if (existing == null) {
      _shops = <ShopProfile>[..._shops, shop];
    } else {
      _shops = _shops.map((item) => item.id == shop.id ? shop : item).toList();
    }

    if (activate || activeShopId == shop.id || _shops.length == 1) {
      _settings = _settings.copyWith(
        activeShopId: shop.id,
        shopName: shop.name,
        organizationPhone: shop.phone,
        userType: shop.userType,
      );
    }

    await _persist();
    notifyListeners();
    return shop;
  }

  Future<void> switchActiveShop(String shopId) async {
    final target = _shops.firstWhere(
      (shop) => shop.id == shopId,
      orElse: () => activeShop,
    );
    _settings = _settings.copyWith(
      activeShopId: target.id,
      shopName: target.name,
      organizationPhone: target.phone,
      userType: target.userType,
    );
    await _persist();
    notifyListeners();
  }

  Future<Customer> addCustomer({
    required String name,
    required String phone,
    String category = '',
  }) {
    return upsertCustomer(name: name, phone: phone, category: category);
  }

  Future<Customer> upsertCustomer({
    String? customerId,
    required String name,
    required String phone,
    String category = 'Regular',
    String address = '',
    String notes = '',
    String tag = '',
    String city = '',
    String cnic = '',
    String? referredByCustomerId,
    String groupName = '',
    double? creditLimit,
    bool isFavourite = false,
    bool isHidden = false,
    List<int> seasonalPauseMonths = const <int>[],
    DateTime? promisedPaymentDate,
    double? promisedPaymentAmount,
  }) async {
    _ensureWritableSession();
    final existing = customerId == null ? null : customerById(customerId);
    final customer = existing == null
        ? Customer(
            id: _makeId(),
            shopId: activeShopId,
            shareCode: _makeShareCode(),
            name: name.trim(),
            phone: phone.trim(),
            createdAt: DateTime.now(),
            category: category.trim().isEmpty ? 'Regular' : category.trim(),
            address: address.trim(),
            notes: notes.trim(),
            tag: tag.trim(),
            city: city.trim(),
            cnic: cnic.trim(),
            referredByCustomerId: referredByCustomerId,
            groupName: groupName.trim(),
            creditLimit: creditLimit,
            isFavourite: isFavourite,
            isHidden: isHidden,
            seasonalPauseMonths: seasonalPauseMonths,
            promisedPaymentDate: promisedPaymentDate,
            promisedPaymentAmount: promisedPaymentAmount,
          )
        : existing.copyWith(
            shopId: existing.shopId,
            name: name.trim(),
            phone: phone.trim(),
            category: category.trim().isEmpty ? 'Regular' : category.trim(),
            address: address.trim(),
            notes: notes.trim(),
            tag: tag.trim(),
            city: city.trim(),
            cnic: cnic.trim(),
            referredByCustomerId: referredByCustomerId,
            groupName: groupName.trim(),
            creditLimit: creditLimit,
            isFavourite: isFavourite,
            isHidden: isHidden,
            seasonalPauseMonths: seasonalPauseMonths,
            promisedPaymentDate: promisedPaymentDate,
            promisedPaymentAmount: promisedPaymentAmount,
            clearCreditLimit: creditLimit == null,
            clearReferredByCustomerId: referredByCustomerId == null,
            clearPromisedPaymentDate: promisedPaymentDate == null,
            clearPromisedPaymentAmount: promisedPaymentAmount == null,
          );

    if (existing == null) {
      _customers = <Customer>[customer, ..._customers];
    } else {
      _customers = _customers
          .map((item) => item.id == customer.id ? customer : item)
          .toList();
    }

    await _syncPromiseFollowUp(customer);
    await _persist();
    notifyListeners();
    return customer;
  }

  Future<void> toggleFavourite(String customerId) async {
    _ensureWritableSession();
    _customers = _customers.map((customer) {
      if (customer.id != customerId) {
        return customer;
      }
      return customer.copyWith(isFavourite: !customer.isFavourite);
    }).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> setCustomerHidden(
    String customerId, {
    required bool hidden,
  }) async {
    _ensureWritableSession();
    _customers = _customers.map((customer) {
      if (customer.id != customerId) {
        return customer;
      }
      return customer.copyWith(isHidden: hidden);
    }).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> deleteCustomer(String customerId) async {
    _ensureWritableSession();
    final inboxToCancel = _reminderInbox
        .where((item) => item.customerId == customerId)
        .toList();
    _customers = _customers.where((customer) => customer.id != customerId).map((
      customer,
    ) {
      if (customer.referredByCustomerId != customerId) {
        return customer;
      }
      return customer.copyWith(clearReferredByCustomerId: true);
    }).toList();
    _transactions = _transactions
        .where((transaction) => transaction.customerId != customerId)
        .toList();
    _reminderLogs = _reminderLogs
        .where((log) => log.customerId != customerId)
        .toList();
    _reminderInbox = _reminderInbox
        .where((item) => item.customerId != customerId)
        .toList();
    _installmentPlans = _installmentPlans
        .where((plan) => plan.customerId != customerId)
        .toList();
    _customerVisits = _customerVisits
        .where((visit) => visit.customerId != customerId)
        .toList();
    _communityBlacklistEntries = _communityBlacklistEntries.map((entry) {
      if (entry.reportedCustomerId != customerId) {
        return entry;
      }
      return entry.copyWith(clearReportedCustomerId: true);
    }).toList();
    _saleRecords = _saleRecords.map((sale) {
      if (sale.customerId != customerId) {
        return sale;
      }
      return sale.copyWith(clearCustomerId: true);
    }).toList();
    for (final item in inboxToCancel) {
      await _localNotificationService?.cancel(item.notificationId);
    }
    await _persist();
    notifyListeners();
  }

  Future<CommunityBlacklistEntry> reportCustomerToCommunityBlacklist({
    required String customerId,
    required String reason,
    String note = '',
    CommunityRiskLevel riskLevel = CommunityRiskLevel.blacklist,
  }) async {
    _ensureWritableSession();
    if (!communityBlacklistEnabled) {
      throw StateError('Community blacklist is disabled.');
    }
    final customer = customerById(customerId);
    if (customer == null) {
      throw ArgumentError.value(customerId, 'customerId', 'Customer not found');
    }

    final normalizedReason = reason.trim();
    if (normalizedReason.isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'Reason is required');
    }

    CommunityBlacklistEntry? existing;
    for (final entry in _communityBlacklistEntries) {
      if (entry.shopId == activeShopId &&
          entry.reportedCustomerId == customerId &&
          entry.reason.trim().toLowerCase() == normalizedReason.toLowerCase()) {
        existing = entry;
        break;
      }
    }

    final blacklistEntry = existing == null
        ? CommunityBlacklistEntry(
            id: _makeId(),
            shopId: activeShopId,
            reportedCustomerId: customer.id,
            customerName: customer.name,
            phone: customer.phone,
            city: customer.city,
            cnic: customer.cnic,
            reason: normalizedReason,
            note: note.trim(),
            createdAt: DateTime.now(),
            riskLevel: riskLevel,
          )
        : existing.copyWith(
            reportedCustomerId: customer.id,
            customerName: customer.name,
            phone: customer.phone,
            city: customer.city,
            cnic: customer.cnic,
            reason: normalizedReason,
            note: note.trim(),
            createdAt: DateTime.now(),
            riskLevel: riskLevel,
          );

    if (existing == null) {
      _communityBlacklistEntries = <CommunityBlacklistEntry>[
        blacklistEntry,
        ..._communityBlacklistEntries,
      ];
    } else {
      _communityBlacklistEntries = _communityBlacklistEntries
          .map(
            (entry) => entry.id == blacklistEntry.id ? blacklistEntry : entry,
          )
          .toList();
    }

    await _persist();
    notifyListeners();
    return blacklistEntry;
  }

  Future<Supplier> saveSupplier({
    String? supplierId,
    required String name,
    String phone = '',
    String notes = '',
  }) async {
    _ensureWritableSession();
    final existing = supplierId == null ? null : supplierById(supplierId);
    final supplier = existing == null
        ? Supplier(
            id: _makeId(),
            shopId: activeShopId,
            name: name.trim(),
            phone: phone.trim(),
            createdAt: DateTime.now(),
            notes: notes.trim(),
          )
        : existing.copyWith(
            name: name.trim(),
            phone: phone.trim(),
            notes: notes.trim(),
          );

    if (existing == null) {
      _suppliers = <Supplier>[supplier, ..._suppliers];
    } else {
      _suppliers = _suppliers
          .map((item) => item.id == supplier.id ? supplier : item)
          .toList();
    }

    await _persist();
    notifyListeners();
    return supplier;
  }

  Future<InventoryItem> saveInventoryItem({
    String? inventoryItemId,
    required String name,
    String sku = '',
    String barcode = '',
    String unit = 'pcs',
    int stockQuantity = 0,
    int reorderLevel = 0,
    double costPrice = 0,
    double salePrice = 0,
    String supplierId = '',
    String notes = '',
    bool isArchived = false,
  }) async {
    _ensureWritableSession();
    final existing = inventoryItemId == null
        ? null
        : inventoryItemById(inventoryItemId);
    final item = existing == null
        ? InventoryItem(
            id: _makeId(),
            shopId: activeShopId,
            name: name.trim(),
            createdAt: DateTime.now(),
            sku: sku.trim(),
            barcode: barcode.trim(),
            unit: unit.trim().isEmpty ? 'pcs' : unit.trim(),
            stockQuantity: max(0, stockQuantity),
            reorderLevel: max(0, reorderLevel),
            costPrice: max(0, costPrice),
            salePrice: max(0, salePrice),
            supplierId: supplierId.trim(),
            notes: notes.trim(),
            isArchived: isArchived,
          )
        : existing.copyWith(
            name: name.trim(),
            sku: sku.trim(),
            barcode: barcode.trim(),
            unit: unit.trim().isEmpty ? 'pcs' : unit.trim(),
            stockQuantity: max(0, stockQuantity),
            reorderLevel: max(0, reorderLevel),
            costPrice: max(0, costPrice),
            salePrice: max(0, salePrice),
            supplierId: supplierId.trim(),
            notes: notes.trim(),
            isArchived: isArchived,
          );

    if (existing == null) {
      _inventoryItems = <InventoryItem>[item, ..._inventoryItems];
    } else {
      _inventoryItems = _inventoryItems
          .map((entry) => entry.id == item.id ? item : entry)
          .toList();
    }

    await _persist();
    notifyListeners();
    return item;
  }

  Future<WholesaleListing> saveWholesaleListing({
    String? listingId,
    required String title,
    required double price,
    String category = '',
    String unit = 'pcs',
    int minQuantity = 1,
    String phone = '',
    String note = '',
    bool isActive = true,
  }) async {
    _ensureWritableSession();
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw ArgumentError('Listing title is required.');
    }
    if (price <= 0) {
      throw ArgumentError('Listing price must be greater than zero.');
    }

    final existing = listingId == null
        ? null
        : _wholesaleListings.firstWhere(
            (entry) => entry.id == listingId,
            orElse: () => throw ArgumentError('Wholesale listing not found.'),
          );
    final listing =
        existing?.copyWith(
          title: normalizedTitle,
          price: price,
          category: category.trim(),
          unit: unit.trim().isEmpty ? 'pcs' : unit.trim(),
          minQuantity: max(1, minQuantity),
          phone: phone.trim(),
          note: note.trim(),
          isActive: isActive,
        ) ??
        WholesaleListing(
          id: _makeId(),
          shopId: activeShopId,
          title: normalizedTitle,
          price: price,
          createdAt: DateTime.now(),
          category: category.trim(),
          unit: unit.trim().isEmpty ? 'pcs' : unit.trim(),
          minQuantity: max(1, minQuantity),
          phone: phone.trim(),
          note: note.trim(),
          isActive: isActive,
        );

    _wholesaleListings = <WholesaleListing>[
      for (final entry in _wholesaleListings)
        if (entry.id != listing.id) entry,
      listing,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    await _persist();
    notifyListeners();
    return listing;
  }

  Future<void> removeWholesaleListing(String listingId) async {
    _ensureWritableSession();
    final hadListing = _wholesaleListings.any((entry) => entry.id == listingId);
    if (!hadListing) {
      return;
    }
    _wholesaleListings = _wholesaleListings
        .where((entry) => entry.id != listingId)
        .toList();
    await _persist();
    notifyListeners();
  }

  String buildWholesaleListingShareText(WholesaleListing listing) {
    final shop = shopById(listing.shopId) ?? activeShop;
    final parts = <String>[
      '${shop.name} wholesale offer',
      listing.title,
      'Rate: ${formatCurrency(listing.price)} per ${listing.unit}',
      'Minimum quantity: ${listing.minQuantity} ${listing.unit}',
      if (listing.category.trim().isNotEmpty) 'Category: ${listing.category}',
      if (listing.note.trim().isNotEmpty) 'Details: ${listing.note}',
      if (listing.phone.trim().isNotEmpty)
        'Contact: ${listing.phone.trim()}'
      else if (shop.phone.trim().isNotEmpty)
        'Contact: ${shop.phone.trim()}',
    ];
    return parts.join('\n');
  }

  Future<SupplierLedgerEntry> recordSupplierPurchase({
    required String supplierId,
    String inventoryItemId = '',
    int quantity = 0,
    double unitCost = 0,
    String note = '',
    DateTime? date,
  }) async {
    _ensureWritableSession();
    final supplier = supplierById(supplierId);
    if (supplier == null) {
      throw ArgumentError('Supplier not found.');
    }
    if (quantity <= 0 || unitCost <= 0) {
      throw ArgumentError('Quantity and unit cost must be greater than zero.');
    }

    final amount = quantity * unitCost;
    if (inventoryItemId.trim().isNotEmpty) {
      final item = inventoryItemById(inventoryItemId);
      if (item == null) {
        throw ArgumentError('Inventory item not found.');
      }
      _inventoryItems = _inventoryItems.map((entry) {
        if (entry.id != item.id) {
          return entry;
        }
        return entry.copyWith(
          stockQuantity: entry.stockQuantity + quantity,
          costPrice: unitCost,
          supplierId: supplierId,
        );
      }).toList();
    }

    final entry = SupplierLedgerEntry(
      id: _makeId(),
      shopId: activeShopId,
      supplierId: supplierId,
      amount: amount,
      type: SupplierEntryType.purchase,
      date: date ?? DateTime.now(),
      note: note.trim(),
      inventoryItemId: inventoryItemId.trim(),
      quantity: quantity,
      unitCost: unitCost,
    );
    _supplierLedgerEntries = <SupplierLedgerEntry>[
      entry,
      ..._supplierLedgerEntries,
    ]..sort((a, b) => b.date.compareTo(a.date));

    await _persist();
    notifyListeners();
    return entry;
  }

  Future<SupplierLedgerEntry> recordSupplierPayment({
    required String supplierId,
    required double amount,
    String note = '',
    DateTime? date,
  }) async {
    _ensureWritableSession();
    final supplier = supplierById(supplierId);
    if (supplier == null) {
      throw ArgumentError('Supplier not found.');
    }
    if (amount <= 0) {
      throw ArgumentError('Payment amount must be greater than zero.');
    }

    final entry = SupplierLedgerEntry(
      id: _makeId(),
      shopId: activeShopId,
      supplierId: supplierId,
      amount: amount,
      type: SupplierEntryType.payment,
      date: date ?? DateTime.now(),
      note: note.trim(),
    );
    _supplierLedgerEntries = <SupplierLedgerEntry>[
      entry,
      ..._supplierLedgerEntries,
    ]..sort((a, b) => b.date.compareTo(a.date));

    await _persist();
    notifyListeners();
    return entry;
  }

  Future<SaleRecord> recordCashSale({
    required List<SaleLineItem> lineItems,
    String note = '',
    DateTime? date,
  }) async {
    _ensureWritableSession();
    final normalizedLineItems = _normalizeSaleLineItems(lineItems);
    _applySaleStockDeductions(normalizedLineItems);
    final sale = SaleRecord(
      id: _makeId(),
      shopId: activeShopId,
      type: SaleRecordType.cash,
      date: date ?? DateTime.now(),
      lineItems: normalizedLineItems,
      note: note.trim(),
    );
    _saleRecords = <SaleRecord>[sale, ..._saleRecords]
      ..sort((a, b) => b.date.compareTo(a.date));

    await _persist();
    notifyListeners();
    return sale;
  }

  Future<SaleRecord> recordInventorySaleAsUdhaar({
    required String customerId,
    required List<SaleLineItem> lineItems,
    String note = '',
    DateTime? date,
    DateTime? dueDate,
  }) async {
    _ensureWritableSession();
    final customer = customerById(customerId);
    if (customer == null) {
      throw ArgumentError('Customer not found.');
    }

    final normalizedLineItems = _normalizeSaleLineItems(lineItems);
    _applySaleStockDeductions(normalizedLineItems);
    final saleId = _makeId();
    final saleDate = date ?? DateTime.now();
    final noteText = note.trim().isEmpty
        ? 'POS sale converted to udhaar'
        : note.trim();
    final transaction = LedgerTransaction(
      id: _makeId(),
      customerId: customerId,
      shopId: activeShopId,
      amount: normalizedLineItems.fold<double>(
        0,
        (total, item) => total + item.lineTotal,
      ),
      type: TransactionType.credit,
      note: noteText,
      date: saleDate,
      dueDate: dueDate,
      reference: saleId,
      attachmentLabel: 'Inventory sale',
    );
    _transactions = <LedgerTransaction>[transaction, ..._transactions]
      ..sort((a, b) => b.date.compareTo(a.date));
    await _syncTransactionDueReminder(transaction);

    final sale = SaleRecord(
      id: saleId,
      shopId: activeShopId,
      type: SaleRecordType.udhaar,
      date: saleDate,
      lineItems: normalizedLineItems,
      customerId: customerId,
      note: noteText,
      linkedTransactionId: transaction.id,
    );
    _saleRecords = <SaleRecord>[sale, ..._saleRecords]
      ..sort((a, b) => b.date.compareTo(a.date));

    await _persist();
    notifyListeners();
    return sale;
  }

  Future<void> addUdhaar({
    required String customerId,
    required double amount,
    required String note,
    DateTime? dueDate,
    DateTime? date,
    String reference = '',
    String attachmentLabel = '',
    String receiptPath = '',
    String audioNotePath = '',
  }) async {
    _ensureWritableSession();
    final customer = customerById(customerId);
    final transaction = LedgerTransaction(
      id: _makeId(),
      customerId: customerId,
      shopId: customer?.shopId ?? activeShopId,
      amount: amount,
      type: TransactionType.credit,
      note: note.isEmpty ? entryLabel : note.trim(),
      date: date ?? DateTime.now(),
      dueDate: dueDate,
      reference: reference.trim(),
      attachmentLabel: attachmentLabel.trim(),
      receiptPath: receiptPath.trim(),
      audioNotePath: audioNotePath.trim(),
    );
    _transactions = <LedgerTransaction>[transaction, ..._transactions];
    _recalculateCustomerTransactionStatuses(customerId);
    await _syncTransactionDueReminder(transaction);
    await _persist();
    notifyListeners();
  }

  Future<void> recordPayment({
    required String customerId,
    required double amount,
    String note = 'Adaigi receive hui',
    DateTime? date,
    String reference = '',
    String attachmentLabel = '',
    String receiptPath = '',
    String audioNotePath = '',
  }) async {
    _ensureWritableSession();
    final customer = customerById(customerId);
    final paymentDate = date ?? DateTime.now();
    final existingIds = _transactions.map((entry) => entry.id).toSet();
    _transactions =
        _applyPaymentUseCase(
            transactions: _transactions,
            customerId: customerId,
            shopId: customer?.shopId ?? activeShopId,
            amount: amount,
            paymentId: _makeId(),
            paymentDate: paymentDate,
            note: note,
          ).map((entry) {
            if (existingIds.contains(entry.id)) {
              return entry;
            }
            return entry.copyWith(
              reference: reference.trim(),
              attachmentLabel: attachmentLabel.trim(),
              receiptPath: receiptPath.trim(),
              audioNotePath: audioNotePath.trim(),
            );
          }).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    await _clearSettledTransactionReminders(customerId);
    await _persist();
    notifyListeners();
  }

  Future<void> updateTransaction({
    required String transactionId,
    required double amount,
    required String note,
    required DateTime date,
    DateTime? dueDate,
    String reference = '',
    String attachmentLabel = '',
    String receiptPath = '',
    String audioNotePath = '',
    bool? isDisputed,
  }) async {
    _ensureWritableSession();
    final existing = transactionById(transactionId);
    if (existing == null) {
      return;
    }

    final normalizedReceiptPath = receiptPath.trim();
    final normalizedAudioNotePath = audioNotePath.trim();
    final updated = existing.copyWith(
      amount: amount,
      note: note.trim().isEmpty
          ? existing.type == TransactionType.credit
                ? entryLabel
                : 'Adaigi receive hui'
          : note.trim(),
      date: date,
      dueDate: dueDate,
      reference: reference.trim(),
      attachmentLabel: attachmentLabel.trim(),
      receiptPath: normalizedReceiptPath,
      audioNotePath: normalizedAudioNotePath,
      isDisputed: isDisputed,
      clearDueDate: existing.type != TransactionType.credit || dueDate == null,
      clearPaidOnTime: true,
      clearReceiptPath: normalizedReceiptPath.isEmpty,
      clearAudioNotePath: normalizedAudioNotePath.isEmpty,
    );

    _transactions = _transactions
        .map(
          (transaction) => transaction.id == updated.id ? updated : transaction,
        )
        .toList();
    _recalculateCustomerTransactionStatuses(updated.customerId);
    await _syncTransactionDueReminder(updated);
    await _persist();
    notifyListeners();
  }

  Future<void> deleteTransaction(String transactionId) async {
    _ensureWritableSession();
    final existing = transactionById(transactionId);
    if (existing == null) {
      return;
    }
    _transactions = _transactions
        .where((transaction) => transaction.id != transactionId)
        .toList();
    _recalculateCustomerTransactionStatuses(existing.customerId);
    await _clearPendingReminderInboxByReferenceId(existing.id);
    await _clearSettledTransactionReminders(existing.customerId);
    await _persist();
    notifyListeners();
  }

  Future<void> setTransactionDispute(
    String transactionId, {
    required bool isDisputed,
  }) async {
    _ensureWritableSession();
    final existing = transactionById(transactionId);
    if (existing == null) {
      return;
    }
    _transactions = _transactions.map((transaction) {
      if (transaction.id != transactionId) {
        return transaction;
      }
      return transaction.copyWith(isDisputed: isDisputed);
    }).toList();
    await _persist();
    notifyListeners();
  }

  bool willExceedCreditLimit(String customerId, double nextAmount) {
    final customer = customerById(customerId);
    final limit = customer?.creditLimit;
    if (limit == null) {
      return false;
    }
    return insightFor(customerId).balance + nextAmount > limit;
  }

  String? creditLimitWarning(String customerId, double nextAmount) {
    if (!willExceedCreditLimit(customerId, nextAmount)) {
      return null;
    }
    final customer = customerById(customerId);
    final limit = customer?.creditLimit ?? 0;
    final totalAfter = insightFor(customerId).balance + nextAmount;
    return '${customer?.name ?? entitySingularLabel} ka limit ${formatCurrency(limit)} hai. '
        'Is entry ke baad total ${formatCurrency(totalAfter)} ho jayega.';
  }

  bool isValidSecurityPin(String pin) {
    final normalized = pin.trim();
    return RegExp(r'^\d{4,6}$').hasMatch(normalized);
  }

  Future<void> setSecurityPin(String pin) async {
    if (!isValidSecurityPin(pin)) {
      throw ArgumentError.value(pin, 'pin', 'Use a 4 to 6 digit PIN.');
    }
    if (_matchesConfiguredPin(
      pin: pin,
      hash: _settings.decoyPinHash,
      salt: _settings.decoyPinSalt,
    )) {
      throw ArgumentError.value(
        pin,
        'pin',
        'Main PIN must be different from the decoy PIN.',
      );
    }
    final salt = _makePinSalt();
    _settings = _settings.copyWith(
      pinHash: _hashPin(pin, salt: salt),
      pinSalt: salt,
      appLockEnabled: true,
    );
    _isAppUnlocked = true;
    _isDecoySession = false;
    await _persist();
    notifyListeners();
  }

  Future<void> clearSecurityPin() async {
    _settings = _settings.copyWith(
      appLockEnabled: false,
      biometricUnlockEnabled: false,
      clearPinHash: true,
      clearPinSalt: true,
    );
    _isAppUnlocked = true;
    _isDecoySession = false;
    await _persist();
    notifyListeners();
  }

  Future<void> setDecoyPin(String pin) async {
    if (!isValidSecurityPin(pin)) {
      throw ArgumentError.value(pin, 'pin', 'Use a 4 to 6 digit PIN.');
    }
    if (_matchesConfiguredPin(
      pin: pin,
      hash: _settings.pinHash,
      salt: _settings.pinSalt,
    )) {
      throw ArgumentError.value(
        pin,
        'pin',
        'Decoy PIN must be different from the main PIN.',
      );
    }
    final salt = _makePinSalt();
    _settings = _settings.copyWith(
      decoyPinHash: _hashPin(pin, salt: salt),
      decoyPinSalt: salt,
      decoyModeEnabled: true,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> clearDecoyPin() async {
    _settings = _settings.copyWith(
      decoyModeEnabled: false,
      clearDecoyPinHash: true,
      clearDecoyPinSalt: true,
    );
    _isDecoySession = false;
    await _persist();
    notifyListeners();
  }

  Future<void> lockApp() async {
    if (!isSecurityEnabled) {
      return;
    }
    _isAppUnlocked = false;
    _isDecoySession = false;
    notifyListeners();
  }

  bool unlockWithPin(String pin) {
    if (_matchesConfiguredPin(
      pin: pin,
      hash: _settings.pinHash,
      salt: _settings.pinSalt,
    )) {
      _isAppUnlocked = true;
      _isDecoySession = false;
      _upgradeStoredPinHashIfNeeded(
        pin,
        currentHash: _settings.pinHash,
        currentSalt: _settings.pinSalt,
        decoy: false,
      );
      notifyListeners();
      return true;
    }
    if (hasDecoyPinConfigured &&
        _matchesConfiguredPin(
          pin: pin,
          hash: _settings.decoyPinHash,
          salt: _settings.decoyPinSalt,
        )) {
      _isAppUnlocked = true;
      _isDecoySession = true;
      _upgradeStoredPinHashIfNeeded(
        pin,
        currentHash: _settings.decoyPinHash,
        currentSalt: _settings.decoyPinSalt,
        decoy: true,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<PartnerAccessProfile> savePartnerAccess({
    String? profileId,
    required String name,
    String phone = '',
    String email = '',
    required PartnerAccessRole role,
    bool canViewHiddenProfiles = false,
    bool canExportReports = false,
    bool isActive = true,
  }) async {
    _ensureWritableSession();
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Partner name is required.');
    }

    final existing = profileId == null
        ? null
        : _partnerAccessProfiles.firstWhere(
            (entry) => entry.id == profileId,
            orElse: () => throw ArgumentError.value(
              profileId,
              'profileId',
              'Partner profile not found.',
            ),
          );

    final profile =
        existing?.copyWith(
          name: normalizedName,
          phone: phone.trim(),
          email: email.trim(),
          role: role,
          canViewHiddenProfiles: canViewHiddenProfiles,
          canExportReports: canExportReports,
          isActive: isActive,
        ) ??
        PartnerAccessProfile(
          id: _makeId(),
          shopId: activeShopId,
          name: normalizedName,
          createdAt: DateTime.now(),
          phone: phone.trim(),
          email: email.trim(),
          role: role,
          inviteCode: _makePartnerInviteCode(),
          canViewHiddenProfiles: canViewHiddenProfiles,
          canExportReports: canExportReports,
          isActive: isActive,
        );

    _partnerAccessProfiles = <PartnerAccessProfile>[
      for (final entry in _partnerAccessProfiles)
        if (entry.id != profile.id) entry,
      profile,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    await _persist();
    notifyListeners();
    return profile;
  }

  Future<void> removePartnerAccess(String profileId) async {
    _ensureWritableSession();
    final hadProfile = _partnerAccessProfiles.any(
      (profile) => profile.id == profileId,
    );
    if (!hadProfile) {
      return;
    }
    _partnerAccessProfiles = _partnerAccessProfiles
        .where((profile) => profile.id != profileId)
        .toList();
    await _persist();
    notifyListeners();
  }

  void unlockWithBiometrics() {
    if (!isSecurityEnabled) {
      return;
    }
    _isAppUnlocked = true;
    _isDecoySession = false;
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings value) async {
    _ensureWritableSession();
    final wasSecurityEnabled = isSecurityEnabled;
    final normalizedWorkspaceId = _normalizeCloudWorkspaceId(
      value.cloudWorkspaceId,
    );
    _settings = value.copyWith(
      language: AppLanguage.english,
      cloudWorkspaceId: normalizedWorkspaceId,
      cloudDeviceLabel: value.cloudDeviceLabel.trim(),
      clearCloudSyncLastError: value.cloudSyncLastError.trim().isEmpty,
    );
    if (_shops.isEmpty) {
      _shops = <ShopProfile>[
        ShopProfile(
          id: value.activeShopId,
          name: value.shopName,
          phone: value.organizationPhone,
          userType: value.userType,
          createdAt: DateTime.now(),
        ),
      ];
    } else {
      _shops = _shops.map((shop) {
        if (shop.id != value.activeShopId) {
          return shop;
        }
        return shop.copyWith(
          name: value.shopName,
          phone: value.organizationPhone,
          userType: value.userType,
        );
      }).toList();
    }
    if (!isSecurityEnabled) {
      _isAppUnlocked = true;
      _isDecoySession = false;
    } else if (!wasSecurityEnabled) {
      _isAppUnlocked = true;
      _isDecoySession = false;
    }
    await _persist();
    if (normalizedWorkspaceId.isEmpty || !_settings.cloudSyncEnabled) {
      _cloudBackups = <CloudBackupManifest>[];
    } else if (_cloudSyncReady) {
      try {
        _cloudBackups = await _cloudBackupService!.listBackups(
          workspaceId: normalizedWorkspaceId,
          limit: 8,
        );
      } catch (_) {
        _cloudBackups = <CloudBackupManifest>[];
      }
    }
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required UserType userType,
    required String organizationName,
    required String organizationPhone,
    required AppLanguage language,
    required AppThemeMode themeMode,
    List<ShopDraft> additionalShops = const <ShopDraft>[],
  }) async {
    final primaryName = organizationName.trim().isEmpty
        ? 'Hisab Rakho'
        : organizationName.trim();
    final primaryShop = ShopProfile(
      id: activeShopId,
      name: primaryName,
      phone: organizationPhone.trim(),
      userType: userType,
      createdAt: DateTime.now(),
    );
    _shops = <ShopProfile>[
      primaryShop,
      ...additionalShops
          .where((draft) => draft.name.trim().isNotEmpty)
          .map(
            (draft) => ShopProfile(
              id: _makeShopId(),
              name: draft.name.trim(),
              phone: draft.phone.trim(),
              userType: draft.userType,
              createdAt: DateTime.now(),
            ),
          ),
    ];
    _settings = _settings.copyWith(
      shopName: primaryShop.name,
      organizationPhone: primaryShop.phone,
      userType: primaryShop.userType,
      language: AppLanguage.english,
      themeMode: themeMode,
      activeShopId: primaryShop.id,
      hasCompletedOnboarding: true,
    );
    await _persist();
    notifyListeners();
  }

  String generateReminderMessage(
    Customer customer, {
    ReminderTone tone = ReminderTone.normal,
  }) {
    final insight = insightFor(customer.id);
    return _buildReminderMessageUseCase(
      customer: customer,
      insight: insight,
      terminology: terminology,
      formattedAmount: formatCurrency(insight.balance),
      shopName: _settings.shopName,
      tone: tone,
    );
  }

  String generatePaymentConfirmationMessage(
    Customer customer,
    double amount, {
    double? remainingBalance,
  }) {
    final remaining = remainingBalance ?? insightFor(customer.id).balance;
    if (remaining <= 0) {
      return 'Assalamualaikum ${customer.name}! '
          'Aap ka poora ${terminology.reminderSubject} ${formatCurrency(amount)} receive ho gaya. '
          'Shukriya! - ${_settings.shopName}';
    }

    return 'Assalamualaikum ${customer.name}, '
        '${formatCurrency(amount)} receive ho gaye. '
        'Baqi ${terminology.reminderSubject}: ${formatCurrency(remaining)}. '
        '- ${_settings.shopName}';
  }

  String generateWhatsAppLink(
    String phone,
    String name,
    double amount, {
    ReminderTone tone = ReminderTone.normal,
    String? customerId,
    String? customMessage,
  }) {
    final targetCustomer = customerId == null ? null : customerById(customerId);
    final message =
        customMessage ??
        (targetCustomer == null
            ? 'Dear $name, your ${terminology.reminderSubject} of ${formatCurrency(amount)} is pending. Kindly clear it.\n- ${_settings.shopName}'
            : generateReminderMessage(targetCustomer, tone: tone));
    final encodedMessage = Uri.encodeComponent(message);
    return 'https://wa.me/${_normalizePakPhone(phone)}?text=$encodedMessage';
  }

  Uri generateSmsUri(String phone, String message) {
    return Uri(
      scheme: 'sms',
      path: _normalizePakPhone(phone),
      queryParameters: <String, String>{'body': message},
    );
  }

  Future<bool> sendCustomReminder(
    Customer customer, {
    required String message,
    required ReminderTone tone,
    String channel = 'whatsapp',
  }) async {
    _ensureWritableSession();
    final launched = await _launchReminderChannel(
      customer: customer,
      tone: tone,
      channel: channel,
      customMessage: message,
    );
    await _recordReminder(
      customerId: customer.id,
      message: message,
      tone: tone,
      channel: channel,
      wasSuccessful: launched,
    );
    if (launched) {
      await _markReminderSent(customer.id);
    }
    return launched;
  }

  Future<bool> sendReminder(Customer customer, {ReminderTone? tone}) async {
    final insight = insightFor(customer.id);
    if (insight.balance <= 0) {
      return false;
    }

    final selectedTone = tone ?? insight.recommendedTone;
    final message = generateReminderMessage(customer, tone: selectedTone);
    return sendCustomReminder(customer, message: message, tone: selectedTone);
  }

  Future<bool> sendPaymentConfirmation(
    Customer customer, {
    required double amount,
  }) async {
    final message = generatePaymentConfirmationMessage(customer, amount);
    return sendCustomReminder(
      customer,
      message: message,
      tone: ReminderTone.soft,
      channel: 'payment_confirmation',
    );
  }

  Future<BulkReminderResult> sendAllReminders() async {
    final pending = customersWithPendingBalance;
    final allowed = _settings.isPaidUser
        ? pending.length
        : min(3, pending.length);
    var opened = 0;

    for (final customer in pending.take(allowed)) {
      final launched = await sendReminder(customer);
      if (launched) {
        opened += 1;
      }
      await Future<void>.delayed(const Duration(milliseconds: 900));
    }

    return BulkReminderResult(
      opened: opened,
      totalEligible: pending.length,
      limitedByPlan: !_settings.isPaidUser && pending.length > allowed,
    );
  }

  Future<BulkReminderResult> sendGroupReminders(
    String groupName, {
    ReminderTone? tone,
  }) async {
    final groupCustomers = groupedCustomers(
      groupName,
    ).where((customer) => insightFor(customer.id).balance > 0).toList();
    final allowed = _settings.isPaidUser
        ? groupCustomers.length
        : min(3, groupCustomers.length);
    var opened = 0;

    for (final customer in groupCustomers.take(allowed)) {
      final launched = await sendReminder(customer, tone: tone);
      if (launched) {
        opened += 1;
      }
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }

    return BulkReminderResult(
      opened: opened,
      totalEligible: groupCustomers.length,
      limitedByPlan: !_settings.isPaidUser && groupCustomers.length > allowed,
    );
  }

  Future<ReminderInboxItem> scheduleReminderFollowUp({
    required String customerId,
    required DateTime dueAt,
    ReminderTone? tone,
    String? message,
    ReminderInboxType type = ReminderInboxType.scheduledReminder,
    String channel = 'whatsapp',
    String note = '',
    String referenceId = '',
  }) async {
    _ensureWritableSession();
    final customer = customerById(customerId);
    if (customer == null) {
      throw ArgumentError.value(customerId, 'customerId', 'Customer not found');
    }

    final selectedTone = tone ?? insightFor(customerId).recommendedTone;
    final reminderMessage =
        message ?? generateReminderMessage(customer, tone: selectedTone);
    final item = ReminderInboxItem(
      id: _makeId(),
      customerId: customerId,
      title: _scheduleTitleFor(customer, type),
      message: reminderMessage,
      tone: selectedTone,
      type: type,
      status: ReminderInboxStatus.pending,
      createdAt: DateTime.now(),
      dueAt: dueAt,
      notificationId: _makeNotificationId(),
      referenceId: referenceId,
      channel: channel,
      note: note,
    );

    _reminderInbox = <ReminderInboxItem>[item, ..._reminderInbox]
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    await _localNotificationService?.scheduleReminder(
      id: item.notificationId,
      title: item.title,
      body: item.message,
      scheduledAt: dueAt,
    );
    await _persist();
    notifyListeners();
    return item;
  }

  Future<bool> openReminderInboxItem(String reminderInboxId) async {
    _ensureWritableSession();
    final item = reminderInboxById(reminderInboxId);
    if (item == null) {
      return false;
    }
    final customer = customerById(item.customerId);
    if (customer == null) {
      await completeReminderInboxItem(reminderInboxId);
      return false;
    }

    final launched = await sendCustomReminder(
      customer,
      message: item.message,
      tone: item.tone,
      channel: item.channel,
    );

    if (launched) {
      await _localNotificationService?.cancel(item.notificationId);
      _reminderInbox = _reminderInbox.map((entry) {
        if (entry.id != item.id) {
          return entry;
        }
        return entry.copyWith(
          status: ReminderInboxStatus.opened,
          handledAt: DateTime.now(),
        );
      }).toList();
      await _persist();
      notifyListeners();
    }

    return launched;
  }

  Future<void> skipReminderInboxItem(String reminderInboxId) async {
    _ensureWritableSession();
    final item = reminderInboxById(reminderInboxId);
    if (item == null) {
      return;
    }
    await _localNotificationService?.cancel(item.notificationId);
    _reminderInbox = _reminderInbox.map((entry) {
      if (entry.id != reminderInboxId) {
        return entry;
      }
      return entry.copyWith(
        status: ReminderInboxStatus.skipped,
        handledAt: DateTime.now(),
      );
    }).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> completeReminderInboxItem(String reminderInboxId) async {
    _ensureWritableSession();
    final item = reminderInboxById(reminderInboxId);
    if (item == null) {
      return;
    }
    await _localNotificationService?.cancel(item.notificationId);
    _reminderInbox = _reminderInbox.map((entry) {
      if (entry.id != reminderInboxId) {
        return entry;
      }
      return entry.copyWith(
        status: ReminderInboxStatus.completed,
        handledAt: DateTime.now(),
      );
    }).toList();
    await _persist();
    notifyListeners();
  }

  Future<CustomerVisit> logCustomerVisit({
    required String customerId,
    String note = '',
    DateTime? followUpAt,
    ReminderTone? tone,
    String locationLabel = '',
    double? latitude,
    double? longitude,
  }) async {
    _ensureWritableSession();
    final customer = customerById(customerId);
    if (customer == null) {
      throw ArgumentError.value(customerId, 'customerId', 'Customer not found');
    }

    final visit = CustomerVisit(
      id: _makeId(),
      customerId: customerId,
      visitedAt: DateTime.now(),
      note: note.trim(),
      followUpDueAt: followUpAt,
      locationLabel: locationLabel.trim(),
      latitude: latitude,
      longitude: longitude,
    );
    _customerVisits = <CustomerVisit>[visit, ..._customerVisits]
      ..sort((a, b) => b.visitedAt.compareTo(a.visitedAt));

    if (followUpAt != null) {
      final insight = insightFor(customerId);
      await scheduleReminderFollowUp(
        customerId: customerId,
        dueAt: followUpAt,
        tone: tone ?? insight.recommendedTone,
        type: ReminderInboxType.visitFollowUp,
        referenceId: 'visit_${visit.id}',
        note: note.trim().isEmpty ? 'Visit follow-up' : note.trim(),
        message:
            'Assalamualaikum ${customer.name}, aaj ki mulaqat ke hawale se yaad dehani hai ke ${formatCurrency(insight.balance)} ${terminology.reminderSubject} abhi pending hai. Meherbani kar ke payment update share kar dein.\n- ${_settings.shopName}',
      );
      return visit;
    }

    await _persist();
    notifyListeners();
    return visit;
  }

  Future<InstallmentPlan> createInstallmentPlan({
    required String customerId,
    required double totalAmount,
    required int installmentCount,
    required int intervalDays,
    required DateTime firstDueDate,
    String note = '',
  }) async {
    _ensureWritableSession();
    final existingPlans = installmentPlansFor(customerId);
    for (final existing in existingPlans) {
      if (!existing.isCompleted) {
        await _markPendingReminderInboxItemsByReferenceId(
          existing.id,
          status: ReminderInboxStatus.skipped,
        );
      }
    }
    _installmentPlans = _installmentPlans.map((plan) {
      if (existingPlans.any((existing) => existing.id == plan.id) &&
          !plan.isCompleted) {
        return plan.copyWith(isPaused: true);
      }
      return plan;
    }).toList();

    final plan = InstallmentPlan(
      id: _makeId(),
      customerId: customerId,
      totalAmount: totalAmount,
      installmentAmount: totalAmount / installmentCount,
      installmentCount: installmentCount,
      completedInstallments: 0,
      intervalDays: intervalDays,
      createdAt: DateTime.now(),
      firstDueDate: firstDueDate,
      nextDueDate: firstDueDate,
      note: note.trim(),
    );
    _installmentPlans = <InstallmentPlan>[plan, ..._installmentPlans]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final customer = customerById(customerId);
    if (customer != null) {
      await scheduleReminderFollowUp(
        customerId: customerId,
        dueAt: firstDueDate,
        tone: ReminderTone.normal,
        type: ReminderInboxType.installmentDue,
        referenceId: plan.id,
        note: 'Installment plan due',
        message:
            'Assalamualaikum ${customer.name}, aap ki installment ${formatCurrency(plan.installmentAmount)} ${formatDate(firstDueDate)} ko due hai.\n- ${_settings.shopName}',
      );
    } else {
      await _persist();
      notifyListeners();
    }

    return plan;
  }

  Future<void> toggleInstallmentPlanPause(
    String planId, {
    required bool isPaused,
  }) async {
    _ensureWritableSession();
    final plan = _installmentPlans.firstWhere(
      (entry) => entry.id == planId,
      orElse: () =>
          throw ArgumentError.value(planId, 'planId', 'Plan not found'),
    );
    _installmentPlans = _installmentPlans.map((plan) {
      if (plan.id != planId) {
        return plan;
      }
      return plan.copyWith(isPaused: isPaused);
    }).toList();
    if (isPaused) {
      await _markPendingReminderInboxItemsByReferenceId(
        planId,
        status: ReminderInboxStatus.skipped,
      );
    } else {
      final customer = customerById(plan.customerId);
      if (customer != null) {
        await scheduleReminderFollowUp(
          customerId: plan.customerId,
          dueAt: plan.nextDueDate,
          tone: ReminderTone.normal,
          type: ReminderInboxType.installmentDue,
          referenceId: planId,
          note: 'Installment resumed',
          message:
              'Assalamualaikum ${customer.name}, next installment ${formatCurrency(plan.installmentAmount)} ${formatDate(plan.nextDueDate)} ko due hai.\n- ${_settings.shopName}',
        );
        return;
      }
    }
    await _persist();
    notifyListeners();
  }

  Future<void> recordInstallmentPayment(
    String planId, {
    String note = 'Installment received',
  }) async {
    _ensureWritableSession();
    final plan = _installmentPlans.firstWhere(
      (entry) => entry.id == planId,
      orElse: () =>
          throw ArgumentError.value(planId, 'planId', 'Plan not found'),
    );
    if (plan.isCompleted) {
      return;
    }

    final remainingInstallments = plan.remainingInstallments;
    final amount = remainingInstallments <= 1
        ? plan.remainingAmount
        : plan.installmentAmount;
    await recordPayment(
      customerId: plan.customerId,
      amount: amount,
      note: note,
    );

    final completedInstallments = plan.completedInstallments + 1;
    final isCompleted = completedInstallments >= plan.installmentCount;
    final nextDueDate = isCompleted
        ? plan.nextDueDate
        : plan.nextDueDate.add(Duration(days: plan.intervalDays));

    _installmentPlans = _installmentPlans.map((entry) {
      if (entry.id != planId) {
        return entry;
      }
      return entry.copyWith(
        completedInstallments: completedInstallments,
        nextDueDate: nextDueDate,
        isCompleted: isCompleted,
        isPaused: false,
        lastPaymentAt: DateTime.now(),
      );
    }).toList();

    _reminderInbox = _reminderInbox.map((item) {
      if (item.referenceId != planId ||
          item.status != ReminderInboxStatus.pending) {
        return item;
      }
      unawaited(_localNotificationService?.cancel(item.notificationId));
      return item.copyWith(
        status: ReminderInboxStatus.completed,
        handledAt: DateTime.now(),
      );
    }).toList();

    if (!isCompleted) {
      final customer = customerById(plan.customerId);
      if (customer != null) {
        final updatedPlan = _installmentPlans.firstWhere(
          (entry) => entry.id == planId,
        );
        await scheduleReminderFollowUp(
          customerId: plan.customerId,
          dueAt: updatedPlan.nextDueDate,
          tone: ReminderTone.normal,
          type: ReminderInboxType.installmentDue,
          referenceId: planId,
          note: 'Next installment due',
          message:
              'Assalamualaikum ${customer.name}, next installment ${formatCurrency(updatedPlan.installmentAmount)} ${formatDate(updatedPlan.nextDueDate)} ko due hai.\n- ${_settings.shopName}',
        );
        return;
      }
    }

    await _persist();
    notifyListeners();
  }

  String buildCustomerPortalSummary(Customer customer) {
    final liveCustomer = customerById(customer.id) ?? customer;
    final insight = insightFor(liveCustomer.id);
    final shop = shopById(liveCustomer.shopId) ?? activeShop;
    final openCredits = transactionsFor(liveCustomer.id)
        .where(
          (entry) =>
              entry.type == TransactionType.credit && entry.paidOnTime == null,
        )
        .length;
    final summary = StringBuffer()
      ..writeln('Portal access summary')
      ..writeln('Shop: ${shop.name}')
      ..writeln('Customer: ${liveCustomer.name}')
      ..writeln('Share code: ${liveCustomer.shareCode}')
      ..writeln('Balance: ${formatCurrency(insight.balance)}')
      ..writeln('Open entries: $openCredits')
      ..writeln('Recovery Score: ${insight.recoveryScore}%');
    if (liveCustomer.promisedPaymentDate != null) {
      summary.writeln(
        'Promise Date: ${formatDate(liveCustomer.promisedPaymentDate!)}',
      );
    }
    summary.writeln('Portal link: ${buildCustomerStatementLink(liveCustomer)}');
    return summary.toString().trimRight();
  }

  String buildCustomerStatementLink(Customer customer) {
    final payload = buildCustomerPortalPayload(customer);
    final encodedPayload = base64UrlEncode(
      utf8.encode(jsonEncode(payload.toJson())),
    ).replaceAll('=', '');
    final baseUrl = kIsWeb
        ? Uri.base.replace(queryParameters: const <String, String>{}).toString()
        : '$kCustomerViewBaseUrl/';
    return Uri.parse(baseUrl)
        .replace(
          queryParameters: <String, String>{
            'share': customer.shareCode,
            'payload': encodedPayload,
          },
        )
        .toString();
  }

  PortalSharePayload buildCustomerPortalPayload(Customer customer) {
    final liveCustomer = customerById(customer.id) ?? customer;
    final shop = shopById(liveCustomer.shopId) ?? activeShop;
    final insight = insightFor(liveCustomer.id);
    final entries = transactionsFor(liveCustomer.id)
        .take(8)
        .map(
          (transaction) => PortalShareEntry(
            date: transaction.date,
            label: transaction.type == TransactionType.credit
                ? creditLabel
                : 'Payment',
            amount: transaction.amount,
            isCredit: transaction.type == TransactionType.credit,
            note: transaction.note.trim(),
          ),
        )
        .toList();
    return PortalSharePayload(
      shopName: shop.name,
      shopPhone: shop.phone.trim(),
      customerName: liveCustomer.name,
      customerPhone: liveCustomer.phone.trim(),
      shareCode: liveCustomer.shareCode,
      balance: insight.balance,
      recoveryScore: insight.recoveryScore,
      generatedAt: DateTime.now(),
      promiseDate: liveCustomer.promisedPaymentDate,
      promiseAmount: liveCustomer.promisedPaymentAmount,
      entries: entries,
    );
  }

  PortalSharePayload? portalPayloadFromUri(Uri uri) {
    final rawPayload = uri.queryParameters['payload']?.trim() ?? '';
    if (rawPayload.isNotEmpty) {
      try {
        final decoded = utf8.decode(
          base64Url.decode(base64Url.normalize(rawPayload)),
        );
        final json = jsonDecode(decoded);
        if (json is Map<String, dynamic>) {
          return PortalSharePayload.fromJson(json);
        }
        if (json is Map) {
          return PortalSharePayload.fromJson(Map<String, dynamic>.from(json));
        }
      } catch (_) {
        return null;
      }
    }

    final shareCode = uri.queryParameters['share']?.trim() ?? '';
    if (shareCode.isEmpty) {
      return null;
    }
    for (final customer in _customers) {
      if (customer.shareCode == shareCode) {
        return buildCustomerPortalPayload(customer);
      }
    }
    return null;
  }

  String buildPortalPromiseMessage(
    PortalSharePayload payload, {
    required double amount,
    required DateTime promiseDate,
  }) {
    final amountText = formatCurrency(amount);
    return 'Assalamualaikum ${payload.shopName}, this is ${payload.customerName}. '
        'I confirm a payment of $amountText by ${formatDate(promiseDate)}. '
        'Share code: ${payload.shareCode}.';
  }

  String customerVisitLocationSummary(CustomerVisit visit) {
    final parts = <String>[];
    if (visit.locationLabel.trim().isNotEmpty) {
      parts.add(visit.locationLabel.trim());
    }
    if (visit.latitude != null && visit.longitude != null) {
      parts.add(
        '${visit.latitude!.toStringAsFixed(5)}, ${visit.longitude!.toStringAsFixed(5)}',
      );
    }
    return parts.join(' | ');
  }

  String buildStatementShareText(Customer customer, {ReportRange? range}) {
    final insight = insightFor(customer.id);
    final openingBalance = range == null
        ? null
        : openingBalanceForCustomerInRange(customer.id, range);
    final periodCredits = range == null
        ? null
        : creditsIssuedForCustomerInRange(customer.id, range);
    final periodPayments = range == null
        ? null
        : paymentsReceivedForCustomerInRange(customer.id, range);
    final closingBalance = range == null
        ? insight.balance
        : closingBalanceForCustomerInRange(customer.id, range);
    final statement = StringBuffer()
      ..writeln('Hisab Rakho ${entitySingularLabel.toLowerCase()} statement')
      ..writeln(customer.name)
      ..writeln('Balance: ${formatCurrency(closingBalance)}')
      ..writeln('Recovery Score: ${insight.recoveryScore}%')
      ..writeln('Phone: ${customer.phone}');
    if (range != null) {
      statement
        ..writeln('Range: ${range.label}')
        ..writeln('Opening: ${formatCurrency(openingBalance ?? 0)}')
        ..writeln('Credit: ${formatCurrency(periodCredits ?? 0)}')
        ..writeln('Payments: ${formatCurrency(periodPayments ?? 0)}');
    }
    if (customer.promisedPaymentDate != null) {
      statement.writeln(
        'Promise Date: ${formatDate(customer.promisedPaymentDate!)}',
      );
    }
    statement.writeln('View link: ${buildCustomerStatementLink(customer)}');
    return statement.toString().trimRight();
  }

  String invoiceNumberForSale(SaleRecord sale) {
    final shop = shopById(sale.shopId) ?? activeShop;
    final prefix = shop.invoicePrefix.trim().isEmpty
        ? 'INV'
        : shop.invoicePrefix.trim().toUpperCase();
    final dateCode = DateFormat('yyyyMMdd').format(sale.date);
    final suffix = sale.id.length <= 6 ? sale.id : sale.id.substring(0, 6);
    return '$prefix-$dateCode-${suffix.toUpperCase()}';
  }

  String quotationNumberForDate(DateTime issuedAt) {
    final prefix = activeShop.quotationPrefix.trim().isEmpty
        ? 'QTN'
        : activeShop.quotationPrefix.trim().toUpperCase();
    return '$prefix-${DateFormat('yyyyMMdd-HHmm').format(issuedAt)}';
  }

  String buildSaleInvoiceDocument(SaleRecord sale) {
    final shop = shopById(sale.shopId) ?? activeShop;
    final customer = sale.customerId == null
        ? null
        : customerById(sale.customerId!);
    final linkedTransaction = sale.linkedTransactionId.trim().isEmpty
        ? null
        : transactionById(sale.linkedTransactionId);
    final total = sale.totalAmount;
    final taxableAmount = _taxableAmountFromInclusiveTotal(
      total,
      shop.salesTaxPercent,
    );
    final salesTaxAmount = total - taxableAmount;
    final lines = StringBuffer()
      ..writeln('SALES INVOICE')
      ..writeln(shop.name);

    if (shop.tagline.trim().isNotEmpty) {
      lines.writeln(shop.tagline.trim());
    }
    if (shop.address.trim().isNotEmpty) {
      lines.writeln('Address: ${shop.address.trim()}');
    }

    final contactParts = <String>[
      if (shop.phone.trim().isNotEmpty) 'Phone: ${shop.phone.trim()}',
      if (shop.email.trim().isNotEmpty) 'Email: ${shop.email.trim()}',
    ];
    if (contactParts.isNotEmpty) {
      lines.writeln(contactParts.join(' | '));
    }

    final complianceParts = <String>[
      if (shop.ntn.trim().isNotEmpty) 'NTN: ${shop.ntn.trim()}',
      if (shop.strn.trim().isNotEmpty) 'STRN: ${shop.strn.trim()}',
    ];
    if (complianceParts.isNotEmpty) {
      lines.writeln(complianceParts.join(' | '));
    }

    lines
      ..writeln('')
      ..writeln('Invoice No: ${invoiceNumberForSale(sale)}')
      ..writeln('Date: ${formatDateTime(sale.date)}')
      ..writeln(
        'Sale type: ${sale.type == SaleRecordType.cash ? 'Cash sale' : 'Udhaar sale'}',
      )
      ..writeln('Customer: ${customer?.name ?? 'Walk-in customer'}');

    if (customer != null) {
      lines.writeln('Phone: ${customer.phone}');
      if (customer.address.trim().isNotEmpty) {
        lines.writeln('Address: ${customer.address.trim()}');
      }
    }

    lines
      ..writeln('')
      ..writeln('LINE ITEMS');

    for (var index = 0; index < sale.lineItems.length; index++) {
      final item = sale.lineItems[index];
      lines.writeln(
        '${index + 1}. ${item.itemName} | Qty ${item.quantity} | Unit ${formatCurrency(item.unitPrice)} | Total ${formatCurrency(item.lineTotal)}',
      );
    }

    lines
      ..writeln('')
      ..writeln('SUMMARY')
      ..writeln('Taxable value: ${formatCurrency(taxableAmount)}');

    if (shop.salesTaxPercent > 0) {
      lines.writeln(
        'GST ${_formatPercent(shop.salesTaxPercent)}% (included): ${formatCurrency(salesTaxAmount)}',
      );
    } else {
      lines.writeln('GST: Not applied');
    }

    lines.writeln('Grand total: ${formatCurrency(total)}');

    if (linkedTransaction?.dueDate != null) {
      lines.writeln('Due date: ${formatDate(linkedTransaction!.dueDate!)}');
    }
    if (sale.note.trim().isNotEmpty) {
      lines
        ..writeln('')
        ..writeln('Notes')
        ..writeln(sale.note.trim());
    }

    lines
      ..writeln('')
      ..writeln('DOCUMENT NOTES')
      ..writeln(
        complianceParts.isEmpty
            ? 'Add NTN and STRN in settings if you want compliance identifiers on invoices.'
            : 'Internal FBR-ready sales summary included with registration identifiers above.',
      );
    return lines.toString().trimRight();
  }

  String buildQuotationDocument({
    Customer? customer,
    required List<SaleLineItem> lineItems,
    String note = '',
    DateTime? issuedAt,
    int validDays = 7,
  }) {
    final shop = activeShop;
    final date = issuedAt ?? DateTime.now();
    final normalizedItems = lineItems
        .where(
          (item) =>
              item.itemName.trim().isNotEmpty &&
              item.quantity > 0 &&
              item.unitPrice >= 0,
        )
        .toList();
    final grossTotal = normalizedItems.fold<double>(
      0,
      (total, item) => total + item.lineTotal,
    );
    final taxableAmount = _taxableAmountFromInclusiveTotal(
      grossTotal,
      shop.salesTaxPercent,
    );
    final salesTaxAmount = grossTotal - taxableAmount;
    final validUntil = date.add(Duration(days: validDays < 1 ? 1 : validDays));
    final lines = StringBuffer()
      ..writeln('QUOTATION / ESTIMATE')
      ..writeln(shop.name);

    if (shop.tagline.trim().isNotEmpty) {
      lines.writeln(shop.tagline.trim());
    }
    if (shop.address.trim().isNotEmpty) {
      lines.writeln('Address: ${shop.address.trim()}');
    }

    final contactParts = <String>[
      if (shop.phone.trim().isNotEmpty) 'Phone: ${shop.phone.trim()}',
      if (shop.email.trim().isNotEmpty) 'Email: ${shop.email.trim()}',
    ];
    if (contactParts.isNotEmpty) {
      lines.writeln(contactParts.join(' | '));
    }

    lines
      ..writeln('')
      ..writeln('Quotation No: ${quotationNumberForDate(date)}')
      ..writeln('Issued: ${formatDateTime(date)}')
      ..writeln('Valid until: ${formatDate(validUntil)}')
      ..writeln('Customer: ${customer?.name ?? 'Prospective customer'}');

    if (customer != null) {
      lines.writeln('Phone: ${customer.phone}');
      if (customer.address.trim().isNotEmpty) {
        lines.writeln('Address: ${customer.address.trim()}');
      }
    }

    lines
      ..writeln('')
      ..writeln('LINE ITEMS');

    if (normalizedItems.isEmpty) {
      lines.writeln('No quotation lines added yet.');
    } else {
      for (var index = 0; index < normalizedItems.length; index++) {
        final item = normalizedItems[index];
        lines.writeln(
          '${index + 1}. ${item.itemName} | Qty ${item.quantity} | Unit ${formatCurrency(item.unitPrice)} | Total ${formatCurrency(item.lineTotal)}',
        );
      }
    }

    lines
      ..writeln('')
      ..writeln('SUMMARY')
      ..writeln('Taxable value: ${formatCurrency(taxableAmount)}');

    if (shop.salesTaxPercent > 0) {
      lines.writeln(
        'GST ${_formatPercent(shop.salesTaxPercent)}% (included): ${formatCurrency(salesTaxAmount)}',
      );
    } else {
      lines.writeln('GST: Not applied');
    }

    lines.writeln('Quoted total: ${formatCurrency(grossTotal)}');

    if (note.trim().isNotEmpty) {
      lines
        ..writeln('')
        ..writeln('Notes')
        ..writeln(note.trim());
    }

    lines
      ..writeln('')
      ..writeln('DOCUMENT NOTES')
      ..writeln(
        'This quotation can be converted into a cash sale or udhaar entry after customer approval.',
      );
    return lines.toString().trimRight();
  }

  double _taxableAmountFromInclusiveTotal(
    double grossTotal,
    double taxPercent,
  ) {
    if (grossTotal <= 0 || taxPercent <= 0) {
      return grossTotal;
    }
    return grossTotal / (1 + (taxPercent / 100));
  }

  String _formatPercent(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  String buildNegotiationScript(Customer customer) {
    final liveCustomer = customerById(customer.id) ?? customer;
    final insight = insightFor(liveCustomer.id);
    final shop = shopById(liveCustomer.shopId) ?? activeShop;
    final plan = activeInstallmentPlanFor(liveCustomer.id);
    final matches = communityBlacklistMatchesForCustomer(liveCustomer.id);
    final visits = customerVisitsFor(liveCustomer.id);
    final latestVisit = visits.isEmpty ? null : visits.first;

    final opening = switch (insight.recommendedTone) {
      ReminderTone.soft =>
        'Hello ${liveCustomer.name}, I hope you are doing well. I am reaching out with a friendly balance follow-up from ${shop.name}.',
      ReminderTone.normal =>
        'Hello ${liveCustomer.name}, I am contacting you for a payment follow-up from ${shop.name}.',
      ReminderTone.strict =>
        'Hello ${liveCustomer.name}, we need a clear update on the overdue payment for ${shop.name}.',
    };

    final todayAsk =
        liveCustomer.promisedPaymentDate != null &&
            liveCustomer.promisedPaymentAmount != null
        ? 'You had promised ${displayCurrency(liveCustomer.promisedPaymentAmount!)} for ${formatDate(liveCustomer.promisedPaymentDate!)}. Can this amount be cleared today?'
        : plan != null
        ? 'The active installment plan shows the next installment as ${displayCurrency(plan.installmentAmount)}. Can this installment be received today?'
        : insight.balance >= 20000 ||
              insight.overdueDays >= 45 ||
              insight.paymentChance == PaymentChance.low
        ? 'The balance is heavy. Ask for a meaningful partial payment today and confirm the exact recovery date.'
        : insight.balance <= 5000 && insight.paymentChance != PaymentChance.low
        ? 'The amount is manageable. Ask directly for full payment today.'
        : 'Get one clear answer today: either a payment now or an exact commitment date.';

    final fallback =
        insight.paymentChance == PaymentChance.low || insight.overdueDays >= 30
        ? 'Fallback: If full payment is not possible, ask how much can be cleared today and what the exact next date will be.'
        : 'Fallback: If payment is not possible today, confirm the exact date and amount.';

    final nextStep = plan != null
        ? 'Next step: reconfirm the current installment plan and lock the missed installment into the follow-up diary.'
        : insight.overdueDays >= 45
        ? 'Next step: schedule a visit follow-up, send a strict reminder, and ask for a written promise note.'
        : 'Next step: schedule a concrete follow-up date in the reminder inbox.';

    final script = StringBuffer()
      ..writeln('Negotiation playbook')
      ..writeln('Customer: ${liveCustomer.name}')
      ..writeln('Balance: ${displayCurrency(insight.balance)}')
      ..writeln('Overdue: ${insight.overdueDays} days')
      ..writeln(
        'Recommended tone: ${reminderToneLabel(insight.recommendedTone)}',
      )
      ..writeln('')
      ..writeln('Opening')
      ..writeln(opening)
      ..writeln('')
      ..writeln('Today ask')
      ..writeln(todayAsk)
      ..writeln('')
      ..writeln(fallback)
      ..writeln(nextStep);

    if (latestVisit != null) {
      script.writeln('');
      script.writeln(
        'Latest visit: ${formatDateTime(latestVisit.visitedAt)}'
        '${latestVisit.note.isEmpty ? '' : ' | ${latestVisit.note}'}',
      );
    }
    if (matches.isNotEmpty) {
      script.writeln('');
      script.writeln(
        'Community caution: ${matches.length} matching local risk report(s). Stay factual, do not argue, and ask for a dated commitment.',
      );
    }
    return script.toString().trimRight();
  }

  List<String> get offlineAssistantPrompts => const <String>[
    'Who needs follow-up today?',
    'Which customers are highest risk?',
    'What stock needs attention?',
    'Show supplier pressure points.',
    'Give me a business summary.',
  ];

  String answerOfflineAssistantQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return _buildOfflineAssistantOverview();
    }
    if (_assistantQueryHasAny(normalized, <String>[
      'follow',
      'recover',
      'due',
      'risk',
      'customer',
      'reminder',
      'collection',
    ])) {
      return _buildOfflineAssistantRecoveryAnswer();
    }
    if (_assistantQueryHasAny(normalized, <String>[
      'stock',
      'inventory',
      'item',
      'reorder',
      'shelf',
    ])) {
      return _buildOfflineAssistantStockAnswer();
    }
    if (_assistantQueryHasAny(normalized, <String>[
      'supplier',
      'payable',
      'vendor',
      'purchase',
    ])) {
      return _buildOfflineAssistantSupplierAnswer();
    }
    if (_assistantQueryHasAny(normalized, <String>[
      'sale',
      'margin',
      'profit',
      'revenue',
      'cash',
    ])) {
      return _buildOfflineAssistantSalesAnswer();
    }
    if (_assistantQueryHasAny(normalized, <String>[
      'staff',
      'payroll',
      'salary',
      'team',
    ])) {
      return _buildOfflineAssistantStaffAnswer();
    }
    return _buildOfflineAssistantOverview(prompt: query.trim());
  }

  String buildBusinessCardText() {
    final shop = activeShop;
    final lines = <String>[
      shop.name,
      if (shop.tagline.trim().isNotEmpty) shop.tagline.trim(),
      terminology.userTypeLabel,
      if (shop.phone.trim().isNotEmpty) 'Phone: ${shop.phone.trim()}',
      if (shop.email.trim().isNotEmpty) 'Email: ${shop.email.trim()}',
      if (shop.address.trim().isNotEmpty) 'Address: ${shop.address.trim()}',
      'Powered by Hisab Rakho',
    ];
    return lines.join('\n');
  }

  String buildBusinessCardQrData() {
    final shop = activeShop;
    return <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      'N:;${_escapeVCardValue(shop.name)};;;',
      'FN:${_escapeVCardValue(shop.name)}',
      'ORG:${_escapeVCardValue(shop.name)}',
      'TITLE:${_escapeVCardValue(terminology.userTypeLabel)}',
      if (shop.phone.trim().isNotEmpty)
        'TEL;TYPE=CELL:${_escapeVCardValue(shop.phone.trim())}',
      if (shop.email.trim().isNotEmpty)
        'EMAIL:${_escapeVCardValue(shop.email.trim())}',
      if (shop.address.trim().isNotEmpty)
        'ADR;TYPE=WORK:;;${_escapeVCardValue(shop.address.trim())};;;;',
      if (shop.tagline.trim().isNotEmpty)
        'NOTE:${_escapeVCardValue(shop.tagline.trim())}',
      'END:VCARD',
    ].join('\n');
  }

  String _buildOfflineAssistantOverview({String prompt = ''}) {
    final supplierPriority = suppliers.toList()
      ..sort(
        (a, b) => supplierOutstandingBalance(
          b.id,
        ).compareTo(supplierOutstandingBalance(a.id)),
      );
    final recoveryLead = highestRiskCustomers.isEmpty
        ? 'No risky balance is active right now.'
        : _assistantCustomerLine(highestRiskCustomers.first);
    final stockLead = lowStockItems.isEmpty
        ? 'No inventory item is below the reorder level.'
        : _assistantInventoryLine(lowStockItems.first);
    final supplierLead = supplierPriority.isEmpty
        ? 'No supplier payable is open.'
        : _assistantSupplierLine(supplierPriority.first);

    final lines = <String>[
      'Hisab Rakho offline assistant',
      'Shop: ${activeShop.name}',
      if (prompt.isNotEmpty) 'Prompt: $prompt',
      '',
      'Next priorities',
      'Recovery: $recoveryLead',
      'Stock: $stockLead',
      'Supplier: $supplierLead',
      'Sales this month: ${displayCurrency(monthlyCashSales)} cash | ${displayCurrency(monthlySalesMargin)} gross margin',
      'Pending reminders: ${pendingReminderInbox.length}',
    ];
    return lines.join('\n');
  }

  String _buildOfflineAssistantRecoveryAnswer() {
    final riskyCustomers = highestRiskCustomers.take(3).toList();
    final dueInbox = pendingReminderInbox.take(3).toList();
    final lines = <String>[
      'Recovery priorities',
      'Pending reminder tasks: ${pendingReminderInbox.length}',
    ];
    if (riskyCustomers.isEmpty) {
      lines.add('No recovery risk is active right now.');
    } else {
      lines
        ..add('')
        ..add('Top customers')
        ..addAll(
          riskyCustomers.map(
            (customer) => '- ${_assistantCustomerLine(customer)}',
          ),
        );
    }
    if (dueInbox.isNotEmpty) {
      lines
        ..add('')
        ..add('Next reminder actions')
        ..addAll(
          dueInbox.map((item) {
            final customer = customerById(item.customerId);
            final targetName = customer?.name ?? 'Unknown customer';
            return '- ${formatDateTime(item.dueAt)} | $targetName | ${item.title}';
          }),
        );
    }
    return lines.join('\n');
  }

  String _buildOfflineAssistantStockAnswer() {
    final watchList = lowStockItems.take(5).toList();
    final lines = <String>[
      'Stock watch',
      'Inventory value: ${displayCurrency(totalInventoryRetailValue)} retail | ${displayCurrency(totalInventoryCostValue)} cost',
      'Low stock items: $lowStockItemCount',
    ];
    if (watchList.isEmpty) {
      lines.add('No item is currently below the reorder level.');
    } else {
      lines
        ..add('')
        ..addAll(watchList.map((item) => '- ${_assistantInventoryLine(item)}'));
    }
    return lines.join('\n');
  }

  String _buildOfflineAssistantSupplierAnswer() {
    final supplierList = suppliers.toList()
      ..sort(
        (a, b) => supplierOutstandingBalance(
          b.id,
        ).compareTo(supplierOutstandingBalance(a.id)),
      );
    final lines = <String>[
      'Supplier pressure',
      'Total payables: ${displayCurrency(totalSupplierPayables)}',
    ];
    if (supplierList.isEmpty) {
      lines.add('No supplier ledger is active.');
    } else {
      lines
        ..add('')
        ..addAll(
          supplierList
              .where((supplier) => supplierOutstandingBalance(supplier.id) > 0)
              .take(5)
              .map((supplier) => '- ${_assistantSupplierLine(supplier)}'),
        );
      if (lines.length <= 3) {
        lines.add('All supplier balances are cleared.');
      }
    }
    return lines.join('\n');
  }

  String _buildOfflineAssistantSalesAnswer() {
    final recentSales = saleRecords.take(3).toList();
    final lines = <String>[
      'Sales summary',
      'Cash sales this month: ${displayCurrency(monthlyCashSales)}',
      'Gross margin this month: ${displayCurrency(monthlySalesMargin)}',
      'Recent sales: ${saleRecords.length}',
    ];
    if (recentSales.isEmpty) {
      lines.add('No sales are recorded yet.');
    } else {
      lines
        ..add('')
        ..addAll(
          recentSales.map((sale) {
            final label = sale.type == SaleRecordType.cash
                ? 'Cash sale'
                : 'Udhaar sale';
            return '- ${formatDateTime(sale.date)} | $label | ${displayCurrency(sale.totalAmount)}';
          }),
        );
    }
    return lines.join('\n');
  }

  String _buildOfflineAssistantStaffAnswer() {
    return <String>[
      'Staff summary',
      'Active staff: ${staffMembers.length}',
      'Present today: $presentStaffTodayCount',
      'Outstanding advances: ${displayCurrency(totalOutstandingStaffAdvances)}',
      'Payroll this month: ${displayCurrency(monthlyPayrollNet)}',
      'Overtime this month: ${monthlyStaffOvertimeHours.toStringAsFixed(1)} hours',
    ].join('\n');
  }

  bool _assistantQueryHasAny(String normalized, List<String> needles) {
    for (final needle in needles) {
      if (normalized.contains(needle)) {
        return true;
      }
    }
    return false;
  }

  String _assistantCustomerLine(Customer customer) {
    final insight = insightFor(customer.id);
    final parts = <String>[
      customer.name,
      'balance ${displayCurrency(insight.balance)}',
      '${insight.overdueDays} overdue days',
    ];
    if (customer.promisedPaymentDate != null &&
        customer.promisedPaymentAmount != null) {
      parts.add(
        'promise ${displayCurrency(customer.promisedPaymentAmount!)} on ${formatDate(customer.promisedPaymentDate!)}',
      );
    }
    return parts.join(' | ');
  }

  String _assistantInventoryLine(InventoryItem item) {
    final supplier = item.supplierId.trim().isEmpty
        ? null
        : supplierById(item.supplierId);
    final parts = <String>[
      item.name,
      '${item.stockQuantity} ${item.unit} left',
      'reorder at ${item.reorderLevel}',
      'sale ${displayCurrency(item.salePrice)}',
    ];
    if (supplier != null) {
      parts.add('supplier ${supplier.name}');
    }
    return parts.join(' | ');
  }

  String _assistantSupplierLine(Supplier supplier) {
    return <String>[
      supplier.name,
      'payable ${displayCurrency(supplierOutstandingBalance(supplier.id))}',
      if (supplier.phone.trim().isNotEmpty) supplier.phone.trim(),
    ].join(' | ');
  }

  String _escapeVCardValue(String value) {
    return value
        .replaceAll('\\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll('\n', r'\n');
  }

  String csvImportSourceLabel(CsvImportSource source) {
    switch (source) {
      case CsvImportSource.digitalKhata:
        return 'Digital Khata';
      case CsvImportSource.okCredit:
        return 'OkCredit';
      case CsvImportSource.generic:
        return 'Generic CSV';
    }
  }

  CsvImportPreview previewCsvImport(
    String rawCsv, {
    CsvImportSource source = CsvImportSource.generic,
  }) {
    final grid = _parseCsvGrid(rawCsv);
    if (grid.isEmpty) {
      return CsvImportPreview(
        source: source,
        headerColumns: const <String>[],
        rows: const <CsvImportRowPreview>[],
        warningMessages: const <String>['CSV file is empty.'],
      );
    }

    final headerColumns = grid.first.map((value) => value.trim()).toList();
    final headerIndex = _buildCsvHeaderIndex(headerColumns);
    final warnings = <String>[];
    if (!_hasCsvAlias(headerIndex, _csvNameAliases)) {
      warnings.add('Customer name column not found.');
    }

    final rows = <CsvImportRowPreview>[];
    for (var index = 1; index < grid.length; index++) {
      final preview = _buildCsvImportRowPreview(
        row: grid[index],
        headerIndex: headerIndex,
        rowNumber: index + 1,
        source: source,
      );
      if (preview != null) {
        rows.add(preview);
      }
    }

    if (rows.isEmpty) {
      warnings.add('No importable rows found in CSV.');
    }

    return CsvImportPreview(
      source: source,
      headerColumns: headerColumns,
      rows: rows,
      warningMessages: warnings,
    );
  }

  Future<CsvImportResult> importCsvData(
    String rawCsv, {
    CsvImportSource source = CsvImportSource.generic,
  }) async {
    _ensureWritableSession();
    final preview = previewCsvImport(rawCsv, source: source);
    final now = DateTime.now();
    var createdCustomerCount = 0;
    var updatedCustomerCount = 0;
    var creditCount = 0;
    var paymentCount = 0;
    var duplicateTransactionCount = 0;
    var skippedRowCount = 0;
    var totalCredits = 0.0;
    var totalPayments = 0.0;
    final touchedCustomerIds = <String>{};
    final importedCreditsWithFutureDueDates = <LedgerTransaction>[];

    for (final row in preview.rows) {
      if (row.isSkipped) {
        skippedRowCount += 1;
        continue;
      }

      final existing = _findExistingCustomerForImport(row);
      final customer = existing == null
          ? Customer(
              id: _makeId(),
              shopId: activeShopId,
              shareCode: _makeShareCode(),
              name: row.customerName.trim(),
              phone: row.phone.trim(),
              createdAt: row.date ?? now,
              category: row.category.trim().isEmpty
                  ? 'Regular'
                  : row.category.trim(),
              address: row.address.trim(),
              notes: row.creditAmount == 0 && row.paymentAmount == 0
                  ? row.note.trim()
                  : '',
              city: row.city.trim(),
              cnic: row.cnic.trim(),
              groupName: row.groupName.trim(),
            )
          : _mergeImportedCustomer(existing, row);

      if (existing == null) {
        _customers = <Customer>[customer, ..._customers];
        createdCustomerCount += 1;
      } else if (!_isSameCustomer(existing, customer)) {
        _customers = _customers
            .map((entry) => entry.id == customer.id ? customer : entry)
            .toList();
        updatedCustomerCount += 1;
      }

      touchedCustomerIds.add(customer.id);
      final date = row.date ?? now;
      final note = row.note.trim().isEmpty
          ? '${csvImportSourceLabel(source)} import'
          : '${csvImportSourceLabel(source)} import | ${row.note.trim()}';

      if (row.creditAmount > 0) {
        if (_hasDuplicateImportedTransaction(
          customerId: customer.id,
          type: TransactionType.credit,
          amount: row.creditAmount,
          date: date,
          note: note,
        )) {
          duplicateTransactionCount += 1;
        } else {
          final transaction = LedgerTransaction(
            id: _makeId(),
            customerId: customer.id,
            shopId: customer.shopId,
            amount: row.creditAmount,
            type: TransactionType.credit,
            note: note,
            date: date,
            dueDate: row.dueDate,
            attachmentLabel: 'CSV import',
          );
          _transactions = <LedgerTransaction>[transaction, ..._transactions];
          creditCount += 1;
          totalCredits += row.creditAmount;
          if (row.dueDate != null && row.dueDate!.isAfter(now)) {
            importedCreditsWithFutureDueDates.add(transaction);
          }
        }
      }

      if (row.paymentAmount > 0) {
        if (_hasDuplicateImportedTransaction(
          customerId: customer.id,
          type: TransactionType.payment,
          amount: row.paymentAmount,
          date: date,
          note: note,
        )) {
          duplicateTransactionCount += 1;
        } else {
          _transactions = <LedgerTransaction>[
            LedgerTransaction(
              id: _makeId(),
              customerId: customer.id,
              shopId: customer.shopId,
              amount: row.paymentAmount,
              type: TransactionType.payment,
              note: note,
              date: date,
              attachmentLabel: 'CSV import',
            ),
            ..._transactions,
          ];
          paymentCount += 1;
          totalPayments += row.paymentAmount;
        }
      }
    }

    _transactions.sort((a, b) => b.date.compareTo(a.date));

    for (final customerId in touchedCustomerIds) {
      _recalculateCustomerTransactionStatuses(customerId);
      await _clearSettledTransactionReminders(customerId);
    }

    for (final transaction in importedCreditsWithFutureDueDates) {
      await _syncTransactionDueReminder(transaction);
    }

    await _persist();
    notifyListeners();

    return CsvImportResult(
      source: source,
      createdCustomerCount: createdCustomerCount,
      updatedCustomerCount: updatedCustomerCount,
      creditCount: creditCount,
      paymentCount: paymentCount,
      duplicateTransactionCount: duplicateTransactionCount,
      skippedRowCount: skippedRowCount,
      totalCredits: totalCredits,
      totalPayments: totalPayments,
    );
  }

  ParsedVoiceCredit? parseVoiceCredit(String rawWords) {
    return _parseVoiceCreditUseCase(
      rawWords: rawWords,
      customers: _activeCustomers,
    );
  }

  String exportBackupJson({String source = 'local'}) {
    return buildBackupExport(source: source).rawJson;
  }

  BackupExportBundle buildBackupExport({
    String source = 'local',
    DateTime? exportedAt,
  }) {
    _ensureWritableSession();
    final timestamp = exportedAt ?? DateTime.now();
    final snapshotJson = _snapshot.toJson();
    final checksum = _snapshotChecksum(snapshotJson);
    final payload = <String, dynamic>{
      'version': 3,
      'source': source,
      'exportedAt': timestamp.toIso8601String(),
      'integrity': <String, dynamic>{
        'algorithm': 'sha256',
        'snapshotHash': checksum,
      },
      'snapshot': snapshotJson,
    };
    final rawJson = const JsonEncoder.withIndent('  ').convert(payload);
    final preview = _buildBackupPreview(
      snapshot: _snapshot,
      version: 3,
      source: source,
      exportedAt: timestamp,
      sizeBytes: utf8.encode(rawJson).length,
      integrityStatus: BackupIntegrityStatus.verified,
      integrityAlgorithm: 'sha256',
      expectedChecksum: checksum,
      actualChecksum: checksum,
    );
    return BackupExportBundle(rawJson: rawJson, preview: preview);
  }

  BackupPreview previewBackupJson(String rawBackup) {
    final map = _parseBackupPayload(rawBackup);
    final snapshotSource = _extractSnapshotPayload(map);
    final restored = AppDataSnapshot.fromJson(snapshotSource);
    final integrity = map['integrity'] is Map
        ? Map<String, dynamic>.from(map['integrity'] as Map)
        : const <String, dynamic>{};
    final algorithm = integrity['algorithm'] as String? ?? '';
    final expectedChecksum = integrity['snapshotHash'] as String? ?? '';
    final actualChecksum = _snapshotChecksum(snapshotSource);
    final integrityStatus = expectedChecksum.isEmpty
        ? BackupIntegrityStatus.legacy
        : algorithm == 'sha256' && expectedChecksum == actualChecksum
        ? BackupIntegrityStatus.verified
        : BackupIntegrityStatus.invalid;

    return _buildBackupPreview(
      snapshot: restored,
      version: (map['version'] as num?)?.toInt() ?? 1,
      source: map['source'] as String? ?? 'legacy',
      exportedAt: _tryParseDateTime(map['exportedAt'] as String?),
      sizeBytes: utf8.encode(rawBackup).length,
      integrityStatus: integrityStatus,
      integrityAlgorithm: algorithm,
      expectedChecksum: expectedChecksum,
      actualChecksum: actualChecksum,
    );
  }

  Future<BackupRecord> recordBackupEvent({
    required BackupPreview preview,
    required String source,
    required String status,
    String note = '',
    String storagePath = '',
    String payload = '',
    bool updateLastBackupAt = true,
  }) async {
    final now = DateTime.now();
    final record = BackupRecord(
      id: _makeId(),
      createdAt: now,
      source: source,
      status: status,
      customerCount: preview.customerCount,
      transactionCount: preview.transactionCount,
      reminderCount: preview.reminderCount,
      note: note,
      checksum: preview.actualChecksum,
      storagePath: storagePath,
      payload: payload,
      sizeBytes: preview.sizeBytes,
      integrityStatus: preview.integrityStatus.name,
    );
    _backups = <BackupRecord>[record, ..._backups];
    if (updateLastBackupAt) {
      _settings = _settings.copyWith(lastBackupAt: now);
    }
    await _persist();
    notifyListeners();
    return record;
  }

  Future<BackupRecord> createLocalBackup({
    String source = 'local',
    String note = 'Manual backup export',
  }) async {
    final bundle = buildBackupExport(source: source);
    return recordBackupEvent(
      preview: bundle.preview,
      source: source,
      status: 'success',
      note: note,
      payload: bundle.rawJson,
    );
  }

  String generateCloudWorkspaceId() {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final buffer = StringBuffer();
    for (var index = 0; index < 12; index += 1) {
      if (index > 0 && index % 4 == 0) {
        buffer.write('-');
      }
      buffer.write(characters[_random.nextInt(characters.length)]);
    }
    return buffer.toString();
  }

  Future<CloudAccountProfile> signInToCloudAccountWithGoogle() async {
    final service = await _requireCloudAuthService();
    final account = await service.signInWithGoogle();
    await _applyCloudAccount(account, notify: false);
    if (_cloudSyncReady) {
      try {
        final backupService = await _requireCloudBackupService();
        _accountCloudWorkspaces = await backupService.listAccountWorkspaces(
          accountId: account.id,
          limit: 12,
        );
      } catch (_) {
        _accountCloudWorkspaces = <CloudWorkspaceDirectoryEntry>[];
      }
    }
    notifyListeners();
    return account;
  }

  Future<CloudAccountProfile> signInToCloudAccountWithCredentials({
    required String identifier,
    required String password,
  }) async {
    final service = await _requireCloudAuthService();
    final account = await service.signInWithEmailOrPhone(
      identifier: identifier,
      password: password,
    );
    await _applyCloudAccount(account, notify: false);
    if (_cloudSyncReady) {
      try {
        final backupService = await _requireCloudBackupService();
        _accountCloudWorkspaces = await backupService.listAccountWorkspaces(
          accountId: account.id,
          limit: 12,
        );
      } catch (_) {
        _accountCloudWorkspaces = <CloudWorkspaceDirectoryEntry>[];
      }
    }
    notifyListeners();
    return account;
  }

  Future<CloudAccountProfile> registerCloudAccount({
    required String displayName,
    required String email,
    required String password,
    String phoneNumber = '',
  }) async {
    final service = await _requireCloudAuthService();
    final account = await service.registerWithEmail(
      displayName: displayName,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
    );
    await _applyCloudAccount(account, notify: false);
    _accountCloudWorkspaces = <CloudWorkspaceDirectoryEntry>[];
    notifyListeners();
    return account;
  }

  Future<void> sendCloudPasswordReset({required String identifier}) async {
    final service = await _requireCloudAuthService();
    await service.sendPasswordReset(identifier: identifier);
  }

  Future<void> sendCloudEmailVerification() async {
    final service = await _requireCloudAuthService();
    await service.sendEmailVerification();
  }

  Future<CloudAccountProfile?> refreshCloudAccountProfile() async {
    final service = await _requireCloudAuthService();
    final account = await service.reloadCurrentAccount();
    await _applyCloudAccount(account, notify: false);
    if (account == null) {
      _accountCloudWorkspaces = <CloudWorkspaceDirectoryEntry>[];
    } else if (_cloudSyncReady) {
      try {
        final backupService = await _requireCloudBackupService();
        _accountCloudWorkspaces = await backupService.listAccountWorkspaces(
          accountId: account.id,
          limit: 12,
        );
      } catch (_) {
        _accountCloudWorkspaces = <CloudWorkspaceDirectoryEntry>[];
      }
    }
    notifyListeners();
    return account;
  }

  Future<void> signOutOfCloudAccount() async {
    if (_cloudAuthService != null && _cloudAuthReady) {
      await _cloudAuthService.signOut();
    }
    _accountCloudWorkspaces = <CloudWorkspaceDirectoryEntry>[];
    await _applyCloudAccount(null, notify: false);
    notifyListeners();
  }

  Future<List<CloudWorkspaceDirectoryEntry>> refreshAccountCloudWorkspaces({
    int limit = 12,
  }) async {
    final account = cloudAccount;
    if (account == null || !_cloudSyncReady) {
      _accountCloudWorkspaces = <CloudWorkspaceDirectoryEntry>[];
      notifyListeners();
      return accountCloudWorkspaces;
    }
    try {
      final service = await _requireCloudBackupService();
      final entries = await service.listAccountWorkspaces(
        accountId: account.id,
        limit: limit,
      );
      _accountCloudWorkspaces = entries;
      await _persist();
      notifyListeners();
      return accountCloudWorkspaces;
    } catch (error) {
      await _setCloudSyncError(error.toString());
      rethrow;
    }
  }

  Future<void> connectCloudWorkspace(String workspaceId) async {
    final normalizedWorkspaceId = _normalizeCloudWorkspaceId(workspaceId);
    if (normalizedWorkspaceId.isEmpty) {
      throw ArgumentError('A cloud workspace code is required.');
    }
    _settings = _settings.copyWith(
      cloudSyncEnabled: true,
      cloudWorkspaceId: normalizedWorkspaceId,
    );
    await _persist();
    await refreshCloudBackups();
  }

  Future<List<CloudBackupManifest>> refreshCloudBackups({int limit = 8}) async {
    if (!isCloudSyncConfigured) {
      _cloudBackups = <CloudBackupManifest>[];
      notifyListeners();
      return cloudBackups;
    }
    try {
      final service = await _requireCloudBackupService();
      final backups = await service.listBackups(
        workspaceId: cloudWorkspaceId,
        limit: limit,
      );
      _cloudBackups = backups;
      _settings = _settings.copyWith(clearCloudSyncLastError: true);
      await _persist();
      notifyListeners();
      return cloudBackups;
    } catch (error) {
      await _setCloudSyncError(error.toString());
      rethrow;
    }
  }

  Future<BackupRecord> syncBackupToCloud({
    String note = 'Manual cloud backup sync',
  }) async {
    _ensureWritableSession();
    if (!isCloudSyncConfigured) {
      throw StateError('Cloud sync is not configured.');
    }

    try {
      final service = await _requireCloudBackupService();
      final bundle = buildBackupExport(source: 'cloud-sync');
      final manifest = await service.uploadBackup(
        workspaceId: cloudWorkspaceId,
        deviceLabel: cloudDeviceLabel,
        shop: activeShop,
        bundle: bundle,
        account: cloudAccount,
      );
      _cloudBackups = <CloudBackupManifest>[
        manifest,
        ..._cloudBackups.where((backup) => backup.id != manifest.id),
      ];
      _settings = _settings.copyWith(
        lastCloudSyncAt: manifest.createdAt,
        clearCloudSyncLastError: true,
      );
      final record = await recordBackupEvent(
        preview: bundle.preview,
        source: 'cloud-sync',
        status: 'uploaded',
        note: note,
        storagePath: 'cloud:${manifest.workspaceId}/${manifest.id}',
        payload: bundle.rawJson,
      );
      if (cloudAccount != null) {
        try {
          _accountCloudWorkspaces = await service.listAccountWorkspaces(
            accountId: cloudAccount!.id,
            limit: 12,
          );
        } catch (_) {
          _accountCloudWorkspaces = <CloudWorkspaceDirectoryEntry>[];
        }
      }
      await _persist();
      notifyListeners();
      return record;
    } catch (error) {
      await _setCloudSyncError(error.toString());
      rethrow;
    }
  }

  Future<BackupPreview> previewCloudBackup(String backupId) async {
    if (!isCloudSyncConfigured) {
      throw StateError('Cloud sync is not configured.');
    }
    final service = await _requireCloudBackupService();
    final rawBackup = await service.downloadBackupJson(
      workspaceId: cloudWorkspaceId,
      backupId: backupId,
    );
    if (rawBackup == null || rawBackup.trim().isEmpty) {
      throw StateError('Cloud backup payload could not be loaded.');
    }
    return previewBackupJson(rawBackup);
  }

  Future<void> restoreCloudBackup(String backupId) async {
    _ensureWritableSession();
    if (!isCloudSyncConfigured) {
      throw StateError('Cloud sync is not configured.');
    }

    try {
      final service = await _requireCloudBackupService();
      final rawBackup = await service.downloadBackupJson(
        workspaceId: cloudWorkspaceId,
        backupId: backupId,
      );
      if (rawBackup == null || rawBackup.trim().isEmpty) {
        throw StateError('Cloud backup payload could not be loaded.');
      }
      await restoreFromBackupJson(rawBackup, source: 'cloud-restore');
      _settings = _settings.copyWith(
        lastCloudRestoreAt: DateTime.now(),
        clearCloudSyncLastError: true,
      );
      await refreshCloudBackups();
    } catch (error) {
      await _setCloudSyncError(error.toString());
      rethrow;
    }
  }

  Future<void> restoreLatestCloudBackup() async {
    final backups = await refreshCloudBackups(limit: 1);
    if (backups.isEmpty) {
      throw StateError('No cloud backups were found for this workspace.');
    }
    await restoreCloudBackup(backups.first.id);
  }

  bool autoBackupDue({DateTime? now}) {
    if (!isAutoBackupEnabled) {
      return false;
    }
    final lastBackupAt = _settings.lastBackupAt;
    if (lastBackupAt == null) {
      return true;
    }
    final threshold = lastBackupAt.add(
      Duration(days: _settings.autoBackupDays),
    );
    return !(now ?? DateTime.now()).isBefore(threshold);
  }

  Future<BackupRecord?> runAutoBackupIfDue({DateTime? now}) async {
    if (!autoBackupDue(now: now)) {
      return null;
    }
    final bundle = buildBackupExport(source: 'auto');
    return recordBackupEvent(
      preview: bundle.preview,
      source: 'auto',
      status: 'scheduled',
      note: 'Automatic backup checkpoint',
      payload: bundle.rawJson,
    );
  }

  Future<void> deleteBackupRecord(String backupId) async {
    _backups = _backups.where((backup) => backup.id != backupId).toList();
    final latestExport = _backups
        .where((backup) => backup.status != 'restored')
        .fold<DateTime?>(null, (latest, backup) {
          if (latest == null || backup.createdAt.isAfter(latest)) {
            return backup.createdAt;
          }
          return latest;
        });
    _settings = _settings.copyWith(
      lastBackupAt: latestExport,
      clearLastBackupAt: latestExport == null,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> clearBackupHistory() async {
    _ensureWritableSession();
    _backups = <BackupRecord>[];
    _settings = _settings.copyWith(clearLastBackupAt: true);
    await _persist();
    notifyListeners();
  }

  bool shouldAutoLockAfterBackground(DateTime backgroundedAt, {DateTime? now}) {
    final lockDuration = autoLockDuration;
    if (!isSecurityEnabled || lockDuration == null) {
      return false;
    }
    return !(now ?? DateTime.now()).difference(backgroundedAt).isNegative &&
        (now ?? DateTime.now()).difference(backgroundedAt) >= lockDuration;
  }

  Future<void> restoreFromBackupJson(
    String rawBackup, {
    String source = 'restore',
  }) async {
    _ensureWritableSession();
    final currentCloudAccount = cloudAccount;
    final preview = previewBackupJson(rawBackup);
    if (!preview.isRestorable) {
      throw const FormatException('Backup integrity check failed.');
    }

    final safetyCheckpoint = buildBackupExport(source: 'pre-restore');
    await recordBackupEvent(
      preview: safetyCheckpoint.preview,
      source: 'pre-restore',
      status: 'checkpoint',
      note: 'Automatic safety checkpoint before restore',
      payload: safetyCheckpoint.rawJson,
      updateLastBackupAt: false,
    );

    final payload = _parseBackupPayload(rawBackup);
    final restored = AppDataSnapshot.fromJson(_extractSnapshotPayload(payload));

    _hydrate(restored);
    _cloudAccount = currentCloudAccount;
    _settings = _settings.copyWith(
      cloudAccountId: currentCloudAccount?.id.trim() ?? '',
      cloudAccountEmail: currentCloudAccount?.email.trim() ?? '',
      cloudAccountDisplayName: currentCloudAccount?.displayName.trim() ?? '',
      cloudAccountProvider: currentCloudAccount?.provider.trim() ?? '',
      lastCloudAccountSignInAt: currentCloudAccount?.signedInAt,
      clearCloudAccount: currentCloudAccount == null,
    );
    await recordBackupEvent(
      preview: preview,
      source: source,
      status: 'restored',
      note: 'Backup restore',
      updateLastBackupAt: false,
    );
  }

  Future<void> restoreFromBackupRecord(String backupId) async {
    _ensureWritableSession();
    BackupRecord? record;
    for (final backup in _backups) {
      if (backup.id == backupId) {
        record = backup;
        break;
      }
    }
    if (record == null) {
      throw StateError('Backup record not found.');
    }
    if (!record.hasPayload) {
      throw StateError(
        'This backup history item does not contain a restore point.',
      );
    }
    await restoreFromBackupJson(record.payload, source: 'history-restore');
  }

  List<SaleLineItem> _normalizeSaleLineItems(List<SaleLineItem> lineItems) {
    final normalized = lineItems
        .where(
          (item) =>
              item.inventoryItemId.trim().isNotEmpty &&
              item.quantity > 0 &&
              item.unitPrice > 0,
        )
        .toList();
    if (normalized.isEmpty) {
      throw ArgumentError('At least one sale line is required.');
    }
    return normalized;
  }

  void _applySaleStockDeductions(List<SaleLineItem> lineItems) {
    final soldQuantities = <String, int>{};
    for (final item in lineItems) {
      soldQuantities.update(
        item.inventoryItemId,
        (value) => value + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }

    for (final entry in soldQuantities.entries) {
      final inventoryItem = inventoryItemById(entry.key);
      if (inventoryItem == null) {
        throw ArgumentError('Inventory item not found.');
      }
      if (inventoryItem.stockQuantity < entry.value) {
        throw StateError(
          'Not enough stock for ${inventoryItem.name}. Available: ${inventoryItem.stockQuantity}.',
        );
      }
    }

    _inventoryItems = _inventoryItems.map((item) {
      final soldQuantity = soldQuantities[item.id];
      if (soldQuantity == null) {
        return item;
      }
      return item.copyWith(stockQuantity: item.stockQuantity - soldQuantity);
    }).toList();
  }

  Future<void> _recordReminder({
    required String customerId,
    required String message,
    required ReminderTone tone,
    required String channel,
    required bool wasSuccessful,
  }) async {
    _reminderLogs = <ReminderLog>[
      ReminderLog(
        id: _makeId(),
        customerId: customerId,
        message: message,
        tone: tone,
        sentAt: DateTime.now(),
        channel: channel,
        wasSuccessful: wasSuccessful,
      ),
      ..._reminderLogs,
    ];
    await _persist();
  }

  void _resetSecurityStateAfterLoad() {
    _isDecoySession = false;
    _isAppUnlocked = !isSecurityEnabled;
  }

  Future<void> _refreshLocalProtectionStatus() async {
    try {
      _localDataProtectionStatus = await _repository.protectionStatus();
    } catch (_) {
      _localDataProtectionStatus = const LocalDataProtectionStatus(
        storageLabel: 'Local storage',
        encryptedAtRest: false,
        keyStoredSecurely: false,
        usesDeviceVault: false,
      );
    }
  }

  void _ensureWritableSession() {
    if (_isDecoySession) {
      throw StateError('Decoy mode is read-only.');
    }
  }

  Future<void> _markReminderSent(String customerId) async {
    _customers = _customers.map((customer) {
      if (customer.id != customerId) {
        return customer;
      }
      return customer.copyWith(
        lastReminderAt: DateTime.now(),
        reminderCount: customer.reminderCount + 1,
      );
    }).toList();
    await _persist();
    notifyListeners();
  }

  double _balanceForTransactions(Iterable<LedgerTransaction> transactions) {
    final credits = transactions
        .where((entry) => entry.type == TransactionType.credit)
        .fold<double>(0, (total, entry) => total + entry.amount);
    final payments = transactions
        .where((entry) => entry.type == TransactionType.payment)
        .fold<double>(0, (total, entry) => total + entry.amount);
    return max(0, credits - payments);
  }

  String _escapeCsvValue(String raw) {
    final escaped = raw.replaceAll('"', '""');
    if (escaped.contains(',') ||
        escaped.contains('\n') ||
        escaped.contains('"')) {
      return '"$escaped"';
    }
    return escaped;
  }

  String _hashPin(String pin, {required String salt}) {
    return crypto.sha256
        .convert(
          utf8.encode(
            '${pin.trim()}|${salt.trim()}|${_settings.activeShopId}|v2',
          ),
        )
        .toString();
  }

  String _legacyHashPin(String pin) {
    final prime = BigInt.parse('100000001b3', radix: 16);
    final mask = BigInt.parse('ffffffffffffffff', radix: 16);
    var input =
        '${pin.trim()}|${_settings.activeShopId}|${_settings.shopName}|v1';
    var hash = BigInt.parse('cbf29ce484222325', radix: 16);
    for (var round = 0; round < 6; round++) {
      for (final code in utf8.encode(input)) {
        hash = ((hash ^ BigInt.from(code)) * prime) & mask;
      }
      input = '$hash|$round|${input.length}';
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  bool _matchesConfiguredPin({
    required String pin,
    required String hash,
    required String salt,
  }) {
    final trimmedHash = hash.trim();
    if (trimmedHash.isEmpty) {
      return false;
    }
    if (salt.trim().isNotEmpty) {
      return _hashPin(pin, salt: salt) == trimmedHash;
    }
    return _legacyHashPin(pin) == trimmedHash;
  }

  void _upgradeStoredPinHashIfNeeded(
    String pin, {
    required String currentHash,
    required String currentSalt,
    required bool decoy,
  }) {
    if (currentHash.trim().isEmpty || currentSalt.trim().isNotEmpty) {
      return;
    }

    final salt = _makePinSalt();
    _settings = decoy
        ? _settings.copyWith(
            decoyPinHash: _hashPin(pin, salt: salt),
            decoyPinSalt: salt,
          )
        : _settings.copyWith(
            pinHash: _hashPin(pin, salt: salt),
            pinSalt: salt,
          );
    unawaited(_persist());
  }

  String _makePinSalt() {
    final values = List<int>.generate(
      16,
      (_) => _random.nextInt(256),
      growable: false,
    );
    return base64UrlEncode(values).replaceAll('=', '');
  }

  String _makePartnerInviteCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final buffer = StringBuffer();
    for (var index = 0; index < 6; index++) {
      buffer.write(alphabet[_random.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }

  Future<void> _runScheduledAutoBackupIfDue() async {
    await runAutoBackupIfDue();
  }

  BackupPreview _buildBackupPreview({
    required AppDataSnapshot snapshot,
    required int version,
    required String source,
    required DateTime? exportedAt,
    required int sizeBytes,
    required BackupIntegrityStatus integrityStatus,
    required String integrityAlgorithm,
    required String expectedChecksum,
    required String actualChecksum,
  }) {
    return BackupPreview(
      version: version,
      exportedAt: exportedAt,
      source: source,
      shopCount: snapshot.shops.length,
      customerCount: snapshot.customers.length,
      transactionCount: snapshot.transactions.length,
      reminderCount: snapshot.reminderLogs.length,
      installmentPlanCount: snapshot.installmentPlans.length,
      visitCount: snapshot.customerVisits.length,
      shopNames: snapshot.shops.map((shop) => shop.name).toList(),
      sizeBytes: sizeBytes,
      integrityStatus: integrityStatus,
      integrityAlgorithm: integrityAlgorithm,
      expectedChecksum: expectedChecksum,
      actualChecksum: actualChecksum,
    );
  }

  Map<String, dynamic> _parseBackupPayload(String rawBackup) {
    final decoded = jsonDecode(rawBackup);
    if (decoded is! Map) {
      throw const FormatException('Backup JSON object expected.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Map<String, dynamic> _extractSnapshotPayload(Map<String, dynamic> payload) {
    final snapshotSource = payload['snapshot'] is Map
        ? Map<String, dynamic>.from(payload['snapshot'] as Map)
        : payload;
    return snapshotSource;
  }

  DateTime? _tryParseDateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  String _snapshotChecksum(Map<String, dynamic> snapshotJson) {
    final canonical = _canonicalizeJsonValue(snapshotJson);
    final encoded = jsonEncode(canonical);
    return crypto.sha256.convert(utf8.encode(encoded)).toString();
  }

  Object? _canonicalizeJsonValue(Object? value) {
    if (value is Map) {
      final normalized = value.map(
        (key, nestedValue) =>
            MapEntry(key.toString(), _canonicalizeJsonValue(nestedValue)),
      );
      final keys = normalized.keys.toList()..sort();
      return <String, Object?>{for (final key in keys) key: normalized[key]};
    }
    if (value is List) {
      return value.map(_canonicalizeJsonValue).toList();
    }
    return value;
  }

  double _priorityScoreFor(String customerId) {
    final customer = customerById(customerId);
    final insight = insightFor(customerId);
    var score = insight.balance / 1000;
    score += insight.overdueDays * 1.5;
    score += (100 - insight.recoveryScore) * 0.6;
    if (insight.paymentChance == PaymentChance.low) {
      score += 18;
    }
    if (insight.isOverCreditLimit) {
      score += 14;
    }
    if (customer?.promisedPaymentDate != null) {
      score += _daysSince(customer!.promisedPaymentDate!).toDouble();
    }
    if (insight.lastReminderAt != null) {
      score += _daysSince(insight.lastReminderAt!).toDouble();
    }
    return score;
  }

  Customer? _findExistingCustomerForImport(CsvImportRowPreview row) {
    final normalizedPhone = _normalizePakPhone(row.phone);
    final normalizedCnic = _digitsOnly(row.cnic);
    final normalizedName = row.customerName.trim().toLowerCase();
    final normalizedCity = row.city.trim().toLowerCase();

    for (final customer in _customers) {
      if (customer.shopId != activeShopId) {
        continue;
      }
      if (normalizedPhone.isNotEmpty &&
          _normalizePakPhone(customer.phone) == normalizedPhone) {
        return customer;
      }
      if (normalizedCnic.isNotEmpty &&
          _digitsOnly(customer.cnic) == normalizedCnic) {
        return customer;
      }
      if (normalizedName.isNotEmpty &&
          customer.name.trim().toLowerCase() == normalizedName &&
          normalizedCity.isNotEmpty &&
          customer.city.trim().toLowerCase() == normalizedCity) {
        return customer;
      }
    }
    return null;
  }

  Customer _mergeImportedCustomer(Customer existing, CsvImportRowPreview row) {
    final normalizedCategory = row.category.trim();
    return existing.copyWith(
      phone: existing.phone.trim().isEmpty ? row.phone.trim() : existing.phone,
      category:
          normalizedCategory.isNotEmpty &&
              (existing.category.trim().isEmpty ||
                  existing.category.trim().toLowerCase() == 'regular')
          ? normalizedCategory
          : existing.category,
      address: existing.address.trim().isEmpty
          ? row.address.trim()
          : existing.address,
      notes:
          existing.notes.trim().isEmpty &&
              row.creditAmount == 0 &&
              row.paymentAmount == 0
          ? row.note.trim()
          : existing.notes,
      city: existing.city.trim().isEmpty ? row.city.trim() : existing.city,
      cnic: existing.cnic.trim().isEmpty ? row.cnic.trim() : existing.cnic,
      groupName: existing.groupName.trim().isEmpty
          ? row.groupName.trim()
          : existing.groupName,
    );
  }

  bool _isSameCustomer(Customer left, Customer right) {
    return left.name == right.name &&
        left.phone == right.phone &&
        left.category == right.category &&
        left.address == right.address &&
        left.notes == right.notes &&
        left.city == right.city &&
        left.cnic == right.cnic &&
        left.groupName == right.groupName;
  }

  bool _hasDuplicateImportedTransaction({
    required String customerId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    required String note,
  }) {
    for (final transaction in _transactions) {
      if (transaction.customerId != customerId || transaction.type != type) {
        continue;
      }
      if ((transaction.amount - amount).abs() > 0.001) {
        continue;
      }
      if (!_isSameDay(transaction.date, date)) {
        continue;
      }
      if (transaction.note.trim().toLowerCase() != note.trim().toLowerCase()) {
        continue;
      }
      return true;
    }
    return false;
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  CsvImportRowPreview? _buildCsvImportRowPreview({
    required List<String> row,
    required Map<String, int> headerIndex,
    required int rowNumber,
    required CsvImportSource source,
  }) {
    final customerName = _csvCell(row, headerIndex, _csvNameAliases);
    final phone = _csvCell(row, headerIndex, _csvPhoneAliases);
    final category = _csvCell(row, headerIndex, _csvCategoryAliases);
    final city = _csvCell(row, headerIndex, _csvCityAliases);
    final address = _csvCell(row, headerIndex, _csvAddressAliases);
    final cnic = _csvCell(row, headerIndex, _csvCnicAliases);
    final groupName = _csvCell(row, headerIndex, _csvGroupAliases);
    final note = _csvCell(row, headerIndex, _csvNoteAliases);
    final rawType = _csvCell(row, headerIndex, _csvTypeAliases);
    final explicitCredit = _parseImportedAmount(
      _csvCell(row, headerIndex, _csvCreditAliases),
    );
    final explicitPayment = _parseImportedAmount(
      _csvCell(row, headerIndex, _csvPaymentAliases),
    );
    final balance = _parseImportedAmount(
      _csvCell(row, headerIndex, _csvBalanceAliases),
    );
    final amount = _parseImportedAmount(
      _csvCell(row, headerIndex, _csvAmountAliases),
    );
    var creditAmount = explicitCredit;
    var paymentAmount = explicitPayment;
    if (creditAmount == 0 && paymentAmount == 0 && balance != 0) {
      if (balance > 0) {
        creditAmount = balance;
      } else {
        paymentAmount = balance.abs();
      }
    }
    if (creditAmount == 0 && paymentAmount == 0 && amount > 0) {
      final transactionType = _normalizeImportedTransactionType(rawType);
      if (transactionType == TransactionType.credit) {
        creditAmount = amount;
      } else if (transactionType == TransactionType.payment) {
        paymentAmount = amount;
      }
    }

    final warnings = <String>[];
    var isSkipped = false;
    if (customerName.trim().isEmpty) {
      warnings.add('Missing customer name');
      isSkipped = true;
    }
    if (creditAmount == 0 && paymentAmount == 0 && note.trim().isEmpty) {
      warnings.add('No amount or note found');
    }
    if (phone.trim().isEmpty) {
      warnings.add('Phone missing');
    }

    final preview = CsvImportRowPreview(
      rowNumber: rowNumber,
      customerName: customerName.trim(),
      phone: phone.trim(),
      creditAmount: creditAmount,
      paymentAmount: paymentAmount,
      note: note.trim(),
      category: category.trim(),
      city: city.trim(),
      address: address.trim(),
      cnic: cnic.trim(),
      groupName: groupName.trim(),
      date: _tryParseImportedDate(_csvCell(row, headerIndex, _csvDateAliases)),
      dueDate: _tryParseImportedDate(
        _csvCell(row, headerIndex, _csvDueDateAliases),
      ),
      warnings: warnings,
      isSkipped: isSkipped,
    );

    if (preview.customerName.isEmpty &&
        preview.phone.isEmpty &&
        preview.creditAmount == 0 &&
        preview.paymentAmount == 0 &&
        preview.note.trim().isEmpty) {
      return null;
    }
    return preview;
  }

  List<List<String>> _parseCsvGrid(String rawCsv) {
    final rows = <List<String>>[];
    var currentRow = <String>[];
    var currentCell = StringBuffer();
    var inQuotes = false;

    for (var index = 0; index < rawCsv.length; index++) {
      final char = rawCsv[index];
      if (char == '"') {
        if (inQuotes && index + 1 < rawCsv.length && rawCsv[index + 1] == '"') {
          currentCell.write('"');
          index += 1;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if (char == ',' && !inQuotes) {
        currentRow.add(currentCell.toString());
        currentCell = StringBuffer();
        continue;
      }

      if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' &&
            index + 1 < rawCsv.length &&
            rawCsv[index + 1] == '\n') {
          index += 1;
        }
        currentRow.add(currentCell.toString());
        if (currentRow.any((value) => value.trim().isNotEmpty)) {
          rows.add(List<String>.from(currentRow));
        }
        currentRow = <String>[];
        currentCell = StringBuffer();
        continue;
      }

      currentCell.write(char);
    }

    currentRow.add(currentCell.toString());
    if (currentRow.any((value) => value.trim().isNotEmpty)) {
      rows.add(List<String>.from(currentRow));
    }
    return rows;
  }

  Map<String, int> _buildCsvHeaderIndex(List<String> headers) {
    final headerIndex = <String, int>{};
    for (var index = 0; index < headers.length; index++) {
      final normalized = _normalizeCsvHeader(headers[index]);
      if (normalized.isEmpty || headerIndex.containsKey(normalized)) {
        continue;
      }
      headerIndex[normalized] = index;
    }
    return headerIndex;
  }

  bool _hasCsvAlias(Map<String, int> headerIndex, List<String> aliases) {
    for (final alias in aliases) {
      if (headerIndex.containsKey(alias)) {
        return true;
      }
    }
    return false;
  }

  String _csvCell(
    List<String> row,
    Map<String, int> headerIndex,
    List<String> aliases,
  ) {
    for (final alias in aliases) {
      final index = headerIndex[alias];
      if (index == null || index >= row.length) {
        continue;
      }
      final value = row[index].trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  String _normalizeCsvHeader(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  double _parseImportedAmount(String raw) {
    if (raw.trim().isEmpty) {
      return 0;
    }
    final cleaned = raw.replaceAll(RegExp(r'[^0-9().-]'), '');
    if (cleaned.trim().isEmpty) {
      return 0;
    }
    final isNegative =
        cleaned.startsWith('-') ||
        (cleaned.startsWith('(') && cleaned.endsWith(')'));
    final normalized = cleaned.replaceAll('(', '').replaceAll(')', '');
    final value = double.tryParse(normalized) ?? 0;
    return isNegative ? -value.abs() : value;
  }

  TransactionType? _normalizeImportedTransactionType(String rawType) {
    final normalized = rawType.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.contains('payment') ||
        normalized.contains('paid') ||
        normalized.contains('receive') ||
        normalized.contains('collection')) {
      return TransactionType.payment;
    }
    if (normalized.contains('credit') ||
        normalized.contains('udhaar') ||
        normalized.contains('invoice') ||
        normalized.contains('debit') ||
        normalized.contains('purchase')) {
      return TransactionType.credit;
    }
    return null;
  }

  DateTime? _tryParseImportedDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) {
      return parsed;
    }
    for (final format in const <String>[
      'd/M/y',
      'dd/MM/y',
      'M/d/y',
      'MM/dd/y',
      'd-M-y',
      'dd-MM-y',
      'd MMM y',
      'dd MMM y',
    ]) {
      try {
        return DateFormat(format).parseStrict(trimmed);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  bool _communityBlacklistEntryMatchesCustomer(
    CommunityBlacklistEntry entry,
    Customer customer,
  ) {
    final customerPhone = _normalizePakPhone(customer.phone);
    final entryPhone = _normalizePakPhone(entry.phone);
    if (customerPhone.isNotEmpty &&
        entryPhone.isNotEmpty &&
        customerPhone == entryPhone) {
      return true;
    }

    final customerCnic = _digitsOnly(customer.cnic);
    final entryCnic = _digitsOnly(entry.cnic);
    if (customerCnic.isNotEmpty &&
        entryCnic.isNotEmpty &&
        customerCnic == entryCnic) {
      return true;
    }

    final customerName = customer.name.trim().toLowerCase();
    final entryName = entry.customerName.trim().toLowerCase();
    final customerCity = customer.city.trim().toLowerCase();
    final entryCity = entry.city.trim().toLowerCase();
    return customerName.isNotEmpty &&
        customerName == entryName &&
        customerCity.isNotEmpty &&
        customerCity == entryCity;
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _normalizePakPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('92')) {
      return digits;
    }
    if (digits.startsWith('0')) {
      return '92${digits.substring(1)}';
    }
    if (digits.length == 10) {
      return '92$digits';
    }
    return digits;
  }

  String _makeId() {
    return '${DateTime.now().microsecondsSinceEpoch}${_random.nextInt(9999)}';
  }

  int _makeNotificationId() {
    return DateTime.now().microsecondsSinceEpoch.remainder(2147483647);
  }

  void _recalculateCustomerTransactionStatuses(String customerId) {
    final timeline =
        _transactions.where((entry) => entry.customerId == customerId).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    if (timeline.isEmpty) {
      return;
    }

    var rebuilt = timeline
        .where((entry) => entry.type == TransactionType.credit)
        .map((entry) => entry.copyWith(clearPaidOnTime: true))
        .toList();
    final payments = timeline
        .where((entry) => entry.type == TransactionType.payment)
        .toList();

    for (final payment in payments) {
      rebuilt =
          _applyPaymentUseCase(
            transactions: rebuilt,
            customerId: customerId,
            shopId: payment.shopId,
            amount: payment.amount,
            paymentId: payment.id,
            paymentDate: payment.date,
            note: payment.note,
          ).map((entry) {
            if (entry.id != payment.id) {
              return entry;
            }
            return entry.copyWith(
              isDisputed: payment.isDisputed,
              reference: payment.reference,
              attachmentLabel: payment.attachmentLabel,
              receiptPath: payment.receiptPath,
              audioNotePath: payment.audioNotePath,
            );
          }).toList();
    }

    final rebuiltById = <String, LedgerTransaction>{
      for (final entry in rebuilt) entry.id: entry,
    };

    _transactions = _transactions.map((entry) {
      if (entry.customerId != customerId) {
        return entry;
      }
      return rebuiltById[entry.id] ?? entry;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  String _makeShopId() {
    return 'shop_${DateTime.now().microsecondsSinceEpoch}${_random.nextInt(999)}';
  }

  String _makeShareCode() {
    final randomPart = (_random.nextInt(900000) + 100000).toString();
    final timePart = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return 'hr$randomPart$timePart';
  }

  Future<bool> _launchReminderChannel({
    required Customer customer,
    required ReminderTone tone,
    required String channel,
    String? customMessage,
  }) async {
    final normalizedChannel = channel.trim().toLowerCase();
    if (normalizedChannel == 'sms') {
      final smsMessage =
          customMessage ?? generateReminderMessage(customer, tone: tone);
      return launchUrl(
        generateSmsUri(customer.phone, smsMessage),
        mode: LaunchMode.externalApplication,
      );
    }

    final link = generateWhatsAppLink(
      customer.phone,
      customer.name,
      insightFor(customer.id).balance,
      customerId: customer.id,
      tone: tone,
      customMessage: customMessage,
    );
    return launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
  }

  Future<void> _syncPromiseFollowUp(Customer customer) async {
    final referenceId = 'promise_${customer.id}';
    await _clearPendingReminderInboxByReferenceId(referenceId);
    final promisedPaymentDate = customer.promisedPaymentDate;
    if (promisedPaymentDate == null) {
      return;
    }

    final scheduledAt = DateTime(
      promisedPaymentDate.year,
      promisedPaymentDate.month,
      promisedPaymentDate.day,
      10,
    );
    final amountText = customer.promisedPaymentAmount == null
        ? ''
        : ' ${formatCurrency(customer.promisedPaymentAmount!)}';
    await scheduleReminderFollowUp(
      customerId: customer.id,
      dueAt: scheduledAt,
      tone: ReminderTone.normal,
      type: ReminderInboxType.promiseFollowUp,
      referenceId: referenceId,
      note: 'Promise-to-pay follow-up',
      message:
          'Assalamualaikum ${customer.name}, aap ki promised payment$amountText ${formatDate(promisedPaymentDate)} ko due hai. Meherbani kar ke update share kar dein.\n- ${_settings.shopName}',
    );
  }

  Future<void> _syncTransactionDueReminder(
    LedgerTransaction transaction,
  ) async {
    await _clearPendingReminderInboxByReferenceId(transaction.id);
    final liveTransaction = transactionById(transaction.id) ?? transaction;
    if (liveTransaction.type != TransactionType.credit ||
        liveTransaction.dueDate == null ||
        liveTransaction.paidOnTime != null) {
      return;
    }

    final customer = customerById(liveTransaction.customerId);
    if (customer == null) {
      return;
    }

    final dueDate = liveTransaction.dueDate!;
    final scheduledAt = DateTime(dueDate.year, dueDate.month, dueDate.day, 10);
    await scheduleReminderFollowUp(
      customerId: customer.id,
      dueAt: scheduledAt,
      tone: ReminderTone.normal,
      type: ReminderInboxType.scheduledReminder,
      referenceId: liveTransaction.id,
      note: 'Auto due-date reminder',
      message:
          'Assalamualaikum ${customer.name}, ${formatCurrency(liveTransaction.amount)} ki entry ${formatDate(dueDate)} ko due hai. Meherbani kar ke payment update share kar dein.\n- ${_settings.shopName}',
    );
  }

  Future<void> _clearPendingReminderInboxByReferenceId(
    String referenceId,
  ) async {
    final itemsToCancel = _reminderInbox
        .where(
          (item) =>
              item.referenceId == referenceId &&
              item.status == ReminderInboxStatus.pending,
        )
        .toList();
    for (final item in itemsToCancel) {
      await _localNotificationService?.cancel(item.notificationId);
    }
    _reminderInbox = _reminderInbox
        .where(
          (item) =>
              !(item.referenceId == referenceId &&
                  item.status == ReminderInboxStatus.pending),
        )
        .toList();
  }

  Future<void> _markPendingReminderInboxItemsByReferenceId(
    String referenceId, {
    required ReminderInboxStatus status,
  }) async {
    for (final item in _reminderInbox) {
      if (item.referenceId == referenceId &&
          item.status == ReminderInboxStatus.pending) {
        await _localNotificationService?.cancel(item.notificationId);
      }
    }
    _reminderInbox = _reminderInbox.map((item) {
      if (item.referenceId != referenceId ||
          item.status != ReminderInboxStatus.pending) {
        return item;
      }
      return item.copyWith(status: status, handledAt: DateTime.now());
    }).toList();
  }

  Future<void> _clearSettledTransactionReminders(String customerId) async {
    final settledCreditIds = transactionsFor(customerId)
        .where(
          (transaction) =>
              transaction.type == TransactionType.credit &&
              transaction.paidOnTime != null,
        )
        .map((transaction) => transaction.id)
        .toList();

    for (final transactionId in settledCreditIds) {
      await _clearPendingReminderInboxByReferenceId(transactionId);
    }
  }

  String _scheduleTitleFor(Customer customer, ReminderInboxType type) {
    switch (type) {
      case ReminderInboxType.scheduledReminder:
        return 'Scheduled reminder for ${customer.name}';
      case ReminderInboxType.bulkReminder:
        return 'Bulk reminder for ${customer.name}';
      case ReminderInboxType.promiseFollowUp:
        return 'Promise follow-up for ${customer.name}';
      case ReminderInboxType.installmentDue:
        return 'Installment due for ${customer.name}';
      case ReminderInboxType.dailyAction:
        return 'Daily action follow-up for ${customer.name}';
      case ReminderInboxType.visitFollowUp:
        return 'Visit follow-up for ${customer.name}';
    }
  }

  int _daysSince(DateTime date) {
    final now = DateTime.now();
    final target = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(target).inDays;
    return days < 0 ? 0 : days;
  }
}
