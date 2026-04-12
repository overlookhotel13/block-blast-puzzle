/// settings_screen.dart
/// Settings screen allowing the player to toggle music and SFX,
/// and view information about the Remove Ads IAP.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

/// App settings screen (accessible from home and pause menu).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _musicEnabled;
  late bool _sfxEnabled;
  late bool _hasRemovedAds;

  @override
  void initState() {
    super.initState();
    _musicEnabled = AudioService.instance.musicEnabled;
    _sfxEnabled = AudioService.instance.sfxEnabled;
    _hasRemovedAds = StorageService.instance.getHasRemovedAds();
  }

  Future<void> _toggleMusic(bool value) async {
    await AudioService.instance.setMusicEnabled(value);
    setState(() => _musicEnabled = value);
  }

  Future<void> _toggleSfx(bool value) async {
    await AudioService.instance.setSfxEnabled(value);
    setState(() => _sfxEnabled = value);
  }

  // TODO: Implement real IAP via the in_app_purchase package
  // Remove Ads is currently a stub — tapping this shows a placeholder dialog
  void _purchaseRemoveAds() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kColorSurface,
        title: Text(
          'Remove Ads',
          style: GoogleFonts.nunito(
            color: kColorTextPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          // TODO: Replace with real IAP flow using in_app_purchase package
          'IAP coming soon! This will permanently remove all ads for a one-time purchase.',
          style: GoogleFonts.nunito(color: kColorTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.nunito(color: kBlockColors[1])),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      appBar: AppBar(
        backgroundColor: kColorSurface,
        title: Text(
          'Settings',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: kColorTextPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: kColorTextPrimary),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Audio section ──────────────────────────────────────
          _SectionHeader(title: 'Audio'),
          _ToggleTile(
            label: 'Background Music',
            icon: Icons.music_note,
            value: _musicEnabled,
            onChanged: _toggleMusic,
          ),
          _ToggleTile(
            label: 'Sound Effects',
            icon: Icons.volume_up,
            value: _sfxEnabled,
            onChanged: _toggleSfx,
          ),

          const SizedBox(height: 24),

          // ── Purchases section ──────────────────────────────────
          _SectionHeader(title: 'Purchases'),
          _InfoTile(
            label: 'Remove Ads',
            icon: Icons.block,
            subtitle: _hasRemovedAds ? 'Purchased — Thank you!' : 'One-time purchase',
            trailing: _hasRemovedAds
                ? const Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                    onPressed: _purchaseRemoveAds,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlockColors[1],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // TODO: Show real price from StoreKit / Play Billing
                    child: Text('Buy', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                  ),
          ),

          const SizedBox(height: 24),

          // ── About section ──────────────────────────────────────
          _SectionHeader(title: 'About'),
          _InfoTile(
            label: 'Version',
            icon: Icons.info_outline,
            subtitle: '1.0.0',
          ),
          _InfoTile(
            label: 'Privacy Policy',
            icon: Icons.privacy_tip_outlined,
            subtitle: 'Tap to view',
            // TODO: Open your privacy policy URL with url_launcher
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HELPER WIDGETS
// ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: kColorTextSecondary,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kColorSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kColorGridLine),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          label,
          style: GoogleFonts.nunito(
            color: kColorTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        secondary: Icon(icon, color: kColorTextSecondary),
        activeColor: kBlockColors[1],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.label,
    required this.icon,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kColorSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kColorGridLine),
      ),
      child: ListTile(
        leading: Icon(icon, color: kColorTextSecondary),
        title: Text(
          label,
          style: GoogleFonts.nunito(
            color: kColorTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: GoogleFonts.nunito(
                  color: kColorTextSecondary,
                  fontSize: 13,
                ),
              )
            : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
