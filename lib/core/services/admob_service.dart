import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:snginepro/App_Settings.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';

/// خدمة إدارة إعلانات AdMob
class AdMobService {
  static AdMobService? _instance;
  static AdMobService get instance => _instance ??= AdMobService._();
  
  AdMobService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// التحقق من ما إذا كان يجب عرض الإعلانات
  /// - إذا كان المستخدم مشترك في Pro، لا تظهر الإعلانات
  /// - إذا كانت الإعلانات معطلة في الإعدادات، لا تظهر
  static bool shouldShowAds(BuildContext context) {
    if (!AppSettings.enableAdMob) {
      return false;
    }

    try {
      final authNotifier = context.read<AuthNotifier>();
      final currentUser = authNotifier.currentUser;
      
      if (currentUser != null) {
        // التحقق من حالة الاشتراك في Pro
        final userSubscribed = currentUser['user_subscribed'];
        if (userSubscribed == true || userSubscribed == 1 || userSubscribed == '1') {
          return false; // المستخدم مشترك في Pro، لا تظهر الإعلانات
        }
      }
    } catch (e) {
    }

    return true;
  }

  /// تهيئة AdMob
  Future<void> initialize() async {
    if (!AppSettings.enableAdMob) {
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
    } catch (e) {
    }
  }

  /// الحصول على Banner Ad Unit ID حسب المنصة
  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return AppSettings.adMobBannerAdUnitAndroid;
    } else if (Platform.isIOS) {
      return AppSettings.adMobBannerAdUnitIOS;
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// الحصول على Native Ad Unit ID حسب المنصة
  String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return AppSettings.adMobNativeAdUnitAndroid;
    } else if (Platform.isIOS) {
      return AppSettings.adMobNativeAdUnitIOS;
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// إنشاء Banner Ad
  BannerAd createBannerAd({
    required Function(Ad ad) onAdLoaded,
    required Function(Ad ad, LoadAdError error) onAdFailedToLoad,
    AdSize size = AdSize.banner,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdOpened: (ad) {},
        onAdClosed: (ad) {},
      ),
    );
  }

  /// إنشاء Native Ad
  NativeAd createNativeAd({
    required Function(Ad ad) onAdLoaded,
    required Function(Ad ad, LoadAdError error) onAdFailedToLoad,
  }) {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdOpened: (ad) {},
        onAdClosed: (ad) {},
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: const Color(0xFFFFFFFF),
        cornerRadius: 12.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFFFFFFFF),
          backgroundColor: const Color(0xFF1976D2),
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF000000),
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF666666),
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF999999),
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
    );
  }
}
