import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pro_service.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  static const String bannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  static const String _actionCounterKey = 'ad_action_counter';

  static const int _showEvery = 4;

  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;
  bool _isShowingInterstitial = false;
  bool _mobileAdsInitialized = false;

  Future<void> initialize() async {
    if (_mobileAdsInitialized) return;
    await MobileAds.instance.initialize();
    _mobileAdsInitialized = true;
  }

  Future<bool> isPro() => ProService().isPro();

  Future<void> preloadInterstitial() async {
    if (_isLoadingInterstitial || _interstitialAd != null) return;
    if (await isPro()) return;

    await initialize();

    _isLoadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd?.dispose();
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isLoadingInterstitial = false;
        },
      ),
    );
  }

  Future<void> warmUpAfterFirstFrame() async {
    await initialize();
    await preloadInterstitial();
  }

  Future<int> _increaseActionCounter() async {
    final prefs = await SharedPreferences.getInstance();
    final nextCount = (prefs.getInt(_actionCounterKey) ?? 0) + 1;
    await prefs.setInt(_actionCounterKey, nextCount);
    return nextCount;
  }

  Future<void> _resetActionCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_actionCounterKey, 0);
  }

  Future<void> registerActionAndMaybeShow({
    required VoidCallback onContinue,
  }) async {
    if (await isPro()) {
      onContinue();
      return;
    }

    final currentCount = await _increaseActionCounter();

    if (currentCount < _showEvery) {
      onContinue();
      unawaited(preloadInterstitial());
      return;
    }

    if (_interstitialAd == null || _isShowingInterstitial) {
      onContinue();
      unawaited(preloadInterstitial());
      return;
    }

    final ad = _interstitialAd!;
    _interstitialAd = null;
    _isShowingInterstitial = true;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) async {
        ad.dispose();
        _isShowingInterstitial = false;
        await _resetActionCounter();
        onContinue();
        unawaited(preloadInterstitial());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isShowingInterstitial = false;
        onContinue();
        unawaited(preloadInterstitial());
      },
    );

    await ad.show();
  }

  Future<BannerAd?> createAdaptiveBanner({
    required BuildContext context,
  }) async {
    if (await isPro()) return null;

    await initialize();

    final width = MediaQuery.of(context).size.width.truncate();
    if (width <= 0) return null;

    final size =
    await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (size == null) return null;

    final banner = BannerAd(
      size: size,
      adUnitId: bannerAdUnitId,
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
      request: const AdRequest(),
    );

    await banner.load();
    return banner;
  }

  void disposeInterstitial() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}