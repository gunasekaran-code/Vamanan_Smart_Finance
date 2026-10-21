import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/advocate_agreements_model.dart';
import '../../services/advocate_agreements_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class AgreementsScreen extends StatefulWidget {
  const AgreementsScreen({super.key});

  @override
  State<AgreementsScreen> createState() => _AgreementsScreenState();
}

class _AgreementsScreenState extends State<AgreementsScreen> {
  final AgreementsService _service = AgreementsService();

  bool _isLoading = true;
  String? _error;
  List<AgreementModel> _agreements = [];

  @override
  void initState() {
    super.initState();
    _loadAgreements();
  }

  Future<void> _loadAgreements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final agreements = await _service.fetchAgreements();
      setState(() {
        _agreements = agreements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // --- SIGNATURE CONFIRMATION LOGIC ---
  Future<void> _handleSign(AgreementModel item) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Sign Agreement',
      message:
          'Are you sure you want to digitally sign and approve agreement AGR-${item.id} for ${item.customerName}?',
      confirmLabel: 'Sign & Approve',
      confirmButtonColor: AppColors.kSuccess,
    );

    if (confirmed != true) return;

    try {
      await _service.signAgreement(item.id);
      setState(() => item.status = 'SIGNED');
      ToastService.show(
        title: 'Agreement Signed',
        message: 'The agreement has been successfully signed and executed.',
        type: ToastType.success,
      );
    } catch (e) {
      ToastService.show(
        title: 'Signing Failed',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _agreements.where((a) => a.status == 'PENDING').length;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return AppPage(
      title: null, // Custom header built below
      children: [
        // 1. Custom Header matching the image
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'AGREEMENT APPROVALS HUB',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  fontSize: 26,
                  color: Color(0xFF1E293B), // Deep Navy
                  letterSpacing: -1.0,
                ),
              ),
            ),
            if (!isMobile) _buildSignatureBadge(pendingCount),
          ],
        ),
        if (isMobile) ...[
          const SizedBox(height: 16),
          _buildSignatureBadge(pendingCount),
        ],

        const SizedBox(height: 40),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60.0),
            child: Center(child: AppLoader()),
          )
        else if (_error != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Failed to load agreements:\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: _loadAgreements, child: const Text('Retry')),
                ],
              ),
            ),
          )
        else
          // 2. The Rounded Table Container
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                  color: const Color(0xFFF1F5F9),
                  width: 2), // Very light grey border
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
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
                      width: MediaQuery.of(context).size.width -
                          64, // Accounts for AppPage padding
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Table Header Row
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 24),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC), // Slight tint for header
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(30)),
                          ),
                          child: Row(
                            children: [
                              _buildHeaderCell('AGREEMENT ID', flex: 2),
                              _buildHeaderCell('CUSTOMER NAME', flex: 3),
                              _buildHeaderCell('AGREEMENT TYPE', flex: 3),
                              _buildHeaderCell('ACTION',
                                  flex: 2, alignRight: true),
                            ],
                          ),
                        ),

                        // Table Data Rows
                        if (_agreements.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 80),
                            child: Center(
                              child: Text(
                                'ALL AGREEMENTS APPROVED',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFFCBD5E1),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          )
                        else
                          ..._agreements
                              .map((item) => _buildDataRow(item))
                              .toList(),

                        const SizedBox(
                            height: 16), // Bottom padding for the container
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

  // --- HEADER BADGE ---
  Widget _buildSignatureBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.goldBadgeBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.goldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, size: 16, color: AppColors.goldColor),
          const SizedBox(width: 8),
          Text(
            '$count SIGNATURES REQUIRED',
            style: const TextStyle(
              color: AppColors.goldColor,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- TABLE HEADER CELL ---
  Widget _buildHeaderCell(String title,
      {required int flex, bool alignRight = false}) {
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
  Widget _buildDataRow(AgreementModel item) {
    return Column(
      children: [
        const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Row(
            children: [
              // Column 1: ID
              Expanded(
                flex: 2,
                child: Text(
                  'AGR-${item.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),

              // Column 2: Customer Name
              Expanded(
                flex: 3,
                child: Text(
                  item.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),

              // Column 3: Agreement Type
              Expanded(
                flex: 3,
                child: Text(
                  item.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 11,
                    color: Color(0xFF2563EB), // Distinct Blue
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Column 4: Action Button
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: item.status == 'PENDING'
                      ? ElevatedButton(
                          onPressed: () => _handleSign(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'REVIEW & SIGN',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4), // Light Green
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Text(
                            item.status,
                            style: const TextStyle(
                              color: Color(0xFF16A34A), // Green 600
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
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
