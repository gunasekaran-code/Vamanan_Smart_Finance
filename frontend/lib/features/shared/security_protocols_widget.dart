import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

class SecurityProtocolsWidget extends StatefulWidget {
  const SecurityProtocolsWidget({super.key});

  @override
  State<SecurityProtocolsWidget> createState() => _SecurityProtocolsWidgetState();
}

class _SecurityProtocolsWidgetState extends State<SecurityProtocolsWidget> {
  // Mock State
  bool _isOperational = true;

  // --- Handlers ---

  Future<void> _handleProtocolOffline() async {
    if (!_isOperational) return;

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'EMERGENCY OVERRIDE',
      message: 'CRITICAL WARNING: Taking the protocol offline will immediately sever access for all global nodes. Do you want to proceed?',
      confirmLabel: 'FORCE OFFLINE',
      cancelLabel: 'CANCEL',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed == true) {
      setState(() => _isOperational = false);
      ToastService.show(
        title: 'Protocol Severed', 
        message: 'System is now offline. Node access restricted.', 
        type: ToastType.error
      );
    }
  }

  Future<void> _handleSystemOperational() async {
    if (_isOperational) return;

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'RESTORE PROTOCOL',
      message: 'Restore global node access and resume standard operations?',
      confirmLabel: 'RESTORE',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFFD97706),
    );

    if (confirmed == true) {
      setState(() => _isOperational = true);
      ToastService.show(
        title: 'System Restored', 
        message: 'Platform operations are back online.', 
        type: ToastType.success
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- 1. Platform State Override Card ---
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // Light blue background
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Stack(
              children: [
                // Watermark Icon
                Positioned(
                  right: -20,
                  bottom: -30,
                  child: Icon(
                    Icons.security_update_warning,
                    size: 160,
                    color: const Color(0xFF3B82F6).withOpacity(0.08),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 24),
                          const SizedBox(width: 12),
                          const Text(
                            'PLATFORM STATE OVERRIDE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF1E3A8A), // Navy text
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'EMERGENCY PROTOCOL TO RESTRICT NODE ACCESS GLOBALLY. USE ONLY DURING MAINTENANCE OR SECURITY BREACH MITIGATION.',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF64748B),
                          height: 1.6,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Responsive Action Buttons
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool isMobile = constraints.maxWidth < 500;
                          
                          Widget offlineBtn = ElevatedButton(
                            onPressed: _handleProtocolOffline,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                              shadowColor: Colors.black.withOpacity(0.1),
                            ),
                            child: const Text('PROTOCOL OFFLINE', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1.5)),
                          );

                          Widget operationalBtn = ElevatedButton(
                            onPressed: _handleSystemOperational,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB48A28), // Matches the dark gold/bronze in the design
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                              shadowColor: const Color(0xFFB48A28).withOpacity(0.3),
                            ),
                            child: const Text('SYSTEM OPERATIONAL', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1.5)),
                          );

                          if (isMobile) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                offlineBtn,
                                const SizedBox(height: 16),
                                operationalBtn,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: offlineBtn),
                              const SizedBox(width: 16),
                              Expanded(child: operationalBtn),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // --- 2. Network Security Status Card ---
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB), // Light amber tint
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Stack(
              children: [
                // Watermark Icon
                Positioned(
                  right: -10,
                  top: -20,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 160,
                    color: const Color(0xFFD97706).withOpacity(0.05),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, color: Color(0xFFD97706), size: 24),
                          const SizedBox(width: 12),
                          const Text(
                            'NETWORK SECURITY STATUS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFFD97706), // Gold/Amber text
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Stat Boxes (Responsive)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool isMobile = constraints.maxWidth < 600;
                          
                          Widget encrytionStat = _buildStatusCard('ENCRYPTION', 'AES-256\nACTIVE');
                          Widget accessLogsStat = _buildStatusCard('ACCESS LOGS', 'MONITORED');
                          Widget isolationStat = _buildStatusCard('NODE ISOLATION', 'ENABLED');

                          if (isMobile) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                encrytionStat,
                                const SizedBox(height: 16),
                                accessLogsStat,
                                const SizedBox(height: 16),
                                isolationStat,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: encrytionStat),
                              const SizedBox(width: 16),
                              Expanded(child: accessLogsStat),
                              const SizedBox(width: 16),
                              Expanded(child: isolationStat),
                            ],
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widget ---

  Widget _buildStatusCard(String label, String status) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEF3C7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFF94A3B8),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            status,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFF1E3A8A), // Navy text
              height: 1.4,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}