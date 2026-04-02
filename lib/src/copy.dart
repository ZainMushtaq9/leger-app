import 'models.dart';

class AppCopy {
  const AppCopy(this.language);

  final AppLanguage language;

  String _pick({
    required String english,
    required String romanUrdu,
    required String urdu,
    required String sindhi,
    required String pashto,
  }) {
    switch (language) {
      case AppLanguage.english:
        return english;
      case AppLanguage.romanUrdu:
        return romanUrdu;
      case AppLanguage.urdu:
        return urdu;
      case AppLanguage.sindhi:
        return sindhi;
      case AppLanguage.pashto:
        return pashto;
    }
  }

  String get appName => 'Hisab Rakho';

  String get splashTagline => _pick(
    english: 'Offline-first khata for fast recovery',
    romanUrdu: 'Offline-first khata for fast recovery',
    urdu: 'تیز وصولی کے لیے آف لائن فرسٹ کھاتہ',
    sindhi: 'تيز وصولي لاءِ آف لائن فرسٽ کاتو',
    pashto: 'د چټک وصولۍ لپاره افلاين ختا',
  );

  String get homeTab => _pick(
    english: 'Home',
    romanUrdu: 'Home',
    urdu: 'ہوم',
    sindhi: 'هوم',
    pashto: 'کور',
  );

  String get reportsTab => _pick(
    english: 'Reports',
    romanUrdu: 'Reports',
    urdu: 'رپورٹس',
    sindhi: 'رپورٽس',
    pashto: 'راپورونه',
  );

  String get businessTab => _pick(
    english: 'Business',
    romanUrdu: 'Business',
    urdu: 'Ø¨Ø²Ù†Ø³',
    sindhi: 'Ø¨Ø²Ù†Ø³',
    pashto: 'Ø³ÙˆØ¯Ø§Ú¯Ø±ÙŠ',
  );

  String get settingsTab => _pick(
    english: 'Settings',
    romanUrdu: 'Settings',
    urdu: 'سیٹنگز',
    sindhi: 'سيٽنگون',
    pashto: 'تنظيمات',
  );

  String get welcomeTitle => _pick(
    english: 'Build your workspace',
    romanUrdu: 'Apna workspace tayar karein',
    urdu: 'اپنا ورک اسپیس تیار کریں',
    sindhi: 'پنهنجو ورڪ اسپيس تيار ڪريو',
    pashto: 'خپل کاري ځای جوړ کړئ',
  );

  String get welcomeSubtitle => _pick(
    english:
        'Set your business type, shop profile, and theme before you start.',
    romanUrdu:
        'Business type, shop profile, language aur theme set karein, phir app ready ho jayegi.',
    urdu:
        'کاروبار کی قسم، دکان پروفائل، زبان اور تھیم سیٹ کریں، پھر ایپ تیار ہو جائے گی۔',
    sindhi:
        'ڪاروبار جو قسم، دوڪان پروفائل، ٻولي ۽ ٿيم سيٽ ڪريو، پوءِ ايپ تيار ٿي ويندي.',
    pashto: 'د کاروبار ډول، دوکان پروفايل، ژبه او تيم وټاکئ، بيا اپ چمتو شي.',
  );

  String get walkthroughTitle => _pick(
    english: 'Getting started',
    romanUrdu: 'Getting started',
    urdu: 'فیز 1 فاؤنڈیشن',
    sindhi: 'فيز 1 فائونڊيشن',
    pashto: 'پړاو ۱ بنسټ',
  );

  String get walkthroughBody => _pick(
    english:
        'Splash, onboarding, workspace setup, dark mode, and local storage are all configured here.',
    romanUrdu:
        'Splash, onboarding, workspace setup, language, dark mode aur local database yahin configure hotay hain.',
    urdu:
        'اس مرحلے میں اسپلیش، آن بورڈنگ، ورک اسپیس سیٹ اپ، زبان، ڈارک موڈ اور لوکل ڈیٹابیس سب کنفیگر ہوتے ہیں۔',
    sindhi:
        'هن مرحلي ۾ اسپليش، آن بورڊنگ، ورڪ اسپيس سيٽ اپ، ٻولي، ڊارڪ موڊ ۽ لوڪل ڊيٽابيس سڀ هتي ترتيب ڏنا وڃن ٿا.',
    pashto:
        'په دې پړاو کې سپلاش، انبورډنګ، کاري ځای، ژبه، تياره بڼه او ځايي ډيټابېس ټول تنظيمېږي.',
  );

