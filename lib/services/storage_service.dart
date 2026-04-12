/// storage_service.dart
/// Thin wrapper around SharedPreferences for all persistent game data.
/// All reads return sane defaults; all writes are fire-and-forget with
/// error logging.  No game logic lives here — only serialization.

import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/player_data.dart';

/// Singleton service for reading and writing player data to local storage.
class StorageService {
  StorageService._internal();

  static final StorageService instance = StorageService._internal();

  SharedPreferences? _prefs;

  // ── Initialisation ────────────────────────────────────────────

  /// Must be called once before any read/write.  Call from main() after
  /// WidgetsFlutterBinding.ensureInitialized().
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      // If SharedPreferences fails to initialise, the game will use in-memory
      // defaults for this session.  Not ideal but non-fatal.
      print('[StorageService] init error: $e');
    }
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'StorageService.init() was not awaited');
    return _prefs!;
  }

  // ── Score ─────────────────────────────────────────────────────

  /// Returns the all-time high score.
  int getHighScore() => _p.getInt(kPrefHighScore) ?? 0;

  /// Saves [score] as the new high score if it exceeds the current record.
  Future<void> saveHighScore(int score) async {
    try {
      if (score > getHighScore()) {
        await _p.setInt(kPrefHighScore, score);
      }
    } catch (e) {
      print('[StorageService] saveHighScore error: $e');
    }
  }

  // ── Level ─────────────────────────────────────────────────────

  /// Returns the player's current level.
  int getCurrentLevel() => _p.getInt(kPrefCurrentLevel) ?? 1;

  /// Saves the current level.
  Future<void> saveCurrentLevel(int level) async {
    try {
      await _p.setInt(kPrefCurrentLevel, level);
    } catch (e) {
      print('[StorageService] saveCurrentLevel error: $e');
    }
  }

  // ── Coins ─────────────────────────────────────────────────────

  /// Returns the player's current coin balance.
  int getCoins() => _p.getInt(kPrefCoins) ?? 0;

  /// Saves the coin balance.
  Future<void> saveCoins(int coins) async {
    try {
      await _p.setInt(kPrefCoins, coins);
    } catch (e) {
      print('[StorageService] saveCoins error: $e');
    }
  }

  // ── Remove Ads IAP ────────────────────────────────────────────

  // TODO: Wire up real IAP via the in_app_purchase plugin.
  // For now this is a simple boolean flag toggled by the stub.

  /// Returns true if the player has purchased the Remove Ads IAP.
  bool getHasRemovedAds() => _p.getBool(kPrefHasRemovedAds) ?? false;

  /// Saves the Remove Ads purchase state.
  Future<void> saveHasRemovedAds(bool value) async {
    try {
      await _p.setBool(kPrefHasRemovedAds, value);
    } catch (e) {
      print('[StorageService] saveHasRemovedAds error: $e');
    }
  }

  // ── Audio Settings ────────────────────────────────────────────

  /// Returns true if background music is enabled (default: true).
  bool getMusicEnabled() => _p.getBool(kPrefMusicEnabled) ?? true;

  /// Saves the music-enabled setting.
  Future<void> saveMusicEnabled(bool value) async {
    try {
      await _p.setBool(kPrefMusicEnabled, value);
    } catch (e) {
      print('[StorageService] saveMusicEnabled error: $e');
    }
  }

  /// Returns true if sound effects are enabled (default: true).
  bool getSfxEnabled() => _p.getBool(kPrefSfxEnabled) ?? true;

  /// Saves the SFX-enabled setting.
  Future<void> saveSfxEnabled(bool value) async {
    try {
      await _p.setBool(kPrefSfxEnabled, value);
    } catch (e) {
      print('[StorageService] saveSfxEnabled error: $e');
    }
  }

  // ── Daily Reward ──────────────────────────────────────────────

  /// Returns the ISO date string of the last daily reward claim, or empty.
  String getLastDailyRewardDate() => _p.getString(kPrefLastDailyReward) ?? '';

  /// Saves the last daily reward claim date (ISO string).
  Future<void> saveLastDailyRewardDate(String dateStr) async {
    try {
      await _p.setString(kPrefLastDailyReward, dateStr);
    } catch (e) {
      print('[StorageService] saveLastDailyRewardDate error: $e');
    }
  }

  /// Returns the current daily streak count.
  int getDailyStreak() => _p.getInt(kPrefDailyStreak) ?? 0;

  /// Saves the daily streak count.
  Future<void> saveDailyStreak(int streak) async {
    try {
      await _p.setInt(kPrefDailyStreak, streak);
    } catch (e) {
      print('[StorageService] saveDailyStreak error: $e');
    }
  }

  // ── Power-Ups ─────────────────────────────────────────────────

  /// Returns the set of power-up type names the player has unlocked.
  Set<PowerUpType> getUnlockedPowerUps() {
    final raw = _p.getStringList(kPrefUnlockedPowerups) ?? [];
    return raw
        .map((name) => PowerUpType.values.firstWhere(
              (t) => t.name == name,
              orElse: () => PowerUpType.bomb,
            ))
        .toSet();
  }

  /// Saves the set of unlocked power-up types.
  Future<void> saveUnlockedPowerUps(Set<PowerUpType> types) async {
    try {
      await _p.setStringList(
        kPrefUnlockedPowerups,
        types.map((t) => t.name).toList(),
      );
    } catch (e) {
      print('[StorageService] saveUnlockedPowerUps error: $e');
    }
  }

  // ── Bulk Load / Save ──────────────────────────────────────────

  /// Reads all persisted values and returns a [PlayerData] snapshot.
  PlayerData loadPlayerData() {
    return PlayerData(
      highScore: getHighScore(),
      currentLevel: getCurrentLevel(),
      coins: getCoins(),
      unlockedPowerUps: getUnlockedPowerUps(),
      hasRemovedAds: getHasRemovedAds(),
    );
  }

  /// Persists all fields from [data] to SharedPreferences.
  Future<void> savePlayerData(PlayerData data) async {
    await Future.wait([
      saveHighScore(data.highScore),
      saveCurrentLevel(data.currentLevel),
      saveCoins(data.coins),
      saveUnlockedPowerUps(data.unlockedPowerUps),
      saveHasRemovedAds(data.hasRemovedAds),
    ]);
  }
}
