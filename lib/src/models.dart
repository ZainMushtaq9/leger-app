enum UserType {
  shopkeeper,
  business,
  schoolCollege,
  freelancerServices,
  enterprise,
}

enum AppLanguage { english, romanUrdu, urdu, sindhi, pashto }

extension AppLanguageX on AppLanguage {
  bool get isRtl {
    switch (this) {
      case AppLanguage.english:
      case AppLanguage.romanUrdu:
        return false;
      case AppLanguage.urdu:
      case AppLanguage.sindhi:
      case AppLanguage.pashto:
        return true;
    }
  }

  String get languageCode {
    switch (this) {
      case AppLanguage.english:
      case AppLanguage.romanUrdu:
        return 'en';
      case AppLanguage.urdu:
        return 'ur';
      case AppLanguage.sindhi:
        return 'sd';
      case AppLanguage.pashto:
        return 'ps';
    }
  }

  String get countryCode {
    switch (this) {
      case AppLanguage.pashto:
        return 'AF';
      case AppLanguage.english:
      case AppLanguage.romanUrdu:
      case AppLanguage.urdu:
      case AppLanguage.sindhi:
        return 'PK';
    }
  }
}

enum AppThemeMode { system, light, dark }

enum CustomerFilter { all, favourites, overdue, risky, vip, newProfiles }

enum CustomerSort { name, highestBalance, recoveryScore, lastReminder }

class AppTerminology {
  const AppTerminology({
    required this.userTypeLabel,
    required this.entitySingular,
    required this.entityPlural,
    required this.creditLabel,
    required this.outstandingLabel,
    required this.categoryLabel,
    required this.dashboardSubtitle,
    required this.reminderSubject,
    required this.entryLabel,
  });

  final String userTypeLabel;
  final String entitySingular;
  final String entityPlural;
  final String creditLabel;
  final String outstandingLabel;
  final String categoryLabel;
  final String dashboardSubtitle;
  final String reminderSubject;
  final String entryLabel;

  static AppTerminology forUserType(
    UserType userType, {
    AppLanguage language = AppLanguage.english,
  }) {
    switch (language) {
      case AppLanguage.english:
        return _english(userType);
      case AppLanguage.romanUrdu:
        return _romanUrdu(userType);
      case AppLanguage.urdu:
        return _urdu(userType);
      case AppLanguage.sindhi:
        return _sindhi(userType);
      case AppLanguage.pashto:
        return _pashto(userType);
    }
  }

  static AppTerminology _english(UserType userType) {
    switch (userType) {
      case UserType.shopkeeper:
        return const AppTerminology(
          userTypeLabel: 'Shopkeeper',
          entitySingular: 'Customer',
          entityPlural: 'Customers',
          creditLabel: 'Udhaar',
          outstandingLabel: 'Total Udhaar',
          categoryLabel: 'Category',
          dashboardSubtitle: 'Smart khata for daily recovery',
          reminderSubject: 'udhaar',
          entryLabel: 'Udhaar Entry',
        );
      case UserType.business:
        return const AppTerminology(
          userTypeLabel: 'Business',
          entitySingular: 'Client',
          entityPlural: 'Clients',
          creditLabel: 'Invoice',
          outstandingLabel: 'Total Outstanding',
          categoryLabel: 'Segment',
          dashboardSubtitle: 'Simple receivables and follow-up system',
          reminderSubject: 'payment',
          entryLabel: 'Invoice Entry',
        );
      case UserType.schoolCollege:
        return const AppTerminology(
          userTypeLabel: 'School / College',
          entitySingular: 'Student',
          entityPlural: 'Students',
          creditLabel: 'Fee',
          outstandingLabel: 'Total Fee Due',
          categoryLabel: 'Class / Group',
          dashboardSubtitle: 'Track and recover fees with clarity',
          reminderSubject: 'fee',
          entryLabel: 'Fee Entry',
        );
      case UserType.freelancerServices:
        return const AppTerminology(
          userTypeLabel: 'Freelancer / Services',
          entitySingular: 'Client',
          entityPlural: 'Clients',
          creditLabel: 'Service Due',
          outstandingLabel: 'Total Due',
          categoryLabel: 'Service Type',
          dashboardSubtitle:
              'Recover service payments with less follow-up chaos',
          reminderSubject: 'payment',
          entryLabel: 'Service Entry',
        );
      case UserType.enterprise:
        return const AppTerminology(
          userTypeLabel: 'Enterprise',
          entitySingular: 'Account',
          entityPlural: 'Accounts',
          creditLabel: 'Receivable',
          outstandingLabel: 'Total Receivable',
          categoryLabel: 'Portfolio',
          dashboardSubtitle:
              'Manage collections and receivables from one shell',
          reminderSubject: 'payment',
          entryLabel: 'Receivable Entry',
        );
    }
  }

  static AppTerminology _romanUrdu(UserType userType) {
    switch (userType) {
      case UserType.shopkeeper:
        return const AppTerminology(
          userTypeLabel: 'Shopkeeper',
          entitySingular: 'Customer',
          entityPlural: 'Customers',
          creditLabel: 'Udhaar',
          outstandingLabel: 'Total Udhaar',
          categoryLabel: 'Category',
          dashboardSubtitle: 'Udhaar ko daily recover karne wala smart khata',
          reminderSubject: 'udhaar',
          entryLabel: 'Udhaar Entry',
        );
      case UserType.business:
        return const AppTerminology(
          userTypeLabel: 'Business',
          entitySingular: 'Client',
          entityPlural: 'Clients',
          creditLabel: 'Invoice',
          outstandingLabel: 'Total Outstanding',
          categoryLabel: 'Segment',
          dashboardSubtitle:
              'Receivables aur follow-ups ko simple rakhne wala smart system',
          reminderSubject: 'payment',
          entryLabel: 'Invoice Entry',
        );
      case UserType.schoolCollege:
        return const AppTerminology(
          userTypeLabel: 'School / College',
          entitySingular: 'Student',
          entityPlural: 'Students',
          creditLabel: 'Fee',
          outstandingLabel: 'Total Fee Due',
          categoryLabel: 'Class / Group',
          dashboardSubtitle:
              'Fees ko track aur recover karne wala smart system',
          reminderSubject: 'fee',
          entryLabel: 'Fee Entry',
        );
      case UserType.freelancerServices:
        return const AppTerminology(
          userTypeLabel: 'Freelancer / Services',
          entitySingular: 'Client',
          entityPlural: 'Clients',
          creditLabel: 'Service Due',
          outstandingLabel: 'Total Due',
          categoryLabel: 'Service Type',
          dashboardSubtitle:
              'Client payments ko recover karne wala smart system',
          reminderSubject: 'payment',
          entryLabel: 'Service Entry',
        );
      case UserType.enterprise:
        return const AppTerminology(
          userTypeLabel: 'Enterprise',
          entitySingular: 'Account',
          entityPlural: 'Accounts',
          creditLabel: 'Receivable',
          outstandingLabel: 'Total Receivable',
          categoryLabel: 'Portfolio',
          dashboardSubtitle:
              'Receivables aur collections ko manage karne wala smart system',
          reminderSubject: 'payment',
          entryLabel: 'Receivable Entry',
        );
    }
  }

  static AppTerminology _urdu(UserType userType) {
    switch (userType) {
      case UserType.shopkeeper:
        return const AppTerminology(
          userTypeLabel: 'دکاندار',
          entitySingular: 'گاہک',
          entityPlural: 'گاہک',
          creditLabel: 'ادھار',
          outstandingLabel: 'کل ادھار',
          categoryLabel: 'قسم',
          dashboardSubtitle: 'روزانہ وصولی کے لیے اسمارٹ کھاتہ',
          reminderSubject: 'ادھار',
          entryLabel: 'ادھار انٹری',
        );
      case UserType.business:
        return const AppTerminology(
          userTypeLabel: 'بزنس',
          entitySingular: 'کلائنٹ',
          entityPlural: 'کلائنٹس',
          creditLabel: 'انوائس',
          outstandingLabel: 'کل بقایا',
          categoryLabel: 'سیگمنٹ',
          dashboardSubtitle: 'وصولیوں اور فالو اپس کے لیے سادہ سسٹم',
          reminderSubject: 'ادائیگی',
          entryLabel: 'انوائس انٹری',
        );
      case UserType.schoolCollege:
        return const AppTerminology(
          userTypeLabel: 'اسکول / کالج',
          entitySingular: 'طالب علم',
          entityPlural: 'طلبہ',
          creditLabel: 'فیس',
          outstandingLabel: 'کل واجب الادا فیس',
          categoryLabel: 'کلاس / گروپ',
          dashboardSubtitle: 'فیس ٹریک اور وصول کرنے والا سسٹم',
          reminderSubject: 'فیس',
          entryLabel: 'فیس انٹری',
        );
      case UserType.freelancerServices:
        return const AppTerminology(
          userTypeLabel: 'فری لانسر / سروسز',
          entitySingular: 'کلائنٹ',
          entityPlural: 'کلائنٹس',
          creditLabel: 'سروس ڈیو',
          outstandingLabel: 'کل بقایا',
          categoryLabel: 'سروس کی قسم',
          dashboardSubtitle: 'کلائنٹ پیمنٹس کو سنبھالنے والا سسٹم',
          reminderSubject: 'ادائیگی',
          entryLabel: 'سروس انٹری',
        );
      case UserType.enterprise:
        return const AppTerminology(
          userTypeLabel: 'انٹرپرائز',
          entitySingular: 'اکاؤنٹ',
          entityPlural: 'اکاؤنٹس',
          creditLabel: 'وصولی',
          outstandingLabel: 'کل وصولی',
          categoryLabel: 'پورٹ فولیو',
          dashboardSubtitle: 'کلیکشنز اور رسیویبلز کے لیے مرکزی شیل',
          reminderSubject: 'ادائیگی',
          entryLabel: 'وصولی انٹری',
        );
    }
  }

  static AppTerminology _sindhi(UserType userType) {
    switch (userType) {
      case UserType.shopkeeper:
        return const AppTerminology(
          userTypeLabel: 'دوڪاندار',
          entitySingular: 'گراهڪ',
          entityPlural: 'گراهڪ',
          creditLabel: 'اڌار',
          outstandingLabel: 'ڪل اڌار',
          categoryLabel: 'قسم',
          dashboardSubtitle: 'روزاني وصولي لاءِ سمارٽ کاتو',
          reminderSubject: 'اڌار',
          entryLabel: 'اڌار انٽري',
        );
      case UserType.business:
        return const AppTerminology(
          userTypeLabel: 'ڪاروبار',
          entitySingular: 'ڪلائنٽ',
          entityPlural: 'ڪلائنٽس',
          creditLabel: 'انوائس',
          outstandingLabel: 'ڪل بقايا',
          categoryLabel: 'سيگمينٽ',
          dashboardSubtitle: 'وصولين ۽ فالو اپ لاءِ سادو نظام',
          reminderSubject: 'ادائيگي',
          entryLabel: 'انوائس انٽري',
        );
      case UserType.schoolCollege:
        return const AppTerminology(
          userTypeLabel: 'اسڪول / ڪاليج',
          entitySingular: 'شاگرد',
          entityPlural: 'شاگرد',
          creditLabel: 'فيس',
          outstandingLabel: 'ڪل واجب الادا فيس',
          categoryLabel: 'ڪلاس / گروپ',
          dashboardSubtitle: 'فيس ٽريڪ ۽ وصول ڪرڻ وارو نظام',
          reminderSubject: 'فيس',
          entryLabel: 'فيس انٽري',
        );
      case UserType.freelancerServices:
        return const AppTerminology(
          userTypeLabel: 'فري لانسر / خدمتون',
          entitySingular: 'ڪلائنٽ',
          entityPlural: 'ڪلائنٽس',
          creditLabel: 'سروس ڊيو',
          outstandingLabel: 'ڪل بقايا',
          categoryLabel: 'سروس قسم',
          dashboardSubtitle: 'ڪلائنٽ ادائيگين لاءِ سادو نظام',
          reminderSubject: 'ادائيگي',
          entryLabel: 'سروس انٽري',
        );
      case UserType.enterprise:
        return const AppTerminology(
          userTypeLabel: 'ادارو',
          entitySingular: 'اکائونٽ',
          entityPlural: 'اکائونٽس',
          creditLabel: 'وصولي',
          outstandingLabel: 'ڪل وصولي',
          categoryLabel: 'پورٽ فوليو',
          dashboardSubtitle: 'ڪليڪشنز ۽ رسي ويبلز لاءِ مرڪزي شيل',
          reminderSubject: 'ادائيگي',
          entryLabel: 'وصولي انٽري',
        );
    }
  }