  String get businessTypeTitle => _pick(
    english: 'Choose your business profile',
    romanUrdu: 'Apna business profile select karein',
    urdu: 'اپنا کاروباری پروفائل منتخب کریں',
    sindhi: 'پنهنجو ڪاروباري پروفائل چونڊيو',
    pashto: 'خپل سوداګريز پروفايل وټاکئ',
  );

  String get workspaceTitle => _pick(
    english: 'Primary shop profile',
    romanUrdu: 'Primary shop profile',
    urdu: 'مرکزی دکان پروفائل',
    sindhi: 'بنيادي دوڪان پروفائل',
    pashto: 'اصلي دوکان پروفايل',
  );

  String get workspaceSubtitle => _pick(
    english:
        'This active shop drives terminology, dashboard totals, and customer data.',
    romanUrdu:
        'Active shop hi terminology, dashboard totals aur customer data ko drive karegi.',
    urdu:
        'فعال دکان ہی اصطلاحات، ڈیش بورڈ ٹوٹلز اور کسٹمر ڈیٹا کو کنٹرول کرے گی۔',
    sindhi:
        'فعال دوڪان ئي اصطلاحات، ڊيش بورڊ ٽوٽلز ۽ گراهڪن جي ڊيٽا کي هلائيندي.',
    pashto:
        'همدا فعاله دوکان به اصطلاحات، ډشبورډ شمېرې او د پېرودونکو معلومات پرمخ وړي.',
  );

  String get appearanceTitle => _pick(
    english: 'Appearance',
    romanUrdu: 'Language aur appearance',
    urdu: 'زبان اور ظاہری انداز',
    sindhi: 'ٻولي ۽ ڏيک',
    pashto: 'ژبه او بڼه',
  );

  String get extraShopsTitle => _pick(
    english: 'Extra shops and businesses',
    romanUrdu: 'Extra shops aur businesses',
    urdu: 'اضافی دکانیں اور کاروبار',
    sindhi: 'وڌيڪ دوڪان ۽ ڪاروبار',
    pashto: 'نورې دوکانونه او کاروبارونه',
  );

  String get extraShopsSubtitle => _pick(
    english: 'Add more workspaces now or manage them later from settings.',
    romanUrdu:
        'Abhi extra workspaces add karein ya baad mein settings se manage karein.',
    urdu: 'ابھی مزید ورک اسپیس شامل کریں یا بعد میں سیٹنگز سے مینج کریں۔',
    sindhi: 'هاڻي وڌيڪ ورڪ اسپيس شامل ڪريو يا پوءِ سيٽنگن مان سنڀاليو.',
    pashto: 'اوس نور کاري ځایونه زيات کړئ يا وروسته يې له تنظيماتو اداره کړئ.',
  );

  String get shopNameLabel => _pick(
    english: 'Shop or organization name',
    romanUrdu: 'Shop ya organization name',
    urdu: 'دکان یا ادارے کا نام',
    sindhi: 'دوڪان يا اداري جو نالو',
    pashto: 'د دوکان يا ادارې نوم',
  );

  String get phoneLabel => _pick(
    english: 'Business phone',
    romanUrdu: 'Business phone',
    urdu: 'کاروباری فون',
    sindhi: 'ڪاروباري فون',
    pashto: 'د کاروبار ټليفون',
  );

  String get languageLabel => _pick(
    english: 'App language',
    romanUrdu: 'App language',
    urdu: 'ایپ کی زبان',
    sindhi: 'ايپ جي ٻولي',
    pashto: 'د اپ ژبه',
  );

  String get themeLabel => _pick(
    english: 'Theme mode',
    romanUrdu: 'Theme mode',
    urdu: 'تھیم موڈ',
    sindhi: 'ٿيم موڊ',
    pashto: 'د تيم حالت',
  );

  String get continueLabel => _pick(
    english: 'Continue',
    romanUrdu: 'Continue',
    urdu: 'جاری رکھیں',
    sindhi: 'جاري رکو',
    pashto: 'دوام',
  );

  String get backLabel => _pick(
    english: 'Back',
    romanUrdu: 'Back',
    urdu: 'واپس',
    sindhi: 'واپس',
    pashto: 'شاته',
  );

