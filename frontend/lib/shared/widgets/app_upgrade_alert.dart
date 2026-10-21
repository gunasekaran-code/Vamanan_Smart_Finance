import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

import 'package:frontend/core/theme/app_theme.dart';

/// Copy shown in the upgrade dialog. upgrader 13 takes the title/body from
/// [UpgraderMessages] rather than from the [Upgrader] constructor.
class AppUpgraderMessages extends UpgraderMessages {
  AppUpgraderMessages({super.code});

  @override
  String get title => 'Update Available';

  @override
  String get body =>
      'A new version of Vamanan Gold is available.\nPlease update to continue.';

  @override
  String get buttonTitleUpdate => 'Update Now';
}

/// Drop-in replacement for [UpgradeAlert] that renders the dialog with the
/// app palette and a layout that adapts to phone widths.
class AppUpgradeAlert extends UpgradeAlert {
  AppUpgradeAlert({
    super.key,
    super.upgrader,
    super.navigatorKey,
    super.showIgnore = false,
    super.showLater = false,
    super.showReleaseNotes = false,
    super.barrierDismissible = false,
    super.child,
  });

  @override
  UpgradeAlertState createState() => _AppUpgradeAlertState();
}

class _AppUpgradeAlertState extends UpgradeAlertState {
  @override
  Widget alertDialog(
    Key? key,
    String title,
    String message,
    String? releaseNotes,
    BuildContext context,
    bool cupertino,
    UpgraderMessages messages,
  ) {
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 400;

    // Blocked = installed version is below minAppVersion, so the secondary
    // dismiss actions must never be offered.
    final isBlocked = widget.upgrader.blocked();
    final showLater = !isBlocked && widget.showLater;
    final showIgnore = !isBlocked && widget.showIgnore;

    return Dialog(
      key: key,
      backgroundColor: AppColors.kSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 20 : 32,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        // Keeps the dialog from stretching across tablets/desktop while still
        // filling the available width on a phone.
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: media.size.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 20 : 28,
            isCompact ? 24 : 28,
            isCompact ? 20 : 28,
            isCompact ? 20 : 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: isCompact ? 60 : 68,
                  height: isCompact ? 60 : 68,
                  decoration: const BoxDecoration(
                    color: AppColors.kPrimaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.system_update_rounded,
                    size: isCompact ? 30 : 34,
                    color: AppColors.kPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isCompact ? 19 : 21,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kTextDark,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isCompact ? 14 : 15,
                  color: AppColors.kTextMuted,
                  height: 1.45,
                ),
              ),
              if (releaseNotes != null && releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.kBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.kBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        messages.message(UpgraderMessage.releaseNotes) ??
                            'Release Notes',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTextDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        releaseNotes,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.kTextMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () => onUserUpdated(context, !widget.upgrader.blocked()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    messages.message(UpgraderMessage.buttonTitleUpdate) ??
                        'Update Now',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              if (showLater) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 46,
                  child: TextButton(
                    onPressed: () => onUserLater(context, true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.kTextMuted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      messages.message(UpgraderMessage.buttonTitleLater) ??
                          'Later',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              if (showIgnore) ...[
                const SizedBox(height: 4),
                SizedBox(
                  height: 40,
                  child: TextButton(
                    onPressed: () => onUserIgnored(context, true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.kTextMuted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      messages.message(UpgraderMessage.buttonTitleIgnore) ??
                          'Ignore',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
