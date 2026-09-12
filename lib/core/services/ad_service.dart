import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob reklam kimlikleri ve başlatma servisi.
class AdService {
  AdService._();

  /// Gerçek (production) banner reklam birimi kimliği.
  static const String _liveBannerAdUnitId =
      'ca-app-pub-4612504640509981/4481760319';

  /// Google'ın resmi test banner kimlikleri. Debug derlemelerinde bunlar
  /// kullanılır; böylece AdMob hesabı/uygulaması henüz onaylanmamışken
  /// (yeni hesaplarda ilk 24-48 saat "no fill" normaldir) reklam
  /// altyapısının kendisinin çalışıp çalışmadığı ayrı ayrı test edilebilir.
  static const String _testBannerAdUnitIdAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerAdUnitIdIOS =
      'ca-app-pub-3940256099942544/2934735716';

  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isIOS
          ? _testBannerAdUnitIdIOS
          : _testBannerAdUnitIdAndroid;
    }
    return _liveBannerAdUnitId;
  }

  static bool _isInitialized = false;

  /// Mobile Ads SDK'sını başlatır. Uygulama açılışını (runApp) bloklamaması
  /// için main() içinde await edilmeden çağrılmalıdır.
  static Future<void> initialize() async {
    if (_isInitialized) return;
    await MobileAds.instance.initialize();
    _isInitialized = true;
  }
}
