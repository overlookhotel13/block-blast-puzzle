/// analytics_service.dart
/// Stub for Firebase Analytics integration.
/// All methods are no-ops until you add firebase_analytics to pubspec.yaml
/// and complete the FlutterFire setup.
///
/// TODO: Add firebase_analytics: ^10.x.x to pubspec.yaml
/// TODO: Run `flutterfire configure` to generate google-services.json
/// TODO: Uncomment FirebaseAnalytics calls below

/// Singleton analytics wrapper.
class AnalyticsService {
  AnalyticsService._internal();

  static final AnalyticsService instance = AnalyticsService._internal();

  // TODO: Uncomment when firebase_analytics is added
  // final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // ── Session events ────────────────────────────────────────────

  /// Called when the player starts a new game.
  Future<void> logGameStart({required int level}) async {
    try {
      print('[Analytics] game_start level=$level');
      // TODO: await _analytics.logEvent(name: 'game_start', parameters: {'level': level});
    } catch (e) {
      print('[Analytics] logGameStart error: $e');
    }
  }

  /// Called when the game ends (either game-over or exit).
  Future<void> logGameOver({
    required int score,
    required int level,
    required bool usedContinue,
  }) async {
    try {
      print('[Analytics] game_over score=$score level=$level continue=$usedContinue');
      // TODO: await _analytics.logEvent(name: 'game_over', parameters: {
      //   'score': score, 'level': level, 'used_continue': usedContinue,
      // });
    } catch (e) {
      print('[Analytics] logGameOver error: $e');
    }
  }

  /// Called when a new high score is set.
  Future<void> logNewHighScore(int score) async {
    try {
      print('[Analytics] new_high_score score=$score');
      // TODO: await _analytics.logEvent(name: 'new_high_score', parameters: {'score': score});
    } catch (e) {
      print('[Analytics] logNewHighScore error: $e');
    }
  }

  // ── Power-up events ───────────────────────────────────────────

  /// Called when a power-up is activated (coin purchase or ad watch).
  Future<void> logPowerUpUsed({
    required String type,
    required bool paidWithCoins,
  }) async {
    try {
      print('[Analytics] powerup_used type=$type coins=$paidWithCoins');
      // TODO: await _analytics.logEvent(name: 'powerup_used', parameters: {
      //   'type': type, 'paid_with_coins': paidWithCoins,
      // });
    } catch (e) {
      print('[Analytics] logPowerUpUsed error: $e');
    }
  }

  // ── Ad events ─────────────────────────────────────────────────

  /// Called when a rewarded ad is watched to completion.
  Future<void> logAdWatched({required String placement}) async {
    try {
      print('[Analytics] ad_watched placement=$placement');
      // TODO: await _analytics.logEvent(name: 'ad_watched', parameters: {'placement': placement});
    } catch (e) {
      print('[Analytics] logAdWatched error: $e');
    }
  }

  // ── Daily reward events ───────────────────────────────────────

  /// Called when the player claims a daily reward.
  Future<void> logDailyRewardClaimed({
    required int day,
    required int coinsEarned,
  }) async {
    try {
      print('[Analytics] daily_reward_claimed day=$day coins=$coinsEarned');
      // TODO: await _analytics.logEvent(name: 'daily_reward_claimed', parameters: {
      //   'day': day, 'coins_earned': coinsEarned,
      // });
    } catch (e) {
      print('[Analytics] logDailyRewardClaimed error: $e');
    }
  }

  // ── Level events ──────────────────────────────────────────────

  /// Called when the player levels up.
  Future<void> logLevelUp(int newLevel) async {
    try {
      print('[Analytics] level_up new_level=$newLevel');
      // TODO: await _analytics.logLevelUp(level: newLevel);
    } catch (e) {
      print('[Analytics] logLevelUp error: $e');
    }
  }
}