  String get finishSetupLabel => _pick(
    english: 'Finish setup',
    romanUrdu: 'Setup finish karein',
    urdu: 'سیٹ اپ مکمل کریں',
    sindhi: 'سيٽ اپ مڪمل ڪريو',
    pashto: 'سيټ اپ بشپړ کړئ',
  );

  String get addAnotherShopLabel => _pick(
    english: 'Add another shop',
    romanUrdu: 'Add another shop',
    urdu: 'ایک اور دکان شامل کریں',
    sindhi: 'ٻيو دوڪان شامل ڪريو',
    pashto: 'بله دوکان زياته کړئ',
  );

  String get noExtraShopLabel => _pick(
    english: 'No extra shops added yet.',
    romanUrdu: 'Abhi koi extra shop add nahi hui.',
    urdu: 'ابھی کوئی اضافی دکان شامل نہیں ہوئی۔',
    sindhi: 'اڃا ڪا وڌيڪ دوڪان شامل ناهي ٿي.',
    pashto: 'لا تر اوسه بله دوکان نه ده زياته شوې.',
  );

  String get saveLabel => _pick(
    english: 'Save',
    romanUrdu: 'Save',
    urdu: 'محفوظ کریں',
    sindhi: 'محفوظ ڪريو',
    pashto: 'خوندي کړئ',
  );

  String get cancelLabel => _pick(
    english: 'Cancel',
    romanUrdu: 'Cancel',
    urdu: 'منسوخ',
    sindhi: 'رد',
    pashto: 'لغوه',
  );

  String get settingsTitle => _pick(
    english: 'Settings',
    romanUrdu: 'Settings',
    urdu: 'سیٹنگز',
    sindhi: 'سيٽنگون',
    pashto: 'تنظيمات',
  );

  String get shopProfileTitle => _pick(
    english: 'Active shop profile',
    romanUrdu: 'Active shop profile',
    urdu: 'فعال دکان پروفائل',
    sindhi: 'فعال دوڪان پروفائل',
    pashto: 'فعاله دوکان پروفايل',
  );

  String get workspaceManagerTitle => _pick(
    english: 'Workspace manager',
    romanUrdu: 'Workspace manager',
    urdu: 'ورک اسپیس مینیجر',
    sindhi: 'ورڪ اسپيس مئنيجر',
    pashto: 'د کاري ځای مدير',
  );

  String get workspaceManagerSubtitle => _pick(
    english: 'Switch, review, and edit multiple shops from one app shell.',
    romanUrdu:
        'Ek hi app shell se multiple shops ko switch, review aur edit karein.',
    urdu: 'ایک ہی ایپ شیل سے متعدد دکانوں کو سوئچ، ریویو اور ایڈٹ کریں۔',
    sindhi: 'هڪ ئي ايپ شيل مان گهڻن دوڪانن کي سوئچ، جائزو ۽ ايڊٽ ڪريو.',
    pashto: 'له همدې اپ شيل څخه څو دوکانونه بدل، وڅېړئ او سم کړئ.',
  );

  String get dataStorageTitle => _pick(
    english: 'Offline data storage',
    romanUrdu: 'Offline data storage',
    urdu: 'لوکل ڈیٹابیس فاؤنڈیشن',
    sindhi: 'لوڪل ڊيٽابيس فائونڊيشن',
    pashto: 'د ځايي ډيټابېس بنسټ',
  );

  String get dataStorageHealthy => _pick(
    english: 'SQLite-backed offline storage is active for this build.',
    romanUrdu: 'SQLite-backed offline storage is active for this build.',
    urdu: 'اس بِلڈ میں SQLite پر مبنی آف لائن اسٹوریج فعال ہے۔',
    sindhi: 'هن بلڊ ۾ SQLite تي ٻڌل آف لائن اسٽوريج فعال آهي.',
    pashto: 'په دې بلډ کې د SQLite پر بنسټ افلاين زېرمه فعاله ده.',
  );

  String get dataStorageFallback => _pick(
    english: 'Local save or load failed. The current session is still running.',
    romanUrdu:
        'Local save ya load fail hua. Current session phir bhi chal raha hai.',
    urdu: 'لوکل سیو یا لوڈ ناکام ہوا۔ موجودہ سیشن پھر بھی چل رہا ہے۔',
    sindhi: 'لوڪل سيو يا لوڊ ناڪام ٿيو. موجوده سيشن اڃا هلي رهيو آهي.',
    pashto: 'ځايي ساتنه يا لوستل ناکام شول، خو اوسنی سيشن لا هم روان دی.',
  );

