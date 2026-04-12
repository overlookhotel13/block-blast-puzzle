/// ad_service.dart
/// Manages Google AdMob rewarded ads.
/// Uses test ad unit IDs during development; replace before release.
/// Banner ads are NOT implemented per product requirements.
/// All ad calls are gated behind StorageService.hasRemovedAds so IAP
/// users never see ads.

// TODO: Replace with your real AdMob App ID in AndroidManifest.xml before release
// TODO: Replace testRewardedAdUnitId with your real unit ID before release

import 'dart:io';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

/// Callback signature invoked when a rewarded ad is successfully watched.
typedef RewardCallback = void Function();

/// Singleton ad manager for the entire app session.
class AdService {
  AdService._internal();

  static final AdService instance = AdService._internal();

  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  bool _initialised = false;

  // ── Initialisation ────────────────────────────────────────────

  /// Must be called once from main() after MobileAds.instance.initialize().
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    try {
      await MobileAds.instance.initialize();
      // Pre-load the first rewarded ad so it is ready when needed
      _loadRewardedAd();
    } catch (e) {
      print('[AdService] init error: $e');
    }
  }

  // ── Ad unit IDs ───────────────────────────────────────────────

  /// Returns the correct ad unit ID for the current platform.
  String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      // TODO: Replace with real Android rewarded ad unit ID before release
      return kRewardedAdUnitIdAndroid;
    }
    // TODO: Add iOS ad unit ID
    return kRewardedAdUnitIdAndroid; // Fallback; update for iOS
  }

  // ── Load ──────────────────────────────────────────────────────

  /// Loads a rewarded ad in the background so it is ready instantly when shown.
  void _loadRewardedAd() {
    if (_isAdLoading) return;

    // Skip loading if ads are removed
    if (StorageService.instance.getHasRemovedAds()) return;

    _isAdLoading = true;
    try {
      RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isAdLoading = false;
            _setFullScreenCallbacks(ad);
            print('[AdService] Rewarded ad loaded');
          },
          onAdFailedToLoad: (error) {
            _rewardedAd = null;
            _isAdLoading = false;
            print('[AdService] Rewarded ad failed to load: $error');
          },
        ),
      );
    } catch (e) {
      _isAdLoading = false;
      print('[AdService] _loadRewardedAd error: $e');
    }
  }

  /// Attaches full-screen lifecycle callbacks to [ad].
  void _setFullScreenCallbacks(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        // Pre-load the next ad immediately
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        print('[AdService] Ad failed to show: $error');
      },
    );
  }

  // ── Availability ──────────────────────────────────────────────

  /// True if a rewarded ad has been loaded and is ready to show.
  bool get isRewardedAdReady =>
      _rewardedAd != null &&
      !StorageService.instance.getHasRemovedAds();

  // ── Show ──────────────────────────────────────────────────────

  /// Shows the loaded rewarded ad.
  /// Calls [onRewarded] if the user completes the ad.
  /// Calls [onFailed] if no ad is available or the show fails.
  Future<void> showRewardedAd({
    required RewardCallback onRewarded,
    VoidCallback? onFailed,
  }) async {
    // Gate: If ads removed, grant reward immediately (premium perk)
    if (StorageService.instance.getHasRemovedAds()) {
      onRewarded();
      return;
    }

    if (_rewardedAd == null) {
      print('[AdService] No rewarded ad available');
      onFailed?.call();
      _loadRewardedAd(); // Start loading for next time
      return;
    }

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (_, reward) {
          print('[AdService] User earned reward: ${reward.amount} ${reward.type}');
          onRewarded();
        },
      );
    } catch (e) {
      print('[AdService] showRewardedAd error: $e');
      onFailed?.call();
    }
  }

  // ── Cleanup ───────────────────────────────────────────────────

  /// Disposes the loaded ad.  Call when the app is closing.
  void dispose() {
    try {
      _rewardedAd?.dispose();
      _rewardedAd = null;
    } catch (e) {
      print('[AdService] dispose error: $e');
    }
  }
}
