/// audio_service.dart
/// Manages all audio playback: looping background music and one-shot
/// sound effects via the audioplayers package.
/// All operations are wrapped in try/catch so audio never crashes the game.
/// Music pauses when the app goes to the background (WidgetsBindingObserver).

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

/// Singleton audio manager for the entire app.
class AudioService with WidgetsBindingObserver {
  AudioService._internal();

  static final AudioService instance = AudioService._internal();

  // ── Players ───────────────────────────────────────────────────

  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  bool _initialised = false;

  // ── Lifecycle ─────────────────────────────────────────────────

  /// Initialises the audio service, loads user settings, and registers as an
  /// app-lifecycle observer so music pauses on background.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    try {
      // Load user settings
      _musicEnabled = StorageService.instance.getMusicEnabled();
      _sfxEnabled = StorageService.instance.getSfxEnabled();

      // Configure players
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.5);
      await _sfxPlayer.setVolume(0.8);

      // Register for lifecycle events
      WidgetsBinding.instance.addObserver(this);
    } catch (e) {
      print('[AudioService] init error: $e');
    }
  }

  /// Releases all audio resources. Call when the app is fully destroyed.
  Future<void> dispose() async {
    try {
      WidgetsBinding.instance.removeObserver(this);
      await _musicPlayer.dispose();
      await _sfxPlayer.dispose();
    } catch (e) {
      print('[AudioService] dispose error: $e');
    }
  }

  // ── App lifecycle callbacks ───────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      pauseMusic();
    } else if (state == AppLifecycleState.resumed) {
      resumeMusic();
    }
  }

  // ── Music ─────────────────────────────────────────────────────

  /// Starts looping background music.  Safe to call when already playing.
  Future<void> playMusic() async {
    if (!_musicEnabled) return;
    try {
      final playerState = _musicPlayer.state;
      if (playerState == PlayerState.playing) return;
      await _musicPlayer.play(AssetSource(kAudioMusic));
    } catch (e) {
      print('[AudioService] playMusic error: $e');
    }
  }

  /// Pauses the background music track.
  Future<void> pauseMusic() async {
    try {
      await _musicPlayer.pause();
    } catch (e) {
      print('[AudioService] pauseMusic error: $e');
    }
  }

  /// Resumes a paused background music track.
  Future<void> resumeMusic() async {
    if (!_musicEnabled) return;
    try {
      await _musicPlayer.resume();
    } catch (e) {
      print('[AudioService] resumeMusic error: $e');
    }
  }

  /// Stops and resets the background music.
  Future<void> stopMusic() async {
    try {
      await _musicPlayer.stop();
    } catch (e) {
      print('[AudioService] stopMusic error: $e');
    }
  }

  // ── SFX ───────────────────────────────────────────────────────

  /// Plays the block-placement sound effect.
  Future<void> playPlaceBlock() => _playSfx(kSfxPlaceBlock);

  /// Plays the line-clear celebration sound.
  Future<void> playClearLine() => _playSfx(kSfxClearLine);

  /// Plays the game-over sound.
  Future<void> playGameOver() => _playSfx(kSfxGameOver);

  /// Plays the power-up activation sound.
  Future<void> playPowerup() => _playSfx(kSfxPowerup);

  /// Plays the combo multiplier sound.
  Future<void> playCombo() => _playSfx(kSfxCombo);

  /// Internal helper that plays [assetPath] as a one-shot SFX.
  Future<void> _playSfx(String assetPath) async {
    if (!_sfxEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource(assetPath));
    } catch (e) {
      print('[AudioService] playSfx($assetPath) error: $e');
    }
  }

  // ── Settings ──────────────────────────────────────────────────

  /// Returns whether background music is enabled.
  bool get musicEnabled => _musicEnabled;

  /// Enables or disables background music and persists the setting.
  Future<void> setMusicEnabled(bool value) async {
    _musicEnabled = value;
    try {
      await StorageService.instance.saveMusicEnabled(value);
      if (!value) {
        await pauseMusic();
      } else {
        await resumeMusic();
      }
    } catch (e) {
      print('[AudioService] setMusicEnabled error: $e');
    }
  }

  /// Returns whether SFX are enabled.
  bool get sfxEnabled => _sfxEnabled;

  /// Enables or disables sound effects and persists the setting.
  Future<void> setSfxEnabled(bool value) async {
    _sfxEnabled = value;
    try {
      await StorageService.instance.saveSfxEnabled(value);
    } catch (e) {
      print('[AudioService] setSfxEnabled error: $e');
    }
  }
}
