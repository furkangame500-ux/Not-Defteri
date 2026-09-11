import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob reklam kimlikleri ve başlatma servisi.
class AdService {
  AdService._();

  /// Banner reklam birimi kimliği.
  static const String bannerAdUnitId =
      'ca-app-pub-4612504640509981/4481760319';

  static bool _isInitialized = false;

  /// Mobile Ads SDK'sını başlatır. Uygulama açılışını (runApp) bloklamaması
  /// için main() içinde await edilmeden çağrılmalıdır.
  static Future<void> initialize() async {
    if (_isInitialized) return;
    await MobileAds.instance.initialize();
    _isInitialized = true;
  }
}
