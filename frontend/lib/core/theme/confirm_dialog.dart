import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart'; // Adjust path based on your directory layout

class AppConfirmDialog {
  AppConfirmDialog._();

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String cancelLabel = 'Cancel',
    String confirmLabel = 'Delete',
    Color confirmButtonColor = AppColors.kDanger,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.width >= 600;

    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Confirmation',
      barrierColor: Colors.black.withOpacity(0.4), // Darkens background
      transitionDuration: const Duration(milliseconds: 350), // Smooth duration
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        // Tablet slides subtly from center (15% offset); Mobile slides from bottom screen edge (100% offset)
        final slideBegin = isTablet ? const Offset(0, 0.15) : const Offset(0, 1.0);

        return SlideTransition(
          position: Tween<Offset>(
            begin: slideBegin,
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: Align(
              alignment: isTablet ? Alignment.center : Alignment.bottomCenter,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: isTablet ? 500 : double.infinity,
                  margin: isTablet
                      ? const EdgeInsets.symmetric(horizontal: 24, vertical: 24)
                      : EdgeInsets.zero,
                  padding: EdgeInsets.only(
                    top: 28,
                    left: 24,
                    right: 24,
                    bottom: isTablet ? 28 : mediaQuery.padding.bottom + 24,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.kSurface,
                    borderRadius: isTablet
                        ? BorderRadius.circular(24) // Fully rounded on Tablet
                        : const BorderRadius.vertical(
                            top: Radius.circular(24), // Top rounded on Mobile
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.kTextDark,
                              ),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.close, color: AppColors.kTextMuted),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.kTextMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                cancelLabel,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: confirmButtonColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                confirmLabel,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}