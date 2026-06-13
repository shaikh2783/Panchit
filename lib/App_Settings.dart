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
      'AWYoJZpCtdr2IFQuay7pNTN9jmZkEqfYskyFWR3KT7WkdT3GwCX6Z5O87tn2-YgqemtnKGjbq1k5vius';

  /// المفتاح السري - وضع الاختبار (Sandbox)
  static const String paypalSandboxSecretKey =
      'ENJ-xbUpPfxPs5rdXRlkxpuy8r9xewamKuzbL2FkwLlm_vFur6G1O96RGCbPcfbpHx3AzG0Iec75L7NX';

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
  static const String oneSignalAppId = '4f06c127-3bc9-48be-b08e-fce0f8907d65';

  // ==================== إعدادات AdMob (الإعلانات) ====================
  // احصل على App IDs و Ad Unit IDs من: https://apps.admob.com/

  /// إظهار إعلان في PostCard كل X منشور
  /// مثال: 5 = إظهار إعلان بعد كل 5 منشورات
  static const int adMobPostCardFrequency = 5;

  /// إظهار إعلان في ProfilePage
  static const bool enableAdMobInProfile = false;

  /// إظهار إعلان في SearchPage
  static const bool enableAdMobInSearch = false;

  /// إظهار إعلان في نتائج البحث كل X نتيجة
  static const int adMobSearchResultFrequency = 8;

  /// إظهار إعلان Banner في Menu Page
  static const bool enableAdMobInMenu = true;

  // ==================== إعدادات Google Sign-In ====================
  // احصل على المعرفات من: https://console.cloud.google.com/

  /// تفعيل تسجيل الدخول عبر Google
  static const bool enableGoogleSignIn = true;

  /// Google Client ID لـ iOS
  /// احصل عليه من: Google Cloud Console > APIs & Services > Credentials
  /// مثال: "123456789-abc123def456.apps.googleusercontent.com"
  static const String googleClientIdIOS = '655828953502-f2sds4bbkom2cbslkctolp3dh6r3uaco.apps.googleusercontent.com';

  /// Google Client ID لـ Android
  /// مثال: "123456789-xyz789abc123.apps.googleusercontent.com"
  static const String googleClientIdAndroid =
      '655828953502-fn6iog5rv9hpkoucp540othl178h5cja.apps.googleusercontent.com';

  /// Google Client ID لـ Web (اختياري)
  static const String googleClientIdWeb = 'YOUR_WEB_CLIENT_ID';

  /// Reversed Client ID لـ iOS (من GoogleService-Info.plist)
  /// مثال: "com.googleusercontent.apps.123456789-abc123def456"
  static const String googleReversedClientIdIOS =
      'com.googleusercontent.apps.655828953502-f2sds4bbkom2cbslkctolp3dh6r3uaco';

  // ==================== إعدادات الذكاء الاصطناعي (AI) ====================

  /// تفعيل ميزة الذكاء الاصطناعي
  static const bool enableAI = true;

  /// مفتاح API للذكاء الاصطناعي (OpenAI, Gemini, إلخ)
  /// احصل عليه من: https://platform.openai.com/api-keys
  static const String aiApiKey = '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';

  /// نموذج الذكاء الاصطناعي المستخدم
  /// أمثلة: 'gpt-4', 'gpt-3.5-turbo', 'gemini-pro'
  static const String aiModel = 'gpt-3.5-turbo';

  /// من يُسمح له باستخدام الذكاء الاصطناعي
  /// 'all' = الجميع، 'pro' = فقط مستخدمي Pro، 'vip' = فقط VIP
  static const String aiAccessLevel = 'all';

  /// الحد الأقصى لعدد طلبات AI اليومية عند السماح للجميع (all)
  static const int aiMaxRequestsPerDayAll = 5;

  /// الحد الأقصى لعدد طلبات AI اليومية للمستخدم العادي
  static const int aiMaxRequestsPerDayFree = 5;

  /// الحد الأقصى لعدد طلبات AI اليومية لمستخدمي Pro
  static const int aiMaxRequestsPerDayPro = 100;

  /// الحد الأقصى لعدد الأحرف في الطلب الواحد
  static const int aiMaxCharactersPerRequest = 2000;

  /// اسم البوت للذكاء الاصطناعي (يُستخدم في المنشن @)
  /// مثال: '@grock' أو '@ai' أو '@assistant'
  static const String aiBotUsername = 'ai';

  /// إيميل حساب البوت (للحصول على توكن)
  static const String aiBotEmail = 'ai@example.com';

  /// كلمة مرور حساب البوت
  static const String aiBotPassword = 'ai@example.com';

  /// تفعيل الرد التلقائي على التعليقات التي تحتوي منشن للبوت
  static const bool enableAIAutoReply = true;

  /// الرد على التعليقات الرئيسية فقط أم الردود أيضاً؟
  static const bool aiReplyToReplies = true;

  /// التحقق من اكتمال إعدادات AI
  static bool get isAIConfigured {
    return enableAI && aiApiKey.isNotEmpty && aiApiKey != 'YOUR_AI_API_KEY';
  }

  /// التحقق من صحة إعدادات AI قبل الاستخدام
  static String? validateAIConfig() {
    if (!enableAI) {
      return 'ميزة الذكاء الاصطناعي معطلة في الإعدادات';
    }
    if (!isAIConfigured) {
      return 'مفتاح API للذكاء الاصطناعي غير مكتمل. يرجى تحديث الإعدادات في App_Settings.dart';
    }
    return null;
  }

  /// التحقق من صلاحية المستخدم لاستخدام AI
  /// @param userType: 'free', 'pro', 'vip'
  static bool canUserAccessAI(String userType) {
    if (!enableAI) return false;

    switch (aiAccessLevel) {
      case 'all':
        return true;
      case 'pro':
        return userType == 'pro' || userType == 'vip';
      case 'vip':
        return userType == 'vip';
      default:
        return false;
    }
  }

  /// الحصول على الحد الأقصى لطلبات AI بناءً على نوع المستخدم
  static int getMaxAIRequestsPerDay(String userType) {
    if (aiAccessLevel == 'all') {
      return aiMaxRequestsPerDayAll;
    }
    if (userType == 'pro' || userType == 'vip') {
      return aiMaxRequestsPerDayPro;
    }
    return aiMaxRequestsPerDayFree;
  }

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

  // ==================== إعدادات تشغيل الفيديو ====================

  /// فتح فيديوهات YouTube في التطبيق (WebView) أم في المتصفح الخارجي
  /// true = تشغيل داخل التطبيق (WebView)
  /// false = فتح في متصفح خارجي
  static const bool playYouTubeInApp = false;

  /// فتح فيديوهات TikTok في التطبيق (WebView) أم في المتصفح الخارجي
  /// true = تشغيل داخل التطبيق (WebView)
  /// false = فتح في متصفح خارجي
  static const bool playTikTokInApp = false;

  /// فتح فيديوهات Vimeo في التطبيق (WebView) أم في المتصفح الخارجي
  /// true = تشغيل داخل التطبيق (WebView)
  /// false = فتح في متصفح خارجي
  static const bool playVimeoInApp = false;

  /// فتح الفيديوهات المضمنة (Embedded) في تطبيق خارجي إذا كان مثبتاً
  /// ملاحظة: هذا الإعداد حالياً غير مفعّل
  static const bool useNativeVideoAppsIfAvailable = false;

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
        oneSignalAppId != '4f06c127-3bc9-48be-b08e-fce0f8907d65';
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
