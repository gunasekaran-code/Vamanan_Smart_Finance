import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';

// --- Dummy Data Model ---
class AgreementArchiveItem {
  final String id;
  final String customerName;
  final String agreementType;
  final String date;
  final String branch;
  final String companyName;
  final String companyAddress;

  AgreementArchiveItem({
    required this.id,
    required this.customerName,
    required this.agreementType,
    required this.date,
    required this.branch,
    required this.companyName,
    required this.companyAddress,
  });
}

class ArchiveAgreementsScreen extends StatefulWidget {
  const ArchiveAgreementsScreen({super.key});

  @override
  State<ArchiveAgreementsScreen> createState() => _ArchiveAgreementsScreenState();
}

class _ArchiveAgreementsScreenState extends State<ArchiveAgreementsScreen> {
  // Dummy Data mimicking your screenshots
  final List<AgreementArchiveItem> _archives = [
    AgreementArchiveItem(
      id: 'AGR-1787720477-93',
      customerName: 'NANDHA KUMAR.M',
      agreementType: 'GOLD ACQUISITION DEED',
      date: '26/8/2026',
      branch: 'KRISHNAGIRI BRANCH',
      companyName: 'VAMANAN ENTERPRISES',
      companyAddress: 'KRISHNAGIRI OPERATIONS CENTER, TAMIL NADU - 635 001.',
    ),
    AgreementArchiveItem(
      id: 'AGR-1787719761-48',
      customerName: 'PRAKASH.A',
      agreementType: 'GOLD ACQUISITION DEED',
      date: '25/8/2026',
      branch: 'CHENNAI MAIN BRANCH',
      companyName: 'VAMANAN ENTERPRISES',
      companyAddress: 'CHENNAI OPERATIONS CENTER, TAMIL NADU - 600 001.',
    ),
    AgreementArchiveItem(
      id: 'AGR-1787661812-50',
      customerName: 'SOMASUNDARAM.S',
      agreementType: 'GOLD ACQUISITION DEED',
      date: '22/8/2026',
      branch: 'MADURAI BRANCH',
      companyName: 'VAMANAN ENTERPRISES',
      companyAddress: 'MADURAI OPERATIONS CENTER, TAMIL NADU - 625 001.',
    ),
    AgreementArchiveItem(
      id: 'AGR-1787658144-122',
      customerName: 'KANAGARAJ K',
      agreementType: 'GOLD ACQUISITION DEED',
      date: '20/8/2026',
      branch: 'COIMBATORE BRANCH',
      companyName: 'VAMANAN ENTERPRISES',
      companyAddress: 'COIMBATORE OPERATIONS CENTER, TAMIL NADU - 641 001.',
    ),
  ];

  void _openVerificationModal(AgreementArchiveItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AgreementVerificationModal(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: null, // Custom header built below
      children: [
        // 1. Header
        const Text(
          'APPROVED AGREEMENTS ARCHIVE',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            fontSize: 24,
            color: Color(0xFF1E293B), // Deep Navy
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 32),

        // 2. Main Rounded Table Container
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Responsive Scrollable Table Wrapper
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  // Tight width (not just minWidth): inside a horizontal
                  // SingleChildScrollView the incoming constraints are
                  // unbounded, and the header/data Rows below use Expanded,
                  // which needs a bounded width to lay out — minWidth alone
                  // leaves maxWidth at infinity and crashes the layout.
                  constraints: BoxConstraints.tightFor(
                    width: MediaQuery.of(context).size.width > 800 ? MediaQuery.of(context).size.width - 64 : 800,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Table Header Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC), // Very light tint
                          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                        ),
                        child: Row(
                          children: [
                            _buildHeaderCell('CUSTOMER DETAILS', flex: 4),
                            _buildHeaderCell('AGREEMENT DETAILS', flex: 4),
                            _buildHeaderCell('STATUS', flex: 2),
                            _buildHeaderCell('ACTION', flex: 1, alignRight: true),
                          ],
                        ),
                      ),
                      
                      // Table Data Rows
                      ..._archives.map((item) => _buildDataRow(item)).toList(),
                        
                      const SizedBox(height: 16), // Bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TABLE HEADER CELL ---
  Widget _buildHeaderCell(String title, {required int flex, bool alignRight = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          fontSize: 10,
          color: Color(0xFF94A3B8), // Slate 400
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  // --- TABLE DATA ROW ---
  Widget _buildDataRow(AgreementArchiveItem item) {
    return Column(
      children: [
        const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Row(
            children: [
              // Column 1: Customer Details
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.customerName[0],
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Column 2: Agreement Details
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.agreementType,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        fontSize: 10,
                        color: AppColors.goldColor, // Gold ID
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Column 3: Status Badge
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.goldBadgeBg, // Light gold bg
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.goldBorder),
                    ),
                    child: const Text(
                      'APPROVED',
                      style: TextStyle(
                        color: AppColors.goldColor,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),

              // Column 4: Action (Eye Icon)
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.remove_red_eye_outlined, size: 16, color: Color(0xFF94A3B8)),
                      onPressed: () => _openVerificationModal(item),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


// ============================================================================
// AGREEMENT VERIFICATION MODAL (Bottom Sheet)
// ============================================================================
class _AgreementVerificationModal extends StatelessWidget {
  final AgreementArchiveItem item;

  const _AgreementVerificationModal({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 80), // Space from top of screen
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Modal Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Dark Navy
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.description_outlined, color: AppColors.goldColor, size: 14),
                    SizedBox(width: 8),
                    Text(
                      'AGREEMENT VERIFICATION',
                      style: TextStyle(
                        color: AppColors.goldColor,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.all(8),
                  minimumSize: Size.zero,
                ),
              )
            ],
          ),
          const SizedBox(height: 32),

          // 2. Center Icon & Title
          Center(
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Icon(Icons.verified, color: AppColors.goldColor, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  item.agreementType,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 20,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AGREEMENT REFERENCE ID: ${item.id}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 10,
                    color: AppColors.goldColor,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
          const SizedBox(height: 24),

          // 3. Establishment Info
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppColors.goldColor, width: 3)),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                  color: Color(0xFF1E293B),
                  letterSpacing: 0.5,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'ESTABLISHED ON '),
                  TextSpan(
                    text: item.date,
                    style: const TextStyle(
                      color: AppColors.goldColor,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.goldColor,
                    ),
                  ),
                  TextSpan(text: ' AT THE\n${item.branch}.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 4. Company (Issuer) Card
          _buildInfoCard(
            label: 'COMPANY (ISSUER)',
            title: item.companyName,
            subtitle: item.companyAddress,
          ),
          const SizedBox(height: 16),

          // 5. Customer Details Card
          _buildInfoCard(
            label: 'CUSTOMER DETAILS',
            title: item.customerName,
            subtitle: '*** / ***',
          ),
          
          // Safe area padding for bottom of screen
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String label, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}