import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Prepared for AdMob. Uses test IDs by default.
/// Replace _testIds with real production IDs before release.
///
/// Architecture isolates ads from game logic.
/// If ads fail or offline, game continues without error.
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // ----- CONFIGURE HERE FOR PRODUCTION -----
  // Test IDs (Google provided)
  static const String _bannerTestId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _interstitialTestId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _rewardedTestId = 'ca-app-pub-3940256099942544/5224354917';

  // TODO: Replace with real IDs for release. Set useTestIds = false after replacing.
  static const bool useTestIds = true;
  static const String bannerIdProd = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
  static const String interstitialIdProd = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
  static const String rewardedIdProd = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';

  String get bannerAdUnitId => useTestIds ? _bannerTestId : bannerIdProd;
  String get interstitialAdUnitId => useTestIds ? _interstitialTestId : interstitialIdProd;
  String get rewardedAdUnitId => useTestIds ? _rewardedTestId : rewardedIdProd;
  // ------------------------------------------

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _initialized = false;
  bool _isBannerLoaded = false;

  bool get isBannerLoaded => _isBannerLoaded;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      if (kDebugMode) print('[AdService] initialized');
      // Preload
      loadInterstitial();
      loadRewarded();
    } catch (e) {
      if (kDebugMode) print('[AdService] init failed (offline?): $e');
      // Don't block game
    }
  }

  // BANNER
  BannerAd createBannerAd() {
    final ad = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerLoaded = true;
          if (kDebugMode) print('[AdService] banner loaded');
        },
        onAdFailedToLoad: (ad, err) {
          _isBannerLoaded = false;
          ad.dispose();
          if (kDebugMode) print('[AdService] banner failed: $err');
        },
      ),
    )..load();
    _bannerAd = ad;
    return ad;
  }

  void disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerLoaded = false;
  }

  // INTERSTITIAL
  void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          if (kDebugMode) print('[AdService] interstitial loaded');
        },
        onAdFailedToLoad: (err) {
          _interstitialAd = null;
          if (kDebugMode) print('[AdService] interstitial failed: $err');
        },
      ),
    );
  }

  Future<bool> showInterstitialIfAvailable() async {
    if (_interstitialAd == null) {
      loadInterstitial();
      return false;
    }
    final completer = Completer<bool>();
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitial();
        completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitial();
        completer.complete(false);
      },
    );
    _interstitialAd!.show();
    return completer.future.timeout(const Duration(seconds: 5), onTimeout: () => false);
  }

  // REWARDED
  void loadRewarded() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          if (kDebugMode) print('[AdService] rewarded loaded');
        },
        onAdFailedToLoad: (err) {
          _rewardedAd = null;
          if (kDebugMode) print('[AdService] rewarded failed: $err');
        },
      ),
    );
  }

  /// Shows rewarded ad. Returns true if user earned reward.
  Future<bool> showRewarded({required void Function() onRewarded}) async {
    if (_rewardedAd == null) {
      loadRewarded();
      return false;
    }
    final completer = Completer<bool>();
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _rewardedAd = null;
        loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
      onRewarded();
      if (!completer.isCompleted) completer.complete(true);
    });
    // If user closes before reward, completer will be completed via dismiss
    return completer.future.timeout(const Duration(seconds: 30), onTimeout: () => false);
  }

  bool get isRewardedReady => _rewardedAd != null;
  bool get isInterstitialReady => _interstitialAd != null;
}
