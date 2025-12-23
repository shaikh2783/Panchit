/// ملف الإعدادات الرئيسي للتطبيق
/// يحتوي على جميع المتغيرات والإعدادات القابلة للتخصيص
class AppSettings {
  // ==================== معلومات التطبيق ====================
  /// اسم التطبيق
  static const String appName = 'Panchit';
  // ==================== إعدادات PayPal ====================
  // احصل على بيانات الاعتماد من: https://developer.paypal.com/
  /// معرف العميل - وضع الاختبار (Sandbox)
  /// احصل عليه من: https://developer.paypal.com/dashboard/applications/sandbox
  static const String paypalSandboxClientId =
      'AQZ9cJfUrNDIeaN01OBTx-SsfFGQdHLdsW27phb2lHUx630547ZGhVOBXUQk8JgPvn571rre7cr1NE-m';
  /// المفتاح السري - وضع الاختبار (Sandbox)
  static const String paypalSandboxSecretKey =
      'EDoeQOfeM-S86IbmWhVYJN21rGuAzUJ0i10sV_047d47hhxoEsubWoOxJb7Ff0uAlkxFW32vMKmzSx-U';
  /// معرف العميل - الوضع الحقيقي (Production)
  /// احصل عليه من: https://developer.paypal.com/dashboard/applications/live
  static const String paypalProductionClientId = 'YOUR_PRODUCTION_CLIENT_ID';
  /// المفتاح السري - الوضع الحقيقي (Production)
  static const String paypalProductionSecretKey = 'YOUR_PRODUCTION_SECRET_KEY';
  /// استخدام وضع الاختبار؟ (true = Sandbox, false = Production)
  static const bool paypalUseSandbox = true;
  /// اسم البيئة الحالية
  static String get paypalEnvironment =>
      paypalUseSandbox ? 'Sandbox' : 'Production';
  /// التحقق من صحة إعدادات PayPal قبل المعالجة
  static String? validatePayPalConfig() {
    if (!isPayPalConfigured) {
      return 'بيانات PayPal غير مكتملة. يرجى تحديث الإعدادات في app_config.dart';
    }
    return null;
  }
  // ==================== إعدادات Agora (البث المباشر) ====================
  // احصل على App ID من: https://console.agora.io/
  /// App ID الخاص بـ Agora
  /// احصل عليه من: https://console.agora.io/
  static const String agoraAppId = '06e8cc01e5ce4a1ba6d1254c2a5aa7da';
  /// Token (اختياري للاختبار - يمكن أن يكون null في بيئة الاختبار)
  static const String? agoraToken = null;
  // إعدادات جودة الفيديو للبث
  static const int agoraVideoWidth = 1280;
  static const int agoraVideoHeight = 720;
  static const int agoraFrameRate = 30;
  static const int agoraBitrate = 1500; // kbps
  // إعدادات الصوت للبث
  static const int agoraAudioSampleRate = 48000;
  static const int agoraAudioChannels = 2;
  // مدة انتظار الاتصال
  static const int agoraConnectionTimeoutSeconds = 10;
  // أقصى عدد مستخدمين في البث
  static const int agoraMaxUsers = 100;
  // ==================== إعدادات OneSignal (الإشعارات) ====================
  // احصل على App ID من: https://app.onesignal.com/
  /// App ID الخاص بـ OneSignal
  /// احصل عليه من: https://app.onesignal.com/ > Settings > Keys & IDs
  static const String oneSignalAppId = '0dc8d96f-0113-4a2b-ab63-e0cd64d751c7';

  // ==================== إعدادات Google Sign-In ====================
  // احصل على المعرفات من: https://console.cloud.google.com/

  /// تفعيل تسجيل الدخول عبر Google
  static const bool enableGoogleSignIn = true;

  /// Google Client ID لـ iOS
  /// احصل عليه من: Google Cloud Console > APIs & Services > Credentials
  /// مثال: "123456789-abc123def456.apps.googleusercontent.com"
  static const String googleClientIdIOS = 'YOUR_IOS_CLIENT_ID';

  /// Google Client ID لـ Android
  /// مثال: "123456789-xyz789abc123.apps.googleusercontent.com"
  static const String googleClientIdAndroid =
      '310376752754-aat3tcudo5enqedpecjvou8s6c7b80n1.apps.googleusercontent.com';

  /// Google Client ID لـ Web (اختياري)
  static const String googleClientIdWeb = 'YOUR_WEB_CLIENT_ID';

  /// Reversed Client ID لـ iOS (من GoogleService-Info.plist)
  /// مثال: "com.googleusercontent.apps.123456789-abc123def456"
  static const String googleReversedClientIdIOS = 'YOUR_REVERSED_CLIENT_ID';

  // ==================== إعدادات التخزين المحلي ====================

  /// مدة حفظ الكاش (بالأيام)
  static const int cacheDuration = 7;

