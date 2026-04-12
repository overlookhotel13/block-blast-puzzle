/// ad_reward_dialog.dart
/// Reusable dialog prompting the user to watch a rewarded ad in exchange
/// for a game benefit (power-up or continue after game-over).
/// Delegates the actual ad display to AdService.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ad_service.dart';
import '../utils/constants.dart';

/// Dialog that shows a "Watch Ad" prompt and handles the ad interaction.
class AdRewardDialog extends StatefulWidget {
  /// Title text shown at the top of the dialog
  final String title;

  /// Explanatory message below the title
  final String message;

  /// Called when the user successfully watches the ad and earns the reward.
  final VoidCallback onRewardGranted;

  const AdRewardDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onRewardGranted,
  });

  @override
  State<AdRewardDialog> createState() => _AdRewardDialogState();
}

class _AdRewardDialogState extends State<AdRewardDialog> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _watchAd() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await AdService.instance.showRewardedAd(
      onRewarded: () {
        // Ad was watched successfully — grant reward then dismiss
        widget.onRewardGranted();
        if (mounted) Navigator.of(context).pop();
      },
      onFailed: () {
        // Ad not available or failed to show
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Ad not available right now. Try again later.';
          });
        }
      },
    );

    // In case the ad was shown (future completes after dismiss), ensure
    // loading state is cleared
    if (mounted && _isLoading) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kColorSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.title,
        style: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: kColorTextPrimary,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play-button icon
          const Icon(Icons.play_circle_fill, color: Colors.amber, size: 56),
          const SizedBox(height: 12),

          Text(
            widget.message,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: kColorTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          // Error message (if ad failed)
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: Colors.redAccent,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'No thanks',
            style: GoogleFonts.nunito(color: kColorTextSecondary),
          ),
        ),

        // Watch Ad button
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _watchAd,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Icon(Icons.videocam, size: 18),
          label: Text(
            _isLoading ? 'Loading...' : 'Watch Ad',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
}
