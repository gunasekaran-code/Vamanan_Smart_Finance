import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_upload.dart'; // Ensure this points to your provided AppUpload file

class PayoutReconciliationScreen extends StatefulWidget {
  const PayoutReconciliationScreen({super.key});

  @override
  State<PayoutReconciliationScreen> createState() => _PayoutReconciliationScreenState();
}

class _PayoutReconciliationScreenState extends State<PayoutReconciliationScreen> {
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
              // --- Global Search Bar ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users, orders, assets...',
                    hintStyle: TextStyle(
                      color: AppColors.kTextMuted,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Responsive Grid for Hub and Pulse ---
              LayoutBuilder(
                builder: (context, constraints) {
                  // Stack vertically on mobile, side-by-side on tablet/desktop
                  if (constraints.maxWidth < 800) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBankResponseHub(context),
                        const SizedBox(height: 24),
                        _buildSystemPulse(),
                      ],
                    );
                  } else {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _buildBankResponseHub(context)),
                        const SizedBox(width: 24),
                        Expanded(flex: 4, child: _buildSystemPulse()),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 24),

              // --- Status Matrix (Data Table) ---
              _buildStatusMatrix(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. Bank Response Hub (Deep Blue Card) ---
  Widget _buildBankResponseHub(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A), // Deep Navy Blue
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24), // Amber/Gold
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BANK RESPONSE HUB',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PAYOUT RECONCILIATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Upload Area (Hooks into provided AppUpload widget)
          InkWell(
            onTap: () => AppUpload.showImagePickerModal(
              context,
              title: 'Upload Bank Response Document',
            ),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1.5,
                  style: BorderStyle.solid, // Using solid as flutter dashed requires external package
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.upload_file, color: Colors.white.withOpacity(0.8), size: 32),
                  const SizedBox(height: 12),
                  const Text(
                    'UPLOAD BANK RESPONSE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Excel, CSV, or PDF Documents.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Document Specification List
          const Text(
            'DOCUMENT SPECIFICATION',
            style: TextStyle(
              color: Color(0xFFFBBF24),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _buildSpecItem('Column 1: Transaction ID'),
          const SizedBox(height: 8),
          _buildSpecItem('Column 2: Status (Success/Failed)'),
          const SizedBox(height: 8),
          _buildSpecItem('Column 3: Failure Reason'),
          const SizedBox(height: 32),

          // Get Live Template Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download, size: 16),
              label: const Text(
                'GET LIVE TEMPLATE',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                backgroundColor: Colors.white.withOpacity(0.05),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String text) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 4, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // --- 2. System Pulse Section ---
  Widget _buildSystemPulse() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SYSTEM PULSE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.5,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Text(
                    '1:46:23 PM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF94A3B8).withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Stats Rows
          _buildPulseStatRow('PENDING BATCH', '0', Icons.pending_actions, const Color(0xFFD97706)),
          const SizedBox(height: 12),
          _buildPulseStatRow('RECONCILED SUCCESS', '0', Icons.check_circle_outline, const Color(0xFFD97706)),
          const SizedBox(height: 12),
          _buildPulseStatRow('FAILURE INTERCEPTS', '0', Icons.cancel_outlined, const Color(0xFF3B82F6)),
          const SizedBox(height: 32),

          // Refresh Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(
                'REFRESH RECORDS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseStatRow(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Status Matrix Table ---
  Widget _buildStatusMatrix(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.storage, color: Color(0xFFD97706), size: 20),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'STATUS MATRIX',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'DATA VERIFICATION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF94A3B8).withOpacity(0.8),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Filter Dropdown Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.kBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_alt_outlined, size: 16, color: AppColors.kTextMuted),
                      SizedBox(width: 8),
                      Text(
                        'ALL STATUS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          const Divider(height: 1, color: AppColors.kBorder),

          // Horizontal Scroll for Table Headers
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 48, 
              ),
              child: DataTable(
                columnSpacing: 48,
                headingRowHeight: 56,
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                dividerThickness: 0,
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
                columns: const [
                  DataColumn(label: Text('INVESTOR ID')),
                  DataColumn(label: Text('TRANSACTION')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('ACTION NEEDED')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: const [], // Empty rows
              ),
            ),
          ),
          
          // Empty State Area
          Container(
            padding: const EdgeInsets.symmetric(vertical: 80),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 40,
                  color: const Color(0xFFCBD5E1).withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'NO STATUS ISSUES FOUND',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}