  /// الحد الأقصى لحجم الكاش (بالميجابايت)
  static const int maxCacheSize = 100;

  // ==================== إعدادات الكاش للفيديوهات ====================

  /// مدة حفظ كاش الفيديوهات (بالأيام) - منفصل عن الكاش العام
  static const int videoCacheDuration = 7;

  /// تفعيل pre-caching للفيديوهات القادمة
  static const bool enableVideoPreCaching = true;

  /// عدد الفيديوهات التي سيتم pre-cache لها مقدماً
  /// ✅ تقليل من 3 إلى 1 لتقليل استهلاك الذاكرة
  static const int preCacheCount = 1;

  /// حد أقصى لحجم الفيديو الواحد المراد pre-cache (بالميجابايت)
  /// ✅ تقليل من 50 إلى 30 MB
  static const int maxPreCacheVideoSize = 30;

  /// تفعيل pre-caching عند استخدام الشبكة المحمولة فقط؟
  /// ✅ تغيير إلى true لتقليل استهلاك الذاكرة على الشبكات المحمولة
  static const bool preCacheOnlyOnWifi = true;

  /// الحد الأقصى لعدد الفيديوهات المخبأة في الذاكرة
  /// ✅ تقليل من 10 إلى 5
  static const int maxCachedVideosCount = 5;

  // ==================== إعدادات الوسائط ====================

  /// الحد الأقصى لحجم الصورة (بالميجابايت)
  static const int maxImageSize = 10;

  /// الحد الأقصى لحجم الفيديو (بالميجابايت)
  static const int maxVideoSize = 100;

  /// جودة ضغط الصور (0-100)
  static const int imageQuality = 85;

  // ==================== إعدادات المحفظة ====================

  /// الحد الأدنى للشحن
  static const double minRechargeAmount = 5.0;

  /// الحد الأقصى للشحن
  static const double maxRechargeAmount = 10000.0;

  /// الحد الأدنى للسحب
  static const double minWithdrawAmount = 10.0;

  /// العملة الافتراضية
  static const String defaultCurrency = 'USD';

  /// رمز العملة
  static const String currencySymbol = '\$';

  // ==================== إعدادات البث المباشر ====================

  /// الحد الأقصى لمدة البث (بالدقائق)
  static const int maxLiveStreamDuration = 240;

  /// معدل البت للبث
  static const int liveStreamBitrate = 2000;

  /// جودة الفيديو للبث
  static const int liveStreamVideoQuality = 720;

  // ==================== إعدادات الأمان ====================

  /// تفعيل البصمة/Face ID
  static const bool biometricAuthEnabled = true;

  /// مدة انتهاء الجلسة (بالدقائق)
  static const int sessionTimeout = 30;

  /// عدد محاولات تسجيل الدخول المسموحة
  static const int maxLoginAttempts = 5;

  // ==================== إعدادات واجهة المستخدم ====================

  /// تفعيل الوضع الليلي تلقائياً
  static const bool autoDarkMode = true;

  /// عدد العناصر في الصفحة الواحدة
  static const int itemsPerPage = 20;

  /// تفعيل الرسوم المتحركة
  static const bool animationsEnabled = true;

  /// سرعة الرسوم المتحركة (بالميلي ثانية)
  static const int animationDuration = 300;

  // ==================== تفعيل/تعطيل الميزات ====================

  // --------- قسم Feed ---------
  /// تفعيل ميزة News Feed
  static const bool enableNewsFeed = true;

  /// تفعيل ميزة Recent Updates
  static const bool enableRecentUpdates = true;

  /// تفعيل ميزة Popular Posts
  static const bool enablePopularPosts = true;

  /// تفعيل ميزة Discover Posts
  static const bool enableDiscoverPosts = true;

  // --------- قسم Mine ---------
  /// تفعيل ميزة My Blogs
  static const bool enableMyBlogs = true;

  /// تفعيل ميزة My Products
  static const bool enableMyProducts = true;

  /// تفعيل ميزة My Funding
  static const bool enableMyFunding = true;

  /// تفعيل ميزة My Offers
  static const bool enableMyOffers = true;

  /// تفعيل ميزة My Jobs
  static const bool enableMyJobs = true;

  /// تفعيل ميزة My Courses
  static const bool enableMyCourses = true;

  /// تفعيل ميزة Saved
  static const bool enableSaved = true;

  /// تفعيل ميزة Scheduled
  static const bool enableScheduled = true;

  /// تفعيل ميزة Memories
  static const bool enableMemories = true;

  // --------- قسم Advertising ---------
  /// تفعيل ميزة Wallet
  static const bool enableWallet = true;

  /// تفعيل ميزة Ads Campaigns
  static const bool enableAdsCampaigns = true;

  /// تفعيل ميزة Premium Packages
  static const bool enablePremiumPackages = true;