  String get appearanceSettingsTitle => _pick(
    english: 'Appearance and behavior',
    romanUrdu: 'Appearance aur behavior',
    urdu: 'ظاہری انداز اور رویہ',
    sindhi: 'ڏيک ۽ رويو',
    pashto: 'بڼه او چلند',
  );

  String get saveSettingsLabel => _pick(
    english: 'Save settings',
    romanUrdu: 'Settings save karein',
    urdu: 'سیٹنگز محفوظ کریں',
    sindhi: 'سيٽنگون محفوظ ڪريو',
    pashto: 'تنظيمات خوندي کړئ',
  );

  String get activeLabel => _pick(
    english: 'Active',
    romanUrdu: 'Active',
    urdu: 'فعال',
    sindhi: 'فعال',
    pashto: 'فعاله',
  );

  String get useThisWorkspaceLabel => _pick(
    english: 'Use this workspace',
    romanUrdu: 'Use this workspace',
    urdu: 'یہ ورک اسپیس استعمال کریں',
    sindhi: 'هي ورڪ اسپيس استعمال ڪريو',
    pashto: 'همدا کاري ځای وکاروئ',
  );

  String get editLabel => _pick(
    english: 'Edit',
    romanUrdu: 'Edit',
    urdu: 'ترمیم',
    sindhi: 'ترميم',
    pashto: 'سمون',
  );

  String get homeWorkspaceLabel => _pick(
    english: 'Active workspace',
    romanUrdu: 'Active workspace',
    urdu: 'فعال ورک اسپیس',
    sindhi: 'فعال ورڪ اسپيس',
    pashto: 'فعاله کاري ځای',
  );

  String get workspaceCountLabel => _pick(
    english: 'Workspaces',
    romanUrdu: 'Workspaces',
    urdu: 'ورک اسپیسز',
    sindhi: 'ورڪ اسپيسز',
    pashto: 'کاري ځایونه',
  );

  String get lightModeLabel => _pick(
    english: 'Light',
    romanUrdu: 'Light',
    urdu: 'لائٹ',
    sindhi: 'لائيٽ',
    pashto: 'روښانه',
  );

  String get darkModeLabel => _pick(
    english: 'Dark',
    romanUrdu: 'Dark',
    urdu: 'ڈارک',
    sindhi: 'ڊارڪ',
    pashto: 'تياره',
  );

  String get systemModeLabel => _pick(
    english: 'System',
    romanUrdu: 'System',
    urdu: 'سسٹم',
    sindhi: 'سسٽم',
    pashto: 'سيستم',
  );

  String get shopNameRequired => _pick(
    english: 'Shop name is required.',
    romanUrdu: 'Shop name zaroori hai.',
    urdu: 'دکان کا نام ضروری ہے۔',
    sindhi: 'دوڪان جو نالو ضروري آهي.',
    pashto: 'د دوکان نوم ضروري دی.',
  );

  String get setupSavedMessage => _pick(
    english: 'Setup saved successfully.',
    romanUrdu: 'Setup save ho gaya.',
    urdu: 'فیز 1 سیٹ اپ کامیابی سے محفوظ ہو گیا۔',
    sindhi: 'فيز 1 سيٽ اپ ڪاميابي سان محفوظ ٿي ويو.',
    pashto: 'د پړاو ۱ سيټ اپ په برياليتوب خوندي شو.',
  );

  String get settingsSavedMessage => _pick(
    english: 'Settings saved successfully.',
    romanUrdu: 'Settings save ho gayi.',
    urdu: 'سیٹنگز محفوظ ہو گئیں۔',
    sindhi: 'سيٽنگون محفوظ ٿي ويون.',
    pashto: 'تنظيمات خوندي شوې.',
  );

  String get reloadLocalLabel => _pick(
    english: 'Reload local data',
    romanUrdu: 'Reload local data',
    urdu: 'لوکل ڈیٹا دوبارہ لوڈ کریں',
    sindhi: 'لوڪل ڊيٽا ٻيهر لوڊ ڪريو',
    pashto: 'ځايي معلومات بيا راواخلئ',
  );
}
