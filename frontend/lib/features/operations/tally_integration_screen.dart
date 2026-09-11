import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'dashboard_view_widget.dart';
import 'ledger_view_screen.dart';
import 'audit_logs_view_widget.dart';
import 'pl_balance_sheet_widget.dart';
import 'vouchers_view_widget.dart';
import 'reconciliation_view_widget.dart';
import 'settings_view_widget.dart';

class TallyIntegrationScreen extends StatefulWidget {
  const TallyIntegrationScreen({super.key});

  @override
  State<TallyIntegrationScreen> createState() => _TallyIntegrationScreenState();
}

class _TallyIntegrationScreenState extends State<TallyIntegrationScreen> {
  String _activeTab = 'DASHBOARD'; // Defaulted to Ledgers to show the new screen

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Page Heading ---
            const Text(
              'ACCOUNTING HUB',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Color(0xFF1E3A8A),
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'LEDGERS · REPORTS · VOUCHERS · SYNC TO TALLY ERP PRIME',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF94A3B8).withOpacity(0.9),
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // --- Navigation Chips ---
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildNavChip(
                  'DASHBOARD',
                  Icons.dashboard_outlined,
                  _activeTab == 'DASHBOARD',
                ),
                _buildNavChip(
                  'LEDGERS',
                  Icons.menu_book_outlined,
                  _activeTab == 'LEDGERS',
                ),
                _buildNavChip(
                  'P&L / BALANCE SHEET',
                  Icons.insert_drive_file_outlined,
                  _activeTab == 'P&L / BALANCE SHEET',
                ),
                _buildNavChip(
                  'VOUCHERS',
                  Icons.receipt_long_outlined,
                  _activeTab == 'VOUCHERS',
                ),
                _buildNavChip(
                  'RECONCILIATION',
                  Icons.compare_arrows_outlined,
                  _activeTab == 'RECONCILIATION',
                ),
                _buildNavChip(
                  'AUDIT LOGS',
                  Icons.find_in_page_outlined,
                  _activeTab == 'AUDIT LOGS',
                ),
                _buildNavChip(
                  'SETTINGS',
                  Icons.settings_outlined,
                  _activeTab == 'SETTINGS',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // --- Dynamic Content ---
            if (_activeTab == 'DASHBOARD')
              const DashboardViewWidget()
            else if (_activeTab == 'LEDGERS')
              const LedgerViewWidget()
            else if (_activeTab == 'P&L / BALANCE SHEET')
              const PlBalanceSheetWidget()
            else if (_activeTab == 'VOUCHERS')
              const VouchersViewWidget()
            else if (_activeTab == 'RECONCILIATION')
              const ReconciliationViewWidget()
            else if (_activeTab == 'AUDIT LOGS')
              const AuditLogsViewWidget()
            else if (_activeTab == 'SETTINGS')
              const SettingsViewWidget()
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    'Module under development',
                    style: TextStyle(
                      color: AppColors.kTextMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildNavChip(String label, IconData icon, bool isActive) {
    return InkWell(
      onTap: () {
        setState(() {
          _activeTab = label;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF1E3A8A) : AppColors.kBorder,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? const Color(0xFFFBBF24) : AppColors.kTextMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: isActive ? Colors.white : const Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
      ),
    );
  }

}