  /// تفعيل ميزة Boosted
  static const bool enableBoosted = true;

  /// تفعيل ميزة Boosted Posts
  static const bool enableBoostedPosts = true;

  /// تفعيل ميزة Boosted Pages
  static const bool enableBoostedPages = true;

  // --------- قسم Explore ---------
  /// تفعيل ميزة People
  static const bool enablePeople = true;

  /// تفعيل ميزة Pages
  static const bool enablePages = true;

  /// تفعيل ميزة Groups
  static const bool enableGroups = true;

  /// تفعيل ميزة Events
  static const bool enableEvents = true;

  /// تفعيل ميزة Market
  static const bool enableMarket = true;

  /// تفعيل ميزة Reels
  static const bool enableReels = true;

  /// تفعيل ميزة Watch
  static const bool enableWatch = true;

  /// تفعيل ميزة Blogs (في قسم Explore)
  static const bool enableBlogs = true;

  /// تفعيل ميزة Funding (في قسم Explore)
  static const bool enableFunding = true;

  /// تفعيل ميزة Offers (في قسم Explore)
  static const bool enableOffers = true;

  /// تفعيل ميزة Jobs (في قسم Explore)
  static const bool enableJobs = true;

  /// تفعيل ميزة Courses (في قسم Explore)
  static const bool enableCourses = true;

  /// تفعيل ميزة Forums
  static const bool enableForums = false;

  /// تفعيل ميزة Movies
  static const bool enableMovies = true;

  /// تفعيل ميزة Games
  static const bool enableGames = false;

  /// تفعيل ميزة Developers
  static const bool enableDevelopers = false;

  /// تفعيل ميزة Merits
  static const bool enableMerits = false;

  // ==================== إعدادات التطوير ====================  /// وضع التطوير (Development Mode)
  static const bool isDevelopment = true;

  /// إظهار سجلات التطبيق (Logs)
  static const bool showLogs = true;

  /// التحقق من اكتمال إعدادات PayPal
  static bool get isPayPalConfigured {
    if (paypalUseSandbox) {
      return paypalSandboxClientId.isNotEmpty &&
          paypalSandboxClientId != 'YOUR_SANDBOX_CLIENT_ID' &&
          paypalSandboxSecretKey.isNotEmpty &&
          paypalSandboxSecretKey != 'YOUR_SANDBOX_SECRET_KEY';
    } else {
      return paypalProductionClientId.isNotEmpty &&
          paypalProductionClientId != 'YOUR_PRODUCTION_CLIENT_ID' &&
          paypalProductionSecretKey.isNotEmpty &&
          paypalProductionSecretKey != 'YOUR_PRODUCTION_SECRET_KEY';
    }
  }

  /// الحصول على معرف عميل PayPal الحالي
  static String get paypalClientId {
    return paypalUseSandbox ? paypalSandboxClientId : paypalProductionClientId;
  }

  /// الحصول على مفتاح PayPal السري الحالي
  static String get paypalSecretKey {
    return paypalUseSandbox
        ? paypalSandboxSecretKey
        : paypalProductionSecretKey;
  }

  /// التحقق من اكتمال إعدادات Agora
  static bool get isAgoraConfigured {
    return agoraAppId.isNotEmpty && agoraAppId != 'YOUR_AGORA_APP_ID';
  }

  /// التحقق من اكتمال إعدادات OneSignal
  static bool get isOneSignalConfigured {
    return oneSignalAppId.isNotEmpty &&
        oneSignalAppId != 'YOUR_ONESIGNAL_APP_ID';
  }

  /// التحقق من صحة المبلغ للشحن
  static bool isValidRechargeAmount(double amount) {
    return amount >= minRechargeAmount && amount <= maxRechargeAmount;
  }

  /// التحقق من صحة المبلغ للسحب
  static bool isValidWithdrawAmount(double amount) {
    return amount >= minWithdrawAmount;
  }

  /// التحقق من اكتمال إعدادات Google Sign-In
  static bool get isGoogleSignInConfigured {
    if (!enableGoogleSignIn) return false;

    // للاختبار: تحقق فقط من Android Client ID
    // في الإنتاج: يجب التحقق من جميع القيم
    return googleClientIdAndroid.isNotEmpty &&
        googleClientIdAndroid != 'YOUR_ANDROID_CLIENT_ID';
  }

  /// التحقق من صحة إعدادات Google Sign-In قبل المعالجة
  static String? validateGoogleSignInConfig() {
    if (!enableGoogleSignIn) {
      return 'تسجيل الدخول عبر Google معطل في الإعدادات';
    }
    if (!isGoogleSignInConfigured) {
      return 'بيانات Google Sign-In غير مكتملة. يرجى تحديث الإعدادات في App_Settings.dart';
    }
    return null;
  }
}