  static AppTerminology _pashto(UserType userType) {
    switch (userType) {
      case UserType.shopkeeper:
        return const AppTerminology(
          userTypeLabel: 'دوکاندار',
          entitySingular: 'پېرودونکی',
          entityPlural: 'پېرودونکي',
          creditLabel: 'پور',
          outstandingLabel: 'ټول پور',
          categoryLabel: 'کټه ګوري',
          dashboardSubtitle: 'د ورځنۍ وصولۍ لپاره هوښيار ختا',
          reminderSubject: 'پور',
          entryLabel: 'د پور ثبت',
        );
      case UserType.business:
        return const AppTerminology(
          userTypeLabel: 'سوداګري',
          entitySingular: 'مراجع',
          entityPlural: 'مراجعین',
          creditLabel: 'انوایس',
          outstandingLabel: 'ټول پاتې',
          categoryLabel: 'برخه',
          dashboardSubtitle: 'د وصوليو او تعقيب لپاره ساده سيستم',
          reminderSubject: 'تاديه',
          entryLabel: 'د انوايس ثبت',
        );
      case UserType.schoolCollege:
        return const AppTerminology(
          userTypeLabel: 'ښوونځی / کالج',
          entitySingular: 'زده کوونکی',
          entityPlural: 'زده کوونکي',
          creditLabel: 'فيس',
          outstandingLabel: 'ټول پاتې فيس',
          categoryLabel: 'ټولګی / ډله',
          dashboardSubtitle: 'د فيس د څارنې او وصولۍ لپاره سيستم',
          reminderSubject: 'فيس',
          entryLabel: 'د فيس ثبت',
        );
      case UserType.freelancerServices:
        return const AppTerminology(
          userTypeLabel: 'فري لانسر / خدمتونه',
          entitySingular: 'مراجع',
          entityPlural: 'مراجعین',
          creditLabel: 'خدمت پاتې',
          outstandingLabel: 'ټول پاتې',
          categoryLabel: 'د خدمت ډول',
          dashboardSubtitle: 'د مراجع تادياتو د تعقيب لپاره سيستم',
          reminderSubject: 'تاديه',
          entryLabel: 'د خدمت ثبت',
        );
      case UserType.enterprise:
        return const AppTerminology(
          userTypeLabel: 'ستر سازمان',
          entitySingular: 'اکاونټ',
          entityPlural: 'اکاونټونه',
          creditLabel: 'وصولي',
          outstandingLabel: 'ټول وصولي',
          categoryLabel: 'پورټفوليو',
          dashboardSubtitle: 'د وصوليو او ټولونو لپاره مرکزي شيل',
          reminderSubject: 'تاديه',
          entryLabel: 'د وصولۍ ثبت',
        );
    }
  }
}

class ShopDraft {
  const ShopDraft({
    required this.name,
    required this.phone,
    required this.userType,
  });

  final String name;
  final String phone;
  final UserType userType;
}

