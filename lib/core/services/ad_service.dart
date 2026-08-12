import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:snow/features/premium/data/premium_service.dart';

class AdService {
  AdService._();

  static bool canRequestAds = false;

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static String get bannerAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return 'ca-app-pub-3940256099942544/6300978111';
  }

  static Future<void> initialize() async {
    if (!isSupported) return;
    await MobileAds.instance.initialize();

    final completer = Completer<void>();
    Future<void> finish() async {
      canRequestAds = await ConsentInformation.instance.canRequestAds();
      if (!completer.isCompleted) completer.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((_) => finish());
      },
      (_) => finish(),
    );
    await completer.future;
  }
}

class FreeBannerAd extends StatefulWidget {
  const FreeBannerAd({super.key});

  @override
  State<FreeBannerAd> createState() => _FreeBannerAdState();
}

class _FreeBannerAdState extends State<FreeBannerAd> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    PremiumService.instance.addListener(_premiumChanged);
    _prepare();
  }

  Future<void> _prepare() async {
    await PremiumService.instance.initialize();
    if (!mounted ||
        PremiumService.instance.isPremium ||
        !AdService.isSupported ||
        !AdService.canRequestAds) {
      return;
    }

    final banner = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
        },
      ),
    );
    _banner = banner;
    await banner.load();
  }

  void _premiumChanged() {
    if (!PremiumService.instance.isPremium) return;
    _banner?.dispose();
    _banner = null;
    if (mounted) setState(() => _loaded = false);
  }

  @override
  void dispose() {
    PremiumService.instance.removeListener(_premiumChanged);
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (!_loaded || banner == null || PremiumService.instance.isPremium) {
      return const SizedBox.shrink();
    }

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Center(
          child: SizedBox(
            width: banner.size.width.toDouble(),
            height: banner.size.height.toDouble(),
            child: AdWidget(ad: banner),
          ),
        ),
      ),
    );
  }
}
