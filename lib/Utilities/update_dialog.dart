import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/remote_config_service.dart';

/// Shows the update dialog. Call this after [RemoteConfigService.checkForUpdate].
///
/// If [updateInfo.forceUpdate] is true, the dialog is NOT dismissible and
/// the user MUST go to the store.
///
/// If [updateInfo.softUpdate] is true, the dialog can be dismissed once.
Future<void> showUpdateDialog(
  BuildContext context,
  UpdateInfo updateInfo,
) async {
  if (!updateInfo.hasUpdate) return;

  await showDialog(
    context: context,
    barrierDismissible: !updateInfo.forceUpdate,
    builder: (ctx) => _UpdateDialog(updateInfo: updateInfo),
  );
}

class _UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  const _UpdateDialog({required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent Android back-button on force update
      canPop: !updateInfo.forceUpdate,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: _DialogContent(updateInfo: updateInfo),
      ),
    );
  }
}

class _DialogContent extends StatelessWidget {
  final UpdateInfo updateInfo;
  const _DialogContent({required this.updateInfo});

  static const _navy = Color(0xFF0A1628);
  static const _gold = Color(0xFFD4A853);
  static const _cardBg = Color(0xFF13213A);
  static const _textPrimary = Color(0xFFF0F0F0);
  static const _textSecondary = Color(0xFF9BA3B4);

  @override
  Widget build(BuildContext context) {
    final bool isForce = updateInfo.forceUpdate;

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header banner ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Platform-specific store icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha:0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: _gold, width: 2),
                  ),
                  child: Icon(
                    Platform.isIOS
                        ? Icons.apple
                        : Icons.android,
                    color: _gold,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isForce ? 'Update Required' : 'Update Available',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                if (updateInfo.latestVersion.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha:0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'v${updateInfo.latestVersion}',
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Body ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              children: [
                Text(
                  updateInfo.updateMessage.isNotEmpty
                      ? updateInfo.updateMessage
                      : 'A new version of My CRM app: Real estate is available. Please update to continue using the app.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                if (isForce) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: Colors.red.withValues(alpha:0.3), width: 1),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.redAccent, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This update is required to continue using the app.',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Buttons ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              children: [
                // Update now button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _openStore(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: _navy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Platform.isIOS ? Icons.apple : Icons.android,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Platform.isIOS
                              ? 'Update on App Store'
                              : 'Update on Play Store',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // "Later" button only for soft updates
                if (!isForce) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: _textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Maybe Later',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openStore(BuildContext context) async {
    final url = updateInfo.storeUrl; // platform-aware: iOS → App Store, Android → Play Store
    if (url.isEmpty) {
      debugPrint('No store URL configured for this platform in Remote Config.');
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