class ShopProfile {
  const ShopProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.userType,
    required this.createdAt,
    this.address = '',
    this.email = '',
    this.tagline = '',
    this.ntn = '',
    this.strn = '',
    this.invoicePrefix = 'INV',
    this.quotationPrefix = 'QTN',
    this.salesTaxPercent = 0,
  });

  final String id;
  final String name;
  final String phone;
  final UserType userType;
  final DateTime createdAt;
  final String address;
  final String email;
  final String tagline;
  final String ntn;
  final String strn;
  final String invoicePrefix;
  final String quotationPrefix;
  final double salesTaxPercent;

  ShopProfile copyWith({
    String? id,
    String? name,
    String? phone,
    UserType? userType,
    DateTime? createdAt,
    String? address,
    String? email,
    String? tagline,
    String? ntn,
    String? strn,
    String? invoicePrefix,
    String? quotationPrefix,
    double? salesTaxPercent,
  }) {
    return ShopProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      address: address ?? this.address,
      email: email ?? this.email,
      tagline: tagline ?? this.tagline,
      ntn: ntn ?? this.ntn,
      strn: strn ?? this.strn,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      quotationPrefix: quotationPrefix ?? this.quotationPrefix,
      salesTaxPercent: salesTaxPercent ?? this.salesTaxPercent,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'phone': phone,
      'userType': userType.name,
      'createdAt': createdAt.toIso8601String(),
      'address': address,
      'email': email,
      'tagline': tagline,
      'ntn': ntn,
      'strn': strn,
      'invoicePrefix': invoicePrefix,
      'quotationPrefix': quotationPrefix,
      'salesTaxPercent': salesTaxPercent,
    };
  }

  factory ShopProfile.fromJson(Map<String, dynamic> json) {
    final rawType = json['userType'] as String?;
    return ShopProfile(
      id: json['id'] as String? ?? AppSettings.defaultShopId,
      name: json['name'] as String? ?? 'Hisab Rakho Store',
      phone: json['phone'] as String? ?? '',
      userType: rawType == null
          ? UserType.shopkeeper
          : UserType.values.firstWhere(
              (value) => value.name == rawType,
              orElse: () => UserType.shopkeeper,
            ),
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['createdAt'] as String),
      address: json['address'] as String? ?? '',
      email: json['email'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      ntn: json['ntn'] as String? ?? '',
      strn: json['strn'] as String? ?? '',
      invoicePrefix: json['invoicePrefix'] as String? ?? 'INV',
      quotationPrefix: json['quotationPrefix'] as String? ?? 'QTN',
      salesTaxPercent: (json['salesTaxPercent'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Customer {
  const Customer({
    required this.id,
    required this.shopId,
    required this.shareCode,
    required this.name,
    required this.phone,
    required this.createdAt,
    this.category = 'Regular',
    this.address = '',
    this.notes = '',
    this.tag = '',
    this.city = '',
    this.cnic = '',
    this.referredByCustomerId,
    this.groupName = '',
    this.creditLimit,
    this.isFavourite = false,
    this.isHidden = false,
    this.lastReminderAt,
    this.reminderCount = 0,
    this.seasonalPauseMonths = const <int>[],
    this.promisedPaymentDate,
    this.promisedPaymentAmount,
  });

  final String id;
  final String shopId;
  final String shareCode;
  final String name;
  final String phone;
  final DateTime createdAt;
  final String category;
  final String address;
  final String notes;
  final String tag;
  final String city;
  final String cnic;
  final String? referredByCustomerId;
  final String groupName;
  final double? creditLimit;
  final bool isFavourite;
  final bool isHidden;
  final DateTime? lastReminderAt;
  final int reminderCount;
  final List<int> seasonalPauseMonths;
  final DateTime? promisedPaymentDate;
  final double? promisedPaymentAmount;

  Customer copyWith({
    String? id,
    String? shopId,
    String? shareCode,
    String? name,
    String? phone,
    DateTime? createdAt,
    String? category,
    String? address,
    String? notes,
    String? tag,
    String? city,
    String? cnic,
    String? referredByCustomerId,
    String? groupName,
    double? creditLimit,
    bool? isFavourite,
    bool? isHidden,
    DateTime? lastReminderAt,
    int? reminderCount,
    List<int>? seasonalPauseMonths,
    DateTime? promisedPaymentDate,
    double? promisedPaymentAmount,
    bool clearCreditLimit = false,
    bool clearReferredByCustomerId = false,
    bool clearLastReminderAt = false,
    bool clearPromisedPaymentDate = false,
    bool clearPromisedPaymentAmount = false,
  }) {
    return Customer(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      shareCode: shareCode ?? this.shareCode,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      tag: tag ?? this.tag,
      city: city ?? this.city,
      cnic: cnic ?? this.cnic,
      referredByCustomerId: clearReferredByCustomerId
          ? null
          : referredByCustomerId ?? this.referredByCustomerId,
      groupName: groupName ?? this.groupName,
      creditLimit: clearCreditLimit ? null : creditLimit ?? this.creditLimit,
      isFavourite: isFavourite ?? this.isFavourite,
      isHidden: isHidden ?? this.isHidden,
      lastReminderAt: clearLastReminderAt
          ? null
          : lastReminderAt ?? this.lastReminderAt,
      reminderCount: reminderCount ?? this.reminderCount,
      seasonalPauseMonths:
          seasonalPauseMonths ?? List<int>.from(this.seasonalPauseMonths),
      promisedPaymentDate: clearPromisedPaymentDate
          ? null
          : promisedPaymentDate ?? this.promisedPaymentDate,
      promisedPaymentAmount: clearPromisedPaymentAmount
          ? null
          : promisedPaymentAmount ?? this.promisedPaymentAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'shopId': shopId,
      'shareCode': shareCode,
      'name': name,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
      'address': address,
      'notes': notes,
      'tag': tag,
      'city': city,
      'cnic': cnic,
      'referredByCustomerId': referredByCustomerId,
      'groupName': groupName,
      'creditLimit': creditLimit,
      'isFavourite': isFavourite,
      'isHidden': isHidden,
      'lastReminderAt': lastReminderAt?.toIso8601String(),
      'reminderCount': reminderCount,
      'seasonalPauseMonths': seasonalPauseMonths,
      'promisedPaymentDate': promisedPaymentDate?.toIso8601String(),
      'promisedPaymentAmount': promisedPaymentAmount,
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    final rawPauseMonths =
        json['seasonalPauseMonths'] as List<dynamic>? ?? const <dynamic>[];
    return Customer(
      id: json['id'] as String,
      shopId: json['shopId'] as String? ?? AppSettings.defaultShopId,
      shareCode: json['shareCode'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      category: json['category'] as String? ?? 'Regular',
      address: json['address'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      city: json['city'] as String? ?? '',
      cnic: json['cnic'] as String? ?? '',
      referredByCustomerId: json['referredByCustomerId'] as String?,
      groupName: json['groupName'] as String? ?? '',
      creditLimit: (json['creditLimit'] as num?)?.toDouble(),
      isFavourite: json['isFavourite'] as bool? ?? false,
      isHidden: json['isHidden'] as bool? ?? false,
      lastReminderAt: json['lastReminderAt'] == null
          ? null
          : DateTime.parse(json['lastReminderAt'] as String),
      reminderCount: (json['reminderCount'] as num?)?.toInt() ?? 0,
      seasonalPauseMonths: rawPauseMonths
          .map((item) => (item as num).toInt())
          .toList(),
      promisedPaymentDate: json['promisedPaymentDate'] == null
          ? null
          : DateTime.parse(json['promisedPaymentDate'] as String),
      promisedPaymentAmount: (json['promisedPaymentAmount'] as num?)
          ?.toDouble(),
    );
  }
}

enum TransactionType { credit, payment }

class LedgerTransaction {
  const LedgerTransaction({
    required this.id,
    required this.customerId,
    required this.shopId,
    required this.amount,
    required this.type,
    required this.note,
    required this.date,
    this.dueDate,
    this.paidOnTime,
    this.isDisputed = false,
    this.reference = '',
    this.attachmentLabel = '',
    this.receiptPath = '',
    this.audioNotePath = '',
  });

  final String id;
  final String customerId;
  final String shopId;
  final double amount;
  final TransactionType type;
  final String note;
  final DateTime date;
  final DateTime? dueDate;
  final bool? paidOnTime;
  final bool isDisputed;
  final String reference;
  final String attachmentLabel;
  final String receiptPath;
  final String audioNotePath;

  LedgerTransaction copyWith({
    String? id,
    String? customerId,
    String? shopId,
    double? amount,
    TransactionType? type,
    String? note,
    DateTime? date,
    DateTime? dueDate,
    bool? paidOnTime,
    bool? isDisputed,
    String? reference,
    String? attachmentLabel,
    String? receiptPath,
    String? audioNotePath,
    bool clearDueDate = false,
    bool clearPaidOnTime = false,
    bool clearReceiptPath = false,
    bool clearAudioNotePath = false,
  }) {
    return LedgerTransaction(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      shopId: shopId ?? this.shopId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      note: note ?? this.note,
      date: date ?? this.date,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      paidOnTime: clearPaidOnTime ? null : paidOnTime ?? this.paidOnTime,
      isDisputed: isDisputed ?? this.isDisputed,
      reference: reference ?? this.reference,
      attachmentLabel: attachmentLabel ?? this.attachmentLabel,
      receiptPath: clearReceiptPath ? '' : receiptPath ?? this.receiptPath,
      audioNotePath: clearAudioNotePath
          ? ''
          : audioNotePath ?? this.audioNotePath,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'customerId': customerId,
      'shopId': shopId,
      'amount': amount,
      'type': type.name,
      'note': note,
      'date': date.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'paidOnTime': paidOnTime,
      'isDisputed': isDisputed,
      'reference': reference,
      'attachmentLabel': attachmentLabel,
      'receiptPath': receiptPath,
      'audioNotePath': audioNotePath,
    };
  }

  factory LedgerTransaction.fromJson(Map<String, dynamic> json) {
    return LedgerTransaction(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      shopId: json['shopId'] as String? ?? AppSettings.defaultShopId,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (value) => value.name == json['type'],
      ),
      note: json['note'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      paidOnTime: json['paidOnTime'] as bool?,
      isDisputed: json['isDisputed'] as bool? ?? false,
      reference: json['reference'] as String? ?? '',
      attachmentLabel: json['attachmentLabel'] as String? ?? '',
      receiptPath: json['receiptPath'] as String? ?? '',
      audioNotePath: json['audioNotePath'] as String? ?? '',
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.shopName,
    required this.organizationPhone,
    required this.userType,
    required this.hasCompletedOnboarding,
    required this.isPaidUser,
    required this.lowDataMode,
    this.language = AppLanguage.english,
    this.adsEnabled = true,
    this.autoBackupDays = 0,
    this.autoLockMinutes = 5,
    this.lastBackupAt,
    this.cloudSyncEnabled = false,
    this.cloudWorkspaceId = '',
    this.cloudDeviceLabel = '',
    this.lastCloudSyncAt,
    this.lastCloudRestoreAt,
    this.cloudSyncLastError = '',
    this.cloudAccountId = '',
    this.cloudAccountEmail = '',
    this.cloudAccountPhone = '',
    this.cloudAccountDisplayName = '',
    this.cloudAccountProvider = '',
    this.cloudAccountEmailVerified = false,
    this.lastCloudAccountSignInAt,
    this.activeShopId = defaultShopId,
    this.themeMode = AppThemeMode.system,
    this.appLockEnabled = false,
    this.biometricUnlockEnabled = false,
    this.hideBalances = false,
    this.hideHiddenCustomers = false,
    this.communityBlacklistEnabled = false,
    this.decoyModeEnabled = false,
    this.pinHash = '',
    this.pinSalt = '',
    this.decoyPinHash = '',
    this.decoyPinSalt = '',
  });

  static const String defaultShopId = 'shop-default';

  final String shopName;
  final String organizationPhone;
  final UserType userType;
  final bool hasCompletedOnboarding;
  final bool isPaidUser;
  final bool lowDataMode;
  final AppLanguage language;
  final bool adsEnabled;
  final int autoBackupDays;
  final int autoLockMinutes;
  final DateTime? lastBackupAt;
  final bool cloudSyncEnabled;
  final String cloudWorkspaceId;
  final String cloudDeviceLabel;
  final DateTime? lastCloudSyncAt;
  final DateTime? lastCloudRestoreAt;
  final String cloudSyncLastError;
  final String cloudAccountId;
  final String cloudAccountEmail;
  final String cloudAccountPhone;
  final String cloudAccountDisplayName;
  final String cloudAccountProvider;
  final bool cloudAccountEmailVerified;
  final DateTime? lastCloudAccountSignInAt;
  final String activeShopId;
  final AppThemeMode themeMode;
  final bool appLockEnabled;
  final bool biometricUnlockEnabled;
  final bool hideBalances;
  final bool hideHiddenCustomers;
  final bool communityBlacklistEnabled;
  final bool decoyModeEnabled;
  final String pinHash;
  final String pinSalt;
  final String decoyPinHash;
  final String decoyPinSalt;

  AppSettings copyWith({
    String? shopName,
    String? organizationPhone,
    UserType? userType,
    bool? hasCompletedOnboarding,
    bool? isPaidUser,
    bool? lowDataMode,
    AppLanguage? language,
    bool? adsEnabled,
    int? autoBackupDays,
    int? autoLockMinutes,
    DateTime? lastBackupAt,
    bool? cloudSyncEnabled,
    String? cloudWorkspaceId,
    String? cloudDeviceLabel,
    DateTime? lastCloudSyncAt,
    DateTime? lastCloudRestoreAt,
    String? cloudSyncLastError,
    String? cloudAccountId,
    String? cloudAccountEmail,
    String? cloudAccountPhone,
    String? cloudAccountDisplayName,
    String? cloudAccountProvider,
    bool? cloudAccountEmailVerified,
    DateTime? lastCloudAccountSignInAt,
    String? activeShopId,
    AppThemeMode? themeMode,
    bool? appLockEnabled,
    bool? biometricUnlockEnabled,
    bool? hideBalances,
    bool? hideHiddenCustomers,
    bool? communityBlacklistEnabled,
    bool? decoyModeEnabled,
    String? pinHash,
    String? pinSalt,
    String? decoyPinHash,
    String? decoyPinSalt,
    bool clearLastBackupAt = false,
    bool clearLastCloudSyncAt = false,
    bool clearLastCloudRestoreAt = false,
    bool clearCloudSyncLastError = false,
    bool clearCloudAccount = false,
    bool clearPinHash = false,
    bool clearPinSalt = false,
    bool clearDecoyPinHash = false,
    bool clearDecoyPinSalt = false,
  }) {
    return AppSettings(
      shopName: shopName ?? this.shopName,
      organizationPhone: organizationPhone ?? this.organizationPhone,
      userType: userType ?? this.userType,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      isPaidUser: isPaidUser ?? this.isPaidUser,
      lowDataMode: lowDataMode ?? this.lowDataMode,
      language: language ?? this.language,
      adsEnabled: adsEnabled ?? this.adsEnabled,
      autoBackupDays: autoBackupDays ?? this.autoBackupDays,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      lastBackupAt: clearLastBackupAt
          ? null
          : lastBackupAt ?? this.lastBackupAt,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      cloudWorkspaceId: cloudWorkspaceId ?? this.cloudWorkspaceId,
      cloudDeviceLabel: cloudDeviceLabel ?? this.cloudDeviceLabel,
      lastCloudSyncAt: clearLastCloudSyncAt
          ? null
          : lastCloudSyncAt ?? this.lastCloudSyncAt,
      lastCloudRestoreAt: clearLastCloudRestoreAt
          ? null
          : lastCloudRestoreAt ?? this.lastCloudRestoreAt,
      cloudSyncLastError: clearCloudSyncLastError
          ? ''
          : cloudSyncLastError ?? this.cloudSyncLastError,
      cloudAccountId: clearCloudAccount
          ? ''
          : cloudAccountId ?? this.cloudAccountId,
      cloudAccountEmail: clearCloudAccount
          ? ''
          : cloudAccountEmail ?? this.cloudAccountEmail,
      cloudAccountPhone: clearCloudAccount
          ? ''
          : cloudAccountPhone ?? this.cloudAccountPhone,
      cloudAccountDisplayName: clearCloudAccount
          ? ''
          : cloudAccountDisplayName ?? this.cloudAccountDisplayName,
      cloudAccountProvider: clearCloudAccount
          ? ''
          : cloudAccountProvider ?? this.cloudAccountProvider,
      cloudAccountEmailVerified: clearCloudAccount
          ? false
          : cloudAccountEmailVerified ?? this.cloudAccountEmailVerified,
      lastCloudAccountSignInAt: clearCloudAccount
          ? null
          : lastCloudAccountSignInAt ?? this.lastCloudAccountSignInAt,
      activeShopId: activeShopId ?? this.activeShopId,
      themeMode: themeMode ?? this.themeMode,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      biometricUnlockEnabled:
          biometricUnlockEnabled ?? this.biometricUnlockEnabled,
      hideBalances: hideBalances ?? this.hideBalances,
      hideHiddenCustomers: hideHiddenCustomers ?? this.hideHiddenCustomers,
      communityBlacklistEnabled:
          communityBlacklistEnabled ?? this.communityBlacklistEnabled,
      decoyModeEnabled: decoyModeEnabled ?? this.decoyModeEnabled,
      pinHash: clearPinHash ? '' : pinHash ?? this.pinHash,
      pinSalt: clearPinSalt ? '' : pinSalt ?? this.pinSalt,
      decoyPinHash: clearDecoyPinHash ? '' : decoyPinHash ?? this.decoyPinHash,
      decoyPinSalt: clearDecoyPinSalt ? '' : decoyPinSalt ?? this.decoyPinSalt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'shopName': shopName,
      'organizationPhone': organizationPhone,
      'userType': userType.name,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'isPaidUser': isPaidUser,
      'lowDataMode': lowDataMode,
      'language': language.name,
      'adsEnabled': adsEnabled,
      'autoBackupDays': autoBackupDays,
      'autoLockMinutes': autoLockMinutes,
      'lastBackupAt': lastBackupAt?.toIso8601String(),
      'cloudSyncEnabled': cloudSyncEnabled,
      'cloudWorkspaceId': cloudWorkspaceId,
      'cloudDeviceLabel': cloudDeviceLabel,
      'lastCloudSyncAt': lastCloudSyncAt?.toIso8601String(),
      'lastCloudRestoreAt': lastCloudRestoreAt?.toIso8601String(),
      'cloudSyncLastError': cloudSyncLastError,
      'cloudAccountId': cloudAccountId,
      'cloudAccountEmail': cloudAccountEmail,
      'cloudAccountPhone': cloudAccountPhone,
      'cloudAccountDisplayName': cloudAccountDisplayName,
      'cloudAccountProvider': cloudAccountProvider,
      'cloudAccountEmailVerified': cloudAccountEmailVerified,
      'lastCloudAccountSignInAt': lastCloudAccountSignInAt?.toIso8601String(),
      'activeShopId': activeShopId,
      'themeMode': themeMode.name,
      'appLockEnabled': appLockEnabled,
      'biometricUnlockEnabled': biometricUnlockEnabled,
      'hideBalances': hideBalances,
      'hideHiddenCustomers': hideHiddenCustomers,
      'communityBlacklistEnabled': communityBlacklistEnabled,
      'decoyModeEnabled': decoyModeEnabled,
      'pinHash': pinHash,
      'pinSalt': pinSalt,
      'decoyPinHash': decoyPinHash,
      'decoyPinSalt': decoyPinSalt,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final storedType = json['userType'] as String?;
    final storedLanguage = json['language'] as String?;
    final storedThemeMode = json['themeMode'] as String?;
    return AppSettings(
      shopName: json['shopName'] as String? ?? 'Hisab Rakho Store',
      organizationPhone: json['organizationPhone'] as String? ?? '',
      userType: storedType == null
          ? UserType.shopkeeper
          : UserType.values.firstWhere(
              (value) => value.name == storedType,
              orElse: () => UserType.shopkeeper,
            ),
      hasCompletedOnboarding:
          json['hasCompletedOnboarding'] as bool? ??
          json.containsKey('shopName'),
      isPaidUser: json['isPaidUser'] as bool? ?? false,
      lowDataMode: json['lowDataMode'] as bool? ?? false,
      language: _languageFromStorage(storedLanguage),
      adsEnabled: json['adsEnabled'] as bool? ?? true,
      autoBackupDays: (json['autoBackupDays'] as num?)?.toInt() ?? 0,
      autoLockMinutes: (json['autoLockMinutes'] as num?)?.toInt() ?? 5,
      lastBackupAt: json['lastBackupAt'] == null
          ? null
          : DateTime.parse(json['lastBackupAt'] as String),
      cloudSyncEnabled: json['cloudSyncEnabled'] as bool? ?? false,
      cloudWorkspaceId: json['cloudWorkspaceId'] as String? ?? '',
      cloudDeviceLabel: json['cloudDeviceLabel'] as String? ?? '',
      lastCloudSyncAt: json['lastCloudSyncAt'] == null
          ? null
          : DateTime.parse(json['lastCloudSyncAt'] as String),
      lastCloudRestoreAt: json['lastCloudRestoreAt'] == null
          ? null
          : DateTime.parse(json['lastCloudRestoreAt'] as String),
      cloudSyncLastError: json['cloudSyncLastError'] as String? ?? '',
      cloudAccountId: json['cloudAccountId'] as String? ?? '',
      cloudAccountEmail: json['cloudAccountEmail'] as String? ?? '',
      cloudAccountPhone: json['cloudAccountPhone'] as String? ?? '',
      cloudAccountDisplayName: json['cloudAccountDisplayName'] as String? ?? '',
      cloudAccountProvider: json['cloudAccountProvider'] as String? ?? '',
      cloudAccountEmailVerified:
          json['cloudAccountEmailVerified'] as bool? ?? false,
      lastCloudAccountSignInAt: json['lastCloudAccountSignInAt'] == null
          ? null
          : DateTime.parse(json['lastCloudAccountSignInAt'] as String),
      activeShopId: json['activeShopId'] as String? ?? defaultShopId,
      themeMode: storedThemeMode == null
          ? AppThemeMode.system
          : AppThemeMode.values.firstWhere(
              (value) => value.name == storedThemeMode,
              orElse: () => AppThemeMode.system,
            ),
      appLockEnabled: json['appLockEnabled'] as bool? ?? false,
      biometricUnlockEnabled: json['biometricUnlockEnabled'] as bool? ?? false,
      hideBalances: json['hideBalances'] as bool? ?? false,
      hideHiddenCustomers: json['hideHiddenCustomers'] as bool? ?? false,
      communityBlacklistEnabled:
          json['communityBlacklistEnabled'] as bool? ?? false,
      decoyModeEnabled: json['decoyModeEnabled'] as bool? ?? false,
      pinHash: json['pinHash'] as String? ?? '',
      pinSalt: json['pinSalt'] as String? ?? '',
      decoyPinHash: json['decoyPinHash'] as String? ?? '',
      decoyPinSalt: json['decoyPinSalt'] as String? ?? '',
    );
  }

  static AppLanguage _languageFromStorage(String? value) {
    if (value == null) {
      return AppLanguage.english;
    }
    if (value == 'romanUrdu') {
      return AppLanguage.romanUrdu;
    }
    return AppLanguage.values.firstWhere(
      (language) => language.name == value,
      orElse: () => AppLanguage.english,
    );
  }
}

enum ReminderTone { soft, normal, strict }

enum PaymentChance { high, medium, low }

enum UrgencyLevel { normal, warning, danger }

class CustomerInsight {
  const CustomerInsight({
    required this.balance,
    required this.overdueDays,
    required this.recoveryScore,
    required this.paymentChance,
    required this.urgency,
    required this.recommendedTone,
    required this.totalCredits,
    required this.totalPayments,
    required this.pendingSince,
    required this.lastReminderAt,
    required this.seasonalPauseActive,
    required this.isOverCreditLimit,
    required this.creditLimit,
  });

  final double balance;
  final int overdueDays;
  final int recoveryScore;
  final PaymentChance paymentChance;
  final UrgencyLevel urgency;
  final ReminderTone recommendedTone;
  final double totalCredits;
  final double totalPayments;
  final DateTime? pendingSince;
  final DateTime? lastReminderAt;
  final bool seasonalPauseActive;
  final bool isOverCreditLimit;
  final double? creditLimit;
}

class DailyAction {
  const DailyAction({
    required this.customerId,
    required this.title,
    required this.subtitle,
    required this.tone,
  });

  final String customerId;
  final String title;
  final String subtitle;
  final ReminderTone tone;
}

enum ReportRangePreset {
  last7Days,
  thisMonth,
  thisQuarter,
  thisYear,
  allTime,
  custom,
}

class ReportRange {
  const ReportRange({required this.label, this.start, this.end});

  final String label;
  final DateTime? start;
  final DateTime? end;

  DateTime? get startAt =>
      start == null ? null : DateTime(start!.year, start!.month, start!.day);

  DateTime? get endAt => end == null
      ? null
      : DateTime(end!.year, end!.month, end!.day, 23, 59, 59, 999, 999);

  bool contains(DateTime value) {
    final startValue = startAt;
    final endValue = endAt;
    if (startValue != null && value.isBefore(startValue)) {
      return false;
    }
    if (endValue != null && value.isAfter(endValue)) {
      return false;
    }
    return true;
  }
}

class CashFlowBucket {
  const CashFlowBucket({
    required this.label,
    required this.credits,
    required this.payments,
  });

  final String label;
  final double credits;
  final double payments;

  double get net => payments - credits;
}

class LocalDataProtectionStatus {
  const LocalDataProtectionStatus({
    required this.storageLabel,
    required this.encryptedAtRest,
    required this.keyStoredSecurely,
    required this.usesDeviceVault,
  });

  final String storageLabel;
  final bool encryptedAtRest;
  final bool keyStoredSecurely;
  final bool usesDeviceVault;

  String get statusLabel =>
      encryptedAtRest ? 'Encrypted local vault' : 'Standard local storage';
}

enum PartnerAccessRole { viewer, operator, manager }

class PartnerAccessProfile {
  const PartnerAccessProfile({
    required this.id,
    required this.shopId,
    required this.name,
    required this.createdAt,
    this.phone = '',
    this.email = '',
    this.role = PartnerAccessRole.viewer,
    this.inviteCode = '',
    this.canViewHiddenProfiles = false,
    this.canExportReports = false,
    this.isActive = true,
  });

  final String id;
  final String shopId;
  final String name;
  final DateTime createdAt;
  final String phone;
  final String email;
  final PartnerAccessRole role;
  final String inviteCode;
  final bool canViewHiddenProfiles;
  final bool canExportReports;
  final bool isActive;

  PartnerAccessProfile copyWith({
    String? id,
    String? shopId,
    String? name,
    DateTime? createdAt,
    String? phone,
    String? email,
    PartnerAccessRole? role,
    String? inviteCode,
    bool? canViewHiddenProfiles,
    bool? canExportReports,
    bool? isActive,
  }) {
    return PartnerAccessProfile(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      inviteCode: inviteCode ?? this.inviteCode,
      canViewHiddenProfiles:
          canViewHiddenProfiles ?? this.canViewHiddenProfiles,
      canExportReports: canExportReports ?? this.canExportReports,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'shopId': shopId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'phone': phone,
      'email': email,
      'role': role.name,
      'inviteCode': inviteCode,
      'canViewHiddenProfiles': canViewHiddenProfiles,
      'canExportReports': canExportReports,
      'isActive': isActive,
    };
  }

  factory PartnerAccessProfile.fromJson(Map<String, dynamic> json) {
    final rawRole = json['role'] as String?;
    return PartnerAccessProfile(
      id: json['id'] as String,
      shopId: json['shopId'] as String? ?? AppSettings.defaultShopId,
      name: json['name'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: rawRole == null
          ? PartnerAccessRole.viewer
          : PartnerAccessRole.values.firstWhere(
              (value) => value.name == rawRole,
              orElse: () => PartnerAccessRole.viewer,
            ),
      inviteCode: json['inviteCode'] as String? ?? '',
      canViewHiddenProfiles: json['canViewHiddenProfiles'] as bool? ?? false,
      canExportReports: json['canExportReports'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class ProfitLossSummary {
  const ProfitLossSummary({
    required this.totalSales,
    required this.cashSales,
    required this.udhaarSales,
    required this.costOfGoodsSold,
    required this.grossProfit,
    required this.payrollExpense,
    required this.operatingProfit,
  });

  final double totalSales;
  final double cashSales;
  final double udhaarSales;
  final double costOfGoodsSold;
  final double grossProfit;
  final double payrollExpense;
  final double operatingProfit;
}

class TaxSummary {
  const TaxSummary({
    required this.salesTaxRate,
    required this.grossSales,
    required this.taxableSales,
    required this.salesTaxAmount,
  });

  final double salesTaxRate;
  final double grossSales;
  final double taxableSales;
  final double salesTaxAmount;
}

class PeriodBusinessSummary {
  const PeriodBusinessSummary({
    required this.label,
    required this.range,
    required this.sales,
    required this.payments,
    required this.creditIssued,
    required this.grossProfit,
    required this.operatingProfit,
  });

  final String label;
  final ReportRange range;
  final double sales;
  final double payments;
  final double creditIssued;
  final double grossProfit;
  final double operatingProfit;
}

class SalesItemSummary {
  const SalesItemSummary({
    required this.itemName,
    required this.quantity,
    required this.salesAmount,
    required this.margin,
  });

  final String itemName;
  final int quantity;
  final double salesAmount;
  final double margin;
}

enum ReminderInboxType {
  scheduledReminder,
  bulkReminder,
  promiseFollowUp,
  installmentDue,
  dailyAction,
  visitFollowUp,
}

enum ReminderInboxStatus { pending, opened, skipped, completed }

class ReminderInboxItem {
  const ReminderInboxItem({
    required this.id,
    required this.customerId,
    required this.title,
    required this.message,
    required this.tone,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.dueAt,
    required this.notificationId,
    this.referenceId = '',
    this.channel = 'whatsapp',
    this.note = '',
    this.handledAt,
  });

  final String id;
  final String customerId;
  final String title;
  final String message;
  final ReminderTone tone;
  final ReminderInboxType type;
  final ReminderInboxStatus status;
  final DateTime createdAt;
  final DateTime dueAt;
  final int notificationId;
  final String referenceId;
  final String channel;
  final String note;
  final DateTime? handledAt;

  ReminderInboxItem copyWith({
    String? id,
    String? customerId,
    String? title,
    String? message,
    ReminderTone? tone,
    ReminderInboxType? type,
    ReminderInboxStatus? status,
    DateTime? createdAt,
    DateTime? dueAt,
    int? notificationId,
    String? referenceId,
    String? channel,
    String? note,
    DateTime? handledAt,
    bool clearHandledAt = false,
  }) {
    return ReminderInboxItem(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      title: title ?? this.title,
      message: message ?? this.message,
      tone: tone ?? this.tone,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      dueAt: dueAt ?? this.dueAt,
      notificationId: notificationId ?? this.notificationId,
      referenceId: referenceId ?? this.referenceId,
      channel: channel ?? this.channel,
      note: note ?? this.note,
      handledAt: clearHandledAt ? null : handledAt ?? this.handledAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'customerId': customerId,
      'title': title,
      'message': message,
      'tone': tone.name,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'dueAt': dueAt.toIso8601String(),
      'notificationId': notificationId,
      'referenceId': referenceId,
      'channel': channel,
      'note': note,
      'handledAt': handledAt?.toIso8601String(),
    };
  }

  factory ReminderInboxItem.fromJson(Map<String, dynamic> json) {
    final rawTone = json['tone'] as String?;
    final rawType = json['type'] as String?;
    final rawStatus = json['status'] as String?;
    return ReminderInboxItem(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      tone: rawTone == null
          ? ReminderTone.normal
          : ReminderTone.values.firstWhere(
              (value) => value.name == rawTone,
              orElse: () => ReminderTone.normal,
            ),
      type: rawType == null
          ? ReminderInboxType.scheduledReminder
          : ReminderInboxType.values.firstWhere(
              (value) => value.name == rawType,
              orElse: () => ReminderInboxType.scheduledReminder,
            ),
      status: rawStatus == null
          ? ReminderInboxStatus.pending
          : ReminderInboxStatus.values.firstWhere(
              (value) => value.name == rawStatus,
              orElse: () => ReminderInboxStatus.pending,
            ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      dueAt: DateTime.parse(json['dueAt'] as String),
      notificationId: (json['notificationId'] as num?)?.toInt() ?? 0,
      referenceId: json['referenceId'] as String? ?? '',
      channel: json['channel'] as String? ?? 'whatsapp',
      note: json['note'] as String? ?? '',
      handledAt: json['handledAt'] == null
          ? null
          : DateTime.parse(json['handledAt'] as String),
    );
  }
}

class CustomerVisit {
  const CustomerVisit({
    required this.id,
    required this.customerId,
    required this.visitedAt,
    this.note = '',
    this.followUpDueAt,
    this.locationLabel = '',
    this.latitude,
    this.longitude,
  });

  final String id;
  final String customerId;
  final DateTime visitedAt;
  final String note;
  final DateTime? followUpDueAt;
  final String locationLabel;
  final double? latitude;
  final double? longitude;

  CustomerVisit copyWith({
    String? id,
    String? customerId,
    DateTime? visitedAt,
    String? note,
    DateTime? followUpDueAt,
    String? locationLabel,
    double? latitude,
    double? longitude,
    bool clearFollowUpDueAt = false,
    bool clearLatitude = false,
    bool clearLongitude = false,
  }) {
    return CustomerVisit(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      visitedAt: visitedAt ?? this.visitedAt,
      note: note ?? this.note,
      followUpDueAt: clearFollowUpDueAt
          ? null
          : followUpDueAt ?? this.followUpDueAt,
      locationLabel: locationLabel ?? this.locationLabel,
      latitude: clearLatitude ? null : latitude ?? this.latitude,
      longitude: clearLongitude ? null : longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'customerId': customerId,
      'visitedAt': visitedAt.toIso8601String(),
      'note': note,
      'followUpDueAt': followUpDueAt?.toIso8601String(),
      'locationLabel': locationLabel,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory CustomerVisit.fromJson(Map<String, dynamic> json) {
    return CustomerVisit(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      visitedAt: DateTime.parse(json['visitedAt'] as String),
      note: json['note'] as String? ?? '',
      followUpDueAt: json['followUpDueAt'] == null
          ? null
          : DateTime.parse(json['followUpDueAt'] as String),
      locationLabel: json['locationLabel'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

enum CommunityRiskLevel { watch, blacklist }

class CommunityBlacklistEntry {
  const CommunityBlacklistEntry({
    required this.id,
    required this.shopId,
    required this.customerName,
    required this.phone,
    required this.city,
    required this.reason,
    required this.createdAt,
    this.cnic = '',
    this.note = '',
    this.reportedCustomerId,
    this.riskLevel = CommunityRiskLevel.blacklist,
  });

  final String id;
  final String shopId;
  final String customerName;
  final String phone;
  final String city;
  final String reason;
  final DateTime createdAt;
  final String cnic;
  final String note;
  final String? reportedCustomerId;
  final CommunityRiskLevel riskLevel;

  CommunityBlacklistEntry copyWith({
    String? id,
    String? shopId,
    String? customerName,
    String? phone,
    String? city,
    String? reason,
    DateTime? createdAt,
    String? cnic,
    String? note,
    String? reportedCustomerId,
    CommunityRiskLevel? riskLevel,
    bool clearReportedCustomerId = false,
  }) {
    return CommunityBlacklistEntry(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      cnic: cnic ?? this.cnic,
      note: note ?? this.note,
      reportedCustomerId: clearReportedCustomerId
          ? null
          : reportedCustomerId ?? this.reportedCustomerId,
      riskLevel: riskLevel ?? this.riskLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'shopId': shopId,
      'customerName': customerName,
      'phone': phone,
      'city': city,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
      'cnic': cnic,
      'note': note,
      'reportedCustomerId': reportedCustomerId,
      'riskLevel': riskLevel.name,
    };
  }

  factory CommunityBlacklistEntry.fromJson(Map<String, dynamic> json) {
    final rawRiskLevel = json['riskLevel'] as String?;
    return CommunityBlacklistEntry(
      id: json['id'] as String,
      shopId: json['shopId'] as String? ?? AppSettings.defaultShopId,
      customerName: json['customerName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      city: json['city'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      cnic: json['cnic'] as String? ?? '',
      note: json['note'] as String? ?? '',
      reportedCustomerId: json['reportedCustomerId'] as String?,
      riskLevel: rawRiskLevel == null
          ? CommunityRiskLevel.blacklist
          : CommunityRiskLevel.values.firstWhere(
              (value) => value.name == rawRiskLevel,
              orElse: () => CommunityRiskLevel.blacklist,
            ),
    );
  }
}

class PortalShareEntry {
  const PortalShareEntry({
    required this.date,
    required this.label,
    required this.amount,
    required this.isCredit,
    this.note = '',
  });

  final DateTime date;
  final String label;
  final double amount;
  final bool isCredit;
  final String note;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'date': date.toIso8601String(),
      'label': label,
      'amount': amount,
      'isCredit': isCredit,
      'note': note,
    };
  }

  factory PortalShareEntry.fromJson(Map<String, dynamic> json) {
    return PortalShareEntry(
      date: DateTime.parse(json['date'] as String),
      label: json['label'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      isCredit: json['isCredit'] as bool? ?? false,
      note: json['note'] as String? ?? '',
    );
  }
}

class PortalSharePayload {
  const PortalSharePayload({
    required this.shopName,
    required this.shopPhone,
    required this.customerName,
    required this.customerPhone,
    required this.shareCode,
    required this.balance,
    required this.recoveryScore,
    required this.generatedAt,
    this.promiseDate,
    this.promiseAmount,
    this.entries = const <PortalShareEntry>[],
  });

  final String shopName;
  final String shopPhone;
  final String customerName;
  final String customerPhone;
  final String shareCode;
  final double balance;
  final int recoveryScore;
  final DateTime generatedAt;
  final DateTime? promiseDate;
  final double? promiseAmount;
  final List<PortalShareEntry> entries;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'shopName': shopName,
      'shopPhone': shopPhone,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'shareCode': shareCode,
      'balance': balance,
      'recoveryScore': recoveryScore,
      'generatedAt': generatedAt.toIso8601String(),
      'promiseDate': promiseDate?.toIso8601String(),
      'promiseAmount': promiseAmount,
      'entries': entries.map((entry) => entry.toJson()).toList(),
    };
  }

  factory PortalSharePayload.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List<dynamic>? ?? const <dynamic>[];
    return PortalSharePayload(
      shopName: json['shopName'] as String? ?? '',
      shopPhone: json['shopPhone'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      shareCode: json['shareCode'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      recoveryScore: (json['recoveryScore'] as num?)?.toInt() ?? 0,
      generatedAt: json['generatedAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['generatedAt'] as String),
      promiseDate: json['promiseDate'] == null
          ? null
          : DateTime.parse(json['promiseDate'] as String),
      promiseAmount: (json['promiseAmount'] as num?)?.toDouble(),
      entries: rawEntries
          .map(
            (item) => PortalShareEntry.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class WholesaleListing {
  const WholesaleListing({
    required this.id,
    required this.shopId,
    required this.title,
    required this.price,
    required this.createdAt,
    this.category = '',
    this.unit = 'pcs',
    this.minQuantity = 1,
    this.phone = '',
    this.note = '',
    this.isActive = true,
  });

  final String id;
  final String shopId;
  final String title;
  final double price;
  final DateTime createdAt;
  final String category;
  final String unit;
  final int minQuantity;
  final String phone;
  final String note;
  final bool isActive;

  WholesaleListing copyWith({
    String? id,
    String? shopId,
    String? title,
    double? price,
    DateTime? createdAt,
    String? category,
    String? unit,
    int? minQuantity,
    String? phone,
    String? note,
    bool? isActive,
  }) {
    return WholesaleListing(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      title: title ?? this.title,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      minQuantity: minQuantity ?? this.minQuantity,
      phone: phone ?? this.phone,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'shopId': shopId,
      'title': title,
      'price': price,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
      'unit': unit,
      'minQuantity': minQuantity,
      'phone': phone,
      'note': note,
      'isActive': isActive,
    };
  }

  factory WholesaleListing.fromJson(Map<String, dynamic> json) {
    return WholesaleListing(
      id: json['id'] as String,
      shopId: json['shopId'] as String? ?? AppSettings.defaultShopId,
      title: json['title'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['createdAt'] as String),
      category: json['category'] as String? ?? '',
      unit: json['unit'] as String? ?? 'pcs',
      minQuantity: (json['minQuantity'] as num?)?.toInt() ?? 1,
      phone: json['phone'] as String? ?? '',
      note: json['note'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class InstallmentPlan {
  const InstallmentPlan({
    required this.id,
    required this.customerId,
    required this.totalAmount,
    required this.installmentAmount,
    required this.installmentCount,
    required this.completedInstallments,
    required this.intervalDays,
    required this.createdAt,
    required this.firstDueDate,
    required this.nextDueDate,
    this.note = '',
    this.isPaused = false,
    this.isCompleted = false,
    this.lastPaymentAt,
  });

  final String id;
  final String customerId;
  final double totalAmount;
  final double installmentAmount;
  final int installmentCount;
  final int completedInstallments;
  final int intervalDays;
  final DateTime createdAt;
  final DateTime firstDueDate;
  final DateTime nextDueDate;
  final String note;
  final bool isPaused;
  final bool isCompleted;
  final DateTime? lastPaymentAt;

  double get remainingAmount {
    final remaining = totalAmount - (completedInstallments * installmentAmount);
    return remaining < 0 ? 0 : remaining;
  }

  int get remainingInstallments {
    final remaining = installmentCount - completedInstallments;
    return remaining < 0 ? 0 : remaining;
  }

  InstallmentPlan copyWith({
    String? id,
    String? customerId,
    double? totalAmount,
    double? installmentAmount,
    int? installmentCount,
    int? completedInstallments,
    int? intervalDays,
    DateTime? createdAt,
    DateTime? firstDueDate,
    DateTime? nextDueDate,
    String? note,
    bool? isPaused,
    bool? isCompleted,
    DateTime? lastPaymentAt,
    bool clearLastPaymentAt = false,
  }) {
    return InstallmentPlan(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      totalAmount: totalAmount ?? this.totalAmount,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      installmentCount: installmentCount ?? this.installmentCount,
      completedInstallments:
          completedInstallments ?? this.completedInstallments,
      intervalDays: intervalDays ?? this.intervalDays,
      createdAt: createdAt ?? this.createdAt,
      firstDueDate: firstDueDate ?? this.firstDueDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      note: note ?? this.note,
      isPaused: isPaused ?? this.isPaused,
      isCompleted: isCompleted ?? this.isCompleted,
      lastPaymentAt: clearLastPaymentAt
          ? null
          : lastPaymentAt ?? this.lastPaymentAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'customerId': customerId,
      'totalAmount': totalAmount,
      'installmentAmount': installmentAmount,
      'installmentCount': installmentCount,
      'completedInstallments': completedInstallments,
      'intervalDays': intervalDays,
      'createdAt': createdAt.toIso8601String(),
      'firstDueDate': firstDueDate.toIso8601String(),
      'nextDueDate': nextDueDate.toIso8601String(),
      'note': note,
      'isPaused': isPaused,
      'isCompleted': isCompleted,
      'lastPaymentAt': lastPaymentAt?.toIso8601String(),
    };
  }

  factory InstallmentPlan.fromJson(Map<String, dynamic> json) {
    return InstallmentPlan(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      installmentAmount: (json['installmentAmount'] as num?)?.toDouble() ?? 0,
      installmentCount: (json['installmentCount'] as num?)?.toInt() ?? 0,
      completedInstallments:
          (json['completedInstallments'] as num?)?.toInt() ?? 0,
      intervalDays: (json['intervalDays'] as num?)?.toInt() ?? 30,
      createdAt: DateTime.parse(json['createdAt'] as String),
      firstDueDate: DateTime.parse(json['firstDueDate'] as String),
      nextDueDate: DateTime.parse(json['nextDueDate'] as String),
      note: json['note'] as String? ?? '',
      isPaused: json['isPaused'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      lastPaymentAt: json['lastPaymentAt'] == null
          ? null
          : DateTime.parse(json['lastPaymentAt'] as String),
    );
  }
}

class Supplier {
  const Supplier({
    required this.id,
    required this.shopId,
    required this.name,
    required this.phone,
    required this.createdAt,
    this.notes = '',
  });

  final String id;
  final String shopId;
  final String name;
  final String phone;
  final DateTime createdAt;
  final String notes;

  Supplier copyWith({
    String? id,
    String? shopId,
    String? name,
    String? phone,
    DateTime? createdAt,
    String? notes,
  }) {
    return Supplier(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'shopId': shopId,
      'name': name,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String,
      shopId: json['shopId'] as String? ?? AppSettings.defaultShopId,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String? ?? '',
    );
  }
}

enum SupplierEntryType { purchase, payment }

class SupplierLedgerEntry {
  const SupplierLedgerEntry({
    required this.id,
    required this.shopId,
    required this.supplierId,
    required this.amount,
    required this.type,
    required this.date,
    this.note = '',
    this.inventoryItemId = '',
    this.quantity = 0,
    this.unitCost = 0,
  });

  final String id;
  final String shopId;
  final String supplierId;
  final double amount;
  final SupplierEntryType type;
  final DateTime date;
  final String note;
  final String inventoryItemId;
  final int quantity;
  final double unitCost;

  SupplierLedgerEntry copyWith({
    String? id,
    String? shopId,
    String? supplierId,
    double? amount,
    SupplierEntryType? type,
    DateTime? date,
    String? note,
    String? inventoryItemId,
    int? quantity,
    double? unitCost,
  }) {
    return SupplierLedgerEntry(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      supplierId: supplierId ?? this.supplierId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      note: note ?? this.note,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'shopId': shopId,
      'supplierId': supplierId,
      'amount': amount,
      'type': type.name,
      'date': date.toIso8601String(),
      'note': note,
      'inventoryItemId': inventoryItemId,
      'quantity': quantity,
      'unitCost': unitCost,
    };
  }

  factory SupplierLedgerEntry.fromJson(Map<String, dynamic> json) {
    return SupplierLedgerEntry(
      id: json['id'] as String,
      shopId: json['shopId'] as String? ?? AppSettings.defaultShopId,
      supplierId: json['supplierId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      type: SupplierEntryType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => SupplierEntryType.purchase,
      ),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String? ?? '',
      inventoryItemId: json['inventoryItemId'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0,
    );
  }
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.shopId,
    required this.name,
    required this.createdAt,
    this.sku = '',
    this.barcode = '',
    this.unit = 'pcs',
    this.stockQuantity = 0,
    this.reorderLevel = 0,
    this.costPrice = 0,
    this.salePrice = 0,
    this.supplierId = '',
    this.notes = '',
    this.isArchived = false,
  });

  final String id;
  final String shopId;
  final String name;
  final DateTime createdAt;
  final String sku;
  final String barcode;
  final String unit;
  final int stockQuantity;
  final int reorderLevel;
  final double costPrice;
  final double salePrice;
  final String supplierId;
  final String notes;
  final bool isArchived;

  bool get isLowStock => stockQuantity <= reorderLevel;
  double get stockCostValue => stockQuantity * costPrice;
  double get stockRetailValue => stockQuantity * salePrice;

  InventoryItem copyWith({
    String? id,
    String? shopId,
    String? name,
    DateTime? createdAt,
    String? sku,
    String? barcode,
    String? unit,
    int? stockQuantity,
    int? reorderLevel,
    double? costPrice,
    double? salePrice,
    String? supplierId,
    String? notes,
    bool? isArchived,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      unit: unit ?? this.unit,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      supplierId: supplierId ?? this.supplierId,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'shopId': shopId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'sku': sku,
      'barcode': barcode,
      'unit': unit,
      'stockQuantity': stockQuantity,
      'reorderLevel': reorderLevel,
      'costPrice': costPrice,
      'salePrice': salePrice,
      'supplierId': supplierId,
      'notes': notes,
      'isArchived': isArchived,
    };
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      shopId: json['shopId'] as String? ?? AppSettings.defaultShopId,
      name: json['name'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      sku: json['sku'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      unit: json['unit'] as String? ?? 'pcs',
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
      reorderLevel: (json['reorderLevel'] as num?)?.toInt() ?? 0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
      salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0,
      supplierId: json['supplierId'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }
}

class SaleLineItem {
  const SaleLineItem({
    required this.inventoryItemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.costPrice,
  });

  final String inventoryItemId;
  final String itemName;
  final int quantity;
  final double unitPrice;
  final double costPrice;

  double get lineTotal => quantity * unitPrice;
  double get lineMargin => quantity * (unitPrice - costPrice);

  SaleLineItem copyWith({
    String? inventoryItemId,
    String? itemName,
    int? quantity,
    double? unitPrice,
    double? costPrice,
  }) {
    return SaleLineItem(
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'inventoryItemId': inventoryItemId,
      'itemName': itemName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'costPrice': costPrice,
    };
  }

  factory SaleLineItem.fromJson(Map<String, dynamic> json) {
    return SaleLineItem(
      inventoryItemId: json['inventoryItemId'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}

enum SaleRecordType { cash, udhaar }

class SaleRecord {
  const SaleRecord({
    required this.id,
    required this.shopId,
    required this.type,
    required this.date,
    required this.lineItems,
    this.customerId,
    this.note = '',
    this.linkedTransactionId = '',
  });

  final String id;
  final String shopId;
  final SaleRecordType type;
  final DateTime date;
  final List<SaleLineItem> lineItems;
  final String? customerId;
  final String note;
  final String linkedTransactionId;

  double get totalAmount =>
      lineItems.fold<double>(0, (total, item) => total + item.lineTotal);

  double get totalMargin =>
      lineItems.fold<double>(0, (total, item) => total + item.lineMargin);

  int get totalUnits =>
      lineItems.fold<int>(0, (total, item) => total + item.quantity);

  SaleRecord copyWith({
    String? id,
    String? shopId,
    SaleRecordType? type,
    DateTime? date,
    List<SaleLineItem>? lineItems,
    String? customerId,
    String? note,
    String? linkedTransactionId,
    bool clearCustomerId = false,
  }) {
    return SaleRecord(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      type: type ?? this.type,
      date: date ?? this.date,
      lineItems: lineItems ?? this.lineItems,
      customerId: clearCustomerId ? null : customerId ?? this.customerId,
      note: note ?? this.note,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'shopId': shopId,
      'type': type.name,
      'date': date.toIso8601String(),
      'lineItems': lineItems.map((item) => item.toJson()).toList(),
      'customerId': customerId,
      'note': note,
      'linkedTransactionId': linkedTransactionId,
    };
  }

  factory SaleRecord.fromJson(Map<String, dynamic> json) {
    final rawLineItems =
        json['lineItems'] as List<dynamic>? ?? const <dynamic>[];
    return SaleRecord(
      id: json['id'] as String,
      shopId: json['shopId'] as String? ?? AppSettings.defaultShopId,
      type: SaleRecordType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => SaleRecordType.cash,
      ),
      date: DateTime.parse(json['date'] as String),
      lineItems: rawLineItems
          .map(
            (item) =>
                SaleLineItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      customerId: json['customerId'] as String?,
      note: json['note'] as String? ?? '',
      linkedTransactionId: json['linkedTransactionId'] as String? ?? '',
    );
  }
}

enum StaffPayType { daily, monthly, hourly }

enum StaffAttendanceStatus { present, absent, halfDay, leave }

class StaffMember {
  const StaffMember({
    required this.id,
    required this.shopId,
    required this.name,
    required this.phone,
    required this.role,
    required this.payType,
    required this.baseRate,
    required this.createdAt,
    this.defaultHoursPerDay = 8,
    this.overtimeRate = 0,
    this.notes = '',
    this.isActive = true,
  });

  final String id;
  final String shopId;
  final String name;
  final String phone;
  final String role;
  final StaffPayType payType;
  final double baseRate;
  final DateTime createdAt;
  final double defaultHoursPerDay;
  final double overtimeRate;
  final String notes;
  final bool isActive;

  StaffMember copyWith({
    String? id,
    String? shopId,
    String? name,
    String? phone,
    String? role,
    StaffPayType? payType,
    double? baseRate,
    DateTime? createdAt,
    double? defaultHoursPerDay,
    double? overtimeRate,
    String? notes,
    bool? isActive,
  }) {
    return StaffMember(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      payType: payType ?? this.payType,
      baseRate: baseRate ?? this.baseRate,
      createdAt: createdAt ?? this.createdAt,
      defaultHoursPerDay: defaultHoursPerDay ?? this.defaultHoursPerDay,
      overtimeRate: overtimeRate ?? this.overtimeRate,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'shopId': shopId,
      'name': name,
      'phone': phone,
      'role': role,
      'payType': payType.name,
      'baseRate': baseRate,
      'createdAt': createdAt.toIso8601String(),
      'defaultHoursPerDay': defaultHoursPerDay,
      'overtimeRate': overtimeRate,
      'notes': notes,
      'isActive': isActive,
    };
  }

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] as String,
      shopId: json['shopId'] as String? ?? AppSettings.defaultShopId,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? '',
      payType: StaffPayType.values.firstWhere(
        (value) => value.name == json['payType'],
        orElse: () => StaffPayType.monthly,
      ),
      baseRate: (json['baseRate'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      defaultHoursPerDay: (json['defaultHoursPerDay'] as num?)?.toDouble() ?? 8,
      overtimeRate: (json['overtimeRate'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class StaffAttendanceEntry {
  const StaffAttendanceEntry({
    required this.id,
    required this.shopId,
    required this.staffId,
    required this.date,
    required this.status,
    required this.createdAt,
    this.workedHours = 0,
    this.overtimeHours = 0,
    this.note = '',
  });

  final String id;
  final String shopId;
  final String staffId;
  final DateTime date;
  final StaffAttendanceStatus status;
  final DateTime createdAt;
  final double workedHours;
  final double overtimeHours;
  final String note;

  StaffAttendanceEntry copyWith({
    String? id,
    String? shopId,
    String? staffId,
    DateTime? date,
    StaffAttendanceStatus? status,
    DateTime? createdAt,
    double? workedHours,
    double? overtimeHours,
    String? note,
  }) {
    return StaffAttendanceEntry(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      staffId: staffId ?? this.staffId,
      date: date ?? this.date,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      workedHours: workedHours ?? this.workedHours,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'shopId': shopId,
      'staffId': staffId,
      'date': date.toIso8601String(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'workedHours': workedHours,
      'overtimeHours': overtimeHours,
      'note': note,
    };
  }

  factory StaffAttendanceEntry.fromJson(Map<String, dynamic> json) {
    return StaffAttendanceEntry(
      id: json['id'] as String,
      shopId: json['shopId'] as String? ?? AppSettings.defaultShopId,
      staffId: json['staffId'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      status: StaffAttendanceStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => StaffAttendanceStatus.present,
      ),
      createdAt: json['createdAt'] == null
          ? DateTime.parse(json['date'] as String)
          : DateTime.parse(json['createdAt'] as String),
      workedHours: (json['workedHours'] as num?)?.toDouble() ?? 0,
      overtimeHours: (json['overtimeHours'] as num?)?.toDouble() ?? 0,
      note: json['note'] as String? ?? '',
    );
  }
}

class StaffAdvanceEntry {
  const StaffAdvanceEntry({
    required this.id,
    required this.shopId,
    required this.staffId,
    required this.amount,
    required this.date,
    this.note = '',
    this.settledPayrollRunId = '',
  });

  final String id;
  final String shopId;
  final String staffId;
  final double amount;
  final DateTime date;
  final String note;
  final String settledPayrollRunId;

  bool get isSettled => settledPayrollRunId.trim().isNotEmpty;

  StaffAdvanceEntry copyWith({
    String? id,
    String? shopId,
    String? staffId,
    double? amount,
    DateTime? date,
    String? note,
    String? settledPayrollRunId,
    bool clearSettledPayrollRunId = false,
  }) {
    return StaffAdvanceEntry(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      staffId: staffId ?? this.staffId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      settledPayrollRunId: clearSettledPayrollRunId
          ? ''
          : settledPayrollRunId ?? this.settledPayrollRunId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'shopId': shopId,
      'staffId': staffId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'settledPayrollRunId': settledPayrollRunId,
    };
  }

  factory StaffAdvanceEntry.fromJson(Map<String, dynamic> json) {
    return StaffAdvanceEntry(
      id: json['id'] as String,
      shopId: json['shopId'] as String? ?? AppSettings.defaultShopId,
      staffId: json['staffId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String? ?? '',
      settledPayrollRunId: json['settledPayrollRunId'] as String? ?? '',
    );
  }
}

class StaffPayrollRun {
  const StaffPayrollRun({
    required this.id,
    required this.shopId,
    required this.staffId,
    required this.payType,
    required this.periodStart,
    required this.periodEnd,
    required this.payDate,
    required this.createdAt,
    required this.basePay,
    required this.overtimePay,
    required this.advanceDeduction,
    required this.netPay,
    required this.paidUnits,
    required this.workingHours,
    required this.overtimeHours,
    this.note = '',
    this.includedAdvanceIds = const <String>[],
  });

  final String id;
  final String shopId;
  final String staffId;
  final StaffPayType payType;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime payDate;
  final DateTime createdAt;
  final double basePay;
  final double overtimePay;
  final double advanceDeduction;
  final double netPay;
  final double paidUnits;
  final double workingHours;
  final double overtimeHours;
  final String note;
  final List<String> includedAdvanceIds;

  double get grossPay => basePay + overtimePay;

  StaffPayrollRun copyWith({
    String? id,
    String? shopId,
    String? staffId,
    StaffPayType? payType,
    DateTime? periodStart,
    DateTime? periodEnd,
    DateTime? payDate,
    DateTime? createdAt,
    double? basePay,
    double? overtimePay,
    double? advanceDeduction,
    double? netPay,
    double? paidUnits,
    double? workingHours,
    double? overtimeHours,
    String? note,
    List<String>? includedAdvanceIds,
  }) {
    return StaffPayrollRun(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      staffId: staffId ?? this.staffId,
      payType: payType ?? this.payType,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      payDate: payDate ?? this.payDate,
      createdAt: createdAt ?? this.createdAt,
      basePay: basePay ?? this.basePay,
      overtimePay: overtimePay ?? this.overtimePay,
      advanceDeduction: advanceDeduction ?? this.advanceDeduction,
      netPay: netPay ?? this.netPay,
      paidUnits: paidUnits ?? this.paidUnits,
      workingHours: workingHours ?? this.workingHours,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      note: note ?? this.note,
      includedAdvanceIds: includedAdvanceIds ?? this.includedAdvanceIds,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'shopId': shopId,
      'staffId': staffId,
      'payType': payType.name,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'payDate': payDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'basePay': basePay,
      'overtimePay': overtimePay,
      'advanceDeduction': advanceDeduction,
      'netPay': netPay,
      'paidUnits': paidUnits,
      'workingHours': workingHours,
      'overtimeHours': overtimeHours,
      'note': note,
      'includedAdvanceIds': includedAdvanceIds,
    };
  }

  factory StaffPayrollRun.fromJson(Map<String, dynamic> json) {
    final rawAdvanceIds =
        json['includedAdvanceIds'] as List<dynamic>? ?? const <dynamic>[];
    return StaffPayrollRun(
      id: json['id'] as String,
      shopId: json['shopId'] as String? ?? AppSettings.defaultShopId,
      staffId: json['staffId'] as String? ?? '',
      payType: StaffPayType.values.firstWhere(
        (value) => value.name == json['payType'],
        orElse: () => StaffPayType.monthly,
      ),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      payDate: DateTime.parse(json['payDate'] as String),
      createdAt: json['createdAt'] == null
          ? DateTime.parse(json['payDate'] as String)
          : DateTime.parse(json['createdAt'] as String),
      basePay: (json['basePay'] as num?)?.toDouble() ?? 0,
      overtimePay: (json['overtimePay'] as num?)?.toDouble() ?? 0,
      advanceDeduction: (json['advanceDeduction'] as num?)?.toDouble() ?? 0,
      netPay: (json['netPay'] as num?)?.toDouble() ?? 0,
      paidUnits: (json['paidUnits'] as num?)?.toDouble() ?? 0,
      workingHours: (json['workingHours'] as num?)?.toDouble() ?? 0,
      overtimeHours: (json['overtimeHours'] as num?)?.toDouble() ?? 0,
      note: json['note'] as String? ?? '',
      includedAdvanceIds: rawAdvanceIds
          .map((item) => item.toString())
          .where((value) => value.trim().isNotEmpty)
          .toList(),
    );
  }
}

class BulkReminderResult {
  const BulkReminderResult({
    required this.opened,
    required this.totalEligible,
    required this.limitedByPlan,
  });

  final int opened;
  final int totalEligible;
  final bool limitedByPlan;
}

class ParsedVoiceCredit {
  const ParsedVoiceCredit({
    required this.customerId,
    required this.amount,
    required this.rawWords,
  });

  final String customerId;
  final double amount;
  final String rawWords;
}

class ReminderLog {
  const ReminderLog({
    required this.id,
    required this.customerId,
    required this.message,
    required this.tone,
    required this.sentAt,
    this.channel = 'whatsapp',
    this.wasSuccessful = true,
  });

  final String id;
  final String customerId;
  final String message;
  final ReminderTone tone;
  final DateTime sentAt;
  final String channel;
  final bool wasSuccessful;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'customerId': customerId,
      'message': message,
      'tone': tone.name,
      'sentAt': sentAt.toIso8601String(),
      'channel': channel,
      'wasSuccessful': wasSuccessful,
    };
  }

  factory ReminderLog.fromJson(Map<String, dynamic> json) {
    final rawTone = json['tone'] as String?;
    return ReminderLog(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      message: json['message'] as String? ?? '',
      tone: rawTone == null
          ? ReminderTone.normal
          : ReminderTone.values.firstWhere(
              (value) => value.name == rawTone,
              orElse: () => ReminderTone.normal,
            ),
      sentAt: DateTime.parse(json['sentAt'] as String),
      channel: json['channel'] as String? ?? 'whatsapp',
      wasSuccessful: json['wasSuccessful'] as bool? ?? true,
    );
  }
}

class BackupRecord {
  const BackupRecord({
    required this.id,
    required this.createdAt,
    required this.source,
    required this.status,
    required this.customerCount,
    required this.transactionCount,
    required this.reminderCount,
    this.note = '',
    this.checksum = '',
    this.storagePath = '',
    this.payload = '',
    this.sizeBytes = 0,
    this.integrityStatus = 'legacy',
  });

  final String id;
  final DateTime createdAt;
  final String source;
  final String status;
  final int customerCount;
  final int transactionCount;
  final int reminderCount;
  final String note;
  final String checksum;
  final String storagePath;
  final String payload;
  final int sizeBytes;
  final String integrityStatus;

  bool get hasPayload => payload.trim().isNotEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'source': source,
      'status': status,
      'customerCount': customerCount,
      'transactionCount': transactionCount,
      'reminderCount': reminderCount,
      'note': note,
      'checksum': checksum,
      'storagePath': storagePath,
      'payload': payload,
      'sizeBytes': sizeBytes,
      'integrityStatus': integrityStatus,
    };
  }

  factory BackupRecord.fromJson(Map<String, dynamic> json) {
    return BackupRecord(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      source: json['source'] as String? ?? 'local',
      status: json['status'] as String? ?? 'success',
      customerCount: (json['customerCount'] as num?)?.toInt() ?? 0,
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
      reminderCount: (json['reminderCount'] as num?)?.toInt() ?? 0,
      note: json['note'] as String? ?? '',
      checksum: json['checksum'] as String? ?? '',
      storagePath: json['storagePath'] as String? ?? '',
      payload: json['payload'] as String? ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      integrityStatus: json['integrityStatus'] as String? ?? 'legacy',
    );
  }
}

enum BackupIntegrityStatus { verified, legacy, invalid }

class CloudAccountProfile {
  const CloudAccountProfile({
    required this.id,
    required this.email,
    this.phoneNumber = '',
    required this.displayName,
    required this.provider,
    this.isEmailVerified = false,
    required this.signedInAt,
  });

  final String id;
  final String email;
  final String phoneNumber;
  final String displayName;
  final String provider;
  final bool isEmailVerified;
  final DateTime signedInAt;

  bool get isEmpty => id.trim().isEmpty && email.trim().isEmpty;

  String get label {
    final trimmedName = displayName.trim();
    if (trimmedName.isNotEmpty) {
      return trimmedName;
    }
    final trimmedEmail = email.trim();
    if (trimmedEmail.isNotEmpty) {
      return trimmedEmail;
    }
    return 'Cloud account';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'provider': provider,
      'isEmailVerified': isEmailVerified,
      'signedInAt': signedInAt.toIso8601String(),
    };
  }

  factory CloudAccountProfile.fromJson(Map<String, dynamic> json) {
    return CloudAccountProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      signedInAt: json['signedInAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['signedInAt'] as String),
    );
  }
}

class CloudWorkspaceDirectoryEntry {
  const CloudWorkspaceDirectoryEntry({
    required this.workspaceId,
    required this.shopId,
    required this.shopName,
    required this.accountId,
    required this.accountEmail,
    required this.accountDisplayName,
    required this.lastDeviceLabel,
    required this.updatedAt,
    required this.latestBackupId,
    this.backupCount = 0,
  });

  final String workspaceId;
  final String shopId;
  final String shopName;
  final String accountId;
  final String accountEmail;
  final String accountDisplayName;
  final String lastDeviceLabel;
  final DateTime updatedAt;
  final String latestBackupId;
  final int backupCount;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'workspaceId': workspaceId,
      'shopId': shopId,
      'shopName': shopName,
      'accountId': accountId,
      'accountEmail': accountEmail,
      'accountDisplayName': accountDisplayName,
      'lastDeviceLabel': lastDeviceLabel,
      'updatedAt': updatedAt.toIso8601String(),
      'latestBackupId': latestBackupId,
      'backupCount': backupCount,
    };
  }

  factory CloudWorkspaceDirectoryEntry.fromJson(Map<String, dynamic> json) {
    return CloudWorkspaceDirectoryEntry(
      workspaceId: json['workspaceId'] as String? ?? '',
      shopId: json['shopId'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      accountId: json['accountId'] as String? ?? '',
      accountEmail: json['accountEmail'] as String? ?? '',
      accountDisplayName: json['accountDisplayName'] as String? ?? '',
      lastDeviceLabel: json['lastDeviceLabel'] as String? ?? '',
      updatedAt: json['updatedAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['updatedAt'] as String),
      latestBackupId: json['latestBackupId'] as String? ?? '',
      backupCount: (json['backupCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class CloudBackupManifest {
  const CloudBackupManifest({
    required this.id,
    required this.workspaceId,
    required this.deviceLabel,
    required this.shopId,
    required this.shopName,
    required this.createdAt,
    required this.source,
    required this.customerCount,
    required this.transactionCount,
    required this.reminderCount,
    required this.checksum,
    required this.sizeBytes,
    required this.integrityStatus,
    this.accountId = '',
    this.accountEmail = '',
    this.accountDisplayName = '',
  });

  final String id;
  final String workspaceId;
  final String deviceLabel;
  final String shopId;
  final String shopName;
  final DateTime createdAt;
  final String source;
  final int customerCount;
  final int transactionCount;
  final int reminderCount;
  final String checksum;
  final int sizeBytes;
  final String integrityStatus;
  final String accountId;
  final String accountEmail;
  final String accountDisplayName;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'workspaceId': workspaceId,
      'deviceLabel': deviceLabel,
      'shopId': shopId,
      'shopName': shopName,
      'createdAt': createdAt.toIso8601String(),
      'source': source,
      'customerCount': customerCount,
      'transactionCount': transactionCount,
      'reminderCount': reminderCount,
      'checksum': checksum,
      'sizeBytes': sizeBytes,
      'integrityStatus': integrityStatus,
      'accountId': accountId,
      'accountEmail': accountEmail,
      'accountDisplayName': accountDisplayName,
    };
  }

  factory CloudBackupManifest.fromJson(Map<String, dynamic> json) {
    return CloudBackupManifest(
      id: json['id'] as String,
      workspaceId: json['workspaceId'] as String? ?? '',
      deviceLabel: json['deviceLabel'] as String? ?? '',
      shopId: json['shopId'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      source: json['source'] as String? ?? 'cloud-sync',
      customerCount: (json['customerCount'] as num?)?.toInt() ?? 0,
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
      reminderCount: (json['reminderCount'] as num?)?.toInt() ?? 0,
      checksum: json['checksum'] as String? ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      integrityStatus: json['integrityStatus'] as String? ?? 'legacy',
      accountId: json['accountId'] as String? ?? '',
      accountEmail: json['accountEmail'] as String? ?? '',
      accountDisplayName: json['accountDisplayName'] as String? ?? '',
    );
  }
}

class BackupPreview {
  const BackupPreview({
    required this.version,
    required this.exportedAt,
    required this.source,
    required this.shopCount,
    required this.customerCount,
    required this.transactionCount,
    required this.reminderCount,
    required this.installmentPlanCount,
    required this.visitCount,
    required this.shopNames,
    required this.sizeBytes,
    required this.integrityStatus,
    this.integrityAlgorithm = '',
    this.expectedChecksum = '',
    this.actualChecksum = '',
  });

  final int version;
  final DateTime? exportedAt;
  final String source;
  final int shopCount;
  final int customerCount;
  final int transactionCount;
  final int reminderCount;
  final int installmentPlanCount;
  final int visitCount;
  final List<String> shopNames;
  final int sizeBytes;
  final BackupIntegrityStatus integrityStatus;
  final String integrityAlgorithm;
  final String expectedChecksum;
  final String actualChecksum;

  bool get isRestorable => integrityStatus != BackupIntegrityStatus.invalid;

  String get integrityLabel {
    switch (integrityStatus) {
      case BackupIntegrityStatus.verified:
        return 'SHA-256 verified';
      case BackupIntegrityStatus.legacy:
        return 'Legacy backup';
      case BackupIntegrityStatus.invalid:
        return 'Integrity failed';
    }
  }
}

class BackupExportBundle {
  const BackupExportBundle({required this.rawJson, required this.preview});

  final String rawJson;
  final BackupPreview preview;
}

enum CsvImportSource { digitalKhata, okCredit, generic }

class CsvImportRowPreview {
  const CsvImportRowPreview({
    required this.rowNumber,
    required this.customerName,
    required this.phone,
    required this.creditAmount,
    required this.paymentAmount,
    required this.note,
    this.category = '',
    this.city = '',
    this.address = '',
    this.cnic = '',
    this.groupName = '',
    this.date,
    this.dueDate,
    this.warnings = const <String>[],
    this.isSkipped = false,
  });

  final int rowNumber;
  final String customerName;
  final String phone;
  final double creditAmount;
  final double paymentAmount;
  final String note;
  final String category;
  final String city;
  final String address;
  final String cnic;
  final String groupName;
  final DateTime? date;
  final DateTime? dueDate;
  final List<String> warnings;
  final bool isSkipped;
}

class CsvImportPreview {
  const CsvImportPreview({
    required this.source,
    required this.headerColumns,
    required this.rows,
    required this.warningMessages,
  });

  final CsvImportSource source;
  final List<String> headerColumns;
  final List<CsvImportRowPreview> rows;
  final List<String> warningMessages;

  int get totalRows => rows.length;
  int get importableRowCount => rows.where((row) => !row.isSkipped).length;
  int get customerCount => rows
      .where((row) => !row.isSkipped && row.customerName.trim().isNotEmpty)
      .map(
        (row) => '${row.customerName.trim().toLowerCase()}|${row.phone.trim()}',
      )
      .toSet()
      .length;
  int get creditRowCount =>
      rows.where((row) => !row.isSkipped && row.creditAmount > 0).length;
  int get paymentRowCount =>
      rows.where((row) => !row.isSkipped && row.paymentAmount > 0).length;
  double get totalCredits => rows
      .where((row) => !row.isSkipped)
      .fold<double>(0, (sum, row) => sum + row.creditAmount);
  double get totalPayments => rows
      .where((row) => !row.isSkipped)
      .fold<double>(0, (sum, row) => sum + row.paymentAmount);
}

class CsvImportResult {
  const CsvImportResult({
    required this.source,
    required this.createdCustomerCount,
    required this.updatedCustomerCount,
    required this.creditCount,
    required this.paymentCount,
    required this.duplicateTransactionCount,
    required this.skippedRowCount,
    required this.totalCredits,
    required this.totalPayments,
  });

  final CsvImportSource source;
  final int createdCustomerCount;
  final int updatedCustomerCount;
  final int creditCount;
  final int paymentCount;
  final int duplicateTransactionCount;
  final int skippedRowCount;
  final double totalCredits;
  final double totalPayments;
}

class AppDataSnapshot {
  const AppDataSnapshot({
    this.shops = const <ShopProfile>[],
    required this.customers,
    required this.transactions,
    required this.settings,
    this.partnerProfiles = const <PartnerAccessProfile>[],
    this.staffMembers = const <StaffMember>[],
    this.staffAttendanceEntries = const <StaffAttendanceEntry>[],
    this.staffAdvanceEntries = const <StaffAdvanceEntry>[],
    this.staffPayrollRuns = const <StaffPayrollRun>[],
    this.suppliers = const <Supplier>[],
    this.supplierLedgerEntries = const <SupplierLedgerEntry>[],
    this.inventoryItems = const <InventoryItem>[],
    this.wholesaleListings = const <WholesaleListing>[],
    this.saleRecords = const <SaleRecord>[],
    this.reminderLogs = const <ReminderLog>[],
    this.backups = const <BackupRecord>[],
    this.reminderInbox = const <ReminderInboxItem>[],
    this.installmentPlans = const <InstallmentPlan>[],
    this.customerVisits = const <CustomerVisit>[],
    this.communityBlacklistEntries = const <CommunityBlacklistEntry>[],
  });

  final List<ShopProfile> shops;
  final List<Customer> customers;
  final List<LedgerTransaction> transactions;
  final AppSettings settings;
  final List<PartnerAccessProfile> partnerProfiles;
  final List<StaffMember> staffMembers;
  final List<StaffAttendanceEntry> staffAttendanceEntries;
  final List<StaffAdvanceEntry> staffAdvanceEntries;
  final List<StaffPayrollRun> staffPayrollRuns;
  final List<Supplier> suppliers;
  final List<SupplierLedgerEntry> supplierLedgerEntries;
  final List<InventoryItem> inventoryItems;
  final List<WholesaleListing> wholesaleListings;
  final List<SaleRecord> saleRecords;
  final List<ReminderLog> reminderLogs;
  final List<BackupRecord> backups;
  final List<ReminderInboxItem> reminderInbox;
  final List<InstallmentPlan> installmentPlans;
  final List<CustomerVisit> customerVisits;
  final List<CommunityBlacklistEntry> communityBlacklistEntries;

  factory AppDataSnapshot.empty() {
    final defaultShop = ShopProfile(
      id: AppSettings.defaultShopId,
      name: 'Hisab Rakho Store',
      phone: '',
      userType: UserType.shopkeeper,
      createdAt: DateTime.now(),
    );
    return AppDataSnapshot(
      shops: <ShopProfile>[defaultShop],
      customers: const <Customer>[],
      transactions: const <LedgerTransaction>[],
      settings: AppSettings(
        shopName: defaultShop.name,
        organizationPhone: defaultShop.phone,
        userType: defaultShop.userType,
        hasCompletedOnboarding: false,
        isPaidUser: false,
        lowDataMode: false,
        activeShopId: defaultShop.id,
      ),
      partnerProfiles: const <PartnerAccessProfile>[],
      reminderInbox: const <ReminderInboxItem>[],
      installmentPlans: const <InstallmentPlan>[],
      customerVisits: const <CustomerVisit>[],
    );
  }

  AppDataSnapshot copyWith({
    List<ShopProfile>? shops,
    List<Customer>? customers,
    List<LedgerTransaction>? transactions,
    AppSettings? settings,
    List<PartnerAccessProfile>? partnerProfiles,
    List<StaffMember>? staffMembers,
    List<StaffAttendanceEntry>? staffAttendanceEntries,
    List<StaffAdvanceEntry>? staffAdvanceEntries,
    List<StaffPayrollRun>? staffPayrollRuns,
    List<Supplier>? suppliers,
    List<SupplierLedgerEntry>? supplierLedgerEntries,
    List<InventoryItem>? inventoryItems,
    List<WholesaleListing>? wholesaleListings,
    List<SaleRecord>? saleRecords,
    List<ReminderLog>? reminderLogs,
    List<BackupRecord>? backups,
    List<ReminderInboxItem>? reminderInbox,
    List<InstallmentPlan>? installmentPlans,
    List<CustomerVisit>? customerVisits,
    List<CommunityBlacklistEntry>? communityBlacklistEntries,
  }) {
    return AppDataSnapshot(
      shops: shops ?? this.shops,
      customers: customers ?? this.customers,
      transactions: transactions ?? this.transactions,
      settings: settings ?? this.settings,
      partnerProfiles: partnerProfiles ?? this.partnerProfiles,
      staffMembers: staffMembers ?? this.staffMembers,
      staffAttendanceEntries:
          staffAttendanceEntries ?? this.staffAttendanceEntries,
      staffAdvanceEntries: staffAdvanceEntries ?? this.staffAdvanceEntries,
      staffPayrollRuns: staffPayrollRuns ?? this.staffPayrollRuns,
      suppliers: suppliers ?? this.suppliers,
      supplierLedgerEntries:
          supplierLedgerEntries ?? this.supplierLedgerEntries,
      inventoryItems: inventoryItems ?? this.inventoryItems,
      wholesaleListings: wholesaleListings ?? this.wholesaleListings,
      saleRecords: saleRecords ?? this.saleRecords,
      reminderLogs: reminderLogs ?? this.reminderLogs,
      backups: backups ?? this.backups,
      reminderInbox: reminderInbox ?? this.reminderInbox,
      installmentPlans: installmentPlans ?? this.installmentPlans,
      customerVisits: customerVisits ?? this.customerVisits,
      communityBlacklistEntries:
          communityBlacklistEntries ?? this.communityBlacklistEntries,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'shops': shops.map((shop) => shop.toJson()).toList(),
      'customers': customers.map((customer) => customer.toJson()).toList(),
      'transactions': transactions
          .map((transaction) => transaction.toJson())
          .toList(),
      'settings': settings.toJson(),
      'partnerProfiles': partnerProfiles
          .map((profile) => profile.toJson())
          .toList(),
      'staffMembers': staffMembers.map((staff) => staff.toJson()).toList(),
      'staffAttendanceEntries': staffAttendanceEntries
          .map((entry) => entry.toJson())
          .toList(),
      'staffAdvanceEntries': staffAdvanceEntries
          .map((entry) => entry.toJson())
          .toList(),
      'staffPayrollRuns': staffPayrollRuns.map((run) => run.toJson()).toList(),
      'suppliers': suppliers.map((supplier) => supplier.toJson()).toList(),
      'supplierLedgerEntries': supplierLedgerEntries
          .map((entry) => entry.toJson())
          .toList(),
      'inventoryItems': inventoryItems.map((item) => item.toJson()).toList(),
      'wholesaleListings': wholesaleListings
          .map((listing) => listing.toJson())
          .toList(),
      'saleRecords': saleRecords.map((sale) => sale.toJson()).toList(),
      'reminderLogs': reminderLogs.map((log) => log.toJson()).toList(),
      'backups': backups.map((backup) => backup.toJson()).toList(),
      'reminderInbox': reminderInbox.map((item) => item.toJson()).toList(),
      'installmentPlans': installmentPlans
          .map((plan) => plan.toJson())
          .toList(),
      'customerVisits': customerVisits.map((visit) => visit.toJson()).toList(),
      'communityBlacklistEntries': communityBlacklistEntries
          .map((entry) => entry.toJson())
          .toList(),
    };
  }

  factory AppDataSnapshot.fromJson(Map<String, dynamic> json) {
    final fallbackSettings = AppDataSnapshot.empty().settings;
    final settings = json['settings'] is Map
        ? AppSettings.fromJson(
            Map<String, dynamic>.from(json['settings'] as Map),
          )
        : fallbackSettings;

    final rawShops = json['shops'] as List<dynamic>? ?? const <dynamic>[];
    final parsedShops = rawShops
        .map(
          (item) =>
              ShopProfile.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();

    final shops = parsedShops.isNotEmpty
        ? parsedShops
        : <ShopProfile>[
            ShopProfile(
              id: settings.activeShopId,
              name: settings.shopName,
              phone: settings.organizationPhone,
              userType: settings.userType,
              createdAt: DateTime.now(),
            ),
          ];

    final shopIds = shops.map((shop) => shop.id).toSet();
    final activeShopId = shopIds.contains(settings.activeShopId)
        ? settings.activeShopId
        : shops.first.id;
    final activeShop = shops.firstWhere((shop) => shop.id == activeShopId);

    final rawCustomers =
        json['customers'] as List<dynamic>? ?? const <dynamic>[];
    final customers = rawCustomers.map((item) {
      final customer = Customer.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      if (shopIds.contains(customer.shopId)) {
        return customer;
      }
      return customer.copyWith(shopId: activeShopId);
    }).toList();

    final rawTransactions =
        json['transactions'] as List<dynamic>? ?? const <dynamic>[];
    final transactions = rawTransactions.map((item) {
      final transaction = LedgerTransaction.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      if (shopIds.contains(transaction.shopId)) {
        return transaction;
      }
      return transaction.copyWith(shopId: activeShopId);
    }).toList();

    final rawStaffMembers =
        json['staffMembers'] as List<dynamic>? ?? const <dynamic>[];
    final rawPartnerProfiles =
        json['partnerProfiles'] as List<dynamic>? ?? const <dynamic>[];
    final partnerProfiles = rawPartnerProfiles.map((item) {
      final profile = PartnerAccessProfile.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      if (shopIds.contains(profile.shopId)) {
        return profile;
      }
      return profile.copyWith(shopId: activeShopId);
    }).toList();
    final staffMembers = rawStaffMembers.map((item) {
      final staff = StaffMember.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      if (shopIds.contains(staff.shopId)) {
        return staff;
      }
      return staff.copyWith(shopId: activeShopId);
    }).toList();

    final rawStaffAttendanceEntries =
        json['staffAttendanceEntries'] as List<dynamic>? ?? const <dynamic>[];
    final staffAttendanceEntries = rawStaffAttendanceEntries.map((item) {
      final entry = StaffAttendanceEntry.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      if (shopIds.contains(entry.shopId)) {
        return entry;
      }
      return entry.copyWith(shopId: activeShopId);
    }).toList();

    final rawStaffAdvanceEntries =
        json['staffAdvanceEntries'] as List<dynamic>? ?? const <dynamic>[];
    final staffAdvanceEntries = rawStaffAdvanceEntries.map((item) {
      final entry = StaffAdvanceEntry.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      if (shopIds.contains(entry.shopId)) {
        return entry;
      }
      return entry.copyWith(shopId: activeShopId);
    }).toList();

    final rawStaffPayrollRuns =
        json['staffPayrollRuns'] as List<dynamic>? ?? const <dynamic>[];
    final staffPayrollRuns = rawStaffPayrollRuns.map((item) {
      final run = StaffPayrollRun.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      if (shopIds.contains(run.shopId)) {
        return run;
      }
      return run.copyWith(shopId: activeShopId);
    }).toList();

    final rawSuppliers =
        json['suppliers'] as List<dynamic>? ?? const <dynamic>[];
    final suppliers = rawSuppliers.map((item) {
      final supplier = Supplier.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      if (shopIds.contains(supplier.shopId)) {
        return supplier;
      }
      return supplier.copyWith(shopId: activeShopId);
    }).toList();

    final rawSupplierLedgerEntries =
        json['supplierLedgerEntries'] as List<dynamic>? ?? const <dynamic>[];
    final supplierLedgerEntries = rawSupplierLedgerEntries.map((item) {
      final entry = SupplierLedgerEntry.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      if (shopIds.contains(entry.shopId)) {
        return entry;
      }
      return entry.copyWith(shopId: activeShopId);
    }).toList();

    final rawInventoryItems =
        json['inventoryItems'] as List<dynamic>? ?? const <dynamic>[];
    final inventoryItems = rawInventoryItems.map((item) {
      final inventoryItem = InventoryItem.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      if (shopIds.contains(inventoryItem.shopId)) {
        return inventoryItem;
      }
      return inventoryItem.copyWith(shopId: activeShopId);
    }).toList();

    final rawWholesaleListings =
        json['wholesaleListings'] as List<dynamic>? ?? const <dynamic>[];
    final wholesaleListings = rawWholesaleListings.map((item) {
      final listing = WholesaleListing.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      if (shopIds.contains(listing.shopId)) {
        return listing;
      }
      return listing.copyWith(shopId: activeShopId);
    }).toList();

    final rawSaleRecords =
        json['saleRecords'] as List<dynamic>? ?? const <dynamic>[];
    final saleRecords = rawSaleRecords.map((item) {
      final saleRecord = SaleRecord.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      if (shopIds.contains(saleRecord.shopId)) {
        return saleRecord;
      }
      return saleRecord.copyWith(shopId: activeShopId);
    }).toList();

    final rawReminderLogs =
        json['reminderLogs'] as List<dynamic>? ?? const <dynamic>[];
    final rawBackups = json['backups'] as List<dynamic>? ?? const <dynamic>[];
    final rawReminderInbox =
        json['reminderInbox'] as List<dynamic>? ?? const <dynamic>[];
    final rawInstallmentPlans =
        json['installmentPlans'] as List<dynamic>? ?? const <dynamic>[];
    final rawCustomerVisits =
        json['customerVisits'] as List<dynamic>? ?? const <dynamic>[];
    final rawCommunityBlacklistEntries =
        json['communityBlacklistEntries'] as List<dynamic>? ??
        const <dynamic>[];

    final communityBlacklistEntries = rawCommunityBlacklistEntries.map((item) {
      final entry = CommunityBlacklistEntry.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      if (shopIds.contains(entry.shopId)) {
        return entry;
      }
      return entry.copyWith(shopId: activeShopId);
    }).toList();

    return AppDataSnapshot(
      shops: shops,
      customers: customers,
      transactions: transactions,
      settings: settings.copyWith(
        activeShopId: activeShopId,
        shopName: activeShop.name,
        organizationPhone: activeShop.phone,
        userType: activeShop.userType,
      ),
      partnerProfiles: partnerProfiles,
      staffMembers: staffMembers,
      staffAttendanceEntries: staffAttendanceEntries,
      staffAdvanceEntries: staffAdvanceEntries,
      staffPayrollRuns: staffPayrollRuns,
      suppliers: suppliers,
      supplierLedgerEntries: supplierLedgerEntries,
      inventoryItems: inventoryItems,
      wholesaleListings: wholesaleListings,
      saleRecords: saleRecords,
      reminderLogs: rawReminderLogs
          .map(
            (item) =>
                ReminderLog.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      backups: rawBackups
          .map(
            (item) =>
                BackupRecord.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      reminderInbox: rawReminderInbox
          .map(
            (item) => ReminderInboxItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      installmentPlans: rawInstallmentPlans
          .map(
            (item) => InstallmentPlan.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      customerVisits: rawCustomerVisits
          .map(
            (item) =>
                CustomerVisit.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      communityBlacklistEntries: communityBlacklistEntries,
    );
  }
